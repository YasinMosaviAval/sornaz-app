#ifndef SORNAZ_MUSIC_ANALYSIS_DSP_H
#define SORNAZ_MUSIC_ANALYSIS_DSP_H

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#define MA_API __declspec(dllexport)
#else
#define MA_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define MA_ABI_VERSION 1u
#define MA_SAMPLE_RATE 44100u
#define MA_WINDOW_SAMPLES 4096u
#define MA_HOP_SAMPLES 512u
#define MA_MAX_QUEUED_FEATURES 256u

typedef struct ma_context ma_context;

typedef enum ma_engine {
  MA_ENGINE_OPEN = 1,
  MA_ENGINE_AUBIO = 2
} ma_engine;

typedef enum ma_status {
  MA_OK = 0,
  MA_INVALID_ARGUMENT = 1,
  MA_UNSUPPORTED_CONFIG = 2,
  MA_OUT_OF_MEMORY = 3,
  MA_QUEUE_FULL = 4,
  MA_FINALIZED = 5,
  MA_INVALID_SAMPLE = 6,
  MA_INTERNAL_ERROR = 7
} ma_status;

typedef struct ma_config {
  uint32_t struct_size;
  uint32_t abi_version;
  uint32_t sample_rate;
  uint32_t channels;
} ma_config;

typedef struct ma_feature {
  uint64_t frame_start_sample;
  uint64_t frame_valid_samples;
  uint64_t onset_sample;
  double timestamp_seconds;
  float pitch_hz;
  float pitch_confidence;
  float onset_strength;
  float energy;
  float rms;
  float peak_abs;
  float clipping_fraction;
  float signal_quality;
  uint32_t onset_candidate;
  uint32_t is_silent;
  uint32_t is_partial;
} ma_feature;

MA_API uint32_t ma_abi_version(void);
MA_API const char *ma_status_message(ma_status status);
/* On success the caller owns *out_context and must call ma_destroy. */
MA_API ma_status ma_create(const ma_config *config, ma_context **out_context);
/* Additive ABI-1 extension. Aubio returns MA_UNSUPPORTED_CONFIG when omitted. */
MA_API ma_status ma_create_with_engine(const ma_config *config, ma_engine engine,
                                       ma_context **out_context);
MA_API uint32_t ma_available_engines(void);
/* Samples are borrowed for this call only. consumed is always written. */
MA_API ma_status ma_push_samples(ma_context *context, const float *samples,
                                  size_t count, size_t *consumed);
/* Pads one final hop with zeroes if needed; repeat after draining on QUEUE_FULL. */
MA_API ma_status ma_finalize(ma_context *context);
/* Copies at most capacity features into caller-owned memory and drains them. */
MA_API ma_status ma_read_features(ma_context *context, ma_feature *features,
                                   size_t capacity, size_t *count);
MA_API void ma_destroy(ma_context *context);

#ifdef __cplusplus
}
#endif
#endif
