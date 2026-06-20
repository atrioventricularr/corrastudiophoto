import React, {
  Component,
  type ErrorInfo,
  type ReactNode,
} from 'react';

type BoothStepErrorBoundaryProps = {
  children: ReactNode;
};

type BoothStepErrorBoundaryState = {
  error: Error | null;
  errorInfo: ErrorInfo | null;
};

function BoothStepErrorFallback({
  error,
  errorInfo,
  onRetry,
}: {
  error: Error;
  errorInfo: ErrorInfo | null;
  onRetry: () => void;
}) {
  return (
    <div className="mt-4 rounded-[2rem] bg-white p-6 text-slate-950">
      <p className="text-xs font-black uppercase tracking-[0.25em] text-red-500">
        Booth Error
      </p>

      <h4 className="mt-3 text-5xl font-black leading-none">
        Step Crashed
      </h4>

      <p className="mt-4 max-w-2xl text-sm font-bold leading-relaxed text-slate-600">
        Ada error di current customer step. Klik Retry untuk render ulang step.
        Kalau masih error, reset session dari dev controls.
      </p>

      <div className="mt-5 rounded-3xl border border-red-200 bg-red-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-red-500">
          Error Message
        </p>
        <p className="mt-2 break-words font-mono text-xs font-bold text-red-800">
          {error.message}
        </p>
      </div>

      {errorInfo?.componentStack && (
        <details className="mt-4 rounded-3xl bg-slate-50 p-4">
          <summary className="cursor-pointer text-xs font-black uppercase tracking-[0.2em] text-slate-500">
            Component Stack
          </summary>
          <pre className="mt-3 max-h-48 overflow-auto whitespace-pre-wrap text-[11px] font-bold text-slate-600">
            {errorInfo.componentStack}
          </pre>
        </details>
      )}

      <button
        type="button"
        onClick={onRetry}
        className="mt-6 rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
      >
        Retry Step
      </button>
    </div>
  );
}

export class BoothStepErrorBoundary extends Component<
  BoothStepErrorBoundaryProps,
  BoothStepErrorBoundaryState
> {
  state: BoothStepErrorBoundaryState = {
    error: null,
    errorInfo: null,
  };

  static getDerivedStateFromError(error: Error) {
    return {
      error,
    };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    this.setState({
      error,
      errorInfo,
    });

    console.error('[Corra Booth] Step crashed:', error, errorInfo);
  }

  handleRetry = () => {
    this.setState({
      error: null,
      errorInfo: null,
    });
  };

  render() {
    if (this.state.error) {
      return (
        <BoothStepErrorFallback
          error={this.state.error}
          errorInfo={this.state.errorInfo}
          onRetry={this.handleRetry}
        />
      );
    }

    return this.props.children;
  }
}
