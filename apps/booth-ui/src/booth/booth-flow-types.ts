export type BoothFlowStep =
  | 'welcome'
  | 'payment'
  | 'camera'
  | 'review'
  | 'delivery'
  | 'complete';

export type BoothCustomerSession = {
  id: string;
  startedAt: string;
  completedAt?: string;
  currentStep: BoothFlowStep;
};

export const boothFlowSteps: BoothFlowStep[] = [
  'welcome',
  'payment',
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
