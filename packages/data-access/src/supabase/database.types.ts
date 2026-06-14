export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface LicenseRow {
  id: string;
  license_code: string;
  owner_email: string;
  owner_name: string | null;
  status: "PENDING" | "ACTIVE" | "EXPIRED" | "SUSPENDED" | "CANCELLED";
  billing_cycle: "MONTHLY" | "YEARLY" | "TRIAL" | "LIFETIME";
  mayar_customer_id: string | null;
  mayar_transaction_id: string | null;
  mayar_subscription_id: string | null;
  active_from: string;
  active_until: string | null;
  max_devices: number;
  created_at: string;
  updated_at: string;
}

export type LicenseInsert = Omit<LicenseRow, "id" | "created_at" | "updated_at"> & {
  id?: string;
  created_at?: string;
  updated_at?: string;
};

export type LicenseUpdate = Partial<LicenseInsert>;

export interface BoothDeviceRow {
  id: string;
  license_id: string;
  device_fingerprint: string;
  device_name: string | null;
  platform: string;
  last_seen_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface TransactionRow {
  id: string;
  session_id: string | null;
  license_id: string | null;
  type: string;
  message: string;
  metadata: Json | null;
  created_at: string;
}

export interface PhotoSessionRow {
  id: string;
  license_id: string | null;
  device_id: string | null;
  mode: "SESSION" | "SINGLE";
  status: string;
  frame_count: number;
  capture_count: number;
  started_at: string;
  completed_at: string | null;
  metadata: Json | null;
  created_at: string;
  updated_at: string;
}

export interface PhotoAssetRow {
  id: string;
  session_id: string;
  frame_id: string | null;
  kind: "RAW_CAPTURE" | "FINAL_FRAME" | "GIF";
  storage_bucket: string | null;
  storage_path: string | null;
  public_url: string | null;
  mime_type: string;
  width: number | null;
  height: number | null;
  size_bytes: number | null;
  created_at: string;
}

export interface TemplateRow {
  id: string;
  layout_id: string;
  name: string;
  background_storage_path: string | null;
  background_public_url: string | null;
  canvas_width: number;
  canvas_height: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface LayoutRow {
  id: string;
  name: string;
  canvas_width: number;
  canvas_height: number;
  slot_count: number;
  slots: Json;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Database {
  public: {
    Tables: {
      licenses: {
        Row: LicenseRow;
        Insert: LicenseInsert;
        Update: LicenseUpdate;
      };
      booth_devices: {
        Row: BoothDeviceRow;
        Insert: Partial<BoothDeviceRow>;
        Update: Partial<BoothDeviceRow>;
      };
      transactions: {
        Row: TransactionRow;
        Insert: Partial<TransactionRow>;
        Update: Partial<TransactionRow>;
      };
      photo_sessions: {
        Row: PhotoSessionRow;
        Insert: Partial<PhotoSessionRow>;
        Update: Partial<PhotoSessionRow>;
      };
      photo_assets: {
        Row: PhotoAssetRow;
        Insert: Partial<PhotoAssetRow>;
        Update: Partial<PhotoAssetRow>;
      };
      templates: {
        Row: TemplateRow;
        Insert: Partial<TemplateRow>;
        Update: Partial<TemplateRow>;
      };
      layouts: {
        Row: LayoutRow;
        Insert: Partial<LayoutRow>;
        Update: Partial<LayoutRow>;
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
}
