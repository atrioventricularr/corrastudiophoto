export type BoothInstallerReadinessStatus =
  | 'untested'
  | 'passed'
  | 'warning'
  | 'failed';

export type BoothInstallerReadinessItem = {
  id: string;
  label: string;
  status: BoothInstallerReadinessStatus;
  message?: string;
  updatedAt: string;
};

export type BoothInstallerReadinessSummary = {
  ready: boolean;
  passed: number;
  warning: number;
  failed: number;
  untested: number;
  total: number;
};
