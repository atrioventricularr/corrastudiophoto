import React, { useState, useEffect } from 'react';
import { Printer, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { playRetroBeep } from '../utils/audio';

interface ProcessingScreenProps {
  onComplete: () => void;
  lang: 'ID' | 'EN' | 'JP';
}

const DICTIONARY = {
  ID: {
    statusInit: "Menginisiasi Printer Dye-Sublimation...",
    statusProcessing: "Menggabungkan foto ke frame Retro-Clean...",
    statusSaving: "Mengunggah unduhan digital GIF...",
    statusFinal: "Sentuhan akhir & pembuatan QR Code...",
    developing: "MENGEMBANGKAN FOTO MINI...",
    readyNote: "Harap berdiri di samping slot dispenser kertas!"
  },
  EN: {
    title: "Processing Snaps",
    statusInit: "Initializing Dye-Sublimation Thermal Printer...",
    statusProcessing: "Stitching captured poses into template layouts...",
    statusSaving: "Uploading digital GIF animation telemetry...",
    statusFinal: "Adding final gloss coating & QR links...",
    developing: "DEVELOPING PHOTO CLUB SHEET...",
    readyNote: "Please stand next to the paper output slot!"
  },
  JP: {
    title: "開発中...",
    statusInit: "昇華型プリンターをウォームアップ中...",
    statusProcessing: "キャプチャ写真をフレームにステッチ...",
    statusSaving: "GIFアニメーションをアップロード中...",
    statusFinal: "光沢ラミネート加工とQRコードを発行中...",
    developing: "プリシートプリント作成中...",
    readyNote: "プリント出口の横でお受け取りの準備をしてください"
  }
};

export default function ProcessingScreen({ onComplete, lang }: ProcessingScreenProps) {
  const dict = DICTIONARY[lang];
  const [progress, setProgress] = useState<number>(0);
  const [activeStepText, setActiveStepText] = useState<string>(dict.statusInit);

  useEffect(() => {
    // Sound effect looped lightly
    playRetroBeep('click');
    const soundTimer = setInterval(() => {
      playRetroBeep('click');
    }, 700);

    const timer = setInterval(() => {
      setProgress((prev) => {
        const next = prev + 5;
        
        // Update stage messages based on percentage progression
        if (next < 25) {
          setActiveStepText(dict.statusInit);
        } else if (next >= 25 && next < 55) {
          setActiveStepText(dict.statusProcessing);
        } else if (next >= 55 && next < 80) {
          setActiveStepText(dict.statusSaving);
        } else {
          setActiveStepText(dict.statusFinal);
        }

        if (next >= 100) {
          clearInterval(timer);
          clearInterval(soundTimer);
          playRetroBeep('success');
          setTimeout(() => {
            onComplete();
          }, 300);
          return 100;
        }
        return next;
      });
    }, 150);

    return () => {
      clearInterval(timer);
      clearInterval(soundTimer);
    };
  }, []);

  return (
    <div className="flex-1 w-full bg-transparent flex flex-col items-center justify-center p-6 select-none relative overflow-hidden">
      
      {/* Decorative starry circles bouncing behind */}
      <div className="absolute top-[20%] left-[20%] text-[#FFB7C5] pointer-events-none text-2xl font-mono animate-bounce font-bold">★</div>
      <div className="absolute bottom-[20%] right-[22%] text-[#BDE0FE] pointer-events-none text-xl font-mono animate-bounce font-bold">★</div>

      {/* Retro processing card box */}
      <div className="w-full max-w-md bg-white border border-[#F2E8DF] p-8 rounded-[32px] shadow-[0_20px_50px_-15px_rgba(255,183,197,0.25)] flex flex-col items-center relative z-10 transition-all">
        
        {/* Keychain ring icon overlay */}
        <div className="w-16 h-16 rounded-full bg-rose-50 border border-[#FFB7C5]/30 flex items-center justify-center mb-6 relative">
          <Printer className="w-7 h-7 text-[#FFB7C5]" />
          <span className="absolute -top-1 -right-1 bg-[#FFB7C5] text-stone-900 font-extrabold text-[8px] px-2 py-0.5 rounded-full shadow-sm">
            FINE
          </span>
        </div>

        <h2 className="font-serif italic font-bold text-sm text-stone-900 tracking-widest uppercase mb-1">
          {dict.developing}
        </h2>
        
        <p className="font-outfit text-[#FF7E8D] text-xs font-semibold uppercase tracking-wider mb-8 flex items-center gap-1.5 justify-center">
          <Loader2 className="w-4 h-4 text-rose-500 animate-spin" />
          <span>PROGRESS {progress}%</span>
        </p>

        {/* Cute customized progress track */}
        <div className="w-full h-5 bg-stone-50 border border-[#F2E8DF] rounded-full overflow-hidden p-0.5 relative shadow-inner">
          <motion.div 
            id="processing-progressbar-fill"
            className="h-full bg-gradient-to-r from-[#FFB7C5] to-[#FF7E8D] rounded-full"
            style={{ width: `${progress}%` }}
            transition={{ duration: 0.1 }}
          ></motion.div>
        </div>

        {/* Step log descriptor text */}
        <div className="mt-6 font-mono text-[10px] text-stone-550 bg-[#FFFDFB] border border-[#F2E8DF] p-3.5 rounded-2xl w-full min-h-[50px] flex items-center gap-2">
          <span className="w-1.5 h-1.5 rounded-full bg-[#FF7E8D] shrink-0"></span>
          <span id="progressbar-stage-text" className="leading-relaxed whitespace-pre-line">{activeStepText}</span>
        </div>

        <div className="mt-5 border-t border-stone-50 w-full pt-4 text-center">
          <span className="text-[9px] text-[#A78B8E] mt-1 font-mono uppercase tracking-wide block leading-none">
            {dict.readyNote}
          </span>
        </div>

      </div>

    </div>
  );
}
