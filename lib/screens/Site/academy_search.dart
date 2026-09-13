import 'package:flutter/material.dart';
import '../Social/social_api.dart';
import '../Social/social_widgets.dart';
import 'site_api.dart';
import 'academy_details.dart';

class AcademySearchCard extends StatefulWidget {
  const AcademySearchCard({super.key, this.api, this.onSearch});
  final SiteApi? api;
  final void Function(Map<String, String>)? onSearch;
  @override
  State<AcademySearchCard> createState() => _AcademySearchCardState();
}

class _AcademySearchCardState extends State<AcademySearchCard> {
  late final api = widget.api ?? SiteApi();
  final query = TextEditingController();
  List<Json> instruments = [], cities = [];
  String instrument = '', city = '';
  bool loading = true, failed = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final data = await api.get('/academies/options');
      if (mounted) {
        setState(() {
          instruments = objects(data['instruments'] ?? []);
          cities = objects(data['cities'] ?? []);
        });
      }
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    query.dispose();
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  Widget select(
    String label,
    String value,
    List<Json> options,
    ValueChanged<String> changed,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: [
      DropdownMenuItem(value: '', child: Text(label)),
      for (final option in options)
        DropdownMenuItem(
          value: '${option['id']}',
          child: Text('${option['title']}', overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: loading ? null : (value) => setState(() => changed(value ?? '')),
  );
  void search() {
    final filters = {
      'q': query.text.trim(),
      'instrument': instrument,
      'city': city,
    };
    if (widget.onSearch != null) {
      widget.onSearch!(filters);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AcademyResultsPage(filters: filters)),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              socialText(
                context,
                'جست‌وجوی آموزشگاه‌های موسیقی',
                'Find music academies',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => search(),
              decoration: InputDecoration(
                labelText: socialText(context, 'نام آموزشگاه', 'Academy name'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: select(
                    socialText(context, 'همه سازها', 'All instruments'),
                    instrument,
                    instruments,
                    (v) => instrument = v,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: select(
                    socialText(context, 'همه شهرها', 'All cities'),
                    city,
                    cities,
                    (v) => city = v,
                  ),
                ),
              ],
            ),
            if (loading) const LinearProgressIndicator(),
            if (failed)
              TextButton.icon(
                onPressed: load,
                icon: const Icon(Icons.refresh),
                label: Text(
                  socialText(
                    context,
                    'بارگیری دوباره سازها و شهرها',
                    'Retry loading instruments and cities',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: search,
              icon: const Icon(Icons.search),
              label: Text(socialText(context, 'جستجو', 'Search')),
            ),
          ],
        ),
      ),
    ),
  );
}

class AcademyResultsPage extends StatefulWidget {
  const AcademyResultsPage({super.key, required this.filters, this.api});
  final Map<String, String> filters;
  final SiteApi? api;
  @override
  State<AcademyResultsPage> createState() => _AcademyResultsPageState();
}

class _AcademyResultsPageState extends State<AcademyResultsPage> {
  late final api = widget.api ?? SiteApi();
  final List<Json> rows = [];
  int page = 1;
  bool loading = false, failed = false, more = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  Future<void> load({bool refresh = false}) async {
    if (loading) return;
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final next = refresh ? 1 : page;
      final data = await api.get('/academies', {
        ...widget.filters,
        'page': '$next',
      });
      if (mounted) {
        setState(() {
          if (refresh) rows.clear();
          rows.addAll(objects(data['items'] ?? []));
          more = data['has_more'] == true;
          page = next + 1;
        });
      }
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        socialText(context, 'آموزشگاه‌های موسیقی', 'Music academies'),
      ),
    ),
    body: RefreshIndicator(
      onRefresh: () => load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          for (final row in rows)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  child: row['avatar'] == null || '${row['avatar']}'.isEmpty
                      ? const Icon(Icons.school_outlined)
                      : ClipOval(
                          child: Image.network(
                            SiteApi.origin
                                .resolve('${row['avatar']}')
                                .toString(),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) =>
                                const Icon(Icons.school_outlined),
                          ),
                        ),
                ),
                title: Text('${row['name']}'),
                subtitle: Text(
                  [
                    '${row['city'] ?? ''}',
                    '${row['summary'] ?? ''}',
                  ].where((v) => v.isNotEmpty).join('\n'),
                ),
                trailing: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AcademyDetailsPage(
                      id: '${row['id']}',
                      name: '${row['name']}',
                    ),
                  ),
                ),
              ),
            ),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (failed)
            SocialEmpty(
              socialText(
                context,
                'آموزشگاه‌ها دریافت نشدند.',
                'Could not load academies.',
              ),
              onRetry: load,
            )
          else if (rows.isEmpty)
            SocialEmpty(
              socialText(
                context,
                'آموزشگاهی با این مشخصات پیدا نشد.',
                'No matching academies found.',
              ),
            )
          else if (more)
            TextButton(
              onPressed: load,
              child: Text(socialText(context, 'نمایش بیشتر', 'Show more')),
            ),
        ],
      ),
    ),
  );
}
