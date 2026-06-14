import React, { useState } from 'react';
import { QrCode, Ticket, CheckCircle2, ShieldCheck, ArrowLeft } from 'lucide-react';
import { motion } from 'motion/react';
import { playRetroBeep } from '../utils/audio';
import { AdminSettings } from '../types';

interface PaymentScreenProps {
  adminSettings: AdminSettings;
  onPaymentSuccess: (voucherUsed?: string) => void;
  onBack: () => void;
  lang: 'ID' | 'EN' | 'JP';
}

const DICTIONARY = {
  ID: {
    title: "Registrasi Sesi",
    subtitle: "Pilih cara aktivasi untuk memulai sesi foto Anda",
    qrisHeader: "QRIS DYNAMIC PAYMENT",
    qrisInstruct: "Pindai QRIS menggunakan aplikasi e-wallet Anda (Gopay, OVO, Dana, LinkAja) untuk menyelesaikan pembayaran.",
    priceTag: "Total Pembayaran:",
    voucherHeader: "KODE VOUCHER SPONSOR",
    voucherPlaceholder: "Masukkan kode voucher...",
    voucherBtn: "KLAIM VOUCHER",
    simulateBtn: "SIMULASI BAYAR INSTAN",
    statusAwaiting: "Menunggu pembayaran terverifikasi...",
    backBtn: "Kembali ke Menu",
    couponSuccess: "Voucher berhasil! Sesi diaktivasi.",
    couponError: "Voucher tidak terdaftar atau kedaluwarsa!"
  },
  EN: {
    title: "Session Registration",
    subtitle: "Choose your activation option to begin shooting",
    qrisHeader: "QRIS DYNAMIC PAYMENT",
    qrisInstruct: "Scan the QRIS code with Indonesian e-wallets or standard banking app to fulfill session fees.",
    priceTag: "Total Session Fee:",
    voucherHeader: "SPONSOR VOUCHER CODE",
    voucherPlaceholder: "Enter promo or voucher...",
    voucherBtn: "CLAIM TICKET",
    simulateBtn: "SIMULATE PAID",
    statusAwaiting: "Awaiting incoming payment telemetry...",
    backBtn: "Back to Home",
    couponSuccess: "Ticket validated! Starting session.",
    couponError: "Invalid coupon or fully claimed!"
  },
  JP: {
    title: "プリクラお支払手続き",
    subtitle: "写真セッションを有効にするための決済を行ってください",
    qrisHeader: "QRIS 電子決済ゲートウェイ",
    qrisInstruct: "おサイフケータイ、GoPay、インドネシアのQRISアプリでスキャンしてお支払いください。",
    priceTag: "お支払い金額:",
    voucherHeader: "スポンサー引換コード",
    voucherPlaceholder: "クーポン券を入力...",
    voucherBtn: "コード検証",
    simulateBtn: "模擬決済を完了する",
    statusAwaiting: "入金確認シグナル待機中...",
    backBtn: "ウェルカム画面に戻る",
    couponSuccess: "引換券が確認されました！ご利用開始。",
    couponError: "無効なクーポンコードです！"
  }
};

export default function PaymentScreen({ adminSettings, onPaymentSuccess, onBack, lang }: PaymentScreenProps) {
  const dict = DICTIONARY[lang];
  const [voucherCode, setVoucherCode] = useState('');
  const [voucherError, setVoucherError] = useState(false);
  const [voucherSuccess, setVoucherSuccess] = useState(false);
  const [isProcessingQr, setIsProcessingQr] = useState(false);

  const handleVoucherSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const cleanCode = voucherCode.trim().toUpperCase();

    if (adminSettings.activeVouchers.includes(cleanCode)) {
      playRetroBeep('success');
      setVoucherSuccess(true);
      setVoucherError(false);
      setTimeout(() => {
        onPaymentSuccess(cleanCode);
      }, 1000);
    } else {
      playRetroBeep('shutter'); // buzz error sound equivalent
      setVoucherError(true);
      setVoucherSuccess(false);
      setTimeout(() => setVoucherError(false), 2500);
    }
  };

  const handleSimulatePayment = () => {
    playRetroBeep('success');
    setIsProcessingQr(true);
    setTimeout(() => {
      onPaymentSuccess('SIMULATED_QRIS');
    }, 1200);
  };

  return (
    <div className="flex-1 w-full bg-transparent flex flex-col justify-between p-4 sm:p-8 select-none text-stone-800">
      
      {/* Header Info */}
      <div className="flex items-center justify-between border-b border-[#F2E8DF] pb-3 shrink-0">
        <button 
          id="btn-back-to-welcome"
          onClick={() => { playRetroBeep('click'); onBack(); }}
          className="flex items-center gap-1.5 px-4 py-2 rounded-xl border border-[#F2E8DF] bg-white text-xs font-semibold text-stone-600 hover:text-stone-900 hover:border-[#FFB7C5] hover:shadow-sm cursor-pointer transition-all"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>{dict.backBtn}</span>
        </button>

        <div className="text-right">
          <h2 className="font-serif italic font-bold text-sm tracking-wide text-stone-900 uppercase">
            {dict.title}
          </h2>
          <p className="text-[10px] text-stone-400 font-mono mt-0.5 uppercase tracking-wider">
            Payment Terminal Active
          </p>
        </div>
      </div>

      {/* Main split dashboard panel */}
      <div className="flex-1 max-w-5xl w-full mx-auto flex flex-col md:flex-row items-stretch justify-center gap-6 my-auto py-4 overflow-y-auto custom-scrollbar">
        
        {/* Left Side: QRIS Interactive scanning column */}
        <div className="flex-1 bg-white border border-[#F2E8DF] shadow-[0_20px_50px_-15px_rgba(255,183,197,0.15)] p-6 rounded-3xl flex flex-col justify-between gap-5 transition-all">
          
          <div className="flex items-center gap-3 border-b border-[#F2E8DF] pb-3 shrink-0">
            <div className="w-9 h-9 rounded-2xl bg-rose-50 flex items-center justify-center border border-[#FFB7C5]/30">
              <QrCode className="w-4.5 h-4.5 text-[#FFB7C5]" />
            </div>
            <div>
              <h3 className="font-outfit font-extrabold text-xs tracking-wide text-stone-900 uppercase">
                {dict.qrisHeader}
              </h3>
              <p className="text-[9px] text-stone-450 font-mono uppercase tracking-tight">Merchant: MOMOPHOTO_KIOSK_CORP</p>
            </div>
          </div>

          <div className="flex-1 flex flex-col items-center justify-center gap-3.5 my-auto">
            
            {/* Dynamic visual price display tag */}
            <div className="bg-[#FFFDFB] border border-[#F2E8DF] px-4 py-3 rounded-2xl flex flex-col items-center text-center w-full max-w-xs shadow-sm">
              <span className="text-[10px] font-mono tracking-wider text-stone-500 uppercase font-bold">
                {dict.priceTag}
              </span>
              <span id="price-value" className="text-3xl font-serif italic font-extrabold text-[#2D2D2D] mt-0.5">
                {adminSettings.currencySymbol} {adminSettings.pricingIDR.toLocaleString('id-ID')}
              </span>
            </div>

            {/* Simulated QR Code box with overlay effect */}
            <div className="w-44 h-44 bg-white border border-[#F2E8DF] p-3 rounded-2xl relative overflow-hidden flex items-center justify-center shadow-sm group">
              
              {/* Scan Bar line running up and down, giving premium kiosk feels */}
              {!isProcessingQr && (
                <div className="absolute left-0 right-0 h-0.5 bg-[#FFB7C5] opacity-80 z-20 animate-bounce top-4"></div>
              )}

              {/* Dynamic QRIS Image mockup */}
              <img 
                src={adminSettings.qrisImageUrl} 
                alt="QRIS Code" 
                className={`w-full h-full object-contain ${isProcessingQr ? 'blur-[3px] opacity-40 scale-95 transition-all' : ''}`}
                referrerPolicy="no-referrer"
              />

              {/* Overlay simulation during scan */}
              {isProcessingQr && (
                <div className="absolute inset-0 bg-white/95 flex flex-col items-center justify-center gap-2 p-2 text-center">
                  <div className="w-8 h-8 rounded-full border-4 border-[#FFB7C5] border-t-transparent animate-spin"></div>
                  <span className="text-[10px] font-bold text-[#FFB7C5] font-mono uppercase tracking-wider">VERIFYING PIN...</span>
                </div>
              )}
            </div>

            <p className="text-[10px] leading-relaxed text-center px-4 text-stone-450 font-outfit">
              {dict.qrisInstruct}
            </p>
          </div>

          {/* Simulate Action buttons in light theme style */}
          <button 
            id="btn-simulate-cash"
            onClick={handleSimulatePayment}
            disabled={isProcessingQr}
            className="w-full bg-[#2D2D2D] hover:bg-[#FFB7C5] hover:text-stone-900 text-white font-outfit py-3.5 rounded-2xl text-xs font-bold transition-all shadow-md hover:shadow-[0_10px_20px_rgba(255,183,197,0.35)] flex items-center justify-center gap-1.5 cursor-pointer disabled:opacity-50"
          >
            <CheckCircle2 className="w-4 h-4 text-white fill-current" />
            <span>{isProcessingQr ? 'PROCESSING SESSION...' : dict.simulateBtn}</span>
          </button>
        </div>

        {/* Right Side: Sponsor ticket / voucher field */}
        <div className="flex-1 bg-white border border-[#F2E8DF] shadow-[0_20px_50px_-15px_rgba(255,183,197,0.15)] p-6 rounded-3xl flex flex-col justify-between gap-5 transition-all">
          
          <div>
            <div className="flex items-center gap-3 border-b border-[#F2E8DF] pb-3 mb-4">
              <div className="w-9 h-9 rounded-2xl bg-rose-50 flex items-center justify-center border border-[#FFB7C5]/30">
                <Ticket className="w-4.5 h-4.5 text-[#FFB7C5]" />
              </div>
              <div>
                <h3 className="font-outfit font-extrabold text-xs tracking-wide text-stone-900 uppercase">
                  {dict.voucherHeader}
                </h3>
                <p className="text-[9px] text-[#A0A0A0] font-mono uppercase tracking-wide">Claim free promo sessions</p>
              </div>
            </div>

            <p className="text-[11px] leading-relaxed text-stone-500 mb-4 font-outfit">
              Gunakan tiket voucher gratis dari penyelenggara acara, sponsor pernikahan, atau kode promosi event digital Anda.
            </p>

            <form onSubmit={handleVoucherSubmit} className="space-y-3">
              <div className="relative">
                <input 
                  id="input-voucher-code"
                  type="text"
                  placeholder={dict.voucherPlaceholder}
                  value={voucherCode}
                  onChange={(e) => setVoucherCode(e.target.value)}
                  className="w-full px-4 py-3 bg-stone-50/50 border border-[#F2E8DF] rounded-xl font-mono text-xs uppercase tracking-widest text-[#2D2D2D] focus:outline-none focus:border-[#FFB7C5] focus:bg-white transition-all font-bold"
                />
              </div>

              <button 
                id="btn-claim-voucher"
                type="submit"
                className="w-full bg-[#FFB7C5]/10 text-[#FFB7C5] hover:bg-[#FFB7C5] hover:text-stone-900 border border-[#FFB7C5]/30 font-outfit py-3.5 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer"
              >
                <Ticket className="w-4 h-4" />
                <span>{dict.voucherBtn}</span>
              </button>
            </form>

            {/* Error & Success States */}
            {voucherError && (
              <motion.div 
                id="voucher-err-tip"
                initial={{ opacity: 0, y: 5 }} 
                animate={{ opacity: 1, y: 0 }} 
                className="mt-3 p-2.5 bg-red-50/60 border border-red-155 rounded-xl text-[10px] text-red-600 font-semibold text-center"
              >
                ⚠️ {dict.couponError} (Contoh: <b>NEOBOOT2026</b>)
              </motion.div>
            )}

            {voucherSuccess && (
              <motion.div 
                id="voucher-success-tip"
                initial={{ opacity: 0, y: 5 }} 
                animate={{ opacity: 1, y: 0 }} 
                className="mt-3 p-2.5 bg-emerald-50 border border-emerald-250 rounded-xl text-[10px] text-emerald-800 font-extrabold text-center flex items-center justify-center gap-1.5 animate-pulse"
              >
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                <span>{dict.couponSuccess}</span>
              </motion.div>
            )}
          </div>

          {/* Quick Info Box */}
          <div className="bg-[#FFFDFB] p-3.5 rounded-2xl border border-[#F2E8DF] font-sans mt-auto">
            <span className="flex items-center gap-1.5 text-stone-500 text-[10px] font-bold">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-500" />
              SECURE TRANSACTION PROTOCOL
            </span>
            <p className="text-[9px] text-[#A0A0A0] leading-relaxed mt-1 font-mono">
              Voucher bypass terikat dengan lisensi terminal {adminSettings.printerModelName}. Hubungi admin event booth jika terjadi kegagalan hardware.
            </p>
          </div>

        </div>

      </div>

      {/* Footer step status */}
      <div className="text-center font-mono text-[9px] text-stone-400 pt-3 border-t border-[#F2E8DF] shrink-0 uppercase tracking-widest">
        Transaction gateway &middot; terminal live &middot; ready
      </div>

    </div>
  );
}
