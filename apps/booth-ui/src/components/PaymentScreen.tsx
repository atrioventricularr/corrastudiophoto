import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  ArrowLeft,
  Banknote,
  CheckCircle2,
  CreditCard,
  ExternalLink,
  QrCode,
  ShieldCheck,
  Ticket,
} from 'lucide-react';
import { motion } from 'motion/react';
import { playRetroBeep } from '../utils/audio';
import { AdminSettings } from '../types';
import { usePaymentSettings, usePaymentTransactions } from '../payments';

interface PaymentScreenProps {
  adminSettings: AdminSettings;
  onPaymentSuccess: (voucherUsed?: string) => void;
  onBack: () => void;
  lang: 'ID' | 'EN' | 'JP';
}

const DICTIONARY = {
  ID: {
    title: 'Registrasi Sesi',
    subtitle: 'Selesaikan pembayaran untuk memulai sesi foto Anda',
    priceTag: 'Total Pembayaran',
    voucherHeader: 'Kode Voucher Sponsor',
    voucherPlaceholder: 'Masukkan kode voucher...',
    voucherBtn: 'Klaim Voucher',
    backBtn: 'Kembali ke Menu',
    couponSuccess: 'Voucher berhasil! Sesi diaktivasi.',
    couponError: 'Voucher tidak terdaftar atau kedaluwarsa!',
    confirmBtn: 'Konfirmasi Pembayaran',
    processingBtn: 'Memproses Sesi...',
    qrisHeader: 'Pembayaran QRIS',
    qrisInstruction: 'Scan QRIS menggunakan aplikasi bank atau e-wallet, lalu konfirmasi setelah pembayaran selesai.',
    manualHeader: 'Pembayaran Manual',
    dokuHeader: 'DOKU Dynamic QRIS',
    dokuInstruction: 'Dynamic QRIS DOKU akan dibuat otomatis setelah integrasi API phase berikutnya.',
    mayarHeader: 'Mayar Checkout',
    mayarInstruction: 'Buka halaman checkout Mayar, selesaikan pembayaran, lalu kembali ke booth.',
    noQris: 'QRIS belum diatur di Admin Panel.',
  },
  EN: {
    title: 'Session Registration',
    subtitle: 'Complete payment to begin your photo session',
    priceTag: 'Total Payment',
    voucherHeader: 'Sponsor Voucher Code',
    voucherPlaceholder: 'Enter voucher code...',
    voucherBtn: 'Claim Voucher',
    backBtn: 'Back to Home',
    couponSuccess: 'Voucher accepted! Session activated.',
    couponError: 'Invalid or expired voucher!',
    confirmBtn: 'Confirm Payment',
    processingBtn: 'Processing Session...',
    qrisHeader: 'QRIS Payment',
    qrisInstruction: 'Scan the QRIS using a banking or e-wallet app, then confirm after payment is complete.',
    manualHeader: 'Manual Payment',
    dokuHeader: 'DOKU Dynamic QRIS',
    dokuInstruction: 'DOKU Dynamic QRIS will be generated automatically after the API integration phase.',
    mayarHeader: 'Mayar Checkout',
    mayarInstruction: 'Open the Mayar checkout page, complete payment, then return to the booth.',
    noQris: 'QRIS has not been configured in Admin Panel.',
  },
  JP: {
    title: 'お支払い手続き',
    subtitle: '写真セッションを開始するにはお支払いを完了してください',
    priceTag: 'お支払い金額',
    voucherHeader: 'スポンサー引換コード',
    voucherPlaceholder: 'クーポン券を入力...',
    voucherBtn: 'コード検証',
    backBtn: '戻る',
    couponSuccess: 'クーポンが承認されました。',
    couponError: '無効または期限切れのクーポンです。',
    confirmBtn: '支払い確認',
    processingBtn: '処理中...',
    qrisHeader: 'QRIS決済',
    qrisInstruction: '銀行アプリまたは電子ウォレットでQRISをスキャンし、支払い完了後に確認してください。',
    manualHeader: '手動支払い',
    dokuHeader: 'DOKU Dynamic QRIS',
    dokuInstruction: 'DOKU Dynamic QRISは次のAPI連携フェーズで自動生成されます。',
    mayarHeader: 'Mayar Checkout',
    mayarInstruction: 'Mayarチェックアウトページで支払いを完了し、ブースに戻ってください。',
    noQris: 'QRISはまだ管理画面で設定されていません。',
  },
};

function formatRupiah(value: number): string {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
  }).format(value || 0);
}

function getPaymentSuccessCode(provider: string): string {
  if (provider === 'STATIC_QRIS') {
    return 'STATIC_QRIS_CONFIRMED';
  }

  if (provider === 'DOKU_QRIS') {
    return 'DOKU_QRIS_SIMULATED';
  }

  if (provider === 'MANUAL_CASH') {
    return 'MANUAL_CASH_CONFIRMED';
  }

  if (provider === 'MAYAR_CHECKOUT') {
    return 'MAYAR_CHECKOUT_CONFIRMED';
  }

  return 'PAYMENT_CONFIRMED';
}

export default function PaymentScreen({
  adminSettings,
  onPaymentSuccess,
  onBack,
  lang,
}: PaymentScreenProps) {
  const dict = DICTIONARY[lang];
  const { paymentConfig } = usePaymentSettings();
  const {
    createPaymentTransaction,
    confirmPaymentTransaction,
    cancelPaymentTransaction,
  } = usePaymentTransactions();
  const transactionIdRef = useRef<string | null>(null);

  const [voucherCode, setVoucherCode] = useState('');
  const [voucherError, setVoucherError] = useState(false);
  const [voucherSuccess, setVoucherSuccess] = useState(false);
  const [isProcessingPayment, setIsProcessingPayment] = useState(false);

  const activeVouchers = useMemo(() => {
    return Array.isArray(adminSettings.activeVouchers)
      ? adminSettings.activeVouchers
      : [];
  }, [adminSettings.activeVouchers]);

  const effectivePrice = paymentConfig.priceIdr || adminSettings.pricingIDR || 0;
  const effectiveMerchantName =
    paymentConfig.merchantName ||
    paymentConfig.staticQris.merchantName ||
    'Corra Studio';

  const effectiveQrisImageUrl =
    paymentConfig.staticQris.imageUrl || adminSettings.qrisImageUrl || '';

  const currentProvider = paymentConfig.provider;


  useEffect(() => {
    if (transactionIdRef.current) {
      return;
    }

    const transaction = createPaymentTransaction({
      provider: paymentConfig.provider,
      amountIdr: paymentConfig.priceIdr || adminSettings.pricingIDR || 0,
      merchantName:
        paymentConfig.merchantName ||
        paymentConfig.staticQris.merchantName ||
        'Corra Studio',
      metadata: {
        screen: 'PaymentScreen',
        qrisConfigured: Boolean(
          paymentConfig.staticQris.imageUrl || adminSettings.qrisImageUrl,
        ),
        dokuEnvironment: paymentConfig.doku.environment,
      },
    });

    transactionIdRef.current = transaction.id;

    return () => {
      if (transactionIdRef.current) {
        cancelPaymentTransaction(
          transactionIdRef.current,
          'left_payment_screen_before_confirmation',
        );
      }
    };
  }, [
    adminSettings.pricingIDR,
    adminSettings.qrisImageUrl,
    cancelPaymentTransaction,
    createPaymentTransaction,
    paymentConfig.doku.environment,
    paymentConfig.merchantName,
    paymentConfig.priceIdr,
    paymentConfig.provider,
    paymentConfig.staticQris.imageUrl,
    paymentConfig.staticQris.merchantName,
  ]);

  const handleVoucherSubmit = (event: React.FormEvent) => {
    event.preventDefault();

    const cleanCode = voucherCode.trim().toUpperCase();

    if (!cleanCode) {
      setVoucherError(true);
      setVoucherSuccess(false);
      return;
    }

    if (activeVouchers.includes(cleanCode)) {
      playRetroBeep('success');
      setVoucherSuccess(true);
      setVoucherError(false);

      setTimeout(() => {
        if (transactionIdRef.current) {
          confirmPaymentTransaction(transactionIdRef.current, {
            status: 'voucher_used',
            voucherCode: cleanCode,
            confirmationCode: `VOUCHER_${cleanCode}`,
            metadata: {
              voucherValidatedAt: new Date().toISOString(),
            },
          });
        }

        onPaymentSuccess(cleanCode);
      }, 900);
    } else {
      playRetroBeep('shutter');
      setVoucherError(true);
      setVoucherSuccess(false);
      setTimeout(() => setVoucherError(false), 2500);
    }
  };

  const handleConfirmPayment = () => {
    playRetroBeep('success');
    setIsProcessingPayment(true);

    const confirmationCode = getPaymentSuccessCode(currentProvider);

    setTimeout(() => {
      if (transactionIdRef.current) {
        confirmPaymentTransaction(transactionIdRef.current, {
          status: 'confirmed',
          confirmationCode,
          metadata: {
            confirmedBy: paymentConfig.requireOperatorConfirmation
              ? 'operator_manual_confirmation'
              : 'customer_self_confirmation',
            confirmedAtProvider: currentProvider,
          },
        });
      }

      onPaymentSuccess(confirmationCode);
    }, 1000);
  };

  const handleOpenMayarCheckout = () => {
    if (!paymentConfig.mayarCheckout.checkoutUrl) {
      return;
    }

    window.open(paymentConfig.mayarCheckout.checkoutUrl, '_blank', 'noopener,noreferrer');
  };

  return (
    <div className="flex-1 w-full bg-transparent flex flex-col justify-between p-4 sm:p-8 select-none text-[var(--corra-text)]">
      <div className="flex items-center justify-between border-b border-[var(--corra-border)] pb-3 shrink-0">
        <button
          id="btn-back-to-welcome"
          onClick={() => {
            playRetroBeep('click');
            onBack();
          }}
          className="flex items-center gap-1.5 px-4 py-2 rounded-xl border border-[var(--corra-border)] bg-white text-xs font-semibold text-[var(--corra-muted)] hover:text-[var(--corra-text)] hover:shadow-sm cursor-pointer transition-all"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>{dict.backBtn}</span>
        </button>

        <div className="text-right">
          <h2 className="corra-heading font-black text-sm tracking-wide text-[var(--corra-text)] uppercase">
            {dict.title}
          </h2>
          <p className="text-[10px] text-[var(--corra-muted)] font-mono mt-0.5 uppercase tracking-wider">
            {dict.subtitle}
          </p>
        </div>
      </div>

      <div className="flex-1 max-w-5xl w-full mx-auto flex flex-col md:flex-row items-stretch justify-center gap-6 my-auto py-4 overflow-y-auto custom-scrollbar">
        <div className="flex-1 bg-[var(--corra-surface)] border border-[var(--corra-border)] shadow-[0_20px_50px_-15px_rgba(0,0,0,0.16)] p-6 rounded-3xl flex flex-col justify-between gap-5 transition-all">
          <div className="flex items-center gap-3 border-b border-[var(--corra-border)] pb-3 shrink-0">
            <div className="w-10 h-10 rounded-2xl bg-[var(--corra-primary-soft)] flex items-center justify-center border border-[var(--corra-border)]">
              {currentProvider === 'MANUAL_CASH' ? (
                <Banknote className="w-5 h-5 text-[var(--corra-primary)]" />
              ) : currentProvider === 'MAYAR_CHECKOUT' ? (
                <CreditCard className="w-5 h-5 text-[var(--corra-primary)]" />
              ) : (
                <QrCode className="w-5 h-5 text-[var(--corra-primary)]" />
              )}
            </div>

            <div>
              <h3 className="font-black text-xs tracking-wide text-[var(--corra-text)] uppercase">
                {currentProvider === 'STATIC_QRIS' && dict.qrisHeader}
                {currentProvider === 'DOKU_QRIS' && dict.dokuHeader}
                {currentProvider === 'MANUAL_CASH' && dict.manualHeader}
                {currentProvider === 'MAYAR_CHECKOUT' && dict.mayarHeader}
              </h3>
              <p className="text-[9px] text-[var(--corra-muted)] font-mono uppercase tracking-tight">
                Merchant: {effectiveMerchantName}
              </p>
            </div>
          </div>

          <div className="flex-1 flex flex-col items-center justify-center gap-4 my-auto">
            <div className="bg-white border border-[var(--corra-border)] px-4 py-3 rounded-2xl flex flex-col items-center text-center w-full max-w-xs shadow-sm">
              <span className="text-[10px] font-mono tracking-wider text-[var(--corra-muted)] uppercase font-bold">
                {dict.priceTag}
              </span>
              <span
                id="price-value"
                className="text-3xl corra-heading font-black text-[var(--corra-text)] mt-0.5"
              >
                {formatRupiah(effectivePrice)}
              </span>
            </div>

            {currentProvider === 'STATIC_QRIS' && (
              <>
                <div className="w-52 h-52 bg-white border border-[var(--corra-border)] p-3 rounded-2xl relative overflow-hidden flex items-center justify-center shadow-sm">
                  {!isProcessingPayment && effectiveQrisImageUrl && (
                    <div className="absolute left-0 right-0 h-0.5 bg-[var(--corra-primary)] opacity-80 z-20 animate-bounce top-4" />
                  )}

                  {effectiveQrisImageUrl ? (
                    <img
                      src={effectiveQrisImageUrl}
                      alt="QRIS Code"
                      className={`w-full h-full object-contain ${
                        isProcessingPayment
                          ? 'blur-[3px] opacity-40 scale-95 transition-all'
                          : ''
                      }`}
                      referrerPolicy="no-referrer"
                    />
                  ) : (
                    <div className="text-center px-4">
                      <QrCode className="mx-auto mb-3 w-14 h-14 text-[var(--corra-muted)]" />
                      <p className="text-xs font-bold text-[var(--corra-muted)]">
                        {dict.noQris}
                      </p>
                    </div>
                  )}

                  {isProcessingPayment && (
                    <div className="absolute inset-0 bg-white/95 flex flex-col items-center justify-center gap-2 p-2 text-center">
                      <div className="w-8 h-8 rounded-full border-4 border-[var(--corra-primary)] border-t-transparent animate-spin" />
                      <span className="text-[10px] font-bold text-[var(--corra-primary)] font-mono uppercase tracking-wider">
                        Verifying...
                      </span>
                    </div>
                  )}
                </div>

                <p className="text-[11px] leading-relaxed text-center px-4 text-[var(--corra-muted)]">
                  {paymentConfig.staticQris.notes || dict.qrisInstruction}
                </p>
              </>
            )}

            {currentProvider === 'DOKU_QRIS' && (
              <div className="w-full max-w-md rounded-3xl border border-blue-100 bg-blue-50 p-6 text-center text-blue-900">
                <QrCode className="mx-auto mb-4 w-20 h-20" />
                <p className="text-sm font-black">Dynamic QRIS Placeholder</p>
                <p className="mt-2 text-xs leading-relaxed">
                  {dict.dokuInstruction}
                </p>
                <p className="mt-3 text-[10px] font-bold uppercase tracking-wider">
                  {paymentConfig.doku.environment} · Client ID{' '}
                  {paymentConfig.doku.clientId ? 'set' : 'not set'} · Secret{' '}
                  {paymentConfig.doku.isCredentialConfigured ? 'set' : 'not set'}
                </p>
              </div>
            )}

            {currentProvider === 'MANUAL_CASH' && (
              <div className="w-full max-w-md rounded-3xl border border-[var(--corra-border)] bg-white p-6 text-center">
                <Banknote className="mx-auto mb-4 w-20 h-20 text-[var(--corra-primary)]" />
                <p className="text-sm font-black">{dict.manualHeader}</p>
                <p className="mt-2 text-xs leading-relaxed text-[var(--corra-muted)]">
                  {paymentConfig.manualCash.instructions}
                </p>
              </div>
            )}

            {currentProvider === 'MAYAR_CHECKOUT' && (
              <div className="w-full max-w-md rounded-3xl border border-purple-100 bg-purple-50 p-6 text-center text-purple-900">
                <CreditCard className="mx-auto mb-4 w-20 h-20" />
                <p className="text-sm font-black">{dict.mayarHeader}</p>
                <p className="mt-2 text-xs leading-relaxed">
                  {dict.mayarInstruction}
                </p>

                {paymentConfig.mayarCheckout.checkoutUrl ? (
                  <button
                    type="button"
                    onClick={handleOpenMayarCheckout}
                    className="mt-4 inline-flex items-center justify-center gap-2 rounded-2xl bg-purple-700 px-5 py-3 text-xs font-black text-white"
                  >
                    Open Checkout
                    <ExternalLink className="w-4 h-4" />
                  </button>
                ) : (
                  <p className="mt-4 text-xs font-bold">
                    Checkout URL belum diisi di Admin Panel.
                  </p>
                )}
              </div>
            )}
          </div>

          <button
            id="btn-confirm-payment"
            onClick={handleConfirmPayment}
            disabled={isProcessingPayment}
            className="w-full bg-[var(--corra-text)] hover:bg-[var(--corra-primary)] text-white font-black py-3.5 rounded-2xl text-xs transition-all shadow-md flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
          >
            <CheckCircle2 className="w-4 h-4 text-white fill-current" />
            <span>
              {isProcessingPayment ? dict.processingBtn : dict.confirmBtn}
            </span>
          </button>
        </div>

        <div className="flex-1 bg-[var(--corra-surface)] border border-[var(--corra-border)] shadow-[0_20px_50px_-15px_rgba(0,0,0,0.16)] p-6 rounded-3xl flex flex-col justify-between gap-5 transition-all">
          <div>
            <div className="flex items-center gap-3 border-b border-[var(--corra-border)] pb-3 mb-4">
              <div className="w-10 h-10 rounded-2xl bg-[var(--corra-primary-soft)] flex items-center justify-center border border-[var(--corra-border)]">
                <Ticket className="w-5 h-5 text-[var(--corra-primary)]" />
              </div>

              <div>
                <h3 className="font-black text-xs tracking-wide text-[var(--corra-text)] uppercase">
                  {dict.voucherHeader}
                </h3>
                <p className="text-[9px] text-[var(--corra-muted)] font-mono uppercase tracking-wide">
                  Claim promo or sponsor session
                </p>
              </div>
            </div>

            <p className="text-[11px] leading-relaxed text-[var(--corra-muted)] mb-4">
              Gunakan tiket voucher gratis dari penyelenggara acara, sponsor,
              wedding organizer, atau kode promosi event digital.
            </p>

            <form onSubmit={handleVoucherSubmit} className="space-y-3">
              <input
                id="input-voucher-code"
                type="text"
                placeholder={dict.voucherPlaceholder}
                value={voucherCode}
                onChange={(event) => setVoucherCode(event.target.value)}
                className="w-full px-4 py-3 bg-white border border-[var(--corra-border)] rounded-xl font-mono text-xs uppercase tracking-widest text-[var(--corra-text)] focus:outline-none focus:border-[var(--corra-primary)] transition-all font-bold"
              />

              <button
                id="btn-claim-voucher"
                type="submit"
                className="w-full bg-[var(--corra-primary-soft)] text-[var(--corra-primary)] hover:bg-[var(--corra-primary)] hover:text-white border border-[var(--corra-border)] py-3.5 rounded-xl text-xs font-black transition-all flex items-center justify-center gap-2 cursor-pointer"
              >
                <Ticket className="w-4 h-4" />
                <span>{dict.voucherBtn}</span>
              </button>
            </form>

            {voucherError && (
              <motion.div
                id="voucher-err-tip"
                initial={{ opacity: 0, y: 5 }}
                animate={{ opacity: 1, y: 0 }}
                className="mt-3 p-3 bg-red-50 border border-red-200 rounded-xl text-[10px] text-red-600 font-semibold text-center"
              >
                ⚠️ {dict.couponError}
              </motion.div>
            )}

            {voucherSuccess && (
              <motion.div
                id="voucher-success-tip"
                initial={{ opacity: 0, y: 5 }}
                animate={{ opacity: 1, y: 0 }}
                className="mt-3 p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-[10px] text-emerald-800 font-extrabold text-center flex items-center justify-center gap-2 animate-pulse"
              >
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                <span>{dict.couponSuccess}</span>
              </motion.div>
            )}
          </div>

          <div className="bg-white p-4 rounded-2xl border border-[var(--corra-border)] mt-auto">
            <span className="flex items-center gap-2 text-[var(--corra-muted)] text-[10px] font-bold">
              <ShieldCheck className="w-4 h-4 text-emerald-500" />
              PAYMENT SETTINGS CONNECTED
            </span>
            <p className="text-[9px] text-[var(--corra-muted)] leading-relaxed mt-1 font-mono">
              Provider: {currentProvider} · Terminal:{' '}
              {adminSettings.printerModelName || 'Corra Booth'}
            </p>
          </div>
        </div>
      </div>

      <div className="text-center font-mono text-[9px] text-[var(--corra-muted)] pt-3 border-t border-[var(--corra-border)] shrink-0 uppercase tracking-widest">
        Payment terminal · {currentProvider} · ready
      </div>
    </div>
  );
}
