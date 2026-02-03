import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_client_provider.g.dart';

@riverpod
Future<SupabaseClient> supabaseClient(Ref ref) async {
  final supabaseURL = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseURL == null) {
    throw Exception('supabaseURL is missing.\nPlease pass it through an env file with the key SUPABASE_URL');
  }
  if (supabaseAnonKey == null) {
    throw Exception('supabase anon key is missing.\nPlease pass it through an env file with the key SUPABASE_ANON_KEY');
  }

  ref.keepAlive();

  final supabase = await Supabase.initialize(
    url: supabaseURL,
    anonKey: supabaseAnonKey,
  );
  
  return supabase.client;
}