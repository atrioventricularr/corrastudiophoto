import React, { useEffect, useMemo, useState } from 'react';
import {
  AlertTriangle,
  CheckCircle2,
  KeyRound,
  Loader2,
  Monitor,
  ShieldCheck,
  Trash2,
} from 'lucide-react';
import {
  clearDesktopLicenseCache,
  getDesktopDeviceInfo,
  isCorraDesktop,
  readDesktopLicenseCache,
  verifyDesktopLicense,
  type CorraDesktopDeviceInfo,
  type CorraVerifyLicenseResult,
} from '../lib/desktop-api';
import { useBrandTheme } from '../branding';

interface LicenseActivationScreenProps {
  onLicenseActivated: (result: CorraVerifyLicenseResult) => void;
}

export default function LicenseActivationScreen({
  onLicenseActivated,
}: LicenseActivationScreenProps) {
  const [licenseCode, setLicenseCode] = useState('');
  const [deviceInfo, setDeviceInfo] = useState<CorraDesktopDeviceInfo | null>(null);
  const [cachedLicense, setCachedLicense] = useState<CorraVerifyLicenseResult | null>(null);
  const [result, setResult] = useState<CorraVerifyLicenseResult | null>(null);
  const [isCheckingCache, setIsCheckingCache] = useState(true);
  const [isVerifying, setIsVerifying] = useState(false);
  const [isClearing, setIsClearing] = useState(false);
  const { brandConfig } = useBrandTheme();

  const desktopMode = useMemo(() => isCorraDesktop(), []);

  useEffect(() => {
    let isCancelled = false;

    async function boot() {
      setIsCheckingCache(true);

      try {
        const [info, cache] = await Promise.all([
          getDesktopDeviceInfo(),
          readDesktopLicenseCache(),
        ]);

        if (isCancelled) {
          return;
        }

        setDeviceInfo(info);
        setCachedLicense(cache);

        if (cache?.valid === true) {
          setResult(cache);
        }
      } finally {
        if (!isCancelled) {
          setIsCheckingCache(false);
        }
      }
    }

    boot();

    return () => {
      isCancelled = true;
    };
  }, []);

  const displayFingerprint = deviceInfo?.fingerprint
    ? `${deviceInfo.fingerprint.slice(0, 12)}...${deviceInfo.fingerprint.slice(-8)}`
    : 'Browser preview mode';

  const handleVerify = async () => {
    const sanitizedCode = licenseCode.trim();

    if (!sanitizedCode) {
      setResult({
        valid: false,
        reason: 'Masukkan kode lisensi terlebih dahulu.',
      });
      return;
    }

    setIsVerifying(true);
    setResult(null);

    try {
      const verifyResult = await verifyDesktopLicense({
        licenseCode: sanitizedCode,
      });

      setResult(verifyResult);

      if (verifyResult.valid) {
        setCachedLicense(verifyResult);
        onLicenseActivated(verifyResult);
      }
    } catch (error) {
      setResult({
        valid: false,
        reason: error instanceof Error ? error.message : 'Unknown activation error',
      });
    } finally {
      setIsVerifying(false);
    }
  };

  const handleUseCachedLicense = () => {
    if (cachedLicense?.valid === true) {
      onLicenseActivated(cachedLicense);
    }
  };

  const handleClearCache = async () => {
    setIsClearing(true);

    try {
      await clearDesktopLicenseCache();
      setCachedLicense(null);
      setResult({
        valid: false,
        reason: 'Cache lisensi lokal sudah dihapus.',
      });
    } finally {
      setIsClearing(false);
    }
  };

  const handleSkipBrowserPreview = () => {
    onLicenseActivated({
      valid: true,
      source: 'browser-preview',
      reason: 'Browser preview mode only.',
      checkedAt: new Date().toISOString(),
    });
  };

  return (
    <div className="flex-1 w-full min-h-[680px] bg-[#FFF8FB] relative overflow-hidden flex items-center justify-center p-6 select-none">
      <div className="absolute inset-0 pointer-events-none opacity-60">
        <div className="absolute -top-32 -left-32 w-96 h-96 rounded-full bg-pink-200 blur-3xl" />
        <div className="absolute -bottom-32 -right-32 w-96 h-96 rounded-full bg-rose-100 blur-3xl" />
        <div className="absolute top-20 right-24 w-48 h-48 rounded-full bg-yellow-100 blur-3xl" />
      </div>

      <div className="relative w-full max-w-5xl grid grid-cols-1 lg:grid-cols-[1.05fr_0.95fr] gap-6 items-stretch">
        <section className="bg-white/80 backdrop-blur border border-pink-100 rounded-[2rem] shadow-[0_24px_80px_rgba(244,114,182,0.18)] p-7 sm:p-9 flex flex-col justify-between">
          <div>
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-rose-50 border border-rose-100 text-rose-500 font-black text-xs tracking-[0.18em] uppercase mb-5">
              <ShieldCheck className="w-4 h-4" />
              Software License Required
            </div>

            <h1 className="font-serif italic text-4xl sm:text-5xl text-stone-900 leading-tight">
              Aktivasi {brandConfig.businessName}
            </h1>

            <p className="mt-4 text-stone-600 font-outfit leading-relaxed max-w-xl">
              Masukkan kode lisensi Mayar yang sudah dibeli customer. Lisensi akan
              diverifikasi ke server, lalu device ini akan di-bind ke lisensi tersebut.
            </p>

            <div className="mt-7 grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="rounded-3xl bg-[#FFF1F2] border border-rose-100 p-4">
                <div className="flex items-center gap-2 text-rose-500 font-black text-xs uppercase tracking-wider">
                  <Monitor className="w-4 h-4" />
                  Device
                </div>
                <p className="mt-2 font-mono text-[11px] break-all text-stone-700">
                  {displayFingerprint}
                </p>
              </div>

              <div className="rounded-3xl bg-[#F8FAFC] border border-stone-100 p-4">
                <div className="flex items-center gap-2 text-stone-500 font-black text-xs uppercase tracking-wider">
                  <KeyRound className="w-4 h-4" />
                  Mode
                </div>
                <p className="mt-2 font-outfit text-sm font-bold text-stone-800">
                  {desktopMode ? 'Electron Desktop' : 'Browser Preview'}
                </p>
              </div>
            </div>
          </div>

          <div className="mt-7 rounded-3xl border border-stone-100 bg-stone-50/80 p-4">
            <p className="text-xs font-outfit text-stone-500 leading-relaxed">
              API key Mayar/DOKU tidak disimpan di React UI. React hanya meminta
              Electron main process untuk memanggil backend yang aman.
            </p>
          </div>
        </section>

        <section className="bg-white border border-pink-100 rounded-[2rem] shadow-[0_24px_80px_rgba(0,0,0,0.08)] p-6 sm:p-8 flex flex-col">
          <div className="flex items-center justify-between gap-4 mb-5">
            <div>
              <h2 className="font-display font-black text-2xl text-stone-900">
                License Code
              </h2>
              <p className="font-outfit text-sm text-stone-500">
                Contoh: kode dari pembelian Mayar
              </p>
            </div>

            {isCheckingCache && (
              <Loader2 className="w-5 h-5 text-rose-400 animate-spin" />
            )}
          </div>

          <div className="space-y-4">
            <input
              value={licenseCode}
              onChange={(event) => setLicenseCode(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') {
                  handleVerify();
                }
              }}
              placeholder="Masukkan kode lisensi"
              className="w-full h-14 rounded-2xl border border-stone-200 bg-white px-4 font-mono text-sm tracking-wider text-stone-900 outline-none focus:border-rose-300 focus:ring-4 focus:ring-rose-100 transition"
              autoCapitalize="characters"
              spellCheck={false}
            />

            <button
              type="button"
              onClick={handleVerify}
              disabled={isVerifying || isCheckingCache}
              className="w-full h-14 rounded-2xl bg-stone-900 text-white font-display font-black tracking-wide shadow-lg shadow-stone-900/10 hover:scale-[1.01] active:scale-[0.99] disabled:opacity-60 disabled:hover:scale-100 transition flex items-center justify-center gap-2"
            >
              {isVerifying ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  VERIFYING...
                </>
              ) : (
                <>
                  <ShieldCheck className="w-5 h-5" />
                  ACTIVATE LICENSE
                </>
              )}
            </button>
          </div>

          {cachedLicense?.valid === true && (
            <div className="mt-5 rounded-3xl border border-emerald-100 bg-emerald-50 p-4">
              <div className="flex items-start gap-3">
                <CheckCircle2 className="w-5 h-5 text-emerald-600 mt-0.5 shrink-0" />
                <div className="flex-1">
                  <p className="font-black text-emerald-800 text-sm">
                    Lisensi valid tersimpan di device ini.
                  </p>
                  <p className="font-mono text-[11px] text-emerald-700 mt-1 break-all">
                    {cachedLicense.license?.licenseCode || 'ACTIVE LICENSE'}
                  </p>
                  <div className="mt-3 flex gap-2">
                    <button
                      type="button"
                      onClick={handleUseCachedLicense}
                      className="px-4 py-2 rounded-xl bg-emerald-600 text-white text-xs font-black"
                    >
                      USE CACHED LICENSE
                    </button>
                    <button
                      type="button"
                      onClick={handleClearCache}
                      disabled={isClearing}
                      className="px-4 py-2 rounded-xl bg-white border border-emerald-200 text-emerald-700 text-xs font-black flex items-center gap-1"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      CLEAR
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}

          {result && result.valid !== true && (
            <div className="mt-5 rounded-3xl border border-amber-100 bg-amber-50 p-4">
              <div className="flex items-start gap-3">
                <AlertTriangle className="w-5 h-5 text-amber-600 mt-0.5 shrink-0" />
                <div>
                  <p className="font-black text-amber-800 text-sm">
                    Aktivasi belum berhasil
                  </p>
                  <p className="text-amber-700 text-xs mt-1 leading-relaxed">
                    {result.reason || 'License verification failed.'}
                  </p>
                </div>
              </div>
            </div>
          )}

          {result?.valid === true && (
            <div className="mt-5 rounded-3xl border border-emerald-100 bg-emerald-50 p-4">
              <div className="flex items-start gap-3">
                <CheckCircle2 className="w-5 h-5 text-emerald-600 mt-0.5 shrink-0" />
                <div>
                  <p className="font-black text-emerald-800 text-sm">
                    Aktivasi berhasil
                  </p>
                  <p className="text-emerald-700 text-xs mt-1 leading-relaxed">
                    Device ini sudah siap menjalankan {brandConfig.businessName}.
                  </p>
                </div>
              </div>
            </div>
          )}

          {!desktopMode && (
            <div className="mt-auto pt-6">
              <button
                type="button"
                onClick={handleSkipBrowserPreview}
                className="w-full h-12 rounded-2xl border border-stone-200 bg-white text-stone-700 font-black text-sm hover:bg-stone-50 transition"
              >
                SKIP FOR BROWSER PREVIEW
              </button>
              <p className="text-[11px] text-stone-400 mt-2 text-center">
                Tombol ini hanya untuk preview browser. Di Electron tetap wajib aktivasi.
              </p>
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
