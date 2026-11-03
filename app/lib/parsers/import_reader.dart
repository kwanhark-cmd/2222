import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/models.dart';
import 'chatgpt_parser.dart';
import 'claude_parser.dart';
import 'gemini_parser.dart';
import 'parser_common.dart';

/// 파일 하나(zip·json·html)를 읽어 어느 AI 것인지 알아내고 대화를 꺼냅니다.
/// 원본 파일은 읽기만 하고 절대 바꾸지 않습니다.
class ImportReader {
  /// 백그라운드(Isolate)에서 실행할 수 있도록 순수 함수로 둡니다.
  static List<ParseResult> read(String fileName, Uint8List bytes, {AiSource? hint}) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.zip') || _isZip(bytes)) {
      return _readZip(bytes, hint);
    }
    final text = _decodeText(bytes);
    if (lower.endsWith('.html') || lower.endsWith('.htm') || text.trimLeft().startsWith('<')) {
      return [_readHtml(text, hint)];
    }
    return [_readJsonText(text, hint)];
  }

  static bool _isZip(Uint8List b) => b.length > 4 && b[0] == 0x50 && b[1] == 0x4b && b[2] == 0x03 && b[3] == 0x04;

  static String _decodeText(Uint8List bytes) {
    var start = 0;
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) start = 3;
    return utf8.decode(bytes.sublist(start), allowMalformed: true);
  }

  static List<ParseResult> _readZip(Uint8List bytes, AiSource? hint) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const UnreadableFileException('압축 파일을 열 수 없음');
    }
    final results = <ParseResult>[];
    final names = <String>[];
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final name = f.name.replaceAll('\\', '/');
      names.add(name);
      final base = name.split('/').last.toLowerCase();
      final isConversations = RegExp(r'^conversations(-\d+)?\.json$').hasMatch(base);
      final inGeminiFolder = name.contains('Gemini') || name.contains('제미나이');
      final isActivity = base.contains('activity') || base.contains('활동');
      try {
        if (isConversations) {
          results.add(_readJsonText(_decodeText(Uint8List.fromList(f.content)), hint));
        } else if (inGeminiFolder && isActivity && base.endsWith('.json')) {
          results.add(_readJsonText(_decodeText(Uint8List.fromList(f.content)), AiSource.gemini));
        } else if (inGeminiFolder && isActivity && (base.endsWith('.html') || base.endsWith('.htm'))) {
          results.add(_readHtml(_decodeText(Uint8List.fromList(f.content)), AiSource.gemini));
        }
      } on UnreadableFileException {
        // 압축 안 다른 파일은 계속 읽음
      }
    }
    if (results.isEmpty) {
      final shown = names.take(8).map((n) => n.split('/').last).join(', ');
      throw UnreadableFileException('압축 안에서 대화 파일을 찾지 못함(들어있는 파일: $shown)');
    }
    return _mergeSameSource(results);
  }

  static List<ParseResult> _mergeSameSource(List<ParseResult> list) {
    final bySource = <AiSource, ParseResult>{};
    for (final r in list) {
      final prev = bySource[r.source];
      if (prev == null) {
        bySource[r.source] = r;
      } else {
        bySource[r.source] = ParseResult(
          source: r.source,
          conversations: [...prev.conversations, ...r.conversations],
          skipped: prev.skipped + r.skipped,
          notices: {...prev.notices, ...r.notices}.toList(),
        );
      }
    }
    return bySource.values.toList();
  }

  static ParseResult _readJsonText(String text, AiSource? hint) {
    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      throw const UnreadableFileException('JSON 형식이 아님');
    }
    // 일부 형식은 {conversations:[...]} 처럼 한 번 감싸져 있음
    if (decoded is Map) {
      for (final k in ['conversations', 'items', 'data']) {
        if (decoded[k] is List) {
          decoded = decoded[k];
          break;
        }
      }
    }
    if (decoded is List && decoded.isEmpty) {
      return ParseResult(source: hint ?? AiSource.claude, conversations: const []);
    }
    if (ChatGptParser.looksLike(decoded)) return ChatGptParser.parse(decoded);
    if (ClaudeParser.looksLike(decoded)) return ClaudeParser.parse(decoded);
    if (GeminiParser.looksLikeJson(decoded)) return GeminiParser.parseJson(decoded);
    switch (hint) {
      case AiSource.claude:
        return ClaudeParser.parse(decoded);
      case AiSource.chatgpt:
        return ChatGptParser.parse(decoded);
      case AiSource.gemini:
        return GeminiParser.parseJson(decoded);
      case null:
        throw UnreadableFileException('어느 AI 파일인지 알 수 없음: ${describeStructure(decoded)}');
    }
  }

  static ParseResult _readHtml(String text, AiSource? hint) {
    if (GeminiParser.looksLikeHtml(text) || hint == AiSource.gemini) {
      return GeminiParser.parseHtml(text);
    }
    // 챗GPT chat.html 안에는 jsonData = [...] 가 들어 있음
    final m = RegExp(r'jsonData\s*=\s*(\[.*?\]);\s*\n', dotAll: true).firstMatch(text);
    if (m != null) {
      try {
        return ChatGptParser.parse(jsonDecode(m.group(1)!));
      } catch (_) {}
    }
    throw const UnreadableFileException('알 수 없는 HTML 파일');
  }
}
