/// Nimbus MCP server over stdio (newline-delimited JSON-RPC 2.0), read-only.
///
/// Config from the environment, or from a KEY=VALUE file named by NIMBUS_ENV_FILE:
///   NIMBUS_SERVER  PocketBase URL
///   AI_EMAIL, AI_PASSWORD  an `ai_readers` login
library;

import 'dart:convert';
import 'dart:io';

import '../../app/lib/features/media/media_api.dart' show booksKey, tmdbKey;
import '../src/tools.dart';
import 'package:pocketbase/pocketbase.dart';

Future<void> main() async {
  final env = {...Platform.environment};
  if (env['NIMBUS_ENV_FILE'] case final String path) {
    for (final line in File(path).readAsLinesSync()) {
      final i = line.indexOf('=');
      if (i > 0 && !line.startsWith('#')) env.putIfAbsent(line.substring(0, i).trim(), () => line.substring(i + 1));
    }
  }
  String need(String k) => env[k] ?? (throw StateError('missing $k'));
  final pb = PocketBase(need('NIMBUS_SERVER'));
  // Optional: without TMDB_KEY no films or series; without BOOKS_KEY Google often refuses a server.
  tmdbKey = env['TMDB_KEY'] ?? tmdbKey;
  booksKey = env['BOOKS_KEY'] ?? booksKey;
  final nimbus = Nimbus(pb);

  Future<void> login() async {
    if (!pb.authStore.isValid) await pb.collection('ai_readers').authWithPassword(need('AI_EMAIL'), need('AI_PASSWORD'));
  }

  Future<Object?> handle(String method, Map params) async => switch (method) {
        'initialize' => {
            'protocolVersion': params['protocolVersion'] ?? '2025-06-18',
            'capabilities': {'tools': {}},
            'serverInfo': {'name': 'nimbus', 'version': '0.1.0'},
            'instructions': 'Read-only access to the user\'s Nimbus app: finance (Rupiah), diary, media log, calendar.',
          },
        'ping' => {},
        'tools/list' => {
            'tools': [
              for (final MapEntry(:key, :value) in nimbus.tools.entries)
                {'name': key, 'description': value.description, 'inputSchema': value.schema},
            ],
          },
        'tools/call' => await _call(nimbus, login, params),
        _ => throw _RpcError(-32601, 'method not found: $method'),
      };

  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    Object? id;
    try {
      final msg = jsonDecode(line) as Map;
      id = msg['id'];
      if (id == null) continue; // notification (e.g. notifications/initialized): no reply
      final result = await handle(msg['method'] as String, (msg['params'] as Map?) ?? {});
      stdout.writeln(jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}));
    } catch (e) {
      final (code, message) = e is _RpcError ? (e.code, e.message) : (-32603, '$e');
      stdout.writeln(jsonEncode({'jsonrpc': '2.0', 'id': id, 'error': {'code': code, 'message': message}}));
    }
  }
}

/// Tool failures go back as a tool result with isError, so the model can read and fix its call.
Future<Object> _call(Nimbus nimbus, Future<void> Function() login, Map params) async {
  final tool = nimbus.tools[params['name']] ?? (throw _RpcError(-32602, 'unknown tool: ${params['name']}'));
  try {
    await login();
    final out = await tool.run((params['arguments'] as Map?) ?? {});
    return {'content': [{'type': 'text', 'text': jsonEncode(out)}]};
  } on ArgumentError catch (e) {
    return _toolError('${e.message}');
  } on ClientException catch (e) {
    return _toolError('Nimbus server error ${e.statusCode}');
  }
}

Map<String, Object> _toolError(String message) => {
      'content': [{'type': 'text', 'text': message}],
      'isError': true,
    };

class _RpcError {
  _RpcError(this.code, this.message);
  final int code;
  final String message;
}
