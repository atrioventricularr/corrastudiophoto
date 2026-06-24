import React, { useMemo } from 'react';

export function BoothReleaseManifestPanel() {
  const manifest = useMemo(() => {
    return {
      appName: 'Corra Booth',
      version: import.meta.env.VITE_CORRA_APP_VERSION || '0.0.0-dev',
      buildId: import.meta.env.VITE_CORRA_BUILD_ID || 'local-dev',
      channel: import.meta.env.VITE_CORRA_RELEASE_CHANNEL || 'dev',
      commit: import.meta.env.VITE_CORRA_COMMIT || 'unknown',
      builtAt: import.meta.env.VITE_CORRA_BUILT_AT || 'runtime',
    };
  }, []);

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">Release Manifest</p>
      <pre className="mt-4 overflow-auto rounded-2xl bg-black/40 p-3 text-[11px] font-bold text-white/60">
        {JSON.stringify(manifest, null, 2)}
      </pre>
    </section>
  );
}
