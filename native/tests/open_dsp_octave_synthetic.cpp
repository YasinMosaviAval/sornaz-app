#include "../music_analysis_dsp.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <fstream>
#include <iostream>
#include <random>
#include <string>
#include <vector>

namespace {
constexpr double pi = 3.14159265358979323846;

std::vector<ma_feature> analyze(const std::vector<float> &signal) {
  ma_config config{sizeof(config), MA_ABI_VERSION, MA_SAMPLE_RATE, 1};
  ma_context *context = nullptr;
  if (ma_create(&config, &context) != MA_OK) throw std::runtime_error("create");
  std::vector<ma_feature> out;
  std::array<ma_feature, MA_MAX_QUEUED_FEATURES> buffer{};
  for (size_t at = 0; at < signal.size();) {
    size_t consumed = 0;
    const auto count = std::min<size_t>(512, signal.size() - at);
    if (ma_push_samples(context, signal.data() + at, count, &consumed) != MA_OK ||
        consumed != count) throw std::runtime_error("push");
    at += consumed;
    size_t produced = 0;
    if (ma_read_features(context, buffer.data(), buffer.size(), &produced) != MA_OK)
      throw std::runtime_error("read");
    out.insert(out.end(), buffer.begin(), buffer.begin() + produced);
  }
  if (ma_finalize(context) != MA_OK) throw std::runtime_error("finalize");
  size_t produced = 0;
  if (ma_read_features(context, buffer.data(), buffer.size(), &produced) != MA_OK)
    throw std::runtime_error("read final");
  out.insert(out.end(), buffer.begin(), buffer.begin() + produced);
  ma_destroy(context);
  return out;
}

std::vector<float> make_tone(double f, const std::array<double, 4> &harmonics,
                             double inharmonicity = 0, double detune = 0,
                             bool decaying = false) {
  std::vector<float> output(MA_SAMPLE_RATE);
  for (size_t i = 0; i < output.size(); ++i) {
    const double t = static_cast<double>(i) / MA_SAMPLE_RATE;
    const double envelope = decaying ? std::min(1.0, t / 0.01) *
        std::exp(-t / 0.65) : 1.0;
    double value = 0;
    for (int h = 1; h <= 4; ++h) {
      const double hz = f * h * std::sqrt(1 + inharmonicity * h * h);
      value += harmonics[h - 1] * std::sin(2 * pi * hz * t + h * 0.13);
    }
    if (detune) value += 0.4 * std::sin(2 * pi * f * (1 + detune) * t);
    output[i] = static_cast<float>(0.32 * envelope * value);
  }
  return output;
}

int control_failures = 0;

void row(std::ostream &out, const std::string &name, double expected,
         const std::vector<float> &signal, double begin = .25,
         double end = .85) {
  const auto time = std::chrono::steady_clock::now();
  const auto features = analyze(signal);
  const auto elapsed = std::chrono::duration<double, std::milli>(
      std::chrono::steady_clock::now() - time).count();
  std::vector<double> hz, conf;
  int octave_down = 0, octave_up = 0, total = 0;
  for (const auto &feature : features) {
    if (feature.timestamp_seconds < begin || feature.timestamp_seconds > end ||
        feature.pitch_hz <= 0) continue;
    hz.push_back(feature.pitch_hz);
    conf.push_back(feature.pitch_confidence);
    const double ratio = feature.pitch_hz / expected;
    if (ratio > .47 && ratio < .53) ++octave_down;
    if (ratio > 1.9 && ratio < 2.1) ++octave_up;
    ++total;
  }
  std::sort(hz.begin(), hz.end());
  std::sort(conf.begin(), conf.end());
  out << name << ',' << expected << ',' << total << ','
      << (hz.empty() ? 0 : hz[hz.size() / 2]) << ','
      << (conf.empty() ? 0 : conf[conf.size() / 2]) << ','
      << octave_down << ',' << octave_up << ',' << elapsed << '\n';
  const bool unvoiced_control = name == "silence" || name == "low_noise" ||
                                name == "impulse";
  const bool pitched_control = name.rfind("interference_", 0) != 0 &&
                               !unvoiced_control;
  if ((unvoiced_control && total != 0) ||
      (pitched_control && (hz.empty() ||
       std::abs(hz[hz.size() / 2] / expected - 1.0) > .05))) {
    std::cerr << "Failed independent control: " << name << '\n';
    ++control_failures;
  }
}
}  // namespace

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  std::ofstream out(argv[1]);
  if (!out) return 3;
  out << "case,expectedHz,voicedFrames,medianHz,medianConfidence,"
         "octaveDownFrames,octaveUpFrames,elapsedMilliseconds\n";
  for (double f : {110.0, 220.0, 293.66, 329.63, 349.23, 440.0,
                   660.0, 880.0, 1760.0}) {
    row(out, "sine_" + std::to_string(static_cast<int>(f)), f,
        make_tone(f, {1, 0, 0, 0}));
  }
  for (double f : {146.83, 293.66, 329.63, 349.23, 440.0, 698.46}) {
    row(out, "harmonic_strong_" + std::to_string(static_cast<int>(f)), f,
        make_tone(f, {1, .5, .25, .1}));
    row(out, "harmonic_h2_" + std::to_string(static_cast<int>(f)), f,
        make_tone(f, {.4, 1, .6, .3}));
    row(out, "harmonic_weak_" + std::to_string(static_cast<int>(f)), f,
        make_tone(f, {.1, 1, .8, .5}));
    row(out, "piano_decay_" + std::to_string(static_cast<int>(f)), f,
        make_tone(f, {1, .5, .25, .1}, .002, 0, true));
    row(out, "piano_inharmonic_" + std::to_string(static_cast<int>(f)), f,
        make_tone(f, {1, .5, .25, .1}, .01, 0, true));
    row(out, "piano_detuned_" + std::to_string(static_cast<int>(f)), f,
        make_tone(f, {1, .5, .25, .1}, .002, .01, true));
  }
  // Independent, non-note low-frequency interference: test whether a strong
  // target fundamental can still be assigned a subharmonic period.
  for (double f : {293.66, 329.63, 349.23, 440.0}) {
    for (double interferer : {120.0, 150.0, 180.0}) {
      for (double gain : {.04, .10, .20}) {
        auto signal = make_tone(f, {1, .35, .20, .10});
        for (size_t i = 0; i < signal.size(); ++i)
          signal[i] += static_cast<float>(gain * std::sin(
              2 * pi * interferer * i / MA_SAMPLE_RATE));
        row(out, "interference_" + std::to_string(static_cast<int>(f)) +
            "_" + std::to_string(static_cast<int>(interferer)) + "_" +
            std::to_string(static_cast<int>(gain * 100)), f, signal);
      }
    }
  }
  auto leap = make_tone(174.614, {1, .4, .2, .1});
  auto next = make_tone(349.228, {1, .4, .2, .1});
  leap.insert(leap.end(), next.begin(), next.end());
  row(out, "octave_f3_f4_first", 174.614, leap, .25, .85);
  row(out, "octave_f3_f4_second", 349.228, leap, 1.25, 1.85);
  leap = make_tone(349.228, {1, .4, .2, .1});
  next = make_tone(698.456, {1, .4, .2, .1});
  leap.insert(leap.end(), next.begin(), next.end());
  row(out, "octave_f4_f5_first", 349.228, leap, .25, .85);
  row(out, "octave_f4_f5_second", 698.456, leap, 1.25, 1.85);
  for (const auto &pair : {std::pair{329.63, 349.23}, {349.23, 329.63}}) {
    auto transition = make_tone(pair.first, {1, .4, .2, .1});
    next = make_tone(pair.second, {1, .4, .2, .1});
    transition.insert(transition.end(), next.begin(), next.end());
    const std::string prefix = pair.first < pair.second ? "e4_f4" : "f4_e4";
    row(out, prefix + "_first", pair.first, transition, .25, .85);
    row(out, prefix + "_second", pair.second, transition, 1.25, 1.85);
  }
  row(out, "silence", 440, std::vector<float>(MA_SAMPLE_RATE, 0));
  std::mt19937 rng(17);
  std::uniform_real_distribution<float> noise(-.001f, .001f);
  std::vector<float> noisy(MA_SAMPLE_RATE);
  for (auto &v : noisy) v = noise(rng);
  row(out, "low_noise", 440, noisy);
  noisy.assign(MA_SAMPLE_RATE, 0);
  noisy[MA_SAMPLE_RATE / 2] = .8f;
  row(out, "impulse", 440, noisy);
  return control_failures == 0 ? 0 : 1;
}
