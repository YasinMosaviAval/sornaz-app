import 'package:sornaz/helpers/app_constants.dart';

class TempoTerm {
  final String name;
  final int min;
  final int max;

  const TempoTerm(this.name, this.min, this.max);
}

List<TempoTerm> tempoTerms = [
  TempoTerm(AppConstants.LARGHISSIMO, 0, 24),
  TempoTerm(AppConstants.GRAVE, 25, 40),
  TempoTerm(AppConstants.LARGO, 40, 60),
  TempoTerm(AppConstants.ADAGIO, 61, 76),
  TempoTerm(AppConstants.ANDANTE, 77, 108),
  TempoTerm(AppConstants.MODERATO, 109, 120),
  TempoTerm(AppConstants.ALLEGRO, 121, 156),
  TempoTerm(AppConstants.PRESTO, 157, 176),
  TempoTerm(AppConstants.PRESTISSIMO, 177, 200),
];
