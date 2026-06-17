import React, { useMemo, useState } from 'react';
import { useSessionLifecycle } from '../../sessions';

function formatDate(value?: string | null): string {
  if (!value) return '-';

  try {
    return new Intl.DateTimeFormat('id-ID', {
      dateStyle: 'medium',
      timeStyle: 'medium',
    }).format(new Date(value));
  } catch {
    return value;
  }
}

function shortId(value?: string | null): string {
  if (!value) return '-';
  if (value.length <= 18) return value;
  return `${value.slice(0, 10)}...${value.slice(-6)}`;
}

function getStatusLabelClass(status?: string | null): string {
  if (!status) return 'bg-gray-100 text-gray-700';

  if (
    ['completed', 'delivered', 'payment_confirmed'].includes(status)
  ) {
    return 'bg-green-100 text-green-800';
  }

  if (
    ['payment_pending', 'capturing', 'processing'].includes(status)
  ) {
    return 'bg-yellow-100 text-yellow-800';
  }

  if (['cancelled', 'failed'].includes(status)) {
    return 'bg-red-100 text-red-800';
  }

  return 'bg-blue-100 text-blue-800';
}

function getSyncStatusLabelClass(status?: string | null): string {
  if (status === 'synced') return 'bg-green-100 text-green-800';
  if (status === 'syncing') return 'bg-yellow-100 text-yellow-800';
  if (status === 'failed') return 'bg-red-100 text-red-800';
  if (status === 'skipped') return 'bg-slate-100 text-slate-700';

  return 'bg-blue-100 text-blue-800';
}

export function SessionLifecyclePanel() {
  const {
    currentSession,
    sessionHistory,
    lifecycleEvents,
    syncStatus,
    lastSyncedAt,
    syncError,
    syncCurrentSession,
    clearSessionHistory,
  } = useSessionLifecycle();

  const [showEvents, setShowEvents] = useState(true);

  const currentSessionEvents = useMemo(() => {
    if (!currentSession) return [];

    return lifecycleEvents.filter(
      (event) => event.sessionId === currentSession.id,
    );
  }, [currentSession, lifecycleEvents]);

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Session Lifecycle
          </p>
          <h3 className="mt-1 text-xl font-black text-slate-950">
            Booth Session Monitor
          </h3>
          <p className="mt-1 text-xs font-semibold text-slate-500">
            Pantau status session dari payment sampai hasil foto delivered.
          </p>

          <div className="mt-3 flex flex-wrap items-center gap-2">
            <span
              className={`rounded-full px-3 py-1 text-[10px] font-black uppercase tracking-wider ${getSyncStatusLabelClass(
                syncStatus,
              )}`}
            >
              Sync: {syncStatus}
            </span>

            <span className="text-[10px] font-bold text-slate-400">
              Last sync: {formatDate(lastSyncedAt)}
            </span>
          </div>

          {syncError && (
            <p className="mt-2 rounded-xl bg-red-50 px-3 py-2 text-xs font-bold text-red-700">
              {syncError}
            </p>
          )}
        </div>

        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setShowEvents((current) => !current)}
            className="rounded-2xl border border-slate-200 px-4 py-2 text-xs font-black text-slate-700"
          >
            {showEvents ? 'Hide Events' : 'Show Events'}
          </button>

          <button
            type="button"
            onClick={() => void syncCurrentSession()}
            disabled={!currentSession || syncStatus === 'syncing'}
            className="rounded-2xl border border-blue-200 bg-blue-50 px-4 py-2 text-xs font-black text-blue-700 disabled:opacity-50"
          >
            {syncStatus === 'syncing' ? 'Syncing...' : 'Sync Now'}
          </button>

          <button
            type="button"
            onClick={clearSessionHistory}
            className="rounded-2xl border border-red-200 bg-red-50 px-4 py-2 text-xs font-black text-red-700"
          >
            Clear
          </button>
        </div>
      </div>

      <div className="mt-5 rounded-2xl border border-slate-100 bg-slate-50 p-4">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-xs font-black uppercase tracking-wider text-slate-400">
              Current Session
            </p>
            <p className="mt-1 font-mono text-xs font-bold text-slate-700">
              {shortId(currentSession?.id)}
            </p>
          </div>

          <span
            className={`rounded-full px-3 py-1 text-xs font-black ${getStatusLabelClass(
              currentSession?.status,
            )}`}
          >
            {currentSession?.status || 'no_active_session'}
          </span>
        </div>

        {currentSession ? (
          <div className="mt-4 grid gap-3 text-xs sm:grid-cols-2">
            <div>
              <p className="font-black text-slate-400">Payment Transaction</p>
              <p className="mt-1 font-mono font-bold text-slate-700">
                {shortId(currentSession.paymentTransactionId)}
              </p>
            </div>

            <div>
              <p className="font-black text-slate-400">Payment Code</p>
              <p className="mt-1 font-mono font-bold text-slate-700">
                {shortId(currentSession.paymentConfirmationCode)}
              </p>
            </div>

            <div>
              <p className="font-black text-slate-400">Layout</p>
              <p className="mt-1 font-mono font-bold text-slate-700">
                {currentSession.layoutId || '-'}
              </p>
            </div>

            <div>
              <p className="font-black text-slate-400">Template</p>
              <p className="mt-1 font-mono font-bold text-slate-700">
                {currentSession.templateId || '-'}
              </p>
            </div>

            <div>
              <p className="font-black text-slate-400">Created</p>
              <p className="mt-1 font-bold text-slate-700">
                {formatDate(currentSession.createdAt)}
              </p>
            </div>

            <div>
              <p className="font-black text-slate-400">Updated</p>
              <p className="mt-1 font-bold text-slate-700">
                {formatDate(currentSession.updatedAt)}
              </p>
            </div>
          </div>
        ) : (
          <p className="mt-4 text-sm font-semibold text-slate-500">
            Belum ada session aktif.
          </p>
        )}
      </div>

      {showEvents && (
        <div className="mt-5">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Current Session Events
          </p>

          <div className="mt-3 space-y-2">
            {currentSessionEvents.length > 0 ? (
              currentSessionEvents.slice(0, 12).map((event) => (
                <div
                  key={event.id}
                  className="rounded-2xl border border-slate-100 bg-white p-3"
                >
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="rounded-full bg-slate-100 px-2 py-1 font-mono text-[10px] font-black text-slate-600">
                      {event.fromStatus || 'start'}
                    </span>
                    <span className="text-xs font-black text-slate-400">→</span>
                    <span
                      className={`rounded-full px-2 py-1 text-[10px] font-black ${getStatusLabelClass(
                        event.toStatus,
                      )}`}
                    >
                      {event.toStatus}
                    </span>
                  </div>

                  <p className="mt-2 text-xs font-bold text-slate-700">
                    {event.reason || 'No reason'}
                  </p>
                  <p className="mt-1 text-[10px] font-semibold text-slate-400">
                    {formatDate(event.createdAt)}
                  </p>
                </div>
              ))
            ) : (
              <p className="rounded-2xl bg-slate-50 p-4 text-sm font-semibold text-slate-500">
                Belum ada event untuk current session.
              </p>
            )}
          </div>
        </div>
      )}

      <div className="mt-5">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Recent Sessions
        </p>

        <div className="mt-3 overflow-hidden rounded-2xl border border-slate-100">
          {sessionHistory.length > 0 ? (
            <div className="max-h-80 overflow-auto">
              <table className="w-full text-left text-xs">
                <thead className="sticky top-0 bg-slate-50 text-slate-400">
                  <tr>
                    <th className="px-3 py-2 font-black">Session</th>
                    <th className="px-3 py-2 font-black">Status</th>
                    <th className="px-3 py-2 font-black">Payment</th>
                    <th className="px-3 py-2 font-black">Updated</th>
                  </tr>
                </thead>
                <tbody>
                  {sessionHistory.slice(0, 30).map((session) => (
                    <tr key={session.id} className="border-t border-slate-100">
                      <td className="px-3 py-2 font-mono font-bold text-slate-700">
                        {shortId(session.id)}
                      </td>
                      <td className="px-3 py-2">
                        <span
                          className={`rounded-full px-2 py-1 text-[10px] font-black ${getStatusLabelClass(
                            session.status,
                          )}`}
                        >
                          {session.status}
                        </span>
                      </td>
                      <td className="px-3 py-2 font-mono font-bold text-slate-600">
                        {shortId(session.paymentTransactionId)}
                      </td>
                      <td className="px-3 py-2 font-semibold text-slate-500">
                        {formatDate(session.updatedAt)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <p className="bg-slate-50 p-4 text-sm font-semibold text-slate-500">
              Belum ada session history.
            </p>
          )}
        </div>
      </div>
    </section>
  );
}
