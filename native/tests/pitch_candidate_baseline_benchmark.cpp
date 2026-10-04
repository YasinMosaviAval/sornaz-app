// Host-only baseline cost of the unchanged production Open engine, no CSV.
#include "../music_analysis_dsp.h"
#include <array>
#include <fstream>

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  std::ifstream input(argv[1], std::ios::binary);
  if (!input) return 3;
  ma_config config{sizeof(config), MA_ABI_VERSION, MA_SAMPLE_RATE, 1};
  ma_context *context = nullptr;
  if (ma_create(&config, &context) != MA_OK) return 4;
  std::array<float, MA_HOP_SAMPLES> hop{};
  std::array<ma_feature, MA_MAX_QUEUED_FEATURES> features{};
  while (input) {
    input.read(reinterpret_cast<char *>(hop.data()), sizeof(hop));
    const size_t count = static_cast<size_t>(input.gcount()) / sizeof(float);
    if (!count) break;
    size_t consumed = 0, produced = 0;
    if (ma_push_samples(context, hop.data(), count, &consumed) != MA_OK ||
        consumed != count ||
        ma_read_features(context, features.data(), features.size(), &produced)
            != MA_OK) { ma_destroy(context); return 5; }
  }
  size_t produced = 0;
  if (ma_finalize(context) != MA_OK ||
      ma_read_features(context, features.data(), features.size(), &produced)
          != MA_OK) { ma_destroy(context); return 6; }
  ma_destroy(context);
  return 0;
}
