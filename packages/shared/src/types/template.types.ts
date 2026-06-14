import type { CorraId, ISODateTimeString } from "./common.types";

export interface BoothTemplate {
  id: CorraId;
  name: string;
  layoutId: CorraId;
  backgroundAssetId: CorraId | null;
  backgroundLocalPath?: string;
  backgroundStoragePath?: string;
  backgroundPublicUrl?: string;
  canvasWidth: number;
  canvasHeight: number;
  isActive: boolean;
  createdAt: ISODateTimeString;
  updatedAt: ISODateTimeString;
}
