import type {
  TransactionLogEntry,
  TransactionLogPort,
} from "@corra/booth-core";
import type { CorraSupabaseClient } from "../supabase-client";

export class SupabaseTransactionLogRepository implements TransactionLogPort {
  constructor(private readonly client: CorraSupabaseClient) {}

  async append(entry: TransactionLogEntry): Promise<void> {
    const { error } = await this.client.from("transactions").insert({
      id: entry.id,
      session_id: entry.sessionId ?? null,
      type: entry.type,
      message: entry.message,
      metadata: entry.metadata ?? null,
      created_at: entry.createdAt,
    });

    if (error) {
      throw new Error(`Failed to append transaction log: ${error.message}`);
    }
  }
}
