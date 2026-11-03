import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/page.dart';
import '../widgets/voice_input.dart';
import 'decisions_screen.dart';
import 'export_guide_screen.dart';
import 'import_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';
import 'topics_screen.dart';

void go(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final s = c.session!;
    final p = AppTheme.of(context).palette;
    final tt = Theme.of(context).textTheme;
    final counts = s.store.countBySource();
    final total = counts.values.fold(0, (a, b) => a + b);
    final due = s.settings.exportDue(DateTime.now());

    final tiles = <Widget>[
      HomeTile(
        image: AppIcons3d.search,
        title: '대화 찾기',
        subtitle: '세 AI 대화를 한 번에 검색',
        color: p.primary,
        onTap: () => go(context, const SearchScreen()),
      ),
      HomeTile(
        image: AppIcons3d.inbox,
        title: '대화 넣기',
        subtitle: '내보내기 파일을 넣어요',
        color: p.accent,
        onTap: () => go(context, const ImportScreen()),
      ),
      HomeTile(
        image: AppIcons3d.folder,
        title: '주제별 보기',
        subtitle: '폴더처럼 주제로 정리',
        color: p.success,
        onTap: () => go(context, const TopicsScreen()),
      ),
      HomeTile(
        image: AppIcons3d.calendar,
        title: '날짜별 보기',
        subtitle: '언제 어떤 이야기를 했는지',
        color: p.info,
        onTap: () => go(context, const TimelineScreen()),
      ),
      HomeTile(
        image: AppIcons3d.memo,
        title: '정한 내용',
        subtitle: '주제별로 지금까지 정한 것',
        color: p.warning,
        onTap: () => go(context, const DecisionsScreen()),
      ),
      HomeTile(
        image: AppIcons3d.gear,
        title: '설정',
        subtitle: '글씨 크기, AI 연결, 백업',
        color: p.textMuted,
        onTap: () => go(context, const SettingsScreen()),
      ),
    ];

    return AppPage(
      title: 'AI 대화 기록 정리 비서',
      isHome: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Mascot(MascotMood.hello, size: 72),
              const SizedBox(width: AppSize.gapM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s.user.name}님, 안녕하세요!', style: tt.titleLarge),
                    Text(
                      total == 0
                          ? '아직 넣은 대화가 없어요'
                          : '모두 $total개 대화 · ${AiSource.values.map((a) => '${a.label} ${counts[a] ?? 0}').join(' · ')}',
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSize.gapL),
          _TodayCard(total: total, due: due),
          const SizedBox(height: AppSize.gapL),
          if (total > 0) ...[
            VoiceTextField(
              hint: '무엇을 찾을까요? 예: 지난달 유튜브 앱',
              onSubmit: (t) => go(context, SearchScreen(initialQuery: t)),
            ),
            const SizedBox(height: AppSize.gapL),
          ],
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth > 620 ? 2 : 1;
              final rows = <Widget>[];
              for (var i = 0; i < tiles.length; i += cols) {
                rows.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSize.gapM),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var j = i; j < i + cols && j < tiles.length; j++) ...[
                            if (j > i) const SizedBox(width: AppSize.gapM),
                            Expanded(
                              child: AppearUp(index: j, child: tiles[j]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Column(children: rows);
            },
          ),
        ],
      ),
    );
  }
}

/// "오늘 할 일" 카드: 지금 눌러야 할 것 하나만 크게.
class _TodayCard extends StatelessWidget {
  final int total;
  final List<AiSource> due;
  const _TodayCard({required this.total, required this.due});

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context).palette;
    final tt = Theme.of(context).textTheme;
    final (String title, String text, String button, String image, VoidCallback onTap, bool wiggle) = switch ((total, due.isNotEmpty)) {
      (0, _) => (
        '오늘 할 일',
        '먼저 AI 대화 기록 파일을 넣어 주세요. 샘플로 체험할 수도 있어요.',
        '대화 기록 넣기',
        AppIcons3d.inbox,
        () => go(context, const ImportScreen()),
        false,
      ),
      (_, true) => (
        '오늘 할 일',
        '${due.map((d) => d.label).join(', ')} 대화 기록 내보내기를 요청할 때가 됐어요.',
        '내보내기 요청하러 가기',
        AppIcons3d.bell,
        () => go(context, const ExportGuideScreen()),
        true,
      ),
      _ => ('오늘 할 일', '궁금한 대화를 찾아보세요. 말로 물어봐도 돼요.', '대화 찾기', AppIcons3d.search, () => go(context, const SearchScreen()), false),
    };
    final card = Container(
      padding: const EdgeInsets.all(AppSize.gapL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.primary, Color.lerp(p.primary, Colors.black, 0.25)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSize.radiusCard),
        boxShadow: AppShadows.raised(p),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(image, width: 48, height: 48, excludeFromSemantics: true),
              const SizedBox(width: AppSize.gapM),
              Expanded(
                child: Text(title, style: tt.titleLarge!.copyWith(color: p.onPrimary)),
              ),
            ],
          ),
          const SizedBox(height: AppSize.gapS),
          Text(text, style: tt.bodyLarge!.copyWith(color: p.onPrimary)),
          const SizedBox(height: AppSize.gapM),
          BigButton(label: button, onPressed: onTap, kind: ButtonKind.accent, icon: Icons.arrow_forward_rounded),
        ],
      ),
    );
    return Semantics(container: true, child: wiggle ? Wiggle(child: card) : card);
  }
}
