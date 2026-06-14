export interface SupabasePublicConfig {
  url: string;
  anonKey: string;
}

export interface SupabaseServerConfig {
  url: string;
  serviceRoleKey: string;
}

export function assertSupabasePublicConfig(
  config: SupabasePublicConfig,
): void {
  if (!config.url.trim()) {
    throw new Error("Supabase URL is required.");
  }

  if (!config.anonKey.trim()) {
    throw new Error("Supabase anon key is required.");
  }
}

export function assertSupabaseServerConfig(
  config: SupabaseServerConfig,
): void {
  if (!config.url.trim()) {
    throw new Error("Supabase URL is required.");
  }

  if (!config.serviceRoleKey.trim()) {
    throw new Error("Supabase service-role key is required.");
  }
}
