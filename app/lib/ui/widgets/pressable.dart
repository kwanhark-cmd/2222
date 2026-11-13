import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

/// 누르면 살짝 눌리고 튀어오르는 입체 표면. 진동·소리 피드백(설정에서 켜고 끔).
/// 누르는 동안 색이 바뀌고, 키보드로 고르면 둘레에 진한 고리가 생겨요.
class Pressable extends StatefulWidget {
  final Widget? child;

  /// 누름 상태에 따라 내용(글자색 등)을 바꿀 때. 있으면 [child] 대신 씀.
  final Widget Function(BuildContext context, bool pressed)? builder;

  /// 누르는 동안 배경색(없으면 조금 진하게).
  final Color? pressedColor;
  final VoidCallback? onTap;
  final Color color;
  final BorderRadius borderRadius;
  final bool raised;
  final String? semanticLabel;
  final Gradient? gradient;
  final BorderSide? border;

  const Pressable({
    super.key,
    this.child,
    required this.onTap,
    required this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppSize.radius)),
    this.raised = true,
    this.semanticLabel,
    this.gradient,
    this.border,
    this.builder,
    this.pressedColor,
  }) : assert(child != null || builder != null);

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _focused = false;

  void feedback(BuildContext context) {
    final s = context.read<AppController?>()?.settings;
    if (s == null || s.haptics) HapticFeedback.lightImpact();
    if (s == null || s.sounds) SystemSound.play(SystemSoundType.click);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final p = theme.palette;
    final enabled = widget.onTap != null;
    final dur = theme.motion(context, AppMotion.fast);
    final normal = enabled ? widget.color : Color.lerp(widget.color, p.surfaceAlt, 0.55)!;
    final pressedColor =
        widget.pressedColor ??
        (widget.color.computeLuminance() < 0.2
            ? Color.lerp(widget.color, Colors.white, 0.12)!
            : Color.lerp(widget.color, Colors.black, 0.08)!);
    final base = _down && enabled ? pressedColor : normal;
    final top = ButtonColors.raisedTop(base);
    final shadows = <BoxShadow>[
      if (widget.raised && enabled) ...AppShadows.raised(p, pressed: _down),
      // 키보드 초점 고리: 바깥 진한 고리 + 안쪽 배경색 틈(어떤 버튼색 위에서도 보이게)
      if (_focused && enabled) ...[
        BoxShadow(color: p.focusRing, spreadRadius: AppSize.focusRing + 2),
        BoxShadow(color: p.background, spreadRadius: 2),
      ],
    ];
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                feedback(context);
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1.0,
          duration: dur,
          curve: _down ? Curves.easeOut : AppMotion.bounce,
          child: AnimatedContainer(
            duration: dur,
            transform: Matrix4.translationValues(0, _down && widget.raised ? AppSize.depth - 2 : 0, 0),
            decoration: BoxDecoration(
              color: base,
              gradient:
                  widget.gradient ??
                  (widget.raised ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, base]) : null),
              borderRadius: widget.borderRadius,
              border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
              boxShadow: shadows.isEmpty ? null : shadows,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: FocusableActionDetector(
                enabled: enabled,
                mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                onShowFocusHighlight: (v) => setState(() => _focused = v),
                actions: {
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (_) {
                      widget.onTap?.call();
                      return null;
                    },
                  ),
                },
                child: widget.builder?.call(context, _down && enabled) ?? widget.child!,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
