import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import {
  assertSupabasePublicConfig,
  assertSupabaseServerConfig,
  type SupabasePublicConfig,
  type SupabaseServerConfig,
} from "../config/supabase-config";
import type { Database } from "./database.types";

export type CorraSupabaseClient = SupabaseClient<Database>;

export function createSupabaseBrowserClient(
  config: SupabasePublicConfig,
): CorraSupabaseClient {
  assertSupabasePublicConfig(config);

  return createClient<Database>(config.url, config.anonKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  });
}

export function createSupabaseServerClient(
  config: SupabaseServerConfig,
): CorraSupabaseClient {
  assertSupabaseServerConfig(config);

  return createClient<Database>(config.url, config.serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}
