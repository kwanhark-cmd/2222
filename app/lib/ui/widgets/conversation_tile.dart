import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import 'common.dart';
import 'dialogs.dart';

final dateText = DateFormat('yyyy년 M월 d일');
final dateTimeText = DateFormat('yyyy년 M월 d일 HH:mm');

/// 긴 목록용 가벼운 평면 카드(그림자 없음 → 스크롤이 끊기지 않게).
class ConversationTile extends StatelessWidget {
  final ConversationSummary c;
  final String? snippet;
  final List<String> highlight;
  final VoidCallback onOpen;
  final Widget? leading;

  const ConversationTile({super.key, required this.c, required this.onOpen, this.snippet, this.highlight = const [], this.leading});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context).palette;
    final tt = Theme.of(context).textTheme;
    final controller = context.read<AppController>();
    final preview = snippet ?? c.summary;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppSize.radius),
        border: Border.all(color: p.border, width: p.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onOpen,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: SourceBadge.colorOf(p, c.source)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSize.gapM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ?leading,
                            SourceBadge(c.source, small: true),
                            Text(dateText.format(c.createdAt), style: tt.bodySmall),
                            if (c.starred) Image.asset(AppIcons3d.star, width: 22, height: 22, semanticLabel: '별표'),
                            if (c.hasAttachments)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.attach_file_rounded, size: 18, color: p.textMuted),
                                  Text('첨부', style: tt.bodySmall),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        HighlightText(c.title, words: highlight, style: tt.titleMedium, maxLines: 2),
                        if (preview != null && preview.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          HighlightText(
                            preview,
                            words: highlight,
                            style: tt.bodyMedium!.copyWith(color: p.textMuted),
                            maxLines: 3,
                          ),
                        ],
                        const SizedBox(height: AppSize.gapS),
                        Wrap(
                          spacing: AppSize.gapS,
                          runSpacing: AppSize.gapS,
                          children: [
                            BigButton(
                              label: '전체 보기',
                              icon: Icons.article_rounded,
                              expand: false,
                              kind: ButtonKind.primary,
                              onPressed: onOpen,
                            ),
                            if (preview != null && preview.isNotEmpty)
                              BigButton(
                                label: '읽어주기',
                                image: AppIcons3d.speaker,
                                expand: false,
                                kind: ButtonKind.quiet,
                                onPressed: () => readAloud(context, controller, '${c.title}. $preview'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> readAloud(BuildContext context, AppController c, String text) async {
  if (!c.settings.ttsEnabled) {
    showNotice(context, '읽어주기가 꺼져 있어요. 설정 > 음성에서 켤 수 있어요.', kind: StatusKind.check);
    return;
  }
  if (!c.voice.canSpeak) {
    showNotice(context, '이 기기에서는 읽어주기를 쓸 수 없어요.', kind: StatusKind.check);
    return;
  }
  await c.voice.stopSpeaking();
  await c.voice.speak(text, rate: c.settings.ttsRate);
}
