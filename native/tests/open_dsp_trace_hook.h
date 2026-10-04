#pragma once

#include "../music_analysis_dsp.h"

// Test executable only. Never compiled into the production library or C ABI.
void ma_trace_yin_window(const float *window, const ma_feature &feature,
                         const double *cmnd, int min_lag, int max_lag,
                         int selected_lag, double interpolated_lag);
