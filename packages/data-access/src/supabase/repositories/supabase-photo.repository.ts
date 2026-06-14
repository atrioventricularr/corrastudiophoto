import type { PhotoAsset, PhotoSessionSummary } from "@corra/shared";
import { mapPhotoAssetRowToAsset, mapPhotoAssetToInsert } from "../mappers/photo-asset.mapper";
import type { CorraSupabaseClient } from "../supabase-client";

export interface CreatePhotoSessionInput {
  id: string;
  licenseId?: string | null;
  deviceId?: string | null;
  mode: "SESSION" | "SINGLE";
  status: string;
  frameCount: number;
  captureCount: number;
  startedAt: string;
  metadata?: Record<string, unknown>;
}

export interface PhotoRepository {
  createSession(input: CreatePhotoSessionInput): Promise<PhotoSessionSummary>;
  updateSessionStatus(sessionId: string, status: string, completedAt?: string | null): Promise<void>;
  saveAsset(asset: PhotoAsset, frameId?: string | null): Promise<PhotoAsset>;
  listAssetsBySession(sessionId: string): Promise<PhotoAsset[]>;
}

export class SupabasePhotoRepository implements PhotoRepository {
  constructor(private readonly client: CorraSupabaseClient) {}

  async createSession(input: CreatePhotoSessionInput): Promise<PhotoSessionSummary> {
    const now = new Date().toISOString();

    const { data, error } = await this.client
      .from("photo_sessions")
      .insert({
        id: input.id,
        license_id: input.licenseId ?? null,
        device_id: input.deviceId ?? null,
        mode: input.mode,
        status: input.status,
        frame_count: input.frameCount,
        capture_count: input.captureCount,
        started_at: input.startedAt,
        completed_at: null,
        metadata: input.metadata ?? null,
        created_at: now,
        updated_at: now,
      })
      .select("*")
      .single();

    if (error) {
      throw new Error(`Failed to create photo session: ${error.message}`);
    }

    return {
      id: data.id,
      mode: data.mode,
      status: data.status as PhotoSessionSummary["status"],
      frameCount: data.frame_count,
      captureCount: data.capture_count,
      startedAt: data.started_at,
      completedAt: data.completed_at,
    };
  }

  async updateSessionStatus(
    sessionId: string,
    status: string,
    completedAt: string | null = null,
  ): Promise<void> {
    const { error } = await this.client
      .from("photo_sessions")
      .update({
        status,
        completed_at: completedAt,
        updated_at: new Date().toISOString(),
      })
      .eq("id", sessionId);

    if (error) {
      throw new Error(`Failed to update photo session: ${error.message}`);
    }
  }

  async saveAsset(asset: PhotoAsset, frameId: string | null = null): Promise<PhotoAsset> {
    const { data, error } = await this.client
      .from("photo_assets")
      .upsert({
        ...mapPhotoAssetToInsert(asset),
        frame_id: frameId,
      })
      .select("*")
      .single();

    if (error) {
      throw new Error(`Failed to save photo asset: ${error.message}`);
    }

    return mapPhotoAssetRowToAsset(data);
  }

  async listAssetsBySession(sessionId: string): Promise<PhotoAsset[]> {
    const { data, error } = await this.client
      .from("photo_assets")
      .select("*")
      .eq("session_id", sessionId)
      .order("created_at", { ascending: true });

    if (error) {
      throw new Error(`Failed to list photo assets: ${error.message}`);
    }

    return data.map(mapPhotoAssetRowToAsset);
  }
}
