import 'package:flutter/material.dart';

import '../../services/app_controller.dart';
import '../../services/backup_service.dart';
import '../../theme/tokens.dart';
import 'dialogs.dart';
import 'file_actions.dart';

/// 백업 파일 이름: 대화기록백업_20261112.aibackup
String backupFileName(DateTime now) =>
    '대화기록백업_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.${BackupService.fileExtension}';

/// 비밀번호로 잠근 백업 파일을 만들어, 사용자가 고른 곳(앱 밖)에 저장합니다.
/// 저장까지 끝나면 true.
Future<bool> makeBackupFile(BuildContext context, AppController c) async {
  final pw = await askText(
    context,
    title: '백업 비밀번호',
    message: '백업 파일을 잠글 비밀번호예요. 잊으면 되살릴 수 없어요(6자 이상).\n\n저장할 곳은 "다운로드" 폴더처럼 앱 밖의 폴더로 골라 주세요. 휴대폰에서 앱을 지우면 앱 안의 자료는 함께 지워져요.',
    obscure: true,
    confirmLabel: '다음',
  );
  if (pw == null || !context.mounted) return false;
  if (pw.length < 6) {
    showNotice(context, '비밀번호는 6자 이상이어야 해요.', kind: StatusKind.check);
    return false;
  }
  final pw2 = await askText(context, title: '한 번 더 입력', obscure: true, confirmLabel: '백업 만들기');
  if (pw2 != pw || !context.mounted) {
    if (context.mounted) showNotice(context, '두 비밀번호가 달라요.', kind: StatusKind.check);
    return false;
  }
  showNotice(context, '백업 파일을 만드는 중이에요…', kind: StatusKind.progress);
  final bytes = await c.makeBackup(pw);
  if (!context.mounted) return false;
  return saveBytes(context, backupFileName(DateTime.now()), bytes);
}

/// 백업 파일을 골라 되살립니다(새로 설치한 앱에서도 같은 순서). 되살렸으면 true.
Future<bool> restoreBackupFile(BuildContext context, AppController c) async {
  final f = await pickOneFile(context);
  if (f == null || !context.mounted) return false;
  final pw = await askText(context, title: '백업 비밀번호', obscure: true, confirmLabel: '다음');
  if (pw == null || !context.mounted) return false;
  final ok = await confirmTwice(context, title: '백업에서 되살릴까요?', message: '지금 앱에 있는 자료가 백업 내용으로 바뀌어요.', confirmLabel: '되살릴게요');
  if (!ok || !context.mounted) return false;
  try {
    await c.restoreBackup(f.$2, pw);
    if (context.mounted) showNotice(context, '되살렸어요! AI 열쇠는 백업에 들어 있지 않아서, 썼다면 설정에서 다시 넣어 주세요.');
    return true;
  } catch (_) {
    if (context.mounted) showNotice(context, '되살리지 못했어요. 비밀번호나 파일을 확인해 주세요.', kind: StatusKind.problem);
    return false;
  }
}
