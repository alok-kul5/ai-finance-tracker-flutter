import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/store.dart';
import 'sync_engine.dart';

/// Sync is compiled in but switched off unless both of these are passed:
///   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get enabled => url.isNotEmpty && anonKey.isNotEmpty;
}

/// [RemoteStore] over one Supabase table, `kharcha_records`, guarded by row
/// level security so each (anonymous) user only ever sees their own rows.
class SupabaseRemote implements RemoteStore {
  SupabaseRemote(this.client);

  final SupabaseClient client;
  static const table = 'kharcha_records';

  static Future<SupabaseRemote> connect() async {
    // Newer projects call it the "publishable" key; a legacy anon key works too.
    await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }
    return SupabaseRemote(client);
  }

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Not signed in to Supabase');
    return id;
  }

  @override
  Future<void> push(List<SyncRecord> records) async {
    final uid = _userId;
    for (var i = 0; i < records.length; i += 200) {
      final batch = records.skip(i).take(200);
      await client.from(table).upsert([
        for (final r in batch)
          {
            'user_id': uid,
            'kind': r.kind,
            'id': r.id,
            'updated_at': r.updatedAtMs,
            'deleted': r.deleted,
            'data': r.data,
          }
      ], onConflict: 'user_id,kind,id');
    }
  }

  @override
  Future<RemotePage> pull(int cursor, {int limit = 500}) async {
    final rows = await client
        .from(table)
        .select('kind,id,updated_at,deleted,data,seq')
        .gt('seq', cursor)
        .order('seq')
        .limit(limit);
    var next = cursor;
    final out = <SyncRecord>[];
    for (final row in rows) {
      final seq = (row['seq'] as num).toInt();
      if (seq > next) next = seq;
      out.add(SyncRecord(
        kind: row['kind'] as String,
        id: row['id'] as String,
        updatedAt: DateTime.fromMillisecondsSinceEpoch((row['updated_at'] as num).toInt()),
        deleted: row['deleted'] as bool? ?? false,
        data: Map<String, Object?>.from(row['data'] as Map),
      ));
    }
    return RemotePage(out, next);
  }
}
