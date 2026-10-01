#include "music_analysis_dsp.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <vector>

namespace {
constexpr double pi = 3.14159265358979323846;

void check(bool value, const char *message) {
  if (!value) {
    std::fprintf(stderr, "FAIL: %s\n", message);
    std::exit(1);
  }
}

ma_context *create() {
  ma_config config{sizeof(ma_config), MA_ABI_VERSION, MA_SAMPLE_RATE, 1};
  ma_context *ctx = nullptr;
  check(ma_create(&config, &ctx) == MA_OK && ctx, "create");
  return ctx;
}

void drain(ma_context *ctx, std::vector<ma_feature> &features) {
  ma_feature buffer[64];
  size_t count = 0;
  do {
    check(ma_read_features(ctx, buffer, 64, &count) == MA_OK, "read features");
    features.insert(features.end(), buffer, buffer + count);
  } while (count);
}

std::vector<ma_feature> analyze(const std::vector<float> &samples,
                                size_t chunk) {
  ma_context *ctx = create();
  std::vector<ma_feature> features;
  for (size_t offset = 0; offset < samples.size();) {
    const size_t requested = std::min(chunk, samples.size() - offset);
    size_t consumed = 0;
    const ma_status status = ma_push_samples(ctx, samples.data() + offset,
                                             requested, &consumed);
    offset += consumed;
    check(status == MA_OK || status == MA_QUEUE_FULL, "push samples");
    if (status == MA_QUEUE_FULL) drain(ctx, features);
  }
  ma_status status;
  do {
    status = ma_finalize(ctx);
    if (status == MA_QUEUE_FULL) drain(ctx, features);
  } while (status == MA_QUEUE_FULL);
  check(status == MA_OK, "finalize");
  drain(ctx, features);
  ma_destroy(ctx);
  return features;
}

std::vector<float> sine(double hz, double seconds, float gain) {
  const size_t count = static_cast<size_t>(seconds * MA_SAMPLE_RATE);
  std::vector<float> data(count);
  for (size_t i = 0; i < count; ++i)
    data[i] = gain * std::sin(2 * pi * hz * i / MA_SAMPLE_RATE);
  return data;
}

double median_pitch(const std::vector<ma_feature> &features, double after,
                    double before = 1e9) {
  std::vector<float> pitches;
  for (const auto &f : features)
    if (f.timestamp_seconds > after && f.timestamp_seconds < before &&
        f.pitch_hz > 0) pitches.push_back(f.pitch_hz);
  check(!pitches.empty(), "voiced pitch found");
  std::sort(pitches.begin(), pitches.end());
  return pitches[pitches.size() / 2];
}
}  // namespace

int main() {
  check(ma_abi_version() == 1, "ABI version");
  const auto tone = sine(440, 1.0, 0.5f);
  const auto baseline = analyze(tone, tone.size());
  check(std::fabs(median_pitch(baseline, 0.25) - 440) < 5, "steady sine pitch");
  check(std::fabs(baseline[10].rms - 0.3535f) < 0.03f, "RMS unchanged");
  check(std::fabs(baseline[10].energy - 0.125f) < 0.02f,
        "mean-square energy unchanged");
  check(baseline[10].peak_abs > 0.49f && baseline[10].peak_abs <= 0.5f,
        "peak unchanged");
  std::puts("PASS steady 440 Hz sine, confidence and RMS");

  auto sequence = sine(440, 0.5, 0.4f);
  const auto second = sine(660, 0.5, 0.4f);
  sequence.insert(sequence.end(), second.begin(), second.end());
  const auto sequential = analyze(sequence, 737);
  check(std::fabs(median_pitch(sequential, 0.2, 0.43) - 440) < 8,
        "first consecutive pitch");
  check(std::fabs(median_pitch(sequential, 0.75) - 660) < 8,
        "second consecutive pitch");
  std::puts("PASS consecutive 440/660 Hz pitches");

  const auto silence = analyze(std::vector<float>(MA_SAMPLE_RATE, 0.0f), 103);
  check(std::all_of(silence.begin(), silence.end(), [](const ma_feature &f) {
    return f.is_silent && f.pitch_hz == 0 && f.rms == 0;
  }), "silence features");
  std::puts("PASS silence");

  std::vector<float> impulse(MA_SAMPLE_RATE, 0.0f);
  impulse[MA_SAMPLE_RATE / 3] = 0.8f;
  const auto attack = analyze(impulse, 173);
  check(std::any_of(attack.begin(), attack.end(), [](const ma_feature &f) {
    return f.onset_candidate != 0;
  }), "impulse onset candidate");
  std::puts("PASS impulse onset candidate");

  auto quiet = sine(440, 0.5, 0.1f);
  auto loud = sine(440, 0.5, 0.8f);
  quiet.insert(quiet.end(), loud.begin(), loud.end());
  const auto dynamics = analyze(quiet, 512);
  check(dynamics[65].rms > dynamics[10].rms * 5.0f,
        "amplitude change retained");
  std::puts("PASS amplitude change without normalization");

  const auto clipped = analyze(std::vector<float>(4096, 1.0f), 47);
  check(clipped[2].clipping_fraction > 0.99f &&
        clipped[2].signal_quality < 0.01f, "clipping metric");
  std::puts("PASS clipping and signal quality");

  for (size_t chunk : {1u, 257u, 512u, 4096u, 16384u}) {
    const auto current = analyze(tone, chunk);
    check(current.size() == baseline.size(), "chunk-invariant feature count");
    for (size_t i = 0; i < baseline.size(); ++i) {
      check(current[i].frame_start_sample == baseline[i].frame_start_sample,
            "chunk-invariant time position");
      check(std::fabs(current[i].rms - baseline[i].rms) < 0.000001f,
            "chunk-invariant RMS");
      check(std::fabs(current[i].pitch_hz - baseline[i].pitch_hz) < 0.0001f,
            "chunk-invariant pitch");
      check(current[i].onset_candidate == baseline[i].onset_candidate,
            "chunk-invariant onset");
    }
  }
  std::puts("PASS chunk-size invariance");

  const auto partial = analyze(std::vector<float>(513, 0.25f), 7);
  check(partial.size() == 2 && partial[1].is_partial &&
        partial[1].frame_valid_samples == 1 &&
        partial[1].frame_start_sample == 512, "partial final frame");
  check(std::fabs(partial[1].rms - 0.25f) < 0.0001f,
        "partial RMS excludes zero padding");
  std::puts("PASS partial final hop");

  ma_context *invalid = create();
  size_t consumed = 999;
  float nan = std::numeric_limits<float>::quiet_NaN();
  check(ma_push_samples(invalid, &nan, 1, &consumed) == MA_INVALID_SAMPLE &&
        consumed == 0, "non-finite sample rejected");
  float above = 1.1f;
  check(ma_push_samples(invalid, &above, 1, &consumed) == MA_INVALID_SAMPLE &&
        consumed == 0, "out-of-range sample rejected");
  check(ma_finalize(invalid) == MA_OK && ma_finalize(invalid) == MA_FINALIZED,
        "finalize lifecycle");
  check(ma_push_samples(invalid, &above, 1, &consumed) == MA_FINALIZED,
        "push after finalize");
  ma_destroy(invalid);
  ma_config wrong{sizeof(ma_config), 99, MA_SAMPLE_RATE, 1};
  ma_context *bad = nullptr;
  check(ma_create(&wrong, &bad) == MA_UNSUPPORTED_CONFIG && !bad,
        "invalid ABI rejected");
  std::puts("PASS invalid data and lifecycle errors");

  ma_context *long_stream = create();
  std::vector<ma_feature> long_features;
  size_t total = 0;
  const auto block = sine(220, 0.1, 0.2f);
  for (int i = 0; i < 1200; ++i) {
    size_t offset = 0;
    while (offset < block.size()) {
      size_t used = 0;
      const auto status = ma_push_samples(long_stream, block.data() + offset,
                                          block.size() - offset, &used);
      offset += used;
      total += used;
      if (status == MA_QUEUE_FULL) drain(long_stream, long_features);
      else check(status == MA_OK, "long stream push");
    }
    if (i % 10 == 0) drain(long_stream, long_features);
  }
  check(ma_finalize(long_stream) == MA_OK, "long stream finalize");
  drain(long_stream, long_features);
  check(long_features.size() == (total + MA_HOP_SAMPLES - 1) / MA_HOP_SAMPLES,
        "long stream frame count");
  ma_destroy(long_stream);
  std::puts("PASS 120-second incremental stream and bounded output queue");
  return 0;
}
