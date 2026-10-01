#include "music_analysis_dsp.h"

#include "dsp_engine.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <new>
#include <memory>

struct ma_context {
  std::unique_ptr<DspEngine> engine;
  float hop[MA_HOP_SAMPLES]{};
  ma_feature queue[MA_MAX_QUEUED_FEATURES]{};
  size_t queue_head = 0;
  size_t queue_count = 0;
  size_t hop_filled = 0;
  uint64_t samples_received = 0;
  float previous_rms = 0.0f;
  bool finalized = false;
};

namespace {
constexpr float kSilenceRms = 0.003f;
constexpr float kClipLevel = 0.999f;

void process_hop(ma_context *ctx, size_t valid) {
  ma_feature feature{};
  feature.frame_start_sample = ctx->samples_received - valid;
  feature.frame_valid_samples = valid;
  feature.timestamp_seconds = static_cast<double>(feature.frame_start_sample) /
                              MA_SAMPLE_RATE;
  feature.is_partial = valid < MA_HOP_SAMPLES ? 1u : 0u;

  double sum_squares = 0.0;
  float peak = 0.0f;
  size_t clipped = 0;
  size_t peak_index = 0;
  for (size_t i = 0; i < valid; ++i) {
    const float value = ctx->hop[i];
    sum_squares += static_cast<double>(value) * value;
    if (std::fabs(value) > peak) {
      peak = std::fabs(value);
      peak_index = i;
    }
    clipped += std::fabs(value) >= kClipLevel ? 1u : 0u;
  }
  feature.energy = valid ? static_cast<float>(sum_squares / valid) : 0.0f;
  feature.rms = std::sqrt(feature.energy);
  feature.peak_abs = peak;
  feature.clipping_fraction = valid ? static_cast<float>(clipped) / valid : 0.0f;
  feature.is_silent = feature.rms < kSilenceRms ? 1u : 0u;
  feature.signal_quality = feature.is_silent ? 0.0f :
      std::max(0.0f, 1.0f - 4.0f * feature.clipping_fraction);

  ctx->engine->process(ctx->hop, feature);
  if (!feature.onset_candidate && feature.rms >= 0.02f &&
             feature.rms > ctx->previous_rms * 4.0f &&
             feature.peak_abs >= 0.1f) {
    // A sparse impulse may be too short for HFC peak-picking; retain it as a
    // raw candidate without declaring a musical onset.
    feature.onset_candidate = 1u;
    feature.onset_sample = feature.frame_start_sample + peak_index;
  }
  ctx->previous_rms = feature.rms;
  ctx->queue[(ctx->queue_head + ctx->queue_count) % MA_MAX_QUEUED_FEATURES] = feature;
  ++ctx->queue_count;
  ctx->hop_filled = 0;
}
}  // namespace

extern "C" {
uint32_t ma_abi_version(void) { return MA_ABI_VERSION; }

const char *ma_status_message(ma_status status) {
  switch (status) {
    case MA_OK: return "ok";
    case MA_INVALID_ARGUMENT: return "invalid argument";
    case MA_UNSUPPORTED_CONFIG: return "unsupported configuration";
    case MA_OUT_OF_MEMORY: return "out of memory";
    case MA_QUEUE_FULL: return "feature queue full";
    case MA_FINALIZED: return "context already finalized";
    case MA_INVALID_SAMPLE: return "non-finite or out-of-range PCM sample";
    case MA_INTERNAL_ERROR: return "native processing error";
  }
  return "unknown status";
}

ma_status ma_create(const ma_config *config, ma_context **out_context) {
  return ma_create_with_engine(config, MA_ENGINE_OPEN, out_context);
}

uint32_t ma_available_engines(void) {
  uint32_t engines = MA_ENGINE_OPEN;
#if defined(MA_ENABLE_AUBIO)
  engines |= MA_ENGINE_AUBIO;
#endif
  return engines;
}

ma_status ma_create_with_engine(const ma_config *config, ma_engine engine,
                                ma_context **out_context) {
  if (!out_context) return MA_INVALID_ARGUMENT;
  *out_context = nullptr;
  if (!config || config->struct_size != sizeof(ma_config) ||
      config->abi_version != MA_ABI_VERSION ||
      config->sample_rate != MA_SAMPLE_RATE || config->channels != 1u) {
    return MA_UNSUPPORTED_CONFIG;
  }
  auto *ctx = new (std::nothrow) ma_context;
  if (!ctx) return MA_OUT_OF_MEMORY;
  try {
    if (engine == MA_ENGINE_OPEN) ctx->engine = make_open_engine();
#if defined(MA_ENABLE_AUBIO)
    else if (engine == MA_ENGINE_AUBIO) ctx->engine = make_aubio_engine();
#endif
    else { delete ctx; return MA_UNSUPPORTED_CONFIG; }
  } catch (const std::bad_alloc &) {
    delete ctx;
    return MA_OUT_OF_MEMORY;
  }
  if (!ctx->engine) {
    ma_destroy(ctx);
    return MA_OUT_OF_MEMORY;
  }
  *out_context = ctx;
  return MA_OK;
}

ma_status ma_push_samples(ma_context *ctx, const float *samples,
                           size_t count, size_t *consumed) {
  if (!consumed) return MA_INVALID_ARGUMENT;
  *consumed = 0;
  if (!ctx || (count && !samples)) return MA_INVALID_ARGUMENT;
  if (ctx->finalized) return MA_FINALIZED;
  while (*consumed < count) {
    if (ctx->queue_count == MA_MAX_QUEUED_FEATURES &&
        ctx->hop_filled == MA_HOP_SAMPLES - 1) return MA_QUEUE_FULL;
    const float value = samples[*consumed];
    if (!std::isfinite(value) || value < -1.0f || value > 1.0f)
      return MA_INVALID_SAMPLE;
    ctx->hop[ctx->hop_filled++] = value;
    ++ctx->samples_received;
    ++*consumed;
    if (ctx->hop_filled == MA_HOP_SAMPLES) process_hop(ctx, MA_HOP_SAMPLES);
  }
  return MA_OK;
}

ma_status ma_finalize(ma_context *ctx) {
  if (!ctx) return MA_INVALID_ARGUMENT;
  if (ctx->finalized) return MA_FINALIZED;
  if (ctx->hop_filled) {
    if (ctx->queue_count == MA_MAX_QUEUED_FEATURES) return MA_QUEUE_FULL;
    const size_t valid = ctx->hop_filled;
    std::fill(ctx->hop + valid, ctx->hop + MA_HOP_SAMPLES, 0.0f);
    process_hop(ctx, valid);
  }
  ctx->finalized = true;
  return MA_OK;
}

ma_status ma_read_features(ma_context *ctx, ma_feature *features,
                            size_t capacity, size_t *count) {
  if (!count) return MA_INVALID_ARGUMENT;
  *count = 0;
  if (!ctx || (capacity && !features)) return MA_INVALID_ARGUMENT;
  const size_t available = std::min(capacity, ctx->queue_count);
  for (size_t i = 0; i < available; ++i) {
    features[i] = ctx->queue[(ctx->queue_head + i) % MA_MAX_QUEUED_FEATURES];
  }
  ctx->queue_head = (ctx->queue_head + available) % MA_MAX_QUEUED_FEATURES;
  ctx->queue_count -= available;
  *count = available;
  return MA_OK;
}

void ma_destroy(ma_context *ctx) {
  if (!ctx) return;
  delete ctx;
}
}  // extern C
