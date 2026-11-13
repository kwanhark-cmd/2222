import 'dart:math' as math;

import 'package:ai_chat_organizer/services/app_controller.dart';
import 'package:ai_chat_organizer/services/settings.dart';
import 'package:ai_chat_organizer/theme/app_theme.dart';
import 'package:ai_chat_organizer/theme/tokens.dart';
import 'package:ai_chat_organizer/ui/screens/conversation_screen.dart';
import 'package:ai_chat_organizer/ui/screens/decisions_screen.dart';
import 'package:ai_chat_organizer/ui/screens/export_guide_screen.dart';
import 'package:ai_chat_organizer/ui/screens/home_screen.dart';
import 'package:ai_chat_organizer/ui/screens/import_screen.dart';
import 'package:ai_chat_organizer/ui/screens/licenses_screen.dart';
import 'package:ai_chat_organizer/ui/screens/problem_report_screen.dart';
import 'package:ai_chat_organizer/ui/screens/profile_screen.dart';
import 'package:ai_chat_organizer/ui/screens/search_screen.dart';
import 'package:ai_chat_organizer/ui/screens/settings_screen.dart';
import 'package:ai_chat_organizer/ui/screens/timeline_screen.dart';
import 'package:ai_chat_organizer/ui/screens/topics_screen.dart';
import 'package:ai_chat_organizer/ui/screens/onboarding_screen.dart';
import 'package:ai_chat_organizer/ui/screens/customize_screen.dart';
import 'package:ai_chat_organizer/ui/screens/gmail_setup_screen.dart';
import 'package:ai_chat_organizer/ui/shell.dart';
import 'package:ai_chat_organizer/ui/widgets/common.dart';
import 'package:ai_chat_organizer/ui/widgets/conversation_tile.dart';
import 'package:ai_chat_organizer/ui/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

typedef ScreenBuilder = Widget Function(AppController c);

/// 앱의 모든 색 묶음(밝게·어둡게·고대비 2가지·색 테마 5가지×밝게/어둡게).
final allPalettes = <(String, AppPalette)>[
  ('밝게', AppPalette.light),
  ('어둡게', AppPalette.dark),
  ('고대비 밝게', AppPalette.highContrastLight),
  ('고대비 어둡게', AppPalette.highContrastDark),
  for (final t in ColorThemes.names.keys) ...[
    ('색 테마 $t 밝게', ColorThemes.apply(AppPalette.light, t)),
    ('색 테마 $t 어둡게', ColorThemes.apply(AppPalette.dark, t)),
  ],
];

/// 버튼 모양에 정해진 값을 실제 상태로 꺼내 보기.
T? resolve<T>(WidgetStateProperty<T>? prop, Set<WidgetState> states) => prop?.resolve(states);

void main() {
  group('대비 검사(글자 7:1 이상, 버튼은 누른 상태까지)', () {
    for (final (name, pal) in allPalettes) {
      test(name, () {
        final low = [
          for (final (fg, bg, label) in pal.contrastPairs)
            if (contrast(fg, bg) < 7.0) '$label ${contrast(fg, bg).toStringAsFixed(2)}',
        ];
        expect(low, isEmpty, reason: '$name 대비 7:1 미만');
        // 테두리(글자가 아닌 선)는 3:1 이상이어야 보임
        for (final bg in [pal.surface, pal.background]) {
          expect(contrast(pal.border, bg), greaterThanOrEqualTo(3.0), reason: '$name / 테두리선');
          expect(contrast(pal.button(ButtonKind.quiet).border!, bg), greaterThanOrEqualTo(3.0), reason: '$name / 테두리 버튼 선');
          expect(contrast(pal.focusRing, bg), greaterThanOrEqualTo(7.0), reason: '$name / 초점 고리');
        }
      });
    }
  });

  group('버튼 규칙(높이 52 이상·글자 17 이상 굵게·테두리 2·위험은 빨강)', () {
    for (final (name, pal) in allPalettes) {
      test(name, () {
        expect(AppSize.buttonHeight, greaterThanOrEqualTo(52));
        expect(AppSize.minTouch, greaterThanOrEqualTo(48));
        expect(pal.outlineWidth, greaterThanOrEqualTo(2));
        // 위험(지우기) 버튼은 분명한 빨강: 색상 각도 345~15도, 진한 채도
        final danger = HSVColor.fromColor(pal.button(ButtonKind.danger).bg);
        expect(danger.hue >= 345 || danger.hue <= 15, isTrue, reason: '$name 위험 버튼 색상 ${danger.hue}');
        expect(danger.saturation, greaterThanOrEqualTo(0.6), reason: '$name 위험 버튼 채도');
        // 누른 상태는 평소와 눈에 띄게 다름
        for (final k in ButtonKind.values) {
          final b = pal.button(k);
          expect(b.pressedBg, isNot(b.bg), reason: '$name ${k.name} 누름 색');
        }

        final theme = AppTheme.build(pal);
        final tt = theme.textTheme;
        // 본문·설명 글자 16 이상, 흐린 회색 금지(7:1)
        for (final st in [tt.bodyLarge!, tt.bodyMedium!, tt.bodySmall!, tt.labelMedium!, tt.titleMedium!]) {
          expect(st.fontSize, greaterThanOrEqualTo(16));
          expect(contrast(st.color!, pal.surface), greaterThanOrEqualTo(7.0));
          expect(contrast(st.color!, pal.background), greaterThanOrEqualTo(7.0));
        }
        final label = tt.labelLarge!;
        expect(label.fontSize, greaterThanOrEqualTo(17));
        expect(label.fontWeight!.value, greaterThanOrEqualTo(FontWeight.w700.value));

        // 기본 위젯 버튼(꽉 찬·테두리·글자 버튼)
        const pressed = {WidgetState.pressed};
        const normal = <WidgetState>{};
        for (final (kind, style) in [
          ('꽉 찬', theme.filledButtonTheme.style!),
          ('입체', theme.elevatedButtonTheme.style!),
          ('테두리', theme.outlinedButtonTheme.style!),
          ('글자', theme.textButtonTheme.style!),
        ]) {
          expect(resolve(style.minimumSize, normal)!.height, greaterThanOrEqualTo(52), reason: '$name $kind 높이');
          expect(resolve(style.minimumSize, normal)!.width, greaterThanOrEqualTo(48), reason: '$name $kind 폭');
          final ts = resolve(style.textStyle, normal)!;
          expect(ts.fontSize, greaterThanOrEqualTo(17));
          expect(ts.fontWeight!.value, greaterThanOrEqualTo(FontWeight.w700.value));
          for (final st in [normal, pressed]) {
            final fg = resolve(style.foregroundColor, st)!;
            var bg = resolve(style.backgroundColor, st)!;
            if (bg.a == 0) bg = pal.background; // 투명이면 화면 배경 위
            expect(contrast(fg, bg), greaterThanOrEqualTo(7.0), reason: '$name $kind 버튼 $st 대비');
          }
          expect(
            resolve<Color?>(style.backgroundColor, pressed),
            isNot(resolve<Color?>(style.backgroundColor, normal)),
            reason: '$name $kind 누름 표시',
          );
          final focus = resolve(style.side, {WidgetState.focused})!;
          expect(focus.width, greaterThanOrEqualTo(2), reason: '$name $kind 초점 표시');
        }
        final outline = resolve(theme.outlinedButtonTheme.style!.side, normal)!;
        expect(outline.width, greaterThanOrEqualTo(2));
        expect(contrast(outline.color, pal.surface), greaterThanOrEqualTo(3.0));
        final icon = theme.iconButtonTheme.style!;
        expect(resolve(icon.minimumSize, normal)!.shortestSide, greaterThanOrEqualTo(48));
      });
    }
  });

  group('큰 버튼(BigButton) 실제 모습', () {
    Widget host(AppPalette pal, List<Widget> children) => MaterialApp(
      theme: AppTheme.build(pal),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [for (final c in children) Padding(padding: const EdgeInsets.all(8), child: c)],
          ),
        ),
      ),
    );
    BoxDecoration deco(WidgetTester tester, String label) =>
        tester
                .widget<AnimatedContainer>(
                  find.descendant(of: find.widgetWithText(Pressable, label), matching: find.byType(AnimatedContainer)).first,
                )
                .decoration!
            as BoxDecoration;
    Color labelColor(WidgetTester tester, String label) => tester.widget<Text>(find.text(label)).style!.color!;

    for (final (name, pal) in allPalettes.take(4)) {
      testWidgets('$name: 누르면 색이 바뀌고 글자 대비 7:1 유지, 테두리 버튼 2px', (tester) async {
        await setScreen(tester, const Size(360, 640));
        await tester.pumpWidget(
          host(pal, [
            BigButton(label: '주요', onPressed: () {}),
            BigButton(label: '테두리', onPressed: () {}, kind: ButtonKind.quiet),
            BigButton(label: '지우기', onPressed: () {}, kind: ButtonKind.danger),
          ]),
        );
        for (final (label, kind) in [('주요', ButtonKind.primary), ('테두리', ButtonKind.quiet), ('지우기', ButtonKind.danger)]) {
          final b = pal.button(kind);
          final before = deco(tester, label);
          expect(before.color, b.bg);
          expect(labelColor(tester, label), b.fg);
          expect(tester.getSize(find.widgetWithText(Pressable, label)).height, greaterThanOrEqualTo(52));
          expect(tester.widget<Text>(find.text(label)).style!.fontSize, greaterThanOrEqualTo(17));
          if (kind == ButtonKind.quiet) {
            final side = (before.border! as Border).top;
            expect(side.width, greaterThanOrEqualTo(2));
            expect(side.color, b.border);
          }
          final g = await tester.startGesture(tester.getCenter(find.text(label)));
          await tester.pump(const Duration(milliseconds: 300));
          final during = deco(tester, label);
          expect(during.color, b.pressedBg, reason: '$label 누르는 중 색');
          expect(contrast(labelColor(tester, label), during.color!), greaterThanOrEqualTo(7.0), reason: '$label 누르는 중 대비');
          for (final c in (during.gradient as LinearGradient?)?.colors ?? <Color>[]) {
            expect(contrast(labelColor(tester, label), c), greaterThanOrEqualTo(7.0), reason: '$label 누르는 중 윗부분 대비');
          }
          await g.up();
          await tester.pump(const Duration(milliseconds: 300));
          expect(deco(tester, label).color, b.bg);
        }
        expect(deco(tester, '지우기').color, pal.danger, reason: '지우기는 빨강');
      });
    }

    testWidgets('키보드로 고르면 둘레에 진한 고리가 보인다', (tester) async {
      await setScreen(tester, const Size(360, 640));
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic);
      const pal = AppPalette.light;
      await tester.pumpWidget(host(pal, [BigButton(label: '주요', onPressed: () {})]));
      expect(deco(tester, '주요').boxShadow?.any((s) => s.color == pal.focusRing) ?? false, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 300));
      final ring = deco(tester, '주요').boxShadow!.where((s) => s.color == pal.focusRing);
      expect(ring, isNotEmpty);
      expect(ring.first.spreadRadius, greaterThanOrEqualTo(AppSize.focusRing));
    });
  });

  group('화면 잘림 검사(360×640, 아주 큰 글씨)', () {
    int? convId;
    int? topicId;
    final screens = <String, ScreenBuilder>{
      '홈': (_) => const HomeScreen(),
      '검색': (_) => const SearchScreen(initialQuery: '유튜브'),
      '가져오기': (_) => const ImportScreen(),
      '주제': (_) => const TopicsScreen(),
      '주제 안': (_) => TopicDetailScreen(topicId: topicId!),
      '타임라인': (_) => const TimelineScreen(),
      '정한 내용': (_) => const DecisionsScreen(),
      '주제 정한 내용': (_) => TopicDigestScreen(topicId: topicId!),
      '설정': (_) => const SettingsScreen(),
      '대화': (_) => ConversationScreen(id: convId!, highlight: const ['유튜브']),
      '받는 법': (_) => const ExportGuideScreen(),
      '문제 신고': (_) => const ProblemReportScreen(),
      '라이선스': (_) => const LicensesScreen(),
      '사용자 고르기': (_) => const ProfileScreen(),
      '첫 안내': (_) => const OnboardingScreen(),
      '지메일 연결': (_) => const GmailSetupScreen(),
      '앱 꾸미기': (_) => const CustomizeScreen(),
      '탭 틀(홈)': (_) => const MainShell(),
      '찾기 탭(넓으면 목록+본문)': (_) => const SearchScreen(asTab: true, initialQuery: '유튜브'),
      '주제 탭(넓으면 3단)': (_) => const TopicsScreen(asTab: true),
      '주제 안(옆 칸)': (_) => TopicDetailScreen(topicId: topicId!, embedded: true),
      '대화(옆 칸)': (_) => ConversationScreen(id: convId!, embedded: true),
    };
    final modes = <String, void Function(AppSettings)>{
      '밝게': (s) => s.theme = ThemeChoice.light,
      '어둡게': (s) => s.theme = ThemeChoice.dark,
      '고대비': (s) {
        s.theme = ThemeChoice.dark;
        s.highContrast = true;
      },
      '고대비 밝게': (s) {
        s.theme = ThemeChoice.light;
        s.highContrast = true;
      },
    };
    for (final size in [const Size(360, 640), const Size(1280, 800), const Size(1600, 900)]) {
      for (final m in modes.entries) {
        testWidgets('${size.width.toInt()}폭 · ${m.key} · 모든 화면', (tester) async {
          await setScreen(tester, size);
          final c = (await tester.runAsync(
            () => readyController(
              settings: (s) {
                s.fontSize = FontSize.xlarge;
                m.value(s);
              },
            ),
          ))!;
          final store = c.session!.store;
          convId = store.list().firstWhere((x) => x.title.contains('유튜브 앱')).id;
          topicId = c.session!.topics.all().first.id;
          for (final e in screens.entries) {
            await tester.pumpWidget(appWith(c, home: e.value(c)));
            for (var i = 0; i < 6; i++) {
              await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
              await tester.pump(const Duration(milliseconds: 120));
            }
            final err = tester.takeException();
            expect(err, isNull, reason: '${e.key} 화면에서 오류/잘림: ${err is FlutterError ? err.toStringDeep() : err}');
            // 위로 끝까지 스크롤해서 긴 화면 아래쪽도 그려 봄
            final scrollables = find.byType(Scrollable);
            if (scrollables.evaluate().isNotEmpty) {
              await tester.drag(scrollables.first, const Offset(0, -3000), warnIfMissed: false);
              await tester.pump(const Duration(milliseconds: 300));
              expect(tester.takeException(), isNull, reason: '${e.key} 화면 아래쪽에서 오류/잘림');
            }
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });

  testWidgets('움직임 줄이기를 켜면 애니메이션이 꺼진다', (tester) async {
    await setScreen(tester, const Size(800, 1200));
    final c = (await tester.runAsync(() => readyController()))!;
    await tester.pumpWidget(appWith(c, home: const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(AnimatedSlide), findsWidgets);
    c.updateSettings((s) => s.reduceMotion = true);
    await tester.pumpWidget(appWith(c, home: const HomeScreen()));
    await tester.pump();
    expect(find.byType(AnimatedSlide), findsNothing);
    final ctx = tester.element(find.byType(HomeScreen));
    expect(AppTheme.of(ctx).motion(ctx, AppMotion.normal), Duration.zero);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('버튼 최소 높이 56, 터치 영역 48 이상, 버튼 글자 17 이상 굵게(설정 화면 전체)', (tester) async {
    await setScreen(tester, const Size(360, 640));
    final c = (await tester.runAsync(() => readyController()))!;
    for (final screen in [const ImportScreen(), const SettingsScreen()]) {
      await tester.pumpWidget(appWith(c, home: screen));
      await tester.pump(const Duration(milliseconds: 300));
      final buttons = find.byType(BigButton);
      expect(buttons, findsWidgets);
      for (final e in buttons.evaluate()) {
        final size = (e.renderObject as RenderBox).size;
        expect(size.height, greaterThanOrEqualTo(AppSize.buttonHeight));
        expect(size.width, greaterThanOrEqualTo(AppSize.minTouch));
        final w = e.widget as BigButton;
        final text = find.descendant(of: find.byWidget(w), matching: find.text(w.label));
        final style = tester.widget<Text>(text.first).style!;
        expect(style.fontSize, greaterThanOrEqualTo(17), reason: w.label);
        expect(style.fontWeight!.value, greaterThanOrEqualTo(FontWeight.w700.value), reason: w.label);
        if (w.label.contains('지우기')) expect(w.kind, ButtonKind.danger, reason: '${w.label}은 빨강 버튼');
      }
      // 누를 수 있는 아이콘도 48 이상
      for (final e in find.byType(IconButton).evaluate()) {
        final size = (e.renderObject as RenderBox).size;
        expect(size.shortestSide, greaterThanOrEqualTo(AppSize.minTouch));
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('글씨 크기 설정이 화면에 즉시 적용된다', (tester) async {
    await setScreen(tester, const Size(800, 1200));
    final c = (await tester.runAsync(() => readyController()))!;
    await tester.pumpWidget(appWith(c, home: const HomeScreen()));
    await tester.pump();
    final ctx = tester.element(find.byType(HomeScreen));
    expect(MediaQuery.textScalerOf(ctx).scale(10), 10);
    c.updateSettings((s) => s.fontSize = FontSize.xlarge);
    await tester.pump();
    expect(MediaQuery.textScalerOf(tester.element(find.byType(HomeScreen))).scale(10), 15);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('가장 먼저 눈에 띄는 것이 가장 중요한 것인가: 홈 검색창이 맨 위·가장 크게', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final c = (await tester.runAsync(() => readyController()))!;
    await tester.pumpWidget(appWith(c, home: const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 300));
    final search = tester.getRect(find.byType(TextField).first);
    final today = tester.getRect(find.text('오늘 할 일'));
    final firstTile = tester.getRect(find.byType(ConversationTile).first);
    expect(search.height, greaterThanOrEqualTo(64), reason: '검색창 높이 64 이상');
    expect(search.width, greaterThan(390 * 0.7), reason: '검색창은 화면 폭 거의 전체');
    expect(search.top, lessThan(today.top), reason: '검색창이 오늘 할 일보다 위');
    expect(today.top, lessThan(firstTile.top), reason: '오늘 할 일이 최근 대화보다 위');
    await tester.pumpWidget(const SizedBox());
  });
}
