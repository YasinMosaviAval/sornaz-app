// SPDX-License-Identifier: MIT
// Original implementation; see open_dsp/LICENSE.
#include "dsp_engine.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <complex>

namespace {
constexpr size_t kFftSize = 8192;
constexpr size_t kWindow = MA_WINDOW_SAMPLES;
constexpr double kPi = 3.14159265358979323846;

void fft(std::array<std::complex<double>, kFftSize> &a, bool inverse) {
  for (size_t i = 1, j = 0; i < kFftSize; ++i) {
    size_t bit = kFftSize >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) std::swap(a[i], a[j]);
  }
  for (size_t len = 2; len <= kFftSize; len <<= 1) {
    const double angle = (inverse ? 2.0 : -2.0) * kPi / len;
    const std::complex<double> unit(std::cos(angle), std::sin(angle));
    for (size_t i = 0; i < kFftSize; i += len) {
      std::complex<double> w(1, 0);
      for (size_t j = 0; j < len / 2; ++j) {
        const auto u = a[i + j], v = a[i + j + len / 2] * w;
        a[i + j] = u + v;
        a[i + j + len / 2] = u - v;
        w *= unit;
      }
    }
  }
  if (inverse) for (auto &v : a) v /= static_cast<double>(kFftSize);
}

class OpenEngine final : public DspEngine {
 public:
  void process(const float *hop, ma_feature &feature) override {
    std::copy(samples_.begin() + MA_HOP_SAMPLES, samples_.end(), samples_.begin());
    std::copy(hop, hop + MA_HOP_SAMPLES, samples_.end() - MA_HOP_SAMPLES);
    received_ += feature.frame_valid_samples;
    if (received_ < 2048 || feature.is_silent) return;

    for (size_t i = 0; i < kWindow; ++i) {
      spectrum_[i] = samples_[i];
      prefix_[i + 1] = prefix_[i] + static_cast<double>(samples_[i]) * samples_[i];
    }
    std::fill(spectrum_.begin() + kWindow, spectrum_.end(), std::complex<double>(0, 0));
    fft(spectrum_, false);

    // Positive spectral flux is a raw attack descriptor, not a musical onset.
    double flux = 0, magnitude = 0;
    for (size_t i = 1; i < 512; ++i) {
      const double current = std::abs(spectrum_[i]);
      flux += std::max(0.0, current - previous_magnitudes_[i]);
      magnitude += current;
      previous_magnitudes_[i] = current;
    }
    feature.onset_strength = static_cast<float>(flux / (magnitude + 1e-12));
    if (feature.onset_strength > 0.38f && previous_rms_ > 0.003f &&
        feature.rms > previous_rms_ * 1.35f &&
        feature.frame_start_sample > last_onset_ + 1323) {
      feature.onset_candidate = 1;
      feature.onset_sample = feature.frame_start_sample;
      last_onset_ = feature.onset_sample;
    }
    previous_rms_ = feature.rms;

    for (auto &value : spectrum_) value = std::norm(value);
    fft(spectrum_, true);
    const int min_lag = static_cast<int>(MA_SAMPLE_RATE / 2000u);
    const int max_lag = static_cast<int>(MA_SAMPLE_RATE / 80u);
    double running = 0;
    cmnd_[0] = 1;
    for (int lag = 1; lag <= max_lag + 1; ++lag) {
      const double x = prefix_[kWindow - lag];
      const double y = prefix_[kWindow] - prefix_[lag];
      const double difference = std::max(0.0, x + y - 2.0 * spectrum_[lag].real());
      running += difference;
      cmnd_[lag] = running > 1e-14 ? difference * lag / running : 1.0;
    }
    int chosen = 0;
    for (int lag = min_lag; lag <= max_lag; ++lag) {
      if (cmnd_[lag] < 0.15) {
        while (lag < max_lag && cmnd_[lag + 1] < cmnd_[lag]) ++lag;
        chosen = lag;
        break;
      }
    }
    if (!chosen) return;
    const double left = cmnd_[chosen - 1], center = cmnd_[chosen], right = cmnd_[chosen + 1];
    const double denominator = left - 2 * center + right;
    const double adjustment = std::abs(denominator) > 1e-12 ?
        std::clamp(0.5 * (left - right) / denominator, -1.0, 1.0) : 0.0;
    const double hz = MA_SAMPLE_RATE / (chosen + adjustment);
    if (hz >= 80 && hz <= 2000) {
      feature.pitch_hz = static_cast<float>(hz);
      feature.pitch_confidence = static_cast<float>(std::clamp(1.0 - center, 0.0, 1.0));
    }
  }
 private:
  std::array<float, kWindow> samples_{};
  std::array<std::complex<double>, kFftSize> spectrum_{};
  std::array<double, kWindow + 1> prefix_{};
  std::array<double, 554> cmnd_{};
  std::array<double, 512> previous_magnitudes_{};
  uint64_t received_ = 0;
  uint64_t last_onset_ = 0;
  float previous_rms_ = 0;
};
}  // namespace

std::unique_ptr<DspEngine> make_open_engine() { return std::make_unique<OpenEngine>(); }
