import 'dart:convert';
import 'dart:io';

import 'package:ai_chat_organizer/data/key_store.dart';
import 'package:ai_chat_organizer/services/app_controller.dart';
import 'package:ai_chat_organizer/services/settings.dart';
import 'package:ai_chat_organizer/services/update_service.dart';
import 'package:ai_chat_organizer/ui/screens/export_guide_screen.dart';
import 'package:ai_chat_organizer/ui/screens/onboarding_screen.dart';
import 'package:ai_chat_organizer/ui/widgets/update_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers/app_harness.dart';

http.Response _json(Object o) =>
    http.Response.bytes(utf8.encode(jsonEncode(o)), 200, headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _release() => {
  'tag_name': 'v9.0.0',
  'body': '- 화면을 새로 꾸몄어요',
  'html_url': 'https://github.com/kwanhark-cmd/2222/releases/tag/v9.0.0',
  'assets': [
    {'name': 'ai-chat-organizer-v9.0.0-android.apk', 'browser_download_url': 'https://x/a.apk', 'size': 5},
    {'name': 'ai-chat-organizer-v9.0.0-macos.zip', 'browser_download_url': 'https://x/m.zip', 'size': 5},
  ],
};

Future<void> _settle(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _tap(WidgetTester tester, String text) async {
  final f = find.text(text).hitTestable().first;
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await _settle(tester);
}

/// 업데이트 카드만 띄우고, 업데이트 서버는 가짜로. 내려받기(파일 요청) 횟수를 셉니다.
Future<(AppController, List<Uri>, List<Uri>)> _cardWith(WidgetTester tester, String platform) async {
  await setScreen(tester, const Size(900, 2400));
  final c = (await tester.runAsync(readyController))!;
  final downloads = <Uri>[];
  final opened = <Uri>[];
  c.updateServiceFactory = () => UpdateService(
    platform: platform,
    currentVersion: '1.1.0',
    client: MockClient((req) async {
      if (req.url.host == 'api.github.com') return _json(_release());
      downloads.add(req.url);
      return http.Response.bytes([1, 2, 3, 4, 5], 200);
    }),
  );
  linkLauncher = (u) async {
    opened.add(u);
    return true;
  };
  addTearDown(() => linkLauncher = (u) async => false);
  await tester.pumpWidget(
    appWith(
      c,
      home: Scaffold(body: ListView(children: const [UpdateCard()])),
    ),
  );
  await _settle(tester);
  return (c, downloads, opened);
}

void main() {
  group('안드로이드 새 버전: 백업 → 기존 앱 지우기 → 새로 설치 → 되살리기', () {
    test('앱 안 설치는 윈도우·리눅스만, 안드로이드·맥은 설치를 시도하지 않는다', () async {
      expect(UpdateService.canInstallInApp('android'), isFalse);
      expect(UpdateService.canInstallInApp('macos'), isFalse);
      expect(UpdateService.canInstallInApp('ios'), isFalse);
      expect(UpdateService.canInstallInApp('windows'), isTrue);
      expect(UpdateService.canInstallInApp('linux'), isTrue);
      final f = File('${Directory.systemTemp.createTempSync('apk').path}/a.apk')..writeAsBytesSync([1]);
      for (final p in ['android', 'macos']) {
        await expectLater(
          UpdateService(platform: p).install(f),
          throwsA(isA<UpdateError>().having((e) => e.kind, 'kind', UpdateErrorKind.unsupported)),
        );
      }
      expect(const UpdateError(UpdateErrorKind.unsupported).message.contains('덮어'), isFalse);
    });

    test('안내 순서: 백업이 언제나 먼저, 앱 지우기는 그 뒤', () {
      final s = UpdateCard.androidSteps;
      final backup = s.indexOf('백업 파일 만들기');
      final delete = s.indexOf('기존 앱을 지워요');
      final install = s.indexOf('설치해요');
      final restore = s.indexOf('백업에서 되살리기');
      expect(backup, greaterThanOrEqualTo(0));
      expect(backup < delete && delete < install && install < restore, isTrue);
      expect(s, contains('앱 밖'));
      expect(s.contains('그대로 남아요'), isFalse);
    });

    testWidgets('안드로이드: 설치 대신 순서 안내, 백업 확인 뒤에만 내려받기 화면을 연다', (tester) async {
      final (_, downloads, opened) = await _cardWith(tester, 'android');
      expect(find.textContaining('지우기 전에 꼭 "백업 파일 만들기"'), findsOneWidget);
      expect(find.textContaining('그대로 남아요'), findsNothing);

      await _tap(tester, '업데이트 확인');
      expect(find.textContaining('1. 먼저 "백업 파일 만들기"'), findsOneWidget);
      expect(find.textContaining('화면을 새로 꾸몄어요'), findsOneWidget);
      expect(find.text('1. 백업 파일 만들기'), findsOneWidget);
      expect(find.text('업데이트'), findsNothing);

      // 백업 없이 내려받으려 하면 한 번 더 묻고, "아니요"면 안내로 돌아감
      await _tap(tester, '2. 내려받기 화면 열기');
      expect(find.text('백업 파일을 만들었나요?'), findsOneWidget);
      await _tap(tester, '아니요, 그만둘게요');
      expect(find.text('1. 백업 파일 만들기'), findsOneWidget);
      expect(opened, isEmpty);

      await _tap(tester, '2. 내려받기 화면 열기');
      await _tap(tester, '네, 이미 만들어 두었어요');
      expect(opened.single.toString(), 'https://x/a.apk');
      expect(downloads, isEmpty, reason: '앱 안에서 설치 파일을 내려받거나 설치하지 않음');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('맥: 앱이 스스로 바꾸지 않고 내려받기 화면을 연다', (tester) async {
      final (_, downloads, opened) = await _cardWith(tester, 'macos');
      await _tap(tester, '업데이트 확인');
      expect(find.textContaining('그래도 열기'), findsOneWidget);
      await _tap(tester, '내려받기 화면 열기');
      expect(opened.single.toString(), 'https://x/m.zip');
      expect(downloads, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    test('백업 파일 → 새로 설치(빈 앱, 새 열쇠) → 되살리기', () async {
      // 기존 앱(파일에 저장되는 실제 자료)
      final oldRoot = Directory.systemTemp.createTempSync('old_install');
      final oldApp = AppController(root: oldRoot, keys: MemoryKeyStore(), voice: FakeVoice(), autoUpdateCheck: false, loadAsset: fileAsset);
      await oldApp.init();
      await oldApp.createUser('할머니');
      await oldApp.importSamples();
      oldApp.updateSettings((s) {
        s.fontSize = FontSize.large;
        s.onboardingDone = true;
      });
      final s = oldApp.session!;
      final first = s.store.list().first;
      final topic = s.topics.create('보관함');
      s.topics.setOrigin(first.id, topic, 'user');
      s.store.addTag(first.id, '중요');
      await s.store.addNote(first.id, '꼭 다시 보기');
      final count = s.store.count();
      final topicNames = s.topics.topicsOf(first.id).map((t) => t.name).toList();
      expect(topicNames, contains('보관함'));
      final bytes = await oldApp.makeBackup('비밀번호123');
      final backupFile = File('${Directory.systemTemp.createTempSync('downloads').path}/대화기록백업.aibackup')..writeAsBytesSync(bytes);
      oldApp.signOut();
      // 안드로이드에서 앱을 지우면 앱 자료와 열쇠가 모두 사라짐
      oldRoot.deleteSync(recursive: true);

      // 새로 설치: 빈 폴더, 빈 열쇠 보관함, 첫 안내에서 이름만 넣음
      final newRoot = Directory.systemTemp.createTempSync('new_install');
      final newApp = AppController(root: newRoot, keys: MemoryKeyStore(), voice: FakeVoice(), autoUpdateCheck: false, loadAsset: fileAsset);
      await newApp.init();
      await newApp.createUser('할머니');
      expect(newApp.session!.store.count(), 0);
      expect(newApp.settings.onboardingDone, isFalse);

      await newApp.restoreBackup(backupFile.readAsBytesSync(), '비밀번호123');
      final n = newApp.session!;
      expect(n.store.count(), count);
      expect(n.store.tagsOf(first.id), ['중요']);
      expect((await n.store.notes(first.id)).single.text, '꼭 다시 보기');
      expect(n.topics.topicsOf(first.id).map((t) => t.name).toList(), topicNames);
      expect((await n.store.messages(first.id)), isNotEmpty);
      expect(n.settings.fontSize, FontSize.large);
      expect(n.settings.onboardingDone, isTrue, reason: '되살리면 첫 안내가 끝남');
      // 앱을 다시 열어도 그대로
      newApp.signOut();
      final reopened = AppController(root: newRoot, keys: newApp.keys, voice: FakeVoice(), autoUpdateCheck: false, loadAsset: fileAsset);
      await reopened.init();
      expect(reopened.session!.store.count(), count);
      expect((await reopened.session!.store.notes(first.id)).single.text, '꼭 다시 보기');
      // 틀린 비밀번호로는 되살리지 않고 자료도 그대로
      await expectLater(reopened.restoreBackup(backupFile.readAsBytesSync(), '틀린비밀번호'), throwsA(anything));
      expect(reopened.session!.store.count(), count);
      reopened.signOut();
    });

    testWidgets('첫 안내 마지막 단계에 "백업에서 되살리기"가 있다', (tester) async {
      await setScreen(tester, const Size(900, 1600));
      final c = makeController();
      await tester.runAsync(c.init);
      await tester.runAsync(() => c.createUser('나'));
      await tester.pumpWidget(appWith(c, home: const OnboardingScreen()));
      await _settle(tester);
      for (var i = 0; i < 3; i++) {
        await _tap(tester, '다음');
      }
      expect(find.text('샘플로 체험하기'), findsOneWidget);
      expect(find.text('백업에서 되살리기'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
