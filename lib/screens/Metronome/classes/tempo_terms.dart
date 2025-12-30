import 'package:sornaz/helpers/app_strings.dart';

class TempoTerm {
  final String name;
  final int min;
  final int max;

  const TempoTerm(this.name, this.min, this.max);
}

List<TempoTerm> tempoTerms = [
  TempoTerm(AppStrings.larghissimo, 0, 24),
  TempoTerm(AppStrings.grave, 25, 40),
  TempoTerm(AppStrings.largo, 40, 60),
  TempoTerm(AppStrings.adagio, 61, 76),
  TempoTerm(AppStrings.andante, 77, 108),
  TempoTerm(AppStrings.moderato, 109, 120),
  TempoTerm(AppStrings.allegro, 121, 156),
  TempoTerm(AppStrings.presto, 157, 176),
  TempoTerm(AppStrings.prestissimo, 177, 200),
];
