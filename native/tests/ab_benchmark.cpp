#include "music_analysis_dsp.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

namespace {
constexpr double pi = 3.14159265358979323846;
void check(bool ok, const char *message) {
  if (!ok) { std::fprintf(stderr, "FAIL %s\n", message); std::exit(1); }
}
std::vector<float> tone(double hz, double duration, float gain = 0.5f) {
  std::vector<float> samples(static_cast<size_t>(duration * MA_SAMPLE_RATE));
  for (size_t i = 0; i < samples.size(); ++i)
    samples[i] = gain * std::sin(2 * pi * hz * i / MA_SAMPLE_RATE);
  return samples;
}
struct Result { std::vector<ma_feature> frames; double milliseconds; };
Result run(ma_engine engine, const std::vector<float> &samples, size_t chunk) {
  ma_config config{sizeof(ma_config), MA_ABI_VERSION, MA_SAMPLE_RATE, 1};
  ma_context *context = nullptr;
  check(ma_create_with_engine(&config, engine, &context) == MA_OK, "engine available");
  Result result;
  auto start = std::chrono::steady_clock::now();
  auto drain = [&] {
    ma_feature buffer[128]; size_t count;
    do {
      check(ma_read_features(context, buffer, 128, &count) == MA_OK, "read");
      result.frames.insert(result.frames.end(), buffer, buffer + count);
    } while (count);
  };
  for (size_t offset = 0; offset < samples.size();) {
    size_t consumed = 0;
    const auto status = ma_push_samples(context, samples.data() + offset,
                                        std::min(chunk, samples.size() - offset), &consumed);
    offset += consumed;
    check(status == MA_OK || status == MA_QUEUE_FULL, "push");
    if (status == MA_QUEUE_FULL) drain();
  }
  ma_status status;
  do { status = ma_finalize(context); if (status == MA_QUEUE_FULL) drain(); }
  while (status == MA_QUEUE_FULL);
  check(status == MA_OK, "finalize"); drain();
  result.milliseconds = std::chrono::duration<double, std::milli>(
      std::chrono::steady_clock::now() - start).count();
  ma_destroy(context);
  return result;
}
double median_error(const Result &result, double hz) {
  std::vector<double> errors;
  for (const auto &f : result.frames)
    if (f.timestamp_seconds >= 0.25 && f.pitch_hz > 0)
      errors.push_back(std::abs(f.pitch_hz - hz));
  if (errors.empty()) return -1;
  std::sort(errors.begin(), errors.end());
  return errors[errors.size() / 2];
}
void write_features(FILE *out, const char *case_name, const char *engine,
                    const Result &result) {
  for (const auto &f : result.frames)
    std::fprintf(out, "%s,%s,%llu,%llu,%llu,%.9f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%u,%u,%u\n",
                 case_name, engine, static_cast<unsigned long long>(f.frame_start_sample),
                 static_cast<unsigned long long>(f.frame_valid_samples),
                 static_cast<unsigned long long>(f.onset_sample), f.timestamp_seconds,
                 f.pitch_hz, f.pitch_confidence, f.onset_strength, f.energy,
                 f.rms, f.peak_abs, f.clipping_fraction, f.signal_quality,
                 f.onset_candidate, f.is_silent, f.is_partial);
}
}  // namespace

int main() {
  const bool compare = (ma_available_engines() & MA_ENGINE_AUBIO) != 0;
  FILE *raw = std::fopen("ab_raw_features.csv", "w");
  FILE *summary = std::fopen("ab_summary.csv", "w");
  FILE *onsets = std::fopen("ab_onset_summary.csv", "w");
  check(raw && summary && onsets, "output files");
  std::fprintf(raw, "case,engine,frame_start_sample,frame_valid_samples,onset_sample,timestamp_seconds,pitch_hz,pitch_confidence,onset_strength,energy,rms,peak_abs,clipping_fraction,signal_quality,onset_candidate,is_silent,is_partial\n");
  std::fprintf(summary, "case,engine,truth_hz,median_abs_error_hz,voiced_frames,total_frames,runtime_ms\n");
  std::fprintf(onsets, "engine,truth_sample,nearest_candidate_sample,absolute_error_samples\n");
  for (double hz : {110.0, 220.0, 440.0, 660.0, 880.0, 1760.0}) {
    const auto samples = tone(hz, 1.0);
    const auto name = std::string("sine_") + std::to_string(static_cast<int>(hz));
    for (ma_engine engine : {MA_ENGINE_OPEN, MA_ENGINE_AUBIO}) {
      if (engine == MA_ENGINE_AUBIO && !compare) continue;
      const auto result = run(engine, samples, 737);
      const char *label = engine == MA_ENGINE_OPEN ? "open" : "aubio";
      const double error = median_error(result, hz);
      const size_t voiced = std::count_if(result.frames.begin(), result.frames.end(),
                                          [](const ma_feature &f) { return f.pitch_hz > 0; });
      write_features(raw, name.c_str(), label, result);
      std::fprintf(summary, "%s,%s,%.0f,%.6f,%zu,%zu,%.3f\n", name.c_str(),
                   label, hz, error, voiced, result.frames.size(), result.milliseconds);
      check(error >= 0 && error < 10, "absolute pitch error");
    }
  }
  // Identical PCM for both paths, including non-tonal and dynamic cases.
  std::vector<float> impulse(MA_SAMPLE_RATE, 0);
  impulse[MA_SAMPLE_RATE / 3] = 0.8f;
  auto dynamics = tone(440, 0.5, 0.1f);
  const auto loud = tone(440, 0.5, 0.8f);
  dynamics.insert(dynamics.end(), loud.begin(), loud.end());
  const std::vector<std::pair<const char *, std::vector<float>>> cases = {
      {"silence", std::vector<float>(MA_SAMPLE_RATE, 0)},
      {"impulse", impulse}, {"dynamics", dynamics},
      {"clipping", std::vector<float>(4096, 1)},
      {"partial", std::vector<float>(513, 0.25f)}};
  for (const auto &item : cases) {
    for (ma_engine engine : {MA_ENGINE_OPEN, MA_ENGINE_AUBIO}) {
      if (engine == MA_ENGINE_AUBIO && !compare) continue;
      const auto result = run(engine, item.second, 173);
      write_features(raw, item.first, engine == MA_ENGINE_OPEN ? "open" : "aubio", result);
      if (std::string(item.first) == "impulse")
      {
        const uint64_t truth = MA_SAMPLE_RATE / 3;
        uint64_t nearest = 0, error = UINT64_MAX;
        for (const auto &f : result.frames) if (f.onset_candidate) {
          const uint64_t delta = f.onset_sample > truth ? f.onset_sample - truth : truth - f.onset_sample;
          if (delta < error) { error = delta; nearest = f.onset_sample; }
        }
        check(error != UINT64_MAX, "impulse onset");
        std::fprintf(onsets, "%s,%llu,%llu,%llu\n",
                     engine == MA_ENGINE_OPEN ? "open" : "aubio",
                     static_cast<unsigned long long>(truth),
                     static_cast<unsigned long long>(nearest),
                     static_cast<unsigned long long>(error));
      }
    }
  }
  std::fclose(raw); std::fclose(summary); std::fclose(onsets);
  std::puts("PASS absolute-truth A/B benchmark and raw feature capture");
}
