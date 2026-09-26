import '../../shared/pdf_skeleton.dart';

import 'package:share_plus/share_plus.dart';

import '../reports.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/design.dart';
import '../../core/models.dart';
import '../../core/settle.dart';
import '../../data/garden_store.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import '../composer.dart';
import '../statements/statement_pdf.dart';

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Groups & trips')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => sheet(context, const GroupEditor()),
        label: const Text('New group'),
        icon: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...store.data.groups
              .where((g) => !g.archived)
              .map(
                (g) => Card(
                  child: ListTile(
                    leading: Text(g.emoji),
                    title: Text(g.name),
                    subtitle: Text(
                      '${g.memberIds.length} people · Your balance ${money(store.groupBalances(g.id)['self'] ?? 0, store.data.currency)}',
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupPage(id: g.id)),
                    ),
                  ),
                ),
              ),
          if (store.data.groups.isEmpty)
            const Center(child: Text('Plan a trip. Keep it fair. 🌱')),
          ExpansionTile(
            title: const Text('Archived trips'),
            children: store.data.groups
                .where((g) => g.archived)
                .map(
                  (g) => ListTile(
                    title: Text(g.name),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupPage(id: g.id)),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class GroupEditor extends ConsumerStatefulWidget {
  const GroupEditor({super.key});
  @override
  ConsumerState<GroupEditor> createState() => _GroupEditorState();
}

class _GroupEditorState extends ConsumerState<GroupEditor> {
  final name = TextEditingController();
  final selected = {'self'};
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(gardenProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Trip / group name'),
        ),
        Wrap(
          children: store.data.people
              .map(
                (p) => FilterChip(
                  label: Text(p.name),
                  selected: selected.contains(p.id),
                  onSelected: (v) => setState(
                    () => v ? selected.add(p.id) : selected.remove(p.id),
                  ),
                ),
              )
              .toList(),
        ),
        TextButton(
          onPressed: () async {
            final value = await askText(context, 'Add a person');
            if (value != null && context.mounted) {
              await perform(
                context,
                () => store.change((d) {
                  if (value.trim().isEmpty ||
                      value.toLowerCase() == 'you' ||
                      d.people.any(
                        (p) => p.name.toLowerCase() == value.toLowerCase(),
                      )) {
                    throw const FormatException('Choose a unique name.');
                  }
                  d.people.add(Person(id: newId(), name: value.trim()));
                }),
              );
            }
          },
          child: const Text('Add person'),
        ),
        FilledButton(
          onPressed: () async {
            final ok = await perform(
              context,
              () => store.saveGroup(
                Group(
                  id: newId(),
                  name: name.text.trim(),
                  memberIds: selected.toList(),
                  createdAt: DateTime.now(),
                ),
              ),
            );
            if (ok && context.mounted) Navigator.pop(context);
          },
          child: const Text('Create group'),
        ),
      ],
    );
  }
}

class GroupPage extends ConsumerWidget {
  final String id;
  const GroupPage({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider),
        g = store.data.groups.firstWhere((g) => g.id == id);
    final net = store.groupBalances(id);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${g.emoji} ${g.name}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Splits'),
              Tab(text: 'Balances'),
              Tab(text: 'Settle up'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Share group statement',
              icon: const Icon(Icons.ios_share),
              onPressed: () => perform(
                context,
                () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Money Plant · ${g.name}\n${net.entries.map((e) => '${store.personName(e.key)}: ${money(e.value, store.data.currency)}').join('\n')}\n${simplifyDebts(net).map((t) => '${store.personName(t.fromId)} → ${store.personName(t.toId)}: ${money(t.amount, store.data.currency)}').join('\n')}',
                    sharePositionOrigin: shareOrigin(context),
                  ),
                ),
              ),
            ),

            IconButton(
              tooltip: 'PDF statement',
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(g.name)),
                    body: PdfPreview(
                      loadingWidget: const PdfSkeleton(),
                      build: (_) => statementPdf(store, group: g),
                      canDebug: false,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: g.archived ? 'Unarchive' : 'Archive',
              icon: const Icon(Icons.archive_outlined),
              onPressed: () => perform(
                context,
                () => store.saveGroup(
                  Group.fromJson({...g.toJson(), 'archived': !g.archived}),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: g.archived
            ? null
            : FloatingActionButton(
                onPressed: () =>
                    openComposer(context, groupId: id, split: true),
                child: const Icon(Icons.add),
              ),
        body: TabBarView(
          children: [
            ListView(
              children: store.data.splits
                  .where((s) => s.groupId == id)
                  .map(
                    (s) => ListTile(
                      title: Text(s.title),
                      subtitle: Text('${store.personName(s.payerId)} paid'),
                      trailing: Text(money(s.total, store.data.currency)),
                      onTap: () => openComposer(context, bill: s),
                    ),
                  )
                  .toList(),
            ),
            ListView(
              children: net.entries
                  .map(
                    (e) => ListTile(
                      title: Text(store.personName(e.key)),
                      trailing: Text(money(e.value, store.data.currency)),
                    ),
                  )
                  .toList(),
            ),
            ListView(
              children: [
                if (net.values.every((v) => v == 0))
                  const ListTile(title: Text('All square 🎉')),
                ...simplifyDebts(net).map(
                  (t) => ListTile(
                    title: Text(
                      '${store.personName(t.fromId)} → ${store.personName(t.toId)}',
                    ),
                    subtitle: Text(money(t.amount, store.data.currency)),
                    trailing: TextButton(
                      onPressed: () => changeWithUndo(
                        context,
                        store,
                        () => store.recordGroupSettlement(id, t),
                        'Group payment recorded',
                      ),
                      child: const Text('Mark paid'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
