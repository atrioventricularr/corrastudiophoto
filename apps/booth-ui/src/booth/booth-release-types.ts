export type BoothReleaseCheckStatus = 'untested' | 'passed' | 'warning' | 'failed';

export type BoothReleaseCheckCategory =
  | 'build'
  | 'electron'
  | 'payment'
  | 'cloud'
  | 'disk'
  | 'hardware'
  | 'kiosk'
  | 'content'
  | 'release';

export type BoothReleaseCheckRecord = {
  id: string;
  label: string;
  category: BoothReleaseCheckCategory;
  status: BoothReleaseCheckStatus;
  message?: string;
  updatedAt: string;
};

export type BoothReleaseSummary = {
  required: number;
  passed: number;
  warnings: number;
  failed: number;
  ready: boolean;
  missingLabels: string[];
};
