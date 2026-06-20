export type BoothFlowStep =
  | 'welcome'
  | 'payment'
  | 'camera'
  | 'review'
  | 'delivery'
  | 'complete';

export type BoothPaymentStatus =
  | 'idle'
  | 'pending'
  | 'confirmed'
  | 'failed';

export type BoothCustomerSession = {
  id: string;
  startedAt: string;
  completedAt?: string;
  currentStep: BoothFlowStep;
  paymentStatus: BoothPaymentStatus;
  paymentConfirmedAt?: string;
};

export const boothFlowSteps: BoothFlowStep[] = [
  'welcome',
  'payment',
  'camera',
  'review',
  'delivery',
  'complete',
];

export const boothProtectedSteps: BoothFlowStep[] = [
  'camera',
  'review',
  'delivery',
  'complete',
];

export const boothFlowStepLabels: Record<BoothFlowStep, string> = {
  welcome: 'Welcome',
  payment: 'Payment',
  camera: 'Camera',
  review: 'Review',
  delivery: 'Delivery',
  complete: 'Complete',
};
