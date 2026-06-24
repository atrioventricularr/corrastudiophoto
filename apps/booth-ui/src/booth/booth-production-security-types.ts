export type BoothProductionSecurityStatus =
  | 'untested'
  | 'passed'
  | 'warning'
  | 'failed';

export type BoothProductionSecurityItem = {
  id: string;
  label: string;
  status: BoothProductionSecurityStatus;
  message?: string;
  updatedAt: string;
};

export type BoothProductionAuditSummary = {
  ready: boolean;
  passed: number;
  warning: number;
  failed: number;
  untested: number;
  total: number;
};
