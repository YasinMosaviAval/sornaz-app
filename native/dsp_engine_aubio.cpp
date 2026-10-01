#include "dsp_engine.h"

#if defined(MA_ENABLE_AUBIO)
#include <aubio.h>
#include <algorithm>
#include <cmath>

namespace {
class AubioEngine final : public DspEngine {
 public:
  AubioEngine() {
    pitch_ = new_aubio_pitch("yinfast", MA_WINDOW_SAMPLES, MA_HOP_SAMPLES, MA_SAMPLE_RATE);
    onset_ = new_aubio_onset("hfc", 1024, MA_HOP_SAMPLES, MA_SAMPLE_RATE);
    hop_ = new_fvec(MA_HOP_SAMPLES);
    pitch_result_ = new_fvec(1);
    onset_result_ = new_fvec(1);
    if (ready()) {
      aubio_pitch_set_unit(pitch_, "Hz");
      aubio_pitch_set_tolerance(pitch_, 0.15f);
      aubio_pitch_set_silence(pitch_, -50.0f);
      aubio_onset_set_threshold(onset_, 0.3f);
      aubio_onset_set_silence(onset_, -55.0f);
      aubio_onset_set_minioi_ms(onset_, 30.0f);
    }
  }
  ~AubioEngine() override {
    if (pitch_) del_aubio_pitch(pitch_);
    if (onset_) del_aubio_onset(onset_);
    if (hop_) del_fvec(hop_);
    if (pitch_result_) del_fvec(pitch_result_);
    if (onset_result_) del_fvec(onset_result_);
  }
  bool ready() const { return pitch_ && onset_ && hop_ && pitch_result_ && onset_result_; }
  void process(const float *hop, ma_feature &feature) override {
    std::copy(hop, hop + MA_HOP_SAMPLES, hop_->data);
    aubio_pitch_do(pitch_, hop_, pitch_result_);
    const float hz = pitch_result_->data[0];
    const float confidence = aubio_pitch_get_confidence(pitch_);
    if (!feature.is_silent && std::isfinite(hz) && hz >= 80.0f && hz <= 2000.0f &&
        std::isfinite(confidence) && confidence >= 0.55f) {
      feature.pitch_hz = hz;
      feature.pitch_confidence = std::clamp(confidence, 0.0f, 1.0f);
    }
    aubio_onset_do(onset_, hop_, onset_result_);
    const float strength = aubio_onset_get_descriptor(onset_);
    feature.onset_strength = std::isfinite(strength) ? std::max(0.0f, strength) : 0.0f;
    if (onset_result_->data[0] > 0.0f && !feature.is_silent) {
      feature.onset_candidate = 1;
      feature.onset_sample = aubio_onset_get_last(onset_);
    }
  }
 private:
  aubio_pitch_t *pitch_ = nullptr;
  aubio_onset_t *onset_ = nullptr;
  fvec_t *hop_ = nullptr;
  fvec_t *pitch_result_ = nullptr;
  fvec_t *onset_result_ = nullptr;
};
}  // namespace

std::unique_ptr<DspEngine> make_aubio_engine() {
  auto engine = std::make_unique<AubioEngine>();
  return engine->ready() ? std::move(engine) : nullptr;
}
#endif
