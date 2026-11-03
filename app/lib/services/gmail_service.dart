/// 지메일 연결(읽기 전용) — 내보내기 안내 메일이 오면 알려 주기 위한 틀.
///
/// 실제 연결에는 구글 클라우드에서 만든 OAuth 클라이언트 ID(개발자 설정)가 필요합니다.
/// 링크는 로그인이 필요하고 금방 만료되므로 자동 내려받기는 하지 않고,
/// "여기를 눌러 내려받기 → 앱에 넣기" 안내만 합니다.
abstract class ExportMailWatcher {
  bool get configured;
  bool get connected;
  Future<void> connect();
  Future<void> disconnect();

  /// 최근 내보내기 안내 메일(보낸 곳, 받은 시각, 링크 열기 주소).
  Future<List<ExportMail>> recentExportMails();
}

class ExportMail {
  final String from;
  final DateTime receivedAt;
  final String openUrl;
  const ExportMail(this.from, this.receivedAt, this.openUrl);
}

/// 아직 구글 연결 키가 없을 때.
class NotConfiguredMailWatcher implements ExportMailWatcher {
  @override
  bool get configured => false;
  @override
  bool get connected => false;
  @override
  Future<void> connect() async => throw UnsupportedError('지메일 연결 준비 중');
  @override
  Future<void> disconnect() async {}
  @override
  Future<List<ExportMail>> recentExportMails() async => const [];

  /// 내보내기 안내 메일을 찾는 검색식(연결되면 이 조건으로 읽기 전용 조회).
  static const query =
      'newer_than:3d (from:no-reply@anthropic.com OR from:noreply@tm.openai.com OR from:noreply@google.com) (export OR 내보내기 OR takeout)';
}
