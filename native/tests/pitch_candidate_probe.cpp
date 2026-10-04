// Host-only exact-window candidate probe. Labels and reference notes are not
// inputs: this program sees only mono-44100-f32le PCM and a safe case ID.
#include "open_dsp_trace_hook.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

namespace {
constexpr double pi = 3.14159265358979323846;
std::ofstream baseline, evidence;
std::string case_id;
std::array<double, MA_WINDOW_SAMPLES> hann;

double spectral(const float *window, double hz) {
  if (hz < 80 || hz > 2000) return 0;
  const double coefficient = 2 * std::cos(2 * pi * hz / MA_SAMPLE_RATE);
  double one = 0, two = 0;
  for (size_t i = 0; i < MA_WINDOW_SAMPLES; ++i) {
    const double next = window[i] * hann[i] + coefficient * one - two;
    two = one;
    one = next;
  }
  return std::sqrt(std::max(0.0, one * one + two * two - coefficient * one * two));
}

bool safe_id(const std::string &id) {
  return !id.empty() && std::all_of(id.begin(), id.end(), [](char c) {
    return (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9');
  });
}
}  // namespace

void ma_trace_yin_window(const float *window, const ma_feature &feature,
                         const double *cmnd, int min_lag, int max_lag,
                         int selected_lag, double interpolated_lag) {
  struct Candidate { int lag; double cmnd; };
  std::vector<Candidate> candidates;
  for (int lag = min_lag; lag <= max_lag; ++lag) {
    if (cmnd[lag] <= cmnd[lag - 1] && cmnd[lag] <= cmnd[lag + 1])
      candidates.push_back({lag, cmnd[lag]});
  }
  // Keep shortest-lag alternatives, the selected lag, and the strongest
  // minima; this is independent of any expected pitch or source filename.
  std::vector<Candidate> retained;
  for (const auto &candidate : candidates) {
    if (retained.size() < 6 || candidate.lag == selected_lag)
      retained.push_back(candidate);
  }
  std::vector<Candidate> by_fit = candidates;
  std::sort(by_fit.begin(), by_fit.end(), [](auto a, auto b) {
    return a.cmnd < b.cmnd;
  });
  for (size_t i = 0; i < std::min<size_t>(3, by_fit.size()); ++i) {
    const auto candidate = by_fit[i];
    if (std::none_of(retained.begin(), retained.end(), [&](auto c) {
          return c.lag == candidate.lag;
        })) retained.push_back(candidate);
  }
  for (const auto &candidate : retained) {
    const double hz = static_cast<double>(MA_SAMPLE_RATE) / candidate.lag;
    evidence << case_id << ',' << feature.frame_start_sample << ','
             << feature.timestamp_seconds << ',' << candidate.lag << ','
             << hz << ',' << candidate.cmnd << ','
             << (candidate.lag == selected_lag ? 1 : 0) << ','
             << spectral(window, hz) << ',' << spectral(window, 2 * hz)
             << ',' << spectral(window, 3 * hz) << ','
             << spectral(window, hz / 2) << ','
             << interpolated_lag << '\n';
  }
}

int main(int argc, char **argv) {
  if (argc != 5 || !safe_id(argv[1])) return 2;
  case_id = argv[1];
  std::ifstream input(argv[2], std::ios::binary);
  if (!input) return 3;
  baseline.open(argv[3], std::ios::app);
  evidence.open(argv[4], std::ios::app);
  if (!baseline || !evidence) return 4;
  baseline << std::setprecision(12);
  evidence << std::setprecision(12);
  for (size_t i = 0; i < hann.size(); ++i)
    hann[i] = .5 - .5 * std::cos(2 * pi * i / (hann.size() - 1));
  ma_config config{sizeof(ma_config), MA_ABI_VERSION, MA_SAMPLE_RATE, 1};
  ma_context *context = nullptr;
  if (ma_create(&config, &context) != MA_OK) return 5;
  std::array<float, MA_HOP_SAMPLES> hop{};
  std::array<ma_feature, MA_MAX_QUEUED_FEATURES> features{};
  auto drain = [&]() {
    size_t produced = 0;
    const auto status = ma_read_features(context, features.data(),
                                         features.size(), &produced);
    if (status != MA_OK) return false;
    for (size_t i = 0; i < produced; ++i) {
      const auto &f = features[i];
      baseline << case_id << ',' << f.frame_start_sample << ','
               << f.timestamp_seconds << ',' << f.pitch_hz << ','
               << f.pitch_confidence << ',' << f.rms << ',' << f.energy << ','
               << f.peak_abs << ',' << f.clipping_fraction << ','
               << f.onset_strength << ',' << f.onset_candidate << ','
               << f.is_silent << ',' << f.is_partial << '\n';
    }
    return true;
  };
  while (input) {
    input.read(reinterpret_cast<char *>(hop.data()), sizeof(hop));
    const size_t count = static_cast<size_t>(input.gcount()) / sizeof(float);
    if (!count) break;
    size_t consumed = 0;
    if (ma_push_samples(context, hop.data(), count, &consumed) != MA_OK ||
        consumed != count || !drain()) { ma_destroy(context); return 6; }
  }
  if (ma_finalize(context) != MA_OK || !drain()) {
    ma_destroy(context); return 7;
  }
  ma_destroy(context);
  return 0;
}
