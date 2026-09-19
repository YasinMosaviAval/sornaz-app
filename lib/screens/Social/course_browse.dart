import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'social_api.dart';
import 'social_widgets.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.api,
    required this.course,
    required this.onTap,
  });
  final SocialApi api;
  final Json course;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final rating = course['rating'] is Map ? course['rating'] as Map : const {};
    final old = number(
      (course['details'] is Map
          ? course['details'] as Map
          : const {})['original_price'],
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: .15),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SocialImage(
                  api: api,
                  path: course['cover_id'] == null
                      ? null
                      : api.courseMedia(course['cover_id']),
                  height: 165,
                  width: double.infinity,
                ),
                PositionedDirectional(
                  bottom: 0,
                  end: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: AppText(
                      '${number(course['lesson_count'])} ${socialText(context, 'درس', 'lessons')}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '${course['title'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    '${(course['author'] is Map ? course['author'] as Map : const {})['name'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    '${course['category'] ?? ''}',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                    ),
                  ),
                  AppText(
                    '${course['description'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (int i = 1; i <= 5; i++)
                        Icon(
                          i <= (double.tryParse('${rating['average']}') ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          size: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      AppText(
                        ' (${rating['count'] ?? 0})',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      AppText(
                        number(course['price']) == 0
                            ? socialText(context, 'رایگان', 'Free')
                            : '${course['price']} ${socialText(context, 'تومان', 'IRT')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (old > number(course['price']))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AppText(
                            '$old',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: onTap,
                        tooltip: socialText(
                          context,
                          'مشاهده دوره',
                          'View course',
                        ),
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseBrowse extends StatefulWidget {
  const CourseBrowse({
    super.key,
    required this.api,
    required this.items,
    required this.open,
    required this.refresh,
    this.embedded = false,
    this.initialQuery = '',
  });
  final SocialApi api;
  final List<Json> items;
  final void Function(Json) open;
  final Future<void> Function() refresh;
  final bool embedded;
  final String initialQuery;
  @override
  State<CourseBrowse> createState() => CourseBrowseState();
}

class CourseBrowseState extends State<CourseBrowse> {
  late String query = widget.initialQuery;
  bool free = true, paid = true;
  void search(String value) => setState(() => query = value.trim());
  double? rating;
  Set<int> durations = {};
  Set<String> categories = {};
  static const hours = [(0, 3), (3, 6), (6, 12), (12, 100000)];
  bool duration(Json c, int i) {
    final h = number(c['duration_seconds']) / 3600;
    return h >= hours[i].$1 && h < hours[i].$2;
  }

  String durationLabel(int i) => ['0–2', '3–5', '6–12', '12+'][i];
  Future<void> filters() async {
    var selectedRating = rating;
    var selectedDurations = {...durations};
    var selectedCategories = {...categories};
    final options =
        widget.items
            .map((c) => '${c['category'] ?? ''}')
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => StatefulBuilder(
        builder: (c, change) => SizedBox(
          height: MediaQuery.sizeOf(c).height * .92,
          child: Column(
            children: [
              ListTile(
                title: AppText(socialText(c, 'فیلتر', 'Filter')),
                trailing: TextButton(
                  onPressed: () => change(() {
                    selectedRating = null;
                    selectedDurations.clear();
                    selectedCategories.clear();
                  }),
                  child: AppText(socialText(c, 'پاک کردن', 'Clear')),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    AppText(
                      socialText(c, 'امتیاز', 'Rating'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    for (final value in [4.5, 3.5, 3.0])
                      RadioListTile<double>(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        value: value,
                        groupValue: selectedRating,
                        onChanged: (v) => change(() => selectedRating = v),
                        title: AppText(
                          '★ $value ${socialText(c, 'و بالاتر', '& up')} (${widget.items.where((r) => (double.tryParse('${optionalObject(r['rating'])['average']}') ?? 0) >= value).length})',
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                    AppText(
                      socialText(c, 'مدت ویدیو', 'Video duration'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    for (int i = 0; i < 4; i++)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        value: selectedDurations.contains(i),
                        onChanged: (v) => change(
                          () => v == true
                              ? selectedDurations.add(i)
                              : selectedDurations.remove(i),
                        ),
                        title: AppText(
                          '${durationLabel(i)} ${socialText(c, 'ساعت', 'Hours')} (${widget.items.where((r) => duration(r, i)).length})',
                        ),
                      ),
                    AppText(
                      socialText(c, 'دسته‌بندی‌ها', 'Categories'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    for (final category in options)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        value: selectedCategories.contains(category),
                        onChanged: (v) => change(
                          () => v == true
                              ? selectedCategories.add(category)
                              : selectedCategories.remove(category),
                        ),
                        title: AppText(
                          '$category (${widget.items.where((r) => r['category'] == category).length})',
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(c, true),
                    icon: const Icon(Icons.tune),
                    label: AppText(
                      socialText(c, 'اعمال فیلترها', 'Set filters'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && mounted)
      setState(() {
        rating = selectedRating;
        durations = selectedDurations;
        categories = selectedCategories;
      });
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.items
        .where(
          (c) =>
              '${c['title']} ${c['description']} ${(c['author'] is Map ? c['author'] as Map : const {})['name']}'
                  .toLowerCase()
                  .contains(query.toLowerCase()) &&
              (rating == null ||
                  (double.tryParse(
                            '${(c['rating'] is Map ? c['rating'] as Map : const {})['average']}',
                          ) ??
                          0) >=
                      rating!) &&
              (categories.isEmpty || categories.contains(c['category'])) &&
              (durations.isEmpty || durations.any((i) => duration(c, i))) &&
              (number(c['price']) == 0 ? free : paid),
        )
        .toList();
    final children = <Widget>[
      Row(
        children: [
          for (final filter in [
            (free, 'دوره‌های رایگان', 'Free courses', true),
            (paid, 'دوره‌های غیررایگان', 'Paid courses', false),
          ])
            Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  if (filter.$4)
                    free = !free;
                  else
                    paid = !paid;
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 24,
                        child: Checkbox(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          value: filter.$1,
                          onChanged: (v) => setState(() {
                            if (filter.$4)
                              free = v ?? false;
                            else
                              paid = v ?? false;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          socialText(context, filter.$2, filter.$3),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (rating != null || durations.isNotEmpty || categories.isNotEmpty) ...[
        AppText(socialText(context, 'فیلترها', 'Filters')),
        Wrap(
          spacing: 8,
          children: [
            if (rating != null)
              InputChip(
                backgroundColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                deleteIconColor: Theme.of(context).colorScheme.onPrimary,
                label: AppText('★ $rating +'),
                onDeleted: () => setState(() => rating = null),
              ),
            for (final i in durations)
              InputChip(
                label: AppText(
                  '${durationLabel(i)} ${socialText(context, 'ساعت', 'Hours')}',
                ),
                onDeleted: () => setState(() => durations.remove(i)),
              ),
            for (final category in categories)
              InputChip(
                label: AppText(category),
                onDeleted: () => setState(() => categories.remove(category)),
              ),
          ],
        ),
      ],
      if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                socialText(
                  context,
                  'نتیجه‌ای برای فیلتر و جست‌وجو پیدا نشد',
                  'No results in these filters & keyword',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              AppText(
                socialText(
                  context,
                  'فیلترها یا عبارت جست‌وجو را تغییر دهید.',
                  'Try another filter or keyword.',
                ),
              ),
            ],
          ),
        ),
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CourseCard(
            api: widget.api,
            course: row,
            onTap: () => widget.open(row),
          ),
        ),
    ];
    if (widget.embedded)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(children: children),
      );
    return RefreshIndicator(
      onRefresh: widget.refresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}
