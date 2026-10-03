/// A copied, immutable raw DSP frame. No musical interpretation is attached.
class RawAudioFeature {
  const RawAudioFeature({
    required this.frameStartSample,
    required this.frameValidSamples,
    required this.onsetSample,
    required this.timestampSeconds,
    required this.pitchHz,
    required this.pitchConfidence,
    required this.onsetStrength,
    required this.energy,
    required this.rms,
    required this.peakAbs,
    required this.clippingFraction,
    required this.signalQuality,
    required this.onsetCandidate,
    required this.isSilent,
    required this.isPartial,
  });

  final int frameStartSample;
  final int frameValidSamples;
  final int onsetSample;
  final double timestampSeconds;
  final double pitchHz;
  final double pitchConfidence;
  final double onsetStrength;
  final double energy;
  final double rms;
  final double peakAbs;
  final double clippingFraction;
  final double signalQuality;
  final bool onsetCandidate;
  final bool isSilent;
  final bool isPartial;
}
