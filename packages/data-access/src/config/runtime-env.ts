import type {
  SupabasePublicConfig,
  SupabaseServerConfig,
} from "./supabase-config";

export function getSupabasePublicConfigFromViteEnv(): SupabasePublicConfig {
  const env = import.meta.env as Record<string, string | undefined>;

  return {
    url: env.VITE_SUPABASE_URL ?? "",
    anonKey: env.VITE_SUPABASE_ANON_KEY ?? "",
  };
}

export function getSupabaseServerConfigFromProcessEnv(): SupabaseServerConfig {
  const env =
    typeof process !== "undefined"
      ? (process.env as Record<string, string | undefined>)
      : {};

  return {
    url: env.SUPABASE_URL ?? env.VITE_SUPABASE_URL ?? "",
    serviceRoleKey: env.SUPABASE_SERVICE_ROLE_KEY ?? "",
  };
}
