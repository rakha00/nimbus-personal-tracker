/// AI worker: takes waiting `ai_requests`, asks Claude Code (headless, subscription login) with
/// only the read-only Nimbus MCP tools, and writes back an answer and/or drafts. Drafts are only
/// suggestions: the app opens its normal forms with them and the user presses Save.
///
/// Env: NIMBUS_SERVER, AI_EMAIL, AI_PASSWORD (ai_readers login), CLAUDE_CODE_OAUTH_TOKEN,
/// optional NIMBUS_MCP_BIN (default /usr/local/bin/nimbus-mcp), AI_MODEL (default haiku).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pocketbase/pocketbase.dart';

const perHour = 30;
const timeout = Duration(seconds: 90);

Future<void> main() async {
  final env = Platform.environment;
  String need(String k) => env[k] ?? (throw StateError('missing $k'));
  final pb = PocketBase(need('NIMBUS_SERVER'));
  final requests = pb.collection('ai_requests');
  Future<void> login() async {
    if (!pb.authStore.isValid) await pb.collection('ai_readers').authWithPassword(need('AI_EMAIL'), need('AI_PASSWORD'));
  }

  // The MCP server gets the ai_readers login from a private file; Claude itself only gets its token.
  final work = Directory.systemTemp.createTempSync('nimbus-ai');
  final mcpConfig = File('${work.path}/mcp.json')
    ..writeAsStringSync(jsonEncode({
      'mcpServers': {
        'nimbus': {
          'command': env['NIMBUS_MCP_BIN'] ?? '/usr/local/bin/nimbus-mcp',
          'env': {
            for (final k in ['NIMBUS_SERVER', 'AI_EMAIL', 'AI_PASSWORD']) k: need(k),
            'TMDB_KEY': ?env['TMDB_KEY'],
            'BOOKS_KEY': ?env['BOOKS_KEY'],
          },
        },
      },
    }));
  final claudeEnv = {
    'PATH': env['PATH'] ?? '/usr/local/bin:/usr/bin:/bin',
    'HOME': env['HOME'] ?? work.path,
    'CLAUDE_CODE_OAUTH_TOKEN': need('CLAUDE_CODE_OAUTH_TOKEN'),
    'DISABLE_AUTOUPDATER': '1',
    'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC': '1',
  };

  await login();
  // A crash mid-request leaves it "running" forever; fail those once at start.
  for (final r in await requests.getFullList(filter: 'status = "running"')) {
    await requests.update(r.id, body: {'status': 'error', 'error': 'failed'});
  }

  final recent = <DateTime>[];
  stderr.writeln('nimbus-ai worker ready');
  // ponytail: polls every 2 s (one cheap query); switch to realtime if latency ever matters.
  while (true) {
    try {
      await login();
      final waiting = await requests.getList(perPage: 5, filter: 'status = ""', sort: 'created');
      for (final r in waiting.items) {
        recent.removeWhere((t) => DateTime.now().difference(t) > const Duration(hours: 1));
        if (recent.length >= perHour) {
          await requests.update(r.id, body: {'status': 'error', 'error': 'rate_limit'});
          continue;
        }
        recent.add(DateTime.now());
        await requests.update(r.id, body: {'status': 'running'});
        final result = await ask(r.getStringValue('prompt'), mcpConfig.path, work.path, claudeEnv, env['AI_MODEL'] ?? 'haiku');
        await requests.update(r.id, body: result);
        stderr.writeln('${r.id} ${result['status']} ${result['error'] ?? ''}');
      }
    } catch (e) {
      stderr.writeln('loop error: $e');
    }
    await Future.delayed(const Duration(seconds: 2));
  }
}

/// Runs one Claude Code call; returns the fields to save on the request.
Future<Map<String, Object>> ask(String prompt, String mcpConfig, String cwd, Map<String, String> env, String model) async {
  final proc = await Process.start(
    'claude',
    [
      '-p',
      '--model', model,
      '--output-format', 'json',
      '--json-schema', jsonEncode(outputSchema),
      '--system-prompt', systemPrompt,
      '--tools', '', // no Bash, files, web or subagents
      '--mcp-config', mcpConfig,
      '--strict-mcp-config',
      '--allowedTools', 'mcp__nimbus', // every tool of the nimbus server, nothing else
      '--setting-sources', 'user', // the container's own empty settings; no project CLAUDE.md
      '--disable-slash-commands',
      '--no-session-persistence',
    ],
    workingDirectory: cwd,
    environment: env,
    includeParentEnvironment: false,
  );
  proc.stdin.write(prompt); // stdin, so a prompt can't be read as a flag
  await proc.stdin.close();
  final out = proc.stdout.transform(utf8.decoder).join();
  final err = proc.stderr.transform(utf8.decoder).join();
  final code = await proc.exitCode.timeout(timeout, onTimeout: () {
    proc.kill(ProcessSignal.sigkill);
    return -1;
  });
  if (code == -1) return {'status': 'error', 'error': 'timeout'};
  try {
    final res = jsonDecode(await out) as Map;
    if (res['is_error'] == true) throw '${res['result']}';
    final data = (res['structured_output'] ?? jsonDecode(res['result'] as String)) as Map;
    return {'status': 'done', 'answer': data['answer'] as String? ?? '', 'drafts': data['drafts'] ?? []};
  } catch (e) {
    stderr.writeln('claude failed (exit $code): $e ${await err}');
    return {'status': 'error', 'error': 'failed'};
  }
}

const systemPrompt = '''
You are the assistant inside Nimbus, one person's private app: finance (Indonesian Rupiah), a daily
diary, a media log (films, series, anime, books) and a calendar. You can only read Nimbus data
through the nimbus tools. Reply in Indonesian, short and plain.

Only handle requests about the user's own Nimbus records. For anything else (general questions,
coding, other apps, the server) set answer to "Di luar Nimbus." with no drafts.

Decide from the message what the user wants; one message can do both.

Something to note (spending, income, a loan, a diary line, a film or book, an event): turn it
into drafts the user will check and save in the app. You never save anything yourself. Call
lookup first for today's date and the exact names; use names exactly as listed. If the account,
category or person is unclear, leave that field out rather than guess. Amounts are whole Rupiah
("25rb" = 25000, "1,5jt" = 1500000). Dates are YYYY-MM-DD; "kemarin", "besok" and weekdays are
relative to today. One note can give several drafts. A diary draft is the text to add to that
day's entry. Say in one short line what you drafted.

To change or delete a transaction, first find it with the transactions tool and use its id
exactly; never make up an id. A transaction_update draft holds the id and only the fields that
change; a transaction_delete draft holds only the id. If more than one transaction could be
meant, make no draft and list the candidates briefly (date, amount, note) so the user can say
which one. The user approves or rejects each draft in the app.

Finding an item in the log: titles may be stored in their original language (e.g. Korean) and the
user may name the wrong type, so if the media tool's query finds nothing, list the whole log (no
query) and also media_search the user's title in every type it could be: a logged item with the
same external_id as a hit is the same title. Treat it as missing only after both checks.

A film, series, anime or book to log: check the log first; if it's already there, make a
media_update instead of a new one. Otherwise call media_search and copy external_id, title, year,
creator and cover_url exactly from a hit. Pick the hit whose title matches what the user typed,
in the same language: for "bumi manusia" take "Bumi Manusia", not a translation like "This Earth
of Mankind"; if only translations come back, search again in the typed language or say so.
One clear match: one media draft. A likely typo or
several possible titles: one media draft per likely candidate, at most 3, and say in the answer
to approve the right one and reject the rest. Nothing found: no draft; say so and suggest a
corrected title or logging it by hand. Only when the user asks to log it by hand (manual): a
media draft with the user's title and no external_id. Films have no "progress" status.

To change a logged item's status, finish date, rating or note, or to delete it, find it in the log
as above and use its id exactly: media_update holds the id and only what changes, media_delete
only the id. Moving an item out of done clears its finish date and rating by itself; no need to
mention them. If more than one item could be meant, make no draft and ask which one. Asked to change
or delete something that isn't in the log: make no draft (never add it as new) and say so.

To change what a diary entry already says (fix, rewrite, reword or remove a line), read that
day with the diary tool first, then give a diary_update draft with the whole new text of the
entry: apply only what the user asked and keep everything else as it was. Use the diary draft
only to add new lines. Never delete a diary entry and never empty one: if asked, make no draft
and say a diary entry can only be deleted in the app.

A question: answer from the tools; never guess numbers, and use totals the tools give rather
than adding many values yourself. Write money like Rp25.000.

If unsure whether it's a note or a question, make the drafts and say in the answer that they are
only drafts.
''';

const _str = {'type': 'string'};
const _date = {'type': 'string', 'description': 'YYYY-MM-DD'};
Map<String, Object> _draft(String module, Map<String, Object> props, List<String> required) => {
      'type': 'object',
      'properties': {'module': {'type': 'string', 'enum': [module]}, ...props},
      'required': ['module', ...required],
      'additionalProperties': false,
    };

const _mediaLog = {
  'status': {'type': 'string', 'enum': ['wishlist', 'progress', 'done']},
  'finished_on': _date,
  'rating': {'type': 'integer', 'minimum': 1, 'maximum': 5},
  'note': _str,
};

const _txFields = {
  'date': _date,
  'type': {'type': 'string', 'enum': ['income', 'expense', 'transfer', 'lend', 'collect', 'borrow', 'repay']},
  'amount': {'type': 'integer'},
  'account': _str,
  'to_account': _str,
  'category': _str,
  'person': _str,
  'note': _str,
};

final outputSchema = {
  'type': 'object',
  'properties': {
    'answer': _str,
    'drafts': {
      'type': 'array',
      'items': {
        'anyOf': [
          _draft('transaction', _txFields, ['date', 'type', 'amount']),
          _draft('transaction_update', {'id': _str, ..._txFields}, ['id']),
          _draft('transaction_delete', {'id': _str}, ['id']),
          _draft('diary', {'date': _date, 'text': _str}, ['date', 'text']),
          // The whole new text of that day's entry; never empty, since an empty entry is deleted.
          _draft('diary_update', {'date': _date, 'content': {'type': 'string', 'minLength': 1}}, ['date', 'content']),
          _draft('media', {
            'media_type': {'type': 'string', 'enum': ['film', 'series', 'anime', 'book']},
            'title': _str,
            'year': {'type': 'integer'},
            'creator': _str,
            'external_id': _str, // from media_search; left out only for a manual entry
            'cover_url': _str,
            ..._mediaLog,
          }, ['media_type', 'title', 'status']),
          _draft('media_update', {'id': _str, ..._mediaLog}, ['id']),
          _draft('media_delete', {'id': _str}, ['id']),
          _draft('event', {
            'title': _str,
            'date': _date,
            'time': {'type': 'string', 'description': 'HH:MM in WIB; leave out for an all-day event'},
            'yearly': {'type': 'boolean'},
            'reminder': {'type': 'string', 'enum': ['at_start', '10m', '1h', '1d']},
            'note': _str,
          }, ['title', 'date']),
        ],
      },
    },
  },
  'required': ['answer', 'drafts'],
  'additionalProperties': false,
};
