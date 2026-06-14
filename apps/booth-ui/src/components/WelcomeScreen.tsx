import React from 'react';
import { Sparkles, Camera, Heart, Play, Award } from 'lucide-react';
import { playRetroBeep } from '../utils/audio';

interface WelcomeScreenProps {
  onStart: () => void;
  lang: 'ID' | 'EN' | 'JP';
  setLang: (l: 'ID' | 'EN' | 'JP') => void;
}

const DICTIONARY = {
  ID: {
    greeting: "Selamat Datang di",
    tagline: "Aesthetic Selfie Photobooth",
    btnStart: "MULAI SEKARANG",
    subStart: "Sentuh layar untuk memulai sesi foto",
    features: ["4x Snap Slot", "Simulasi QRIS Instan", "Cetak Kertas Glossy", "Gratis Unduh GIF & Frame"],
    footerNote: "*Pastikan kamera aktif dan printer siap cetak di event Anda."
  },
  EN: {
    greeting: "Welcome to",
    tagline: "Aesthetic Selfie Photobooth",
    btnStart: "START DEBUT",
    subStart: "Touch screen to start your photo session",
    features: ["4x Snap Slots", "Instant QRIS Simulation", "Premium Glossy print", "Free GIF & Frame download"],
    footerNote: "*Make sure camera is active and event printer is online."
  },
  JP: {
    greeting: "ようこそ！プリクラ",
    tagline: "ヴィンテージ・レトロ セルフィー",
    btnStart: "プリ撮影をはじめる",
    subStart: "画面をタッチしてお祝いのポーズ!",
    features: ["4つのポーズ撮影", "インスタントQRコード", "光沢プリント", "GIF & フレーム無料DL"],
    footerNote: "*カメラをオンにして撮影の準備をしてください。"
  }
};

export default function WelcomeScreen({ onStart, lang, setLang }: WelcomeScreenProps) {
  const dict = DICTIONARY[lang];

  const handleStartClicked = () => {
    playRetroBeep('success');
    onStart();
  };

  return (
    <div className="flex-1 w-full bg-transparent relative flex flex-col justify-between p-6 sm:p-10 select-none overflow-hidden">
      
      {/* Dynamic year 2000s Japanese Moving Marquee/Banner at top */}
      <div className="w-full bg-[#FFF1F2] border-y border-[#FFB7C5]/30 py-2 overflow-hidden rotate-[-0.5deg] translate-y-1 shrink-0">
        <div className="whitespace-nowrap flex animate-marquee font-display font-medium text-xs text-[#E11D48] tracking-widest uppercase">
          <div className="flex gap-16">
            <span>✧ プリクラ CLUB DEBUT 2000s ✧</span>
            <span>★ SWEET RETRO NOSTALGIC ★</span>
            <span>✦ SELF SERVICE PHOTO STATION ✦</span>
            <span>♥ SMILE WITH US • SMILE WITH US ♥</span>
            <span>✧ TOKIMEKI SWEET PEACH ✧</span>
          </div>
          <div className="flex gap-16 px-16">
            <span>✧ プリクラ CLUB DEBUT 2000s ✧</span>
            <span>★ SWEET RETRO NOSTALGIC ★</span>
            <span>✦ SELF SERVICE PHOTO STATION ✦</span>
            <span>♥ SMILE WITH US • SMILE WITH US ♥</span>
            <span>✧ TOKIMEKI SWEET PEACH ✧</span>
          </div>
        </div>
      </div>

      {/* Main interactive center part */}
      <div className="flex-1 max-w-5xl mx-auto w-full flex flex-col lg:flex-row items-center justify-center gap-8 md:gap-16 my-auto pt-6">
        
        {/* Left column: Visual decoration featuring styled photobooth polaroids and Japanese retro aesthetics */}
        <div className="flex-1 flex flex-col items-center lg:items-start text-center lg:text-left">
          
          {/* Momo Brand Header decoration block */}
          <div className="flex items-center gap-4 mb-6">
            <div className="w-12 h-12 bg-white rounded-2xl shadow-sm flex items-center justify-center border border-[#F2E8DF] shrink-0">
              <div className="w-5 h-5 rounded-full bg-[#FFB7C5] ring-4 ring-[#FFB7C5]/20 animate-pulse"></div>
            </div>
            <div className="text-left">
              <h1 className="text-2xl sm:text-3xl font-display font-black text-[#2D2D2D] tracking-tight">
                MOMO PHOTO <span className="text-[#FFB7C5] text-lg sm:text-xl font-medium">モモフォト</span>
              </h1>
              <p className="text-[10px] uppercase tracking-[0.2em] text-[#A0A0A0] font-bold">Y2K Self-Service Studio • Est. 2004</p>
            </div>
          </div>

          <div className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full bg-[#FEF2F4] border border-[#FDA4AF]/35 text-rose-500 text-xs font-outfit font-bold tracking-wider mb-4">
            <Sparkles className="w-4 h-4 fill-rose-500 text-rose-500 animate-spin" style={{ animationDuration: '4s' }} />
            <span>2000s JP PURIKURA EXPERIENCE</span>
          </div>

          <h2 className="text-lg sm:text-xl font-serif italic text-stone-500 tracking-wide">
            {dict.greeting}
          </h2>
          
          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-serif italic font-light text-[#2D2D2D] tracking-tight leading-none mt-1">
            Momo Selfie Club ♡
          </h1>
          
          <p className="font-outfit text-stone-600 mt-3 text-sm sm:text-base leading-relaxed font-light">
            {dict.tagline}. {dict.subStart}.
          </p>

          {/* Bullet features styled as beautiful retro grid stickers */}
          <div className="grid grid-cols-2 gap-3.5 w-full mt-6 select-none max-w-md">
            {dict.features.map((feat, idx) => (
              <div 
                key={idx} 
                className="bg-white border border-[#F2E8DF] px-3.5 py-2.5 rounded-2xl shadow-[0_4px_12px_rgba(0,0,0,0.02)] hover:border-[#FFB7C5] transition-all flex items-center gap-2"
              >
                <div className="w-5 h-5 rounded-full bg-rose-50 flex items-center justify-center shrink-0">
                  <Heart className="w-3.5 h-3.5 text-[#FFB7C5] fill-[#FFB7C5]" />
                </div>
                <span className="font-outfit text-[11px] font-bold text-stone-700 tracking-tight leading-tight">
                  {feat}
                </span>
              </div>
            ))}
          </div>

          <p className="text-[10px] text-stone-400 font-mono mt-4 italic">
            {dict.footerNote}
          </p>
        </div>

        {/* Right column: Interactive START button container */}
        <div className="w-full max-w-sm shrink-0 flex flex-col items-center">
          
          {/* Aesthetic Photobooth Polaroid Card Frame Container */}
          <div className="bg-white p-6 rounded-[32px] shadow-[0_20px_50px_-15px_rgba(255,183,197,0.25)] border border-[#F2E8DF] w-full flex flex-col items-center relative">
            
            {/* Elegant ribbon tag */}
            <div className="absolute -top-3 bg-[#FFB7C5] text-white px-4 py-1 rounded-full text-[9px] font-bold tracking-widest uppercase shadow-sm">
              Sweet Studio
            </div>

            {/* Simulated Live Cam Stamp Bubble */}
            <div className="w-full aspect-[4/3] rounded-[24px] bg-[#FDF2F4] border border-[#FFB7C5]/30 relative overflow-hidden flex items-center justify-center p-3">
              <div className="absolute top-3.5 right-3.5 flex items-center gap-1.5 z-20">
                <span className="w-2.5 h-2.5 rounded-full bg-rose-500 animate-ping"></span>
                <span className="w-2.5 h-2.5 rounded-full bg-rose-500"></span>
                <span className="font-mono text-[9px] font-bold text-rose-500">LIVE PREVIEW</span>
              </div>

              {/* Looping camera avatar artwork inside frame */}
              <div className="flex flex-col items-center">
                <div className="w-16 h-16 rounded-full bg-rose-50 flex items-center justify-center border-2 border-[#FDA4AF] mb-3 relative animate-pulse">
                  <Camera className="w-7 h-7 text-rose-500" />
                  <Heart className="absolute bottom-0 right-0 w-5 h-5 text-indigo-400 fill-indigo-400" />
                </div>
                <span className="font-outfit text-xs font-semibold text-[#8C3C43] tracking-wide uppercase">
                  READY TO CAPTURE
                </span>
                <span className="font-mono text-[9px] text-[#A78B8E] mt-1">
                  16:9 HD WEBCAM PREVIEW
                </span>
              </div>
            </div>

            {/* The Big Touch-Friendly Start button */}
            <button 
              id="btn-big-start-kiosk"
              onClick={handleStartClicked}
              className="w-full mt-6 bg-[#2D2D2D] hover:bg-[#FFB7C5] hover:text-stone-900 text-white font-outfit py-4.5 rounded-3xl transition-all shadow-[0_10px_25px_rgba(45,45,45,0.25)] hover:shadow-[0_10px_25px_rgba(255,183,197,0.4)] hover:scale-[1.02] cursor-pointer font-bold tracking-widest text-center text-xs sm:text-sm uppercase relative overflow-hidden group"
            >
              <div className="absolute inset-0 bg-white/10 translate-y-[-100%] group-hover:translate-y-[0%] transition-transform duration-300"></div>
              <div className="flex items-center justify-center gap-2">
                <Play className="w-4 h-4 fill-current" />
                <span>{dict.btnStart}</span>
              </div>
            </button>

            {/* Sticker Text Label on Card */}
            <div className="mt-4 flex gap-1.5 items-center justify-center text-stone-400 font-mono text-[10px]">
              <span>SWEET SESSIONS</span>
              <span>•</span>
              <span className="font-semibold text-rose-400 font-sans">TAP HERE TO SMILE</span>
            </div>
          </div>
          
        </div>

      </div>

      {/* Language Toggle and Kiosk footer notes */}
      <div className="w-full border-t border-[#F2E8DF] pt-5 flex flex-col sm:flex-row items-center justify-between gap-4 shrink-0 mt-5">
        
        {/* Soft 3-State Language Bar */}
        <div className="flex bg-white p-1 rounded-2xl border border-[#F2E8DF] shadow-sm">
          <button 
            id="toggle-lang-id"
            onClick={() => { playRetroBeep('click'); setLang('ID'); }} 
            className={`px-3 py-1.5 rounded-xl font-outfit text-xs font-bold transition-all cursor-pointer ${lang === 'ID' ? 'bg-[#FFB7C5] text-stone-950 shadow-sm' : 'text-stone-500 hover:text-stone-900'}`}
          >
            Bahasa ID
          </button>
          <button 
            id="toggle-lang-en"
            onClick={() => { playRetroBeep('click'); setLang('EN'); }} 
            className={`px-3 py-1.5 rounded-xl font-outfit text-xs font-bold transition-all cursor-pointer ${lang === 'EN' ? 'bg-[#FFB7C5] text-stone-950 shadow-sm' : 'text-stone-500 hover:text-stone-900'}`}
          >
            English
          </button>
          <button 
            id="toggle-lang-jp"
            onClick={() => { playRetroBeep('click'); setLang('JP'); }} 
            className={`px-3 py-1.5 rounded-xl font-outfit text-xs font-bold transition-all cursor-pointer ${lang === 'JP' ? 'bg-[#FFB7C5] text-stone-950 shadow-sm' : 'text-stone-500 hover:text-stone-900'}`}
          >
            日本語
          </button>
        </div>

        <div className="flex items-center gap-2">
          <Award className="w-4 h-4 text-rose-400" />
          <span className="font-outfit text-stone-400 text-xs">
            Y2K Purikura Club // Premium Glossy Output
          </span>
        </div>

      </div>
    </div>
  );
}
