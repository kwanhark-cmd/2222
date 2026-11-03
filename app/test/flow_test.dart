import 'dart:typed_data';

import 'package:ai_chat_organizer/ui/screens/conversation_screen.dart';
import 'package:ai_chat_organizer/ui/screens/home_screen.dart';
import 'package:ai_chat_organizer/ui/widgets/conversation_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

Future<void> settle(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text).first;
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await settle(tester);
}

void main() {
  testWidgets('흐름: 첫 안내 → 샘플 넣기 → 목록 → 검색 → 음성 검색 → 분류 → 타임라인 → 요약', (tester) async {
    await setScreen(tester, const Size(900, 1600));
    final voice = FakeVoice();
    final c = makeController(voice: voice);
    await tester.runAsync(c.init);
    await tester.pumpWidget(appWith(c));
    await settle(tester);

    // 첫 안내 마법사
    expect(find.text('반가워요!'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '할머니');
    await tapText(tester, '다음');
    expect(find.text('글씨 크기를 골라 주세요'), findsOneWidget);
    await tapText(tester, '가나다 — 크게');
    expect(c.settings.fontSize.name, 'large');
    await tapText(tester, '다음');
    expect(find.text('허락이 필요한 것'), findsOneWidget);
    await tapText(tester, '다음');
    expect(find.text('대화 기록 받는 법'), findsOneWidget);
    await tapText(tester, '다음');
    await tapText(tester, '샘플로 체험하기');
    await settle(tester, rounds: 20);

    // 홈: 샘플 10개
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.textContaining('모두 10개 대화'), findsOneWidget);
    c.updateSettings((s) => s.seenTips.addAll(['search', 'topics', 'decisions', 'conversation-voice']));
    await settle(tester);

    // 목록
    await tapText(tester, '대화 찾기');
    expect(find.text('모든 대화'), findsOneWidget);
    expect(find.byType(ConversationTile), findsWidgets);

    // 글자 검색
    await tester.enterText(find.byType(TextField).first, '일출봉');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.textContaining('찾은 대화 1개'), findsOneWidget);

    // 음성 검색
    voice.nextPhrase = '지난달에 유튜브 앱 얘기한 대화 찾아줘';
    await tester.tap(find.bySemanticsLabel('말로 하기').first);
    await settle(tester);
    expect(find.textContaining('기간: 지난달'), findsOneWidget);
    expect(find.textContaining('낱말: 유튜브, 앱'), findsOneWidget);

    // 대화 열기 → 요약 표시, 읽어주기
    await tapText(tester, '전체 보기');
    expect(find.byType(ConversationScreen), findsOneWidget);
    expect(find.textContaining('요약:'), findsOneWidget);
    await tapText(tester, '읽어주기');
    expect(voice.spoken, isNotEmpty);

    // 음성 명령: 주제 옮기기 + 메모
    final tf = find.byType(TextField).first;
    await tester.ensureVisible(tf);
    await tester.enterText(tf, '이 대화를 앱 만들기 주제로 옮겨');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.textContaining('"앱 만들기" 주제로 옮겼어요'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '메모 다음 주에 다시 보기');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.textContaining('다음 주에 다시 보기'), findsWidgets);

    // 홈으로 → 주제별 보기(분류됨)
    await tester.tap(find.bySemanticsLabel('홈').first);
    await settle(tester);
    await tapText(tester, '주제별 보기');
    expect(find.text('유튜브·영상'), findsOneWidget);
    expect(find.text('투자·재테크'), findsOneWidget);

    // 무료 다시 정리하기
    await tapText(tester, '다시 정리하기');
    await tapText(tester, '무료로 정리하기(낱말 기준, 인터넷 필요 없음)');
    await settle(tester, rounds: 12);
    expect(find.textContaining('대화를 정리했어요'), findsOneWidget);

    // 주제 안 → 정한 내용(요약)
    await tapText(tester, '투자·재테크');
    await tapText(tester, '정한 내용 보기');
    await settle(tester);
    expect(find.textContaining('원칙이 수익을 만든다'), findsWidgets);

    // 타임라인
    await tester.tap(find.bySemanticsLabel('홈').first);
    await settle(tester);
    await tapText(tester, '날짜별 보기');
    expect(find.textContaining('2026년 11월'), findsWidgets);
    await tapText(tester, '이전 달');
    expect(find.textContaining('2026년 10월 · 대화'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('읽을 수 없는 파일은 안내와 문제 신고 버튼을 보여준다', (tester) async {
    await setScreen(tester, const Size(900, 1600));
    final c = (await tester.runAsync(() => readyController()))!;
    await tester.pumpWidget(appWith(c));
    await settle(tester);
    await tapText(tester, '대화 넣기');
    await tester.runAsync(() => c.importBytes('이상한파일.json', Uint8List.fromList('{"x":1}'.codeUnits)));
    await settle(tester);
    expect(find.textContaining('이 파일은 읽을 수 없어요'), findsOneWidget);
    expect(find.text('문제 신고'), findsOneWidget);
    expect(find.text('어느 AI 파일인지 알려 주기'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
