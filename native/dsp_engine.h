#pragma once

#include "music_analysis_dsp.h"
#include <memory>

// Internal only. The public C ABI and ma_feature layout remain unchanged.
class DspEngine {
 public:
  virtual ~DspEngine() = default;
  virtual void process(const float *hop, ma_feature &feature) = 0;
};

std::unique_ptr<DspEngine> make_open_engine();
#if defined(MA_ENABLE_AUBIO)
std::unique_ptr<DspEngine> make_aubio_engine();
#endif
