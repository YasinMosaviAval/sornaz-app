class TempoTerm {
  final String name;
  final int min;
  final int max;

  const TempoTerm(this.name, this.min, this.max);
}

const List<TempoTerm> tempoTerms = [
  TempoTerm('Largo', 40, 60),
  TempoTerm('Adagio', 61, 76),
  TempoTerm('Andante', 77, 108),
  TempoTerm('Moderato', 109, 120),
  TempoTerm('Allegro', 121, 156),
  TempoTerm('Presto', 157, 176),
  TempoTerm('Prestissimo', 177, 200),
];
