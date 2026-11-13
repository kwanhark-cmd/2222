import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 안내 문서와 배포 안내가 주인의 설치 방법(서명 키 없음, 안드로이드는 백업 → 지우기 → 설치 → 되살리기)을 따르는지.
void main() {
  group('안내 문서와 배포 안내', () {
    final root = Directory.current.parent.path;
    String read(String p) => File('$root/$p').readAsStringSync();

    test('배포 안내 맨 위에 안드로이드 순서(백업 먼저)가 있고, 덮어쓰기 약속이 없다', () {
      final yml = read('.github/workflows/build.yml');
      final start = yml.indexOf('변경 내역(한국어) 꺼내기');
      final step = yml.substring(start, yml.indexOf('- uses: actions/download-artifact', start));
      final android = step.indexOf('안드로이드');
      final changelog = step.indexOf('awk');
      expect(android, greaterThan(0));
      expect(android < changelog, isTrue, reason: '안드로이드 안내가 변경 내역보다 먼저');
      expect(step.indexOf('백업 파일 만들기') < step.indexOf('기존 앱 지우기'), isTrue);
      expect(step.contains('덮어쓰기'), isFalse);
      expect(step.contains('그대로 남아요)'), isFalse);
      expect(yml.contains('secrets.'), isFalse, reason: '서명 키 없이 배포');
      expect(yml.toLowerCase().contains('keystore'), isFalse);
    });

    test('README: 공개 내려받기 화면, 안드로이드는 백업부터', () {
      final readme = read('README.md');
      expect(readme, contains('https://github.com/kwanhark-cmd/2222/releases/latest'));
      expect(readme.contains('Artifacts'), isFalse);
      expect(readme.contains('덮어쓰기'), isFalse);
      final sec = readme.indexOf('안드로이드 새 버전');
      expect(sec, greaterThan(0));
      expect(readme.indexOf('백업 파일 만들기', sec) < readme.indexOf('기존 앱을 지워', sec), isTrue);
    });
  });
}
