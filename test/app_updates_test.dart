import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_plant/data/update_store.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:money_plant/core/app_updates.dart';
import 'package:money_plant/data/update_service.dart';
import 'package:money_plant/features/update_prompt.dart';

class MemoryUpdates implements UpdateStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

Map<String, dynamic> release(
  String version, {
  bool prerelease = false,
  bool draft = false,
}) => {
  'tag_name': version,
  'html_url': '$releasesUrl/tag/$version',
  'draft': draft,
  'prerelease': prerelease,
  'assets': [
    {
      'name': 'money-plant.apk',
      'browser_download_url': '$releasesUrl/download/$version/money-plant.apk',
    },
  ],
};

void main() {
  test(
    'selects newest stable semver, excluding drafts and installed versions',
    () {
      final rows = [
        release('v1.2.0'),
        release('v1.10.0'),
        release('v9.0.0', draft: true),
        release('v8.0.0', prerelease: true),
        release('v7.0.0-beta.1'),
        release('bad'),
      ];
      expect(newerRelease(rows, '1.9.0+50')?.version, '1.10.0');
      expect(newerRelease(rows, '1.10.0+51'), isNull);
      expect(newerRelease(rows, '2.0.0'), isNull);
      expect(newerRelease(rows, 'invalid'), isNull);
    },
  );

  test('accepts only trusted release links and universal APK assets', () {
    expect(
      AppRelease.parse({
        ...release('v1.1.0'),
        'html_url': 'https://example.com/malware',
      }),
      isNull,
    );
    final r = AppRelease.parse({
      ...release('v1.1.0'),
      'assets': [
        {
          'name': 'money-plant.apk',
          'browser_download_url': 'https://example.com/app.apk',
        },
        {
          'name': 'app-arm64-v8a-release.apk',
          'browser_download_url':
              '$releasesUrl/download/v1.1.0/app-arm64-v8a-release.apk',
        },
      ],
    });
    expect(r?.apk, isNull);
    expect(
      AppRelease.parse(release('v1.1.0'))?.apk?.path,
      endsWith('/money-plant.apk'),
    );
    expect(websiteUri()?.host, 'moneyplantbydev.pages.dev');
    expect(websiteUri('http://example.com'), isNull);
    expect(websiteUri('https://example.com/app')?.host, 'example.com');
  });

  test('recognises the published APK filename containing its build number', () {
    final r = AppRelease.parse({
      ...release('v1.0.1'),
      'assets': [
        {
          'name': 'money-plant-v1.0.1+2.apk',
          'browser_download_url':
              '$releasesUrl/download/v1.0.1/money-plant-v1.0.1%2B2.apk',
        },
      ],
    });
    expect(r?.apk, isNotNull);
  });

  testWidgets('notification tap reopens the launch dialog after Later', (
    tester,
  ) async {
    final service = UpdateService(
      MemoryUpdates(),
      clientFactory: () => MockClient(
        (_) async => http.Response(jsonEncode([release('v1.5.0')]), 200),
      ),
    );
    final store = UpdateStore(service)..installed = '1.0.0';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [updateProvider.overrideWith((ref) => store)],
        child: const MaterialApp(
          home: UpdatePromptHost(child: Scaffold(body: Text('Garden'))),
        ),
      ),
    );
    await store.check();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateDialog), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    await store.check();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(UpdateDialog), findsNothing);
    await store.check(notificationTap: true);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateDialog), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
  });

  test('offline checks stay silent; notification taps use only a newer cached release', () async {
    final storage = MemoryUpdates();
    final service = UpdateService(
      storage,
      clientFactory: () => MockClient(
        (_) async => http.Response(jsonEncode([release('v1.5.0')]), 200),
      ),
    );
    expect((await service.check('1.0.0'))?.version, '1.5.0');
    final offline = UpdateService(
      storage,
      clientFactory: () =>
          MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(await offline.check('1.0.0'), isNull);
    expect(
      (await offline.check('1.0.0', notificationTap: true))?.version,
      '1.5.0',
    );
    expect(await offline.check('1.5.0', notificationTap: true), isNull);
  });

  test(
    'API errors, missing releases, malformed responses and timeouts are quiet',
    () async {
      for (final response in [
        http.Response('rate limited', 403),
        http.Response('missing', 404),
        http.Response('<html/>', 200),
        http.Response('{}', 200),
        http.Response('[]', 200),
      ]) {
        final service = UpdateService(
          MemoryUpdates(),
          clientFactory: () => MockClient((_) async => response),
        );
        expect(await service.check('1.0.0'), isNull);
      }
      final service = UpdateService(
        MemoryUpdates(),
        timeout: const Duration(milliseconds: 1),
        clientFactory: () => MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return http.Response('[]', 200);
        }),
      );
      expect(await service.check('1.0.0'), isNull);
    },
  );

  test(
    'daily jobs notify once per version and retry permission-denied delivery',
    () async {
      final storage = MemoryUpdates();
      final service = UpdateService(
        storage,
        clientFactory: () => MockClient(
          (_) async => http.Response(jsonEncode([release('v1.5.0')]), 200),
        ),
      );
      var count = 0;
      await service.notifyIfNew('1.0.0', (_) async => false);
      expect(storage.values['notified'], isNull);
      Future<bool> deliver(AppRelease _) async {
        count++;
        return true;
      }

      await service.notifyIfNew('1.0.0', deliver);
      await service.notifyIfNew('1.0.0', deliver);
      expect(count, 1);
      await service.notifyIfNew('1.5.0', deliver);
      expect(count, 1);
      expect(await service.cached('1.0.0'), isNull);
    },
  );

  testWidgets(
    'shared update dialog offers Update and Later without blocking dismissal',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => UpdateDialog(
                    release: AppRelease.parse(release('v1.5.0'))!,
                  ),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('New version v1.5.0 is ready 🌱'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(find.byType(UpdateDialog), findsNothing);
    },
  );
}
