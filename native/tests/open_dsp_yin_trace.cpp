// Diagnostic executable only: uses the same OpenEngine translation unit and
// observes its exact rolling window without adding symbols to the public ABI.
#include "open_dsp_trace_hook.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

namespace {
constexpr double kPi = 3.14159265358979323846;
std::map<uint64_t, double> targets;
std::ofstream trace_file, candidate_file, spectrum_file;
size_t traced = 0;

double magnitude(const float *window, double hz) {
  double re = 0.0, im = 0.0;
  for (size_t i = 0; i < MA_WINDOW_SAMPLES; ++i) {
    const double taper = 0.5 - 0.5 * std::cos(2 * kPi * i /
                                             (MA_WINDOW_SAMPLES - 1));
    const double phase = 2 * kPi * hz * i / MA_SAMPLE_RATE;
    re += window[i] * taper * std::cos(phase);
    im -= window[i] * taper * std::sin(phase);
  }
  return std::hypot(re, im);
}
}  // namespace

void ma_trace_yin_window(const float *window, const ma_feature &feature,
                         const double *cmnd, int min_lag, int max_lag,
                         int selected_lag, double interpolated_lag) {
  const auto target = targets.find(feature.frame_start_sample);
  if (target == targets.end()) return;
  ++traced;
  const double expected_hz = target->second;
  const int expected_lag = static_cast<int>(std::lround(MA_SAMPLE_RATE / expected_hz));
  const int double_lag = 2 * expected_lag;
  const auto curve = [&](int lag) {
    return lag >= min_lag && lag <= max_lag ? cmnd[lag] : -1.0;
  };
  int best = min_lag;
  for (int lag = min_lag + 1; lag <= max_lag; ++lag) {
    if (cmnd[lag] < cmnd[best]) best = lag;
  }
  const int64_t window_start = static_cast<int64_t>(feature.frame_start_sample) +
                               MA_HOP_SAMPLES - MA_WINDOW_SAMPLES;
  const uint64_t window_end = feature.frame_start_sample + MA_HOP_SAMPLES;
  const double midi = feature.pitch_hz > 0 ?
      69 + 12 * std::log2(feature.pitch_hz / 440.0) : 0;
  const double selected_cmnd = selected_lag ? cmnd[selected_lag] : -1;
  trace_file << feature.frame_start_sample << ',' << feature.timestamp_seconds
             << ',' << window_start << ',' << window_end << ','
             << MA_WINDOW_SAMPLES << ',' << MA_HOP_SAMPLES << ','
             << expected_hz << ',' << expected_lag << ',' << curve(expected_lag)
             << ',' << double_lag << ',' << curve(double_lag) << ','
             << selected_lag << ',' << interpolated_lag << ','
             << selected_cmnd << ',' << feature.pitch_hz << ',' << midi << ','
             << feature.pitch_confidence << ',' << feature.rms << ','
             << feature.onset_strength << ',' << feature.onset_candidate << ','
             << feature.is_silent << ',' << best << ',' << cmnd[best] << ','
             << (selected_lag ? "first_minimum_below_0.15" : "none_below_0.15")
             << '\n';
  int order = 0;
  for (int lag = min_lag; lag <= max_lag; ++lag) {
    if (cmnd[lag] <= cmnd[lag - 1] && cmnd[lag] <= cmnd[lag + 1]) {
      candidate_file << feature.frame_start_sample << ',' << order++ << ','
                     << lag << ',' << static_cast<double>(MA_SAMPLE_RATE) / lag
                     << ',' << cmnd[lag] << ',' << (cmnd[lag] < 0.15) << ','
                     << (lag == selected_lag) << '\n';
    }
  }
  std::vector<std::pair<double, double>> peaks;
  for (int bin = 15; bin <= 260; ++bin) {
    const double hz = static_cast<double>(bin) * MA_SAMPLE_RATE / 8192;
    peaks.emplace_back(magnitude(window, hz), hz);
  }
  std::sort(peaks.begin(), peaks.end(), std::greater<>());
  spectrum_file << feature.frame_start_sample << ',' << expected_hz << ','
                << magnitude(window, expected_hz / 2) << ','
                << magnitude(window, expected_hz) << ','
                << magnitude(window, expected_hz * 2) << ','
                << magnitude(window, expected_hz * 3);
  int listed = 0;
  std::vector<double> printed_hz;
  for (const auto &peak : peaks) {
    if (listed == 4) break;
    bool distinct = true;
    for (double hz : printed_hz)
      if (std::abs(peak.second - hz) < 20) distinct = false;
    if (!distinct) continue;
    spectrum_file << ',' << peak.second << ',' << peak.first;
    printed_hz.push_back(peak.second);
    ++listed;
  }
  while (listed++ < 4) spectrum_file << ",0,0";
  spectrum_file << '\n';
}

int main(int argc, char **argv) {
  if (argc != 6) {
    std::cerr << "usage: trace pcm.f32le sample:expectedHz[,..] trace.csv "
                 "candidates.csv spectrum.csv\n";
    return 2;
  }
  std::stringstream requested(argv[2]);
  std::string item;
  while (std::getline(requested, item, ',')) {
    const auto delimiter = item.find(':');
    if (delimiter == std::string::npos) return 2;
    targets[std::stoull(item.substr(0, delimiter))] =
        std::stod(item.substr(delimiter + 1));
  }
  trace_file.open(argv[3]);
  candidate_file.open(argv[4]);
  spectrum_file.open(argv[5]);
  if (!trace_file || !candidate_file || !spectrum_file) return 3;
  trace_file << std::setprecision(12);
  candidate_file << std::setprecision(12);
  spectrum_file << std::setprecision(12);
  trace_file << "sample,timestamp,windowStart,windowEndExclusive,windowSize,hop,"
      "expectedHz,expectedLag,expectedCmnd,doubleLag,doubleCmnd,selectedLag,"
      "interpolatedLag,selectedCmnd,pitchHz,fractionalMidi,confidence,rms,"
      "onsetStrength,onsetCandidate,isSilent,bestLag,bestCmnd,selectionReason\n";
  candidate_file << "sample,order,lag,hz,cmnd,belowThreshold,selected\n";
  spectrum_file << "sample,expectedHz,halfMagnitude,fundamentalMagnitude,"
      "secondMagnitude,thirdMagnitude,peak1Hz,peak1Magnitude,peak2Hz,"
      "peak2Magnitude,peak3Hz,peak3Magnitude,peak4Hz,peak4Magnitude\n";
  std::ifstream input(argv[1], std::ios::binary);
  if (!input) return 4;
  ma_config config{sizeof(ma_config), MA_ABI_VERSION, MA_SAMPLE_RATE, 1};
  ma_context *context = nullptr;
  if (ma_create(&config, &context) != MA_OK) return 5;
  std::array<float, MA_HOP_SAMPLES> hop{};
  std::array<ma_feature, MA_MAX_QUEUED_FEATURES> features{};
  while (input) {
    input.read(reinterpret_cast<char *>(hop.data()), sizeof(hop));
    const auto count = static_cast<size_t>(input.gcount()) / sizeof(float);
    if (!count) break;
    size_t consumed = 0;
    const auto status = ma_push_samples(context, hop.data(), count, &consumed);
    if (status != MA_OK || consumed != count) { ma_destroy(context); return 6; }
    size_t produced = 0;
    if (ma_read_features(context, features.data(), features.size(), &produced)
        != MA_OK) { ma_destroy(context); return 7; }
  }
  if (ma_finalize(context) != MA_OK) { ma_destroy(context); return 8; }
  ma_destroy(context);
  std::cout << "traced=" << traced << " requested=" << targets.size() << '\n';
  return traced == targets.size() ? 0 : 9;
}
