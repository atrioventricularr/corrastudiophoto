import React, { type ReactNode } from 'react';
import { useBoothFlow } from './BoothFlowProvider';

type BoothStepGuardProps = {
  children: ReactNode;
};

function GuardNotice({
  title,
  description,
  primaryLabel,
  onPrimary,
  secondaryLabel,
  onSecondary,
}: {
  title: string;
  description: string;
  primaryLabel: string;
  onPrimary: () => void;
  secondaryLabel?: string;
  onSecondary?: () => void;
}) {
  return (
    <div className="mt-4 rounded-[2rem] bg-white p-6 text-slate-950">
      <p className="text-xs font-black uppercase tracking-[0.25em] text-amber-500">
        Booth Guard
      </p>

      <h4 className="mt-3 text-5xl font-black leading-none">
        {title}
      </h4>

      <p className="mt-4 max-w-2xl text-sm font-bold leading-relaxed text-slate-600">
        {description}
      </p>

      <div className="mt-6 grid gap-3 sm:grid-cols-2">
        <button
          type="button"
          onClick={onPrimary}
          className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
        >
          {primaryLabel}
        </button>

        {secondaryLabel && onSecondary && (
          <button
            type="button"
            onClick={onSecondary}
            className="rounded-3xl border border-slate-200 bg-white px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
          >
            {secondaryLabel}
          </button>
        )}
      </div>
    </div>
  );
}

export function BoothStepGuard({ children }: BoothStepGuardProps) {
  const {
    currentStep,
    paymentConfirmed,
    setStep,
  } = useBoothFlow();

  const isProtectedStep =
    currentStep === 'camera' ||
    currentStep === 'review' ||
    currentStep === 'delivery' ||
    currentStep === 'complete';

  if (isProtectedStep && !paymentConfirmed) {
    return (
      <GuardNotice
        title="Payment Not Confirmed"
        description="Step camera dan setelahnya dikunci sampai pembayaran dikonfirmasi. Kembali ke payment untuk melanjutkan flow dengan aman."
        primaryLabel="Back to Payment"
        onPrimary={() => setStep('payment')}
        secondaryLabel="Back to Welcome"
        onSecondary={() => setStep('welcome')}
      />
    );
  }

  return <>{children}</>;
}
