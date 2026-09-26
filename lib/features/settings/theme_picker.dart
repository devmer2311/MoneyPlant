import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../data/garden_store.dart';
import '../../shared/widgets.dart';

class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(gardenProvider);
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: themePacks.length,
        separatorBuilder: (_, i) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final pack = themePacks[i];
          final t = pack.tokens(Theme.of(context).brightness);
          final selected = store.data.themePack == pack.id;
          return Semantics(
            selected: selected,
            button: true,
            label: pack.name,
            child: InkWell(
              onTap: () => perform(
                context,
                () => store.change((d) => d.themePack = pack.id),
              ),
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                width: 148,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.canvas,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? t.brand : t.inkMuted,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: t.hero,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Aa',
                          style: TextStyle(
                            fontFamily: t.displayFont,
                            fontSize: 32,
                            color: t.heroInk,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(height: 12, color: t.receive),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 12, color: t.owe)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${selected ? '✓' : pack.emoji} ${pack.name}',
                      style: TextStyle(color: t.ink, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
