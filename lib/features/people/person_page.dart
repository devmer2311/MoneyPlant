import '../../shared/payment_row.dart';
import '../../shared/pdf_skeleton.dart';
import 'settle_all_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design.dart';
import '../../core/models.dart';
import '../../core/upi.dart';
import '../../data/garden_store.dart';
import '../../shared/actions.dart';
import '../../shared/widgets.dart';
import '../composer.dart';
import '../reports.dart';
import '../settings/get_paid.dart';
import '../statements/person_text.dart';
import '../statements/statement_pdf.dart';

void openPerson(BuildContext context, Person person) =>
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PersonDetails(person: person)));

class PersonDetails extends ConsumerStatefulWidget {
  final Person person;
  const PersonDetails({super.key, required this.person});
  @override
  ConsumerState<PersonDetails> createState() => _PersonDetailsState();
}

class _PersonDetailsState extends ConsumerState<PersonDetails> {
  String filter = 'All';
  DateTimeRange? range;
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(gardenProvider);
    final p = store.data.people
        .where((p) => p.id == widget.person.id)
        .firstOrNull;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Person removed.')),
      );
    }
    final net = store.personNet(p.id), link = paymentLink(store.data, net);
    final splits = store.data.splits.where((s) {
      final due = s.payerId == 'self'
          ? store.remaining(s, p.id)
          : s.payerId == p.id
          ? store.remaining(s, 'self')
          : 0;
      return s.portions.containsKey(p.id) &&
          (filter == 'All' || (filter == 'Pending' ? due > 0 : due == 0)) &&
          (range == null ||
              !s.date.isBefore(range!.start) &&
                  s.date.isBefore(range!.end.add(const Duration(days: 1))));
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'Rename') {
                final name = await askText(
                  context,
                  'Rename ${p.name}',
                  initial: p.name,
                );
                if (name != null && context.mounted) {
                  await perform(context, () => store.renamePerson(p.id, name));
                }
              } else if (action == 'Delete') {
                await changeWithUndo(
                  context,
                  store,
                  () => store.deletePerson(p.id),
                  'Person removed',
                );
              } else {
                final target = await showDialog<Person>(
                  context: context,
                  builder: (c) => SimpleDialog(
                    title: Text('Merge ${p.name} into…'),
                    children: store.data.people
                        .where((x) => x.id != p.id)
                        .map(
                          (x) => SimpleDialogOption(
                            onPressed: () => Navigator.pop(c, x),
                            child: Text(x.name),
                          ),
                        )
                        .toList(),
                  ),
                );
                if (target != null && context.mounted) {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text('Merge into ${target.name}?'),
                      content: Text(
                        '${splits.length} splits, linked tasks, payments and group memberships will be combined. ${p.name} will be removed.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Merge'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await changeWithUndo(
                      context,
                      store,
                      () => store.mergePeople(p.id, target.id),
                      'People merged',
                    );
                  }
                }
              }
            },
            itemBuilder: (_) => [
              'Rename',
              'Merge',
              'Delete',
            ].map((x) => PopupMenuItem(value: x, child: Text(x))).toList(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Hero(
            tag: 'person:${p.id}',
            child: CircleAvatar(radius: 34, child: Text(p.name[0])),
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(end: net.toDouble()),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 450),
            builder: (c, v, _) => Text(
              net == 0
                  ? 'All square 🎉'
                  : '${net > 0 ? '${p.name} owes you' : 'You owe ${p.name}'} ${money(v.round().abs(), store.data.currency)}',
              style: context.type.headlineMedium,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => perform(
                  context,
                  () => SharePlus.instance.share(
                    ShareParams(
                      text: personMessage(
                        store,
                        p,
                        start: range?.start,
                        end: range?.end,
                      ),
                      sharePositionOrigin: shareOrigin(context),
                    ),
                  ),
                ),
                child: const Text('Share text'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text('${p.name} · Statement')),
                      body: PdfPreview(
                        loadingWidget: const PdfSkeleton(),
                        build: (_) => statementPdf(
                          store,
                          person: p,
                          start: range?.start,
                          end: range?.end,
                        ),
                        pdfFileName:
                            'MoneyPlant-Statement-${p.name}-${DateTime.now().toIso8601String().split('T').first}.pdf',
                        canDebug: false,
                        canChangePageFormat: false,
                      ),
                    ),
                  ),
                ),
                child: const Text('PDF statement'),
              ),
              if (link != null)
                OutlinedButton(
                  onPressed: () =>
                      sheet(context, PayQr(link: link, amount: net)),
                  child: const Text('Show QR'),
                ),
              if (net != 0)
                FilledButton(
                  onPressed: () => sheet(context, SettleAllSheet(person: p)),
                  child: const Text('Settle all'),
                ),
              if (net > 0)
                OutlinedButton(
                  onPressed: () =>
                      sheet(context, NudgeSheet(person: p, amount: net)),
                  child: const Text('Nudge'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              ...['All', 'Pending', 'Settled'].map(
                (v) => ChoiceChip(
                  label: Text(v),
                  selected: filter == v,
                  onSelected: (_) => setState(() => filter = v),
                ),
              ),
              ActionChip(
                label: Text(range == null ? 'All dates' : 'Clear dates'),
                onPressed: () async {
                  if (range != null) {
                    setState(() => range = null);
                    return;
                  }
                  final r = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (r != null) setState(() => range = r);
                },
              ),
            ],
          ),
          const SectionTitle('Splits'),
          ...splits.map(
            (s) => ListTile(
              title: Text(s.title),
              subtitle: Text(
                'Share ${money(s.portions[p.id]!, store.data.currency)} · Paid ${money(store.paid(s, p.id), store.data.currency)}',
              ),
              onTap: () => openComposer(context, bill: s),
            ),
          ),
          const SectionTitle('Payments'),
          ...store.data.payments
              .where(
                (pay) => store.data.splits.any(
                  (s) =>
                      s.id == pay.splitId &&
                      (pay.personId == p.id ||
                          s.payerId == p.id && pay.personId == 'self'),
                ),
              )
              .toList()
              .reversed
              .map(
                (pay) => PaymentRow(
                  store: store,
                  paymentId: pay.id,
                  child: ListTile(
                    title: Text(money(pay.amount, store.data.currency)),
                    subtitle: Text(pay.date.toIso8601String().split('T').first),
                    trailing: IconButton(
                      icon: const Icon(Icons.undo),
                      tooltip: 'Remove payment',
                      onPressed: () => changeWithUndo(
                        context,
                        store,
                        () => store.removePayment(pay.id),
                        'Payment removed',
                      ),
                    ),
                  ),
                ),
              ),
          const SectionTitle('Money tasks'),
          ...store.data.tasks
              .where((t) => t.personId == p.id && !t.completed)
              .map(
                (t) => ListTile(
                  title: Text(t.title),
                  subtitle: Text(
                    '${t.direction} · ${money(t.amount, store.data.currency)}',
                  ),
                  onTap: () => openComposer(context, mode: 'task', task: t),
                ),
              ),
        ],
      ),
    );
  }
}

class NudgeSheet extends ConsumerStatefulWidget {
  final Person person;
  final int amount;
  final BillSplit? split;
  const NudgeSheet({
    super.key,
    required this.person,
    required this.amount,
    this.split,
  });
  @override
  ConsumerState<NudgeSheet> createState() => _NudgeSheetState();
}

class _NudgeSheetState extends ConsumerState<NudgeSheet> {
  final text = TextEditingController();
  String tone = 'Cute';
  bool attachPdf = false;
  @override
  void initState() {
    super.initState();
    update();
  }

  void update() {
    final s = ref.read(gardenProvider), p = widget.person;
    final amount = money(widget.amount, s.data.currency);
    text.text = tone == 'Cute'
        ? 'Hey ${p.name}! Gentle nudge 🌱 $amount pending. No rush 💚'
        : tone == 'Polite'
        ? 'Hi ${p.name}, just a reminder: $amount is pending. Thanks!'
        : '${p.name} bhai, $amount pending. Paisa ped pe nahi ugta 😤🌱';
    final link = paymentLink(s.data, widget.amount);
    if (link != null) text.text += '\n$link';
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        children: ['Cute', 'Polite', 'Boss mode']
            .map(
              (v) => ChoiceChip(
                label: Text(v),
                selected: v == tone,
                onSelected: (_) => setState(() {
                  tone = v;
                  update();
                }),
              ),
            )
            .toList(),
      ),
      TextField(controller: text, maxLines: 5),
      CheckboxListTile(
        title: Text(
          widget.split == null
              ? 'Attach PDF statement'
              : 'Attach split receipt',
        ),
        value: attachPdf,
        onChanged: (v) => setState(() => attachPdf = v!),
      ),
      FilledButton(
        onPressed: () => perform(context, () async {
          final origin = shareOrigin(context);
          final result = await SharePlus.instance.share(
            ShareParams(
              text: text.text,
              files: attachPdf
                  ? [
                      XFile.fromData(
                        await statementPdf(
                          ref.read(gardenProvider),
                          person: widget.split == null ? widget.person : null,
                          split: widget.split,
                        ),
                        mimeType: 'application/pdf',
                      ),
                    ]
                  : null,
              fileNameOverrides: attachPdf
                  ? ['MoneyPlant-Statement.pdf']
                  : null,
              sharePositionOrigin: origin,
            ),
          );
          if (result.status == ShareResultStatus.success) {
            await ref
                .read(gardenProvider)
                .change(
                  (d) =>
                      d.activity['nudge:${widget.person.id}:${DateTime.now().toIso8601String().split('T').first}'] =
                          DateTime.now().toIso8601String(),
                );
          }
        }),
        child: const Text('Share nudge'),
      ),
    ],
  );
}
