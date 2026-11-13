import 'package:flutter/material.dart';

/// 앱 디자인 값은 모두 이 파일에만 둡니다. 여기 값을 바꾸면 모든 화면이 함께 바뀝니다.

/// 크기·간격·둥글기
class AppSize {
  static const buttonHeight = 56.0; // 모든 버튼 최소 높이(52 이상 규칙)
  static const minTouch = 48.0; // 누를 수 있는 곳 최소 크기
  static const outlineWidth = 2.0; // 테두리 버튼 테두리 두께(고대비는 3)
  static const focusRing = 3.0; // 키보드로 고른 버튼 둘레 고리 두께
  static const radius = 16.0;
  static const radiusCard = 20.0;
  static const radiusSmall = 12.0;
  static const gapXs = 4.0;
  static const gapS = 8.0;
  static const gapM = 12.0;
  static const cardGap = 18.0; // 카드 사이 간격(기본의 1.5배)
  static const gapL = 16.0;
  static const gapXl = 24.0;
  static const gapXxl = 32.0;
  static const pagePadding = 16.0;
  static const maxContentWidth = 760.0;
  static const depth = 6.0; // 입체 버튼의 두께
  static const iconTile = 64.0;
  static const iconButton = 28.0;

  // 글씨 기본 크기(글씨 크기 설정으로 배율이 곱해짐)
  static const textBody = 17.0;
  static const textSmall = 16.0; // 설명 글자도 16 이상
  static const textTitle = 21.0;
  static const textHeadline = 26.0;
  static const textDisplay = 34.0; // 큰 숫자(토스처럼 크게)
  static const searchHeight = 68.0; // 홈 검색창 높이
  static const textButton = 18.0; // 버튼 글자(17 이상, 굵게)
}

/// 움직임 시간
class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const page = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 400);
  static const stagger = Duration(milliseconds: 40);
  static const curve = Curves.easeOutCubic;
  static const bounce = Curves.easeOutBack;
}

/// 색 묶음(밝게·어둡게·고대비).
@immutable
class AppPalette {
  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color primaryText; // 배경 위에 쓰는 주요색 글자
  final Color accent;
  final Color onAccent;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color onSuccess;
  final Color info;
  final Color onInfo;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color shadow;
  final Color highlight; // 검색어 강조 배경
  final Color claude;
  final Color chatgpt;
  final Color gemini;
  final double borderWidth;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.accent,
    required this.onAccent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.onSuccess,
    required this.info,
    required this.onInfo,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.shadow,
    required this.highlight,
    required this.claude,
    required this.chatgpt,
    required this.gemini,
    this.borderWidth = 1,
  });

  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF2A4299),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF2A4299),
    accent: Color(0xFF8A2F08),
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFFECF0F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE2E8F4),
    text: Color(0xFF1A1D24),
    textMuted: Color(0xFF3A4152),
    border: Color(0xFF79829A),
    success: Color(0xFF145A26),
    onSuccess: Color(0xFFFFFFFF),
    info: Color(0xFF194C99),
    onInfo: Color(0xFFFFFFFF),
    warning: Color(0xFFF2C230),
    onWarning: Color(0xFF1A1D24),
    danger: Color(0xFF9C1A1A),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x33233066),
    highlight: Color(0xFFFFE58A),
    claude: Color(0xFF9A3309),
    chatgpt: Color(0xFF0A5C47),
    gemini: Color(0xFF2346A6),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF2C44AE),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFFB5C3FF),
    accent: Color(0xFF8A2F08),
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFF0E1116),
    surface: Color(0xFF1F242D),
    surfaceAlt: Color(0xFF2C323E),
    text: Color(0xFFF1F3F8),
    textMuted: Color(0xFFC3C9D7),
    border: Color(0xFF79819A),
    success: Color(0xFF145A26),
    onSuccess: Color(0xFFFFFFFF),
    info: Color(0xFF194C99),
    onInfo: Color(0xFFFFFFFF),
    warning: Color(0xFFF2C230),
    onWarning: Color(0xFF1A1D24),
    danger: Color(0xFF9C1A1A),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x99000000),
    highlight: Color(0xFF574500),
    claude: Color(0xFF9A3309),
    chatgpt: Color(0xFF0A5C47),
    gemini: Color(0xFF2346A6),
  );

  static const highContrastLight = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF0A2A8C),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF0A2A8C),
    accent: Color(0xFF8A2A00),
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEDEDED),
    text: Color(0xFF000000),
    textMuted: Color(0xFF1F1F1F),
    border: Color(0xFF000000),
    success: Color(0xFF0D5A25),
    onSuccess: Color(0xFFFFFFFF),
    info: Color(0xFF0A3F94),
    onInfo: Color(0xFFFFFFFF),
    warning: Color(0xFFFFD000),
    onWarning: Color(0xFF000000),
    danger: Color(0xFF9E0000),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x66000000),
    highlight: Color(0xFFFFE600),
    claude: Color(0xFF6E3214),
    chatgpt: Color(0xFF064A39),
    gemini: Color(0xFF173C9E),
    borderWidth: 2,
  );

  static const highContrastDark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF1F3BBF),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFFFFE600),
    accent: Color(0xFF8A2A00),
    onAccent: Color(0xFFFFFFFF),
    background: Color(0xFF000000),
    surface: Color(0xFF000000),
    surfaceAlt: Color(0xFF1A1A1A),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFEDEDED),
    border: Color(0xFFFFFFFF),
    success: Color(0xFF0D5A25),
    onSuccess: Color(0xFFFFFFFF),
    info: Color(0xFF0A3F94),
    onInfo: Color(0xFFFFFFFF),
    warning: Color(0xFFFFD000),
    onWarning: Color(0xFF000000),
    danger: Color(0xFF9E0000),
    onDanger: Color(0xFFFFFFFF),
    shadow: Color(0x00000000),
    highlight: Color(0xFF574800),
    claude: Color(0xFF6E3214),
    chatgpt: Color(0xFF064A39),
    gemini: Color(0xFF173C9E),
    borderWidth: 2,
  );

  static AppPalette pick({required bool isDark, required bool highContrast}) =>
      highContrast ? (isDark ? highContrastDark : highContrastLight) : (isDark ? dark : light);

  AppPalette copyWithPrimary({required Color primary, required Color primaryText}) => AppPalette(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    primaryText: primaryText,
    accent: accent,
    onAccent: onAccent,
    background: background,
    surface: surface,
    surfaceAlt: surfaceAlt,
    text: text,
    textMuted: textMuted,
    border: border,
    success: success,
    onSuccess: onSuccess,
    info: info,
    onInfo: onInfo,
    warning: warning,
    onWarning: onWarning,
    danger: danger,
    onDanger: onDanger,
    shadow: shadow,
    highlight: highlight,
    claude: claude,
    chatgpt: chatgpt,
    gemini: gemini,
    borderWidth: borderWidth,
  );

  /// 테두리 버튼의 테두리 두께(보통 2, 고대비 3).
  double get outlineWidth => borderWidth > 1 ? 3 : AppSize.outlineWidth;

  /// 키보드로 고른 버튼 둘레 고리 색(배경과 대비 7:1 이상인 본문색).
  Color get focusRing => text;

  /// 버튼 종류별 색(평소·눌렀을 때). 모든 버튼 글자는 배경과 7:1 이상.
  ButtonColors button(ButtonKind kind) {
    if (kind == ButtonKind.quiet) {
      // 테두리 버튼: 카드색 바탕 + 주요색 글자·두꺼운 테두리. 누르면 주요색으로 꽉 차요.
      return ButtonColors(bg: surface, fg: primaryText, pressedBg: primary, pressedFg: onPrimary, border: primaryText);
    }
    final (bg, fg) = switch (kind) {
      ButtonKind.primary => (primary, onPrimary),
      ButtonKind.accent => (accent, onAccent),
      ButtonKind.danger => (danger, onDanger),
      ButtonKind.success => (success, onSuccess),
      ButtonKind.info => (info, onInfo),
      ButtonKind.quiet => (surface, primaryText),
    };
    return ButtonColors(bg: bg, fg: fg, pressedBg: ButtonColors.pressedFill(bg, fg), pressedFg: fg);
  }

  /// (글자색, 배경색, 이름) — 대비 검사용(7:1 이상)
  List<(Color, Color, String)> get contrastPairs => [
    for (final k in ButtonKind.values) ...[
      (button(k).fg, button(k).bg, '버튼 ${k.name}'),
      (button(k).fg, ButtonColors.raisedTop(button(k).bg), '버튼 ${k.name} 윗부분'),
      (button(k).pressedFg, button(k).pressedBg, '버튼 ${k.name} 누름'),
    ],
    (textMuted, surfaceAlt, '흐린글자/보조카드'),
    (primaryText, surfaceAlt, '주요색 글자/보조카드'),
    (text, background, '본문/배경'),
    (text, surface, '본문/카드'),
    (text, surfaceAlt, '본문/보조카드'),
    (textMuted, surface, '흐린글자/카드'),
    (textMuted, background, '흐린글자/배경'),
    (primaryText, surface, '주요색 글자/카드'),
    (primaryText, background, '주요색 글자/배경'),
    (onPrimary, primary, '주요 버튼'),
    (onAccent, accent, '강조 버튼'),
    (onSuccess, success, '완료'),
    (onInfo, info, '진행 중'),
    (onWarning, warning, '확인 필요'),
    (onDanger, danger, '문제·위험'),
    (const Color(0xFFFFFFFF), claude, '클로드 배지'),
    (const Color(0xFFFFFFFF), chatgpt, '챗GPT 배지'),
    (const Color(0xFFFFFFFF), gemini, '제미나이 배지'),
    (text, highlight, '검색어 강조'),
  ];
}

/// 버튼 종류: 주요(파랑)·강조(주황)·위험(빨강)·완료(초록)·안내(파랑)·테두리(quiet).
enum ButtonKind { primary, accent, danger, success, info, quiet }

/// 버튼 한 종류의 색.
@immutable
class ButtonColors {
  final Color bg;
  final Color fg;
  final Color pressedBg;
  final Color pressedFg;
  final Color? border;
  const ButtonColors({required this.bg, required this.fg, required this.pressedBg, required this.pressedFg, this.border});

  /// 눌렀을 때 배경: 글자색에서 더 멀어지는 쪽으로(대비가 오히려 커짐).
  static Color pressedFill(Color bg, Color fg) =>
      fg.computeLuminance() > bg.computeLuminance() ? Color.lerp(bg, Colors.black, 0.28)! : Color.lerp(bg, Colors.white, 0.4)!;

  /// 입체 버튼 윗부분(살짝 밝게). 글자 대비가 떨어지지 않을 만큼만.
  static Color raisedTop(Color base) => Color.lerp(base, Colors.white, 0.05)!;
}

/// 상태 4가지: 초록=완료, 파랑=진행 중, 노랑=확인 필요, 빨강=문제
enum StatusKind { done, progress, check, problem }

extension StatusColors on AppPalette {
  (Color bg, Color fg, IconData icon) status(StatusKind k) => switch (k) {
    StatusKind.done => (success, onSuccess, Icons.check_circle_rounded),
    StatusKind.progress => (info, onInfo, Icons.autorenew_rounded),
    StatusKind.check => (warning, onWarning, Icons.error_outline_rounded),
    StatusKind.problem => (danger, onDanger, Icons.report_rounded),
  };
}

/// 입체감용 그림자(메인 타일·주요 버튼에만 사용).
class AppShadows {
  static List<BoxShadow> raised(AppPalette p, {bool pressed = false}) => [
    BoxShadow(color: p.shadow, offset: Offset(0, pressed ? 2 : AppSize.depth), blurRadius: pressed ? 4 : 14),
  ];

  static List<BoxShadow> soft(AppPalette p) => [
    BoxShadow(
      color: p.shadow.withValues(alpha: p.shadow.a * 0.5),
      offset: const Offset(0, 2),
      blurRadius: 6,
    ),
  ];
}

/// 3D 그림 자산 위치(교체하려면 같은 이름으로 파일만 바꾸면 됨).
class AppIcons3d {
  static const _base = 'assets/icons3d';
  static const search = '$_base/search.png';
  static const inbox = '$_base/inbox.png';
  static const folder = '$_base/folder.png';
  static const calendar = '$_base/calendar.png';
  static const memo = '$_base/memo.png';
  static const gear = '$_base/gear.png';
  static const mic = '$_base/mic.png';
  static const speaker = '$_base/speaker.png';
  static const star = '$_base/star.png';
  static const sparkles = '$_base/sparkles.png';
  static const check = '$_base/check.png';
  static const warning = '$_base/warning.png';
  static const bell = '$_base/bell.png';
  static const bulb = '$_base/bulb.png';
  static const wave = '$_base/wave.png';
  static const package = '$_base/package.png';
  static const lock = '$_base/lock.png';
  static const robot = '$_base/robot.png';
  static const envelope = '$_base/envelope.png';
  static const books = '$_base/books.png';
  static const speech = '$_base/speech.png';
  static const people = '$_base/people.png';
  static const party = '$_base/trophy.png';

  static const all = [
    search,
    inbox,
    folder,
    calendar,
    memo,
    gear,
    mic,
    speaker,
    star,
    sparkles,
    check,
    warning,
    bell,
    bulb,
    wave,
    package,
    lock,
    robot,
    envelope,
    books,
    speech,
    people,
    party,
  ];
}

/// 주제마다 다른 색(중간 채도). 점·타일·대화 카드 왼쪽 띠에 씁니다.
class TopicColors {
  static const all = [
    Color(0xFF3B82C4), // 파랑
    Color(0xFF2E9E6B), // 초록
    Color(0xFFD9822B), // 주황
    Color(0xFF8E5CC4), // 보라
    Color(0xFFD0516E), // 장미
    Color(0xFF1F9AA6), // 청록
    Color(0xFFB59A1E), // 겨자
    Color(0xFF5C6BC0), // 남색
    Color(0xFF7A8F3A), // 올리브
    Color(0xFFC0604A), // 벽돌
  ];

  static Color of(int topicId) => all[topicId.abs() % all.length];
}

/// 사용자가 고르는 색 테마(주요색만 바뀜, 글자 대비는 모두 7:1 이상).
class ColorThemes {
  static const names = {'blue': '파랑', 'green': '초록', 'purple': '보라', 'teal': '청록', 'rose': '장미'};

  /// (밝게 버튼색, 어둡게 버튼색, 어둡게 글자색)
  static const _colors = {
    'blue': (Color(0xFF2A4299), Color(0xFF2C44AE), Color(0xFFB5C3FF)),
    'green': (Color(0xFF145529), Color(0xFF145529), Color(0xFF8FD9A8)),
    'purple': (Color(0xFF5A2FA0), Color(0xFF6234AD), Color(0xFFCDB5FF)),
    'teal': (Color(0xFF09515A), Color(0xFF09515A), Color(0xFF8ADBE3)),
    'rose': (Color(0xFF82224A), Color(0xFF82224A), Color(0xFFFFB0CB)),
  };

  static Color sample(String name) => (_colors[name] ?? _colors['blue']!).$1;

  static AppPalette apply(AppPalette base, String name) {
    final c = _colors[name];
    if (c == null || name == 'blue' || base.borderWidth > 1) return base; // 고대비는 그대로
    final dark = base.brightness == Brightness.dark;
    return base.copyWithPrimary(primary: dark ? c.$2 : c.$1, primaryText: dark ? c.$3 : c.$1);
  }
}
