#include "music_analysis_dsp.h"

#include <string.h>

int main(void) {
  ma_config config = {sizeof(ma_config), MA_ABI_VERSION, MA_SAMPLE_RATE, 1};
  ma_context *context = 0;
  float samples[MA_HOP_SAMPLES] = {0};
  ma_feature feature;
  size_t consumed = 0;
  size_t count = 0;
  if (ma_abi_version() != MA_ABI_VERSION) return 1;
  if (!(ma_available_engines() & MA_ENGINE_OPEN)) return 7;
  if (ma_create_with_engine(&config, (ma_engine)99, &context) !=
      MA_UNSUPPORTED_CONFIG || context) return 8;
  if (ma_create(&config, &context) != MA_OK || !context) return 2;
  if (ma_push_samples(context, samples, MA_HOP_SAMPLES, &consumed) != MA_OK ||
      consumed != MA_HOP_SAMPLES) return 3;
  if (ma_finalize(context) != MA_OK) return 4;
  memset(&feature, 0xff, sizeof(feature));
  if (ma_read_features(context, &feature, 1, &count) != MA_OK || count != 1)
    return 5;
  if (!feature.is_silent || feature.rms != 0 || feature.energy != 0 ||
      feature.pitch_hz != 0)
    return 6;
  ma_destroy(context);
  return 0;
}
