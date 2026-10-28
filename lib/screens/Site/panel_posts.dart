part of 'panel_resource_page.dart';

extension _PostEditing on _PanelResourcePageState {
  Future<Json> postOptions() async {
    final result = <String, dynamic>{...data};
    for (final name in widget.section['optionActions'] as List? ?? []) {
      final response = await widget.api.get('/posts/$name');
      final target = optionalObject(actions['$name'])['optionResultKey'];
      if (target is String)
        result[target] =
            response['items'] ?? response[target] ?? response['posts'] ?? [];
      else
        result.addAll(response);
    }
    return result;
  }

  Future<Json> submitPost(
    String operation,
    PanelFormResult result,
    Json record,
    Json source,
  ) async {
    final values = panelDialogPayload('posts', operation, result.values, {
      ...source,
      'record': record,
    });
    final image = result.files['coverFile'];
    if (image == null && operation != 'metadata') {
      for (final key in ['cover', 'cover_media_id'])
        if (record.containsKey(key)) values[key] = record[key];
    }
    if (image != null) {
      final extension = image.name.split('.').last.toLowerCase();
      if (!['png', 'jpg', 'jpeg', 'webp'].contains(extension) ||
          image.size > 50 * 1024 * 1024)
        throw const SocialException(
          'PNG, JPG or WebP images up to 50 MB are supported.',
        );
      final uploaded =
          postCoverUploads[image] ??
          await widget.api.act('posts', 'cover-upload', files: {'file': image});
      if (uploaded['id'] == null || uploaded['url'] == null)
        throw const SocialException('بارگذاری تصویر انجام نشد.');
      postCoverUploads[image] = uploaded;
      values['cover_media_id'] = uploaded['id'];
      values['cover'] = uploaded['url'];
    }
    final submitted = await widget.api.act(
      'posts',
      operation,
      params: {'id': '${record['id'] ?? ''}'},
      values: values,
    );
    return submitted;
  }

  void closePostMetadata() {
    postRequest++;
    if (mounted)
      updatePostUi(() {
        expandedPostId = null;
        expandedPost = null;
        expandedPostData = null;
        expandedPostError = null;
      });
  }

  Future<void> editPostMetadata(Json row) async {
    final id = '${row['id']}';
    if (expandedPostId == id) {
      closePostMetadata();
      return;
    }
    final version = ++postRequest;
    updatePostUi(() {
      expandedPostId = id;
      expandedPost = null;
      expandedPostData = null;
      expandedPostError = null;
    });
    try {
      final values = await Future.wait([
        widget.api.get('/posts/details', {'id': id}),
        postOptions(),
      ]);
      if (!mounted || version != postRequest || expandedPostId != id) return;
      updatePostUi(() {
        expandedPost = {...row, ...values[0]};
        expandedPostData = values[1];
      });
    } catch (e) {
      if (mounted && version == postRequest)
        updatePostUi(() => expandedPostError = e);
    }
  }

  Widget postEditor(Json row) {
    if (expandedPostError != null)
      return Column(
        children: [
          Text(
            socialText(
              context,
              'دریافت تنظیمات ناموفق بود.',
              'Could not load post settings.',
            ),
          ),
          TextButton(
            onPressed: () {
              closePostMetadata();
              editPostMetadata(row);
            },
            child: Text(socialText(context, 'تلاش دوباره', 'Retry')),
          ),
          TextButton(
            onPressed: closePostMetadata,
            child: Text(socialText(context, 'انصراف', 'Cancel')),
          ),
        ],
      );
    if (expandedPost == null)
      return const Padding(
        padding: EdgeInsets.all(20),
        child: LinearProgressIndicator(),
      );
    final record = expandedPost!, source = expandedPostData ?? data;
    final action = optionalObject(actions['metadata']);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: PanelFormPage(
        key: ValueKey('post-metadata-${record['id']}'),
        title: socialText(context, 'تنظیمات نوشته', 'Post settings'),
        embedded: true,
        declaredOnly: true,
        onCancel: closePostMetadata,
        fields: objects(action['fields'])
            .where(
              (field) =>
                  !['content', 'summary', 'description'].contains(field['key']),
            )
            .toList(),
        data: {...source, 'record': record, 'operation': 'metadata'},
        initial: record,
        onSubmit: (result) async {
          final id = expandedPostId;
          await submitPost('metadata', result, record, source);
          if (!mounted || expandedPostId != id) return;
          closePostMetadata();
          await load(refresh: true);
        },
      ),
    );
  }

  Widget postTable(List<Json> rows, {int offset = 0}) {
    final columns = panelTableColumns(tableContract, data);
    final rowActions =
        tableContract['rowActions'] as List? ??
        ['preview', 'details', 'metadata', 'delete'];
    if (expandedPostId != null &&
        !rows.any((row) => '${row['id']}' == expandedPostId))
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) closePostMetadata();
      });
    return LayoutBuilder(
      builder: (context, space) {
        final widths = [
          for (final column in columns)
            column['key'] == '_index'
                ? 72.0
                : column['key'] == 'title'
                ? 230.0
                : 160.0,
          190.0,
        ];
        final total = widths.fold<double>(0, (sum, width) => sum + width);
        Widget cell(Widget child, int index) => SizedBox(
          width: widths[index],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: child,
          ),
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: total,
            child: Column(
              children: [
                ColoredBox(
                  color: branchCanvas(context),
                  child: Row(
                    children: [
                      for (final column in columns.indexed)
                        cell(
                          TextButton(
                            onPressed: () {
                              updatePostUi(() {
                                sortAscending = sortKey == '${column.$2['key']}'
                                    ? !sortAscending
                                    : true;
                                sortKey = '${column.$2['key']}';
                                page = 1;
                                localPage = 1;
                              });
                              load();
                            },
                            child: Text(panelCaption(context, column.$2)),
                          ),
                          column.$1,
                        ),
                      cell(
                        Text(socialText(context, 'عملیات', 'Actions')),
                        columns.length,
                      ),
                    ],
                  ),
                ),
                for (final entry in rows.indexed) ...[
                  Builder(
                    builder: (context) {
                      final original = entry.$2,
                          display = panelDisplayRow('posts', {
                            ...original,
                            '_index': offset + entry.$1 + 1,
                          }, data);
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: branchDivider(context),
                              width: .3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            for (final column in columns.indexed)
                              cell(
                                column.$2['key'] == 'title'
                                    ? TextButton(
                                        onPressed: busy
                                            ? null
                                            : () => perform('update', original),
                                        child: Text(
                                          panelCellText(
                                            context,
                                            display,
                                            column.$2,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    : column.$2['key'] == 'status'
                                    ? PanelStatusCell(
                                        row: {...display, '_record': original},
                                        column: column.$2,
                                        section: 'posts',
                                        onPressed:
                                            !busy &&
                                                available('status', original)
                                            ? () => changeStatus(
                                                original,
                                                'status',
                                              )
                                            : null,
                                      )
                                    : Text(
                                        panelCellText(
                                          context,
                                          display,
                                          column.$2,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                column.$1,
                              ),
                            cell(
                              Wrap(
                                spacing: 2,
                                children: [
                                  for (final key in rowActions)
                                    if (key == 'details' ||
                                        available('$key', original))
                                      IconButton(
                                        tooltip: key == 'details'
                                            ? socialText(
                                                context,
                                                'جزئیات',
                                                'Details',
                                              )
                                            : key == 'metadata'
                                            ? socialText(
                                                context,
                                                'ویرایش',
                                                'Edit',
                                              )
                                            : panelLabel(
                                                context,
                                                optionalObject(actions[key]),
                                              ),
                                        icon: Icon(
                                          switch (key) {
                                            'details' => Icons.info_outline,
                                            'metadata' ||
                                            'update' => Icons.edit_outlined,
                                            'delete' ||
                                            'trash' => Icons.delete_outline,
                                            'preview' =>
                                              Icons.visibility_outlined,
                                            _ => Icons.restore,
                                          },
                                          color:
                                              ['delete', 'trash'].contains(key)
                                              ? Colors.red
                                              : branchAccent(context),
                                        ),
                                        onPressed: busy
                                            ? null
                                            : () => key == 'details'
                                                  ? openRecord(original)
                                                  : [
                                                          'metadata',
                                                          'update',
                                                        ].contains(key) &&
                                                        actions.containsKey(
                                                          'metadata',
                                                        )
                                                  ? editPostMetadata(original)
                                                  : perform('$key', original),
                                      ),
                                ],
                              ),
                              columns.length,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  AnimatedSize(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
                    alignment: Alignment.topCenter,
                    child: expandedPostId == '${entry.$2['id']}'
                        ? Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: SizedBox(
                              width: min(space.maxWidth, total),
                              child: postEditor(entry.$2),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
