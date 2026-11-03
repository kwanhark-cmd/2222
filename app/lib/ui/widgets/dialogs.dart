import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import 'common.dart';

/// 짧은 안내 띠(상태 색 + 아이콘). 되돌리기 버튼을 붙일 수 있음.
void showNotice(BuildContext context, String text, {StatusKind kind = StatusKind.done, String? undoLabel, VoidCallback? onUndo}) {
  final (bg, fg, icon) = AppTheme.of(context).palette.status(kind);
  final m = ScaffoldMessenger.maybeOf(context);
  m?.hideCurrentSnackBar();
  m?.showSnackBar(
    SnackBar(
      backgroundColor: bg,
      duration: Duration(seconds: onUndo != null ? 6 : 3),
      content: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: fg, fontSize: AppSize.textBody, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      action: onUndo == null
          ? null
          : SnackBarAction(label: undoLabel ?? '되돌리기', textColor: fg, backgroundColor: Colors.black26, onPressed: onUndo),
    ),
  );
}

class _DialogShell extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> buttons;
  final MascotMood? mood;
  const _DialogShell({required this.title, required this.body, required this.buttons, this.mood});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSize.gapXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mood != null) Center(child: Mascot(mood!, size: 80)),
              if (mood != null) const SizedBox(height: AppSize.gapM),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSize.gapM),
              body,
              const SizedBox(height: AppSize.gapXl),
              for (var i = 0; i < buttons.length; i++) ...[if (i > 0) const SizedBox(height: AppSize.gapM), buttons[i]],
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmOnce(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => _DialogShell(
      title: title,
      mood: danger ? MascotMood.warning : null,
      body: Text(message),
      buttons: [
        BigButton(label: confirmLabel, onPressed: () => Navigator.pop(ctx, true), kind: danger ? ButtonKind.danger : ButtonKind.accent),
        BigButton(label: '아니요, 그만둘게요', onPressed: () => Navigator.pop(ctx, false), kind: ButtonKind.primary),
      ],
    ),
  );
  return r == true;
}

/// 위험한 동작(지우기·초기화·합치기)은 두 번 확인합니다.
Future<bool> confirmTwice(BuildContext context, {required String title, required String message, required String confirmLabel}) async {
  if (!await confirmOnce(context, title: title, message: message, confirmLabel: '네, 계속할게요', danger: true)) return false;
  if (!context.mounted) return false;
  return confirmOnce(context, title: '한 번 더 확인할게요', message: '$message\n\n정말 $confirmLabel?', confirmLabel: confirmLabel, danger: true);
}

Future<String?> askText(
  BuildContext context, {
  required String title,
  String? message,
  String? initial,
  String hint = '',
  String confirmLabel = '확인',
  bool obscure = false,
  TextInputType? keyboard,
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => _DialogShell(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null) ...[Text(message), const SizedBox(height: AppSize.gapM)],
          TextField(
            controller: ctrl,
            autofocus: true,
            obscureText: obscure,
            keyboardType: keyboard,
            decoration: InputDecoration(hintText: hint),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
        ],
      ),
      buttons: [
        BigButton(label: confirmLabel, onPressed: () => Navigator.pop(ctx, ctrl.text), kind: ButtonKind.accent),
        BigButton(label: '그만두기', onPressed: () => Navigator.pop(ctx), kind: ButtonKind.primary),
      ],
    ),
  );
}

/// 여러 항목 중 하나 고르기(큰 버튼 목록).
Future<T?> pickOne<T>(BuildContext context, {required String title, String? message, required List<(T, String)> options}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => _DialogShell(
      title: title,
      body: message == null ? const SizedBox.shrink() : Text(message),
      buttons: [
        for (final (v, label) in options) BigButton(label: label, onPressed: () => Navigator.pop(ctx, v), kind: ButtonKind.primary),
        BigButton(label: '그만두기', onPressed: () => Navigator.pop(ctx), kind: ButtonKind.quiet),
      ],
    ),
  );
}

Future<void> showInfo(BuildContext context, {required String title, required String message, MascotMood mood = MascotMood.hello}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _DialogShell(
      title: title,
      mood: mood,
      body: Text(message),
      buttons: [BigButton(label: '알겠어요', onPressed: () => Navigator.pop(ctx), kind: ButtonKind.accent)],
    ),
  );
}
