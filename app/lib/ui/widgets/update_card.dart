import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/app_info.dart';
import '../../core/cancel_token.dart';
import '../../services/app_controller.dart';
import '../../services/update_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../screens/export_guide_screen.dart';
import 'backup_actions.dart';
import 'common.dart';
import 'dialogs.dart';

/// 설정 맨 위: 지금 버전 + 업데이트 확인 + 문제 신고.
class UpdateCard extends StatefulWidget {
  const UpdateCard({super.key});

  /// 안드로이드 새 버전 안내(백업이 언제나 첫 단계).
  static const androidSteps =
      '안드로이드는 새 버전을 기존 앱 위에 설치할 수 없어요. 기존 앱을 지우면 앱 안의 대화·주제·메모·설정도 함께 지워지니, 꼭 이 순서대로 해 주세요.\n\n'
      '1. 먼저 "백업 파일 만들기"를 눌러 백업 파일을 "다운로드" 폴더처럼 앱 밖에 저장해요.\n'
      '2. "내려받기 화면 열기"를 눌러 새 설치 파일을 받아요.\n'
      '3. 기존 앱을 지워요.\n'
      '4. 받은 새 파일을 눌러 설치해요.\n'
      '5. 새 앱을 열고 첫 안내의 마지막 단계나 설정 > 자료 관리에서 "백업에서 되살리기"로 백업 파일을 골라요. AI 열쇠는 다시 넣어 주세요.';

  /// 맥 새 버전 안내(앱이 스스로 바꿔 설치하지 않음).
  static const desktopSteps =
      '새 파일을 받아 기존 앱과 바꿔 넣으면 돼요. 설정과 대화는 사용자 폴더에 있어 그대로 남아요.\n\n'
      '1. "내려받기 화면 열기"를 눌러 새 파일을 받아요.\n'
      '2. 이 앱을 닫아요.\n'
      '3. 받은 압축 파일을 풀고, 새 앱을 "응용 프로그램" 폴더의 기존 앱과 바꿔 넣어요.\n'
      '4. 처음 열 때 막히면 시스템 설정 > 개인정보 보호 및 보안에서 "그래도 열기"를 눌러요.';

  @override
  State<UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<UpdateCard> {
  bool checking = false;
  double? progress;
  String? status;
  CancelToken? cancel;

  AppController get c => context.read<AppController>();

  Future<void> _check() async {
    setState(() {
      checking = true;
      status = '새 버전을 확인하고 있어요…';
    });
    try {
      final info = await c.checkForUpdate();
      if (!mounted) return;
      setState(() => status = info == null ? '지금이 최신 버전이에요 (${AppInfo.version}).' : '새 버전 ${info.version}이 있어요!');
      if (info != null) await _offer(info);
    } on UpdateError catch (e) {
      if (!mounted) return;
      setState(() => status = e.kind == UpdateErrorKind.noRelease ? e.message : null);
      if (e.kind != UpdateErrorKind.noRelease) {
        await showFailure(context, title: '업데이트를 확인하지 못했어요', message: e.message, stage: '업데이트 확인', error: e, onRetry: _check);
      }
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  Future<void> _offer(UpdateInfo info) async {
    final platform = c.updates.platform;
    if (platform == 'android') return _offerAndroid(info);
    if (!UpdateService.canInstallInApp(platform)) return _offerManual(info);
    final notes = info.notes.isEmpty ? '바뀐 내용 안내가 없어요.' : info.notes;
    final ok = await confirmOnce(
      context,
      title: '새 버전 ${info.version}',
      message: '$notes\n\n"업데이트"를 누르면 먼저 내 자료를 자동으로 백업하고, 새 버전을 내려받아 설치해요. 설정과 대화는 그대로 남아요.',
      confirmLabel: '업데이트',
    );
    if (!ok || !mounted) return;
    if (info.downloadUrl == null) {
      await showInfo(context, title: '이 기기용 파일이 아직 없어요', message: const UpdateError(UpdateErrorKind.noFileForDevice).message);
      if (mounted) await openLink(context, info.pageUrl);
      return;
    }
    await _download(info);
  }

  /// 안드로이드: 앱 안에서 설치하지 않아요. 백업(앱 밖) → 새 파일 받기 → 기존 앱 지우기 → 설치 → 되살리기.
  Future<void> _offerAndroid(UpdateInfo info) async {
    final notes = info.notes.isEmpty ? '' : '\n\n바뀐 내용\n${info.notes}';
    var backedUp = false;
    while (true) {
      if (!mounted) return;
      final choice = await pickOne<_Step>(
        context,
        title: '새 버전 ${info.version}',
        message: '${UpdateCard.androidSteps}$notes',
        options: [(_Step.backup, backedUp ? '백업 파일 다시 만들기' : '1. 백업 파일 만들기'), (_Step.download, '2. 내려받기 화면 열기')],
      );
      if (choice == null || !mounted) return;
      if (choice == _Step.backup) {
        if (await makeBackupFile(context, c)) backedUp = true;
        continue;
      }
      if (!backedUp) {
        final sure = await confirmOnce(
          context,
          title: '백업 파일을 만들었나요?',
          message: '기존 앱을 지우면 앱 안의 대화·주제·메모·설정이 모두 지워져요. 백업 파일을 앱 밖에 저장해 두었을 때만 계속하세요.',
          confirmLabel: '네, 이미 만들어 두었어요',
          danger: true,
        );
        if (!mounted) return;
        if (!sure) continue;
      }
      await openLink(context, info.downloadUrl ?? info.pageUrl);
      return;
    }
  }

  /// 맥 등: 내려받기 화면을 열고 바꿔 넣는 법을 안내(자료는 사용자 폴더에 그대로).
  Future<void> _offerManual(UpdateInfo info) async {
    final notes = info.notes.isEmpty ? '' : '\n\n바뀐 내용\n${info.notes}';
    final ok = await confirmOnce(
      context,
      title: '새 버전 ${info.version}',
      message: '${UpdateCard.desktopSteps}$notes',
      confirmLabel: '내려받기 화면 열기',
    );
    if (!ok || !mounted) return;
    await openLink(context, info.downloadUrl ?? info.pageUrl);
  }

  Future<void> _download(UpdateInfo info) async {
    final token = CancelToken();
    setState(() {
      cancel = token;
      progress = 0;
      status = '내 자료를 백업하고 있어요…';
    });
    try {
      await c.backupBeforeUpdate(info.version);
      if (!mounted) return;
      setState(() => status = '새 버전을 내려받고 있어요…');
      final dir = Directory('${(await getTemporaryDirectory()).path}/ai_chat_organizer_update');
      final file = await c.updates.download(
        info,
        dir,
        cancel: token,
        onProgress: (got, total) {
          if (mounted) setState(() => progress = total == null || total == 0 ? null : got / total);
        },
      );
      if (!mounted) return;
      setState(() => status = '앱을 닫고 새 버전으로 바꾼 뒤 다시 열어요…');
      await c.updates.install(file);
    } on UpdateError catch (e) {
      if (!mounted) return;
      if (token.isCancelled) {
        showNotice(context, '업데이트를 취소했어요.', kind: StatusKind.check);
      } else {
        await showFailure(
          context,
          title: '업데이트하지 못했어요',
          message: e.message,
          stage: '업데이트(${e.kind.name})',
          error: e,
          onRetry: () => _download(info),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          progress = null;
          cancel = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctl = context.watch<AppController>();
    final tt = Theme.of(context).textTheme;
    final p = AppTheme.of(context).palette;
    final badge = ctl.hasUpdateBadge;
    return SectionCard(
      title: '앱 버전',
      image: AppIcons3d.package,
      children: [
        Row(
          children: [
            Expanded(child: Text('지금 버전 ${AppInfo.version}', style: tt.titleMedium)),
            if (badge) StatusBadge(kind: StatusKind.check, text: '새 버전 ${ctl.settings.latestVersion} 있어요'),
          ],
        ),
        if (status != null) ...[const SizedBox(height: AppSize.gapS), Text(status!, style: tt.bodyLarge)],
        if (progress != null || cancel != null) ...[
          const SizedBox(height: AppSize.gapS),
          ProgressBar(value: progress, label: progress == null ? '준비 중' : '${((progress ?? 0) * 100).round()}%'),
          const SizedBox(height: AppSize.gapS),
          BigButton(label: '취소', icon: Icons.close_rounded, kind: ButtonKind.danger, onPressed: () => cancel?.cancel()),
        ],
        const SizedBox(height: AppSize.gapM),
        BigButton(
          label: checking ? '확인하는 중…' : '업데이트 확인',
          icon: Icons.system_update_rounded,
          kind: badge ? ButtonKind.accent : ButtonKind.primary,
          onPressed: checking || cancel != null ? null : _check,
        ),
        const SizedBox(height: AppSize.gapS),
        BigButton(label: '문제 신고', icon: Icons.flag_rounded, kind: ButtonKind.danger, onPressed: () => openProblemReport(context)),
        const SizedBox(height: AppSize.gapS),
        Text(
          ctl.updates.platform == 'android'
              ? '안드로이드는 새 버전으로 바꿀 때 기존 앱을 지워야 해요. 지우기 전에 꼭 "백업 파일 만들기"로 백업 파일을 앱 밖에 저장하세요. 자동으로 내려받지는 않아요.'
              : '새 버전으로 바꿔도 설정과 대화는 그대로 남아요. 자동으로 내려받지는 않아요.',
          style: tt.bodySmall?.copyWith(color: p.textMuted),
        ),
      ],
    );
  }
}

enum _Step { backup, download }
