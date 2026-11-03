import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_log.dart';
import '../../models/models.dart';
import '../../search/query_parser.dart';
import '../../search/search_service.dart';
import '../../services/app_controller.dart';
import '../../theme/tokens.dart';
import '../../voice/voice_command.dart';
import '../widgets/common.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/dialogs.dart';
import '../widgets/page.dart';
import '../widgets/voice_input.dart';
import 'conversation_screen.dart';
import 'import_screen.dart';

/// 검색창 하나로 세 AI 대화 전체를 찾습니다(빈칸이면 전체 목록).
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ctrl = TextEditingController();
  AiSource? source;
  bool starredOnly = false;
  String? tag;
  SearchQuery? query;
  final hits = <SearchHit>[];
  int cursor = 0;
  bool hasMore = false;
  bool loading = false;
  int seenRevision = -1;
  static const pageSize = 30;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) ctrl.text = widget.initialQuery!;
    WidgetsBinding.instance.addPostFrameCallback((_) => submit(ctrl.text, fromUser: widget.initialQuery != null));
  }

  AppController get c => context.read<AppController>();

  Future<void> submit(String text, {bool fromUser = true}) async {
    final cmd = VoiceCommandParser.parse(text);
    if (fromUser && text.isNotEmpty && cmd is! SearchCommand) {
      await _runCommand(cmd);
      return;
    }
    final s = c.settings;
    final q = QueryParser.parse(text, exact: s.exactMatch, similar: s.similarWords);
    await _load(q, reset: true);
  }

  Future<void> _runCommand(VoiceCommand cmd) async {
    switch (cmd) {
      case ClassifyRecentCommand(:final todayOnly):
        final ids = todayOnly ? c.todayImportedIds() : c.allIds();
        if (ids.isEmpty) {
          showNotice(context, todayOnly ? '오늘 가져온 대화가 없어요.' : '정리할 대화가 없어요.', kind: StatusKind.check);
          return;
        }
        showNotice(context, '${ids.length}개 대화를 정리할게요.', kind: StatusKind.progress);
        final j = await c.classify(ids, useAi: false);
        if (mounted && j != null) showNotice(context, j.message ?? '', kind: j.state == JobState.done ? StatusKind.done : StatusKind.check);
      case GoHomeCommand():
        Navigator.of(context).popUntil((r) => r.isFirst);
      case StopReadingCommand():
        await c.voice.stopSpeaking();
      case SearchCommand():
        break;
      default:
        showNotice(context, '이 명령은 대화를 연 다음 말해 주세요. 지금은 검색으로 찾아볼게요.', kind: StatusKind.check);
        final s = c.settings;
        await _load(QueryParser.parse(ctrl.text, exact: s.exactMatch, similar: s.similarWords), reset: true);
    }
  }

  SearchQuery _withFilters(SearchQuery q) => SearchQuery(
    keywords: q.keywords,
    from: q.from,
    to: q.to,
    source: source ?? q.source,
    exact: q.exact,
    similar: q.similar,
    dateLabel: q.dateLabel,
    raw: q.raw,
  );

  Future<void> _load(SearchQuery q, {required bool reset}) async {
    final session = c.session;
    if (session == null) return;
    setState(() {
      loading = true;
      if (reset) {
        query = q;
        hits.clear();
        cursor = 0;
      }
    });
    try {
      final fq = _withFilters(q);
      if (fq.keywords.isEmpty && (starredOnly || tag != null || fq.source != null || fq.from != null)) {
        // 낱말 없이 거르기만 할 때는 목록에서 바로
        final list = session.store.list(
          offset: cursor,
          limit: pageSize + 1,
          source: fq.source,
          starred: starredOnly ? true : null,
          tag: tag,
          from: fq.from,
          to: fq.to,
        );
        hits.addAll(
          list.take(pageSize).map((x) => SearchHit(conversation: x, snippet: x.summary ?? '', messageIndex: 0, highlight: const [])),
        );
        cursor += list.take(pageSize).length;
        hasMore = list.length > pageSize;
      } else {
        final page = await session.search.search(fq, cursor: cursor, limit: pageSize);
        var list = page.hits;
        if (starredOnly) list = list.where((h) => h.conversation.starred).toList();
        if (tag != null) {
          final tagged = session.store.list(tag: tag, limit: 100000).map((e) => e.id).toSet();
          list = list.where((h) => tagged.contains(h.conversation.id)).toList();
        }
        hits.addAll(list);
        cursor = page.nextCursor;
        hasMore = page.hasMore;
      }
    } catch (e, st) {
      AppLog.error('검색 실패', e, st);
      if (mounted) showNotice(context, '검색 중 문제가 생겼어요. 다른 낱말로 해 보세요.', kind: StatusKind.problem);
    }
    if (mounted) setState(() => loading = false);
  }

  void _refilter() {
    final q = query ?? const SearchQuery();
    _load(q, reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final ctl = context.watch<AppController>();
    final session = ctl.session;
    if (session == null) return const SizedBox.shrink();
    if (seenRevision != ctl.revision) {
      final first = seenRevision == -1;
      seenRevision = ctl.revision;
      if (!first) WidgetsBinding.instance.addPostFrameCallback((_) => _refilter());
    }
    final tt = Theme.of(context).textTheme;
    final s = ctl.settings;
    final total = session.store.count();
    final tags = session.store.allTags();
    final q = query;
    final words = q == null ? const <String>[] : session.search.highlightWords(q);
    return AppPage(
      title: '대화 찾기',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TipBubble(id: 'search', text: '"지난달 유튜브 앱"처럼 날짜와 낱말을 함께 말하거나 써도 돼요. 마이크를 누르면 말로 찾을 수 있어요.'),
          VoiceTextField(hint: '찾을 낱말이나 문장', controller: ctrl, onSubmit: (t) => submit(t)),
          const SizedBox(height: AppSize.gapM),
          Wrap(
            spacing: AppSize.gapS,
            runSpacing: AppSize.gapS,
            children: [
              FilterChip(
                label: const Text('정확히 일치'),
                selected: s.exactMatch,
                onSelected: (v) {
                  ctl.updateSettings((x) => x.exactMatch = v);
                  submit(ctrl.text, fromUser: false);
                },
              ),
              FilterChip(
                label: const Text('비슷한 말도 찾기'),
                selected: s.similarWords && !s.exactMatch,
                onSelected: s.exactMatch
                    ? null
                    : (v) {
                        ctl.updateSettings((x) => x.similarWords = v);
                        submit(ctrl.text, fromUser: false);
                      },
              ),
              FilterChip(
                avatar: Image.asset(AppIcons3d.star, width: 20, height: 20, excludeFromSemantics: true),
                label: const Text('별표만'),
                selected: starredOnly,
                onSelected: (v) {
                  setState(() => starredOnly = v);
                  _refilter();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSize.gapS),
          Wrap(
            spacing: AppSize.gapS,
            runSpacing: AppSize.gapS,
            children: [
              ChoiceChip(
                label: const Text('모든 AI'),
                selected: source == null,
                onSelected: (_) {
                  setState(() => source = null);
                  _refilter();
                },
              ),
              for (final a in AiSource.values)
                ChoiceChip(
                  label: Text(a.label),
                  selected: source == a,
                  onSelected: (_) {
                    setState(() => source = source == a ? null : a);
                    _refilter();
                  },
                ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: AppSize.gapS),
            Wrap(
              spacing: AppSize.gapS,
              runSpacing: AppSize.gapS,
              children: [
                for (final (t, n) in tags.take(12))
                  ChoiceChip(
                    label: Text('#$t ($n)'),
                    selected: tag == t,
                    onSelected: (_) {
                      setState(() => tag = tag == t ? null : t);
                      _refilter();
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSize.gapM),
          if (q != null && (q.dateLabel != null || q.source != null || q.keywords.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSize.gapS),
              child: Text(
                [
                  if (q.dateLabel != null) '기간: ${q.dateLabel}',
                  if (q.source != null) 'AI: ${q.source!.label}',
                  if (q.keywords.isNotEmpty) '낱말: ${q.keywords.join(', ')}',
                ].join(' · '),
                style: tt.bodySmall,
              ),
            ),
          if (total == 0)
            EmptyState(
              title: '아직 대화가 없어요',
              message: '이렇게 시작하세요: AI에서 받은 내보내기 파일을 넣으면 여기서 찾을 수 있어요.',
              actionLabel: '대화 넣기',
              onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ImportScreen())),
            )
          else if (!loading && hits.isEmpty)
            const EmptyState(mood: MascotMood.warning, title: '찾는 대화가 없어요', message: '다른 낱말로 해 보거나 "비슷한 말도 찾기"를 켜 보세요.')
          else ...[
            Text(q == null || q.isEmpty ? '모든 대화' : '찾은 대화 ${hits.length}${hasMore ? '개 이상' : '개'}', style: tt.titleMedium),
            const SizedBox(height: AppSize.gapS),
            for (final (i, h) in hits.indexed) ...[
              AppearUp(
                index: i % pageSize,
                child: ConversationTile(
                  c: h.conversation,
                  snippet: h.snippet.isEmpty ? null : h.snippet,
                  highlight: words,
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(id: h.conversation.id, highlight: words, focusMessage: h.messageIndex),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSize.gapM),
            ],
            if (loading)
              const Center(
                child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
              ),
            if (hasMore && !loading)
              BigButton(
                label: '더 보기',
                icon: Icons.expand_more_rounded,
                kind: ButtonKind.primary,
                onPressed: () => _load(query ?? const SearchQuery(), reset: false),
              ),
          ],
        ],
      ),
    );
  }
}
