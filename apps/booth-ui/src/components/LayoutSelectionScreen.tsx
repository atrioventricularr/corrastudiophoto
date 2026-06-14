import React from 'react';
import { Layout, Sparkles, User, Users, Camera, ArrowLeft } from 'lucide-react';
import { LayoutOptions, LayoutType } from '../types';
import { playRetroBeep } from '../utils/audio';

interface LayoutSelectionScreenProps {
  layouts: LayoutOptions[];
  selectedLayout: LayoutType;
  onSelectLayout: (id: LayoutType) => void;
  onNext: () => void;
  onBack: () => void;
  lang: 'ID' | 'EN' | 'JP';
}

const DICTIONARY = {
  ID: {
    title: "Pilih Jumlah Foto",
    subtitle: "Pilih layout kolase strip yang ingin Anda cetak & simpan",
    nextBtn: "Pilih Frame Template",
    tagline: "Desain Layout Strip",
    slots: "Foto",
    backBtn: "Kembali"
  },
  EN: {
    title: "Choose Layout Size",
    subtitle: "Select the photo frame layout collage for printing & saving",
    nextBtn: "Choose Frame Template",
    tagline: "Layout Border Formats",
    slots: "Snaps",
    backBtn: "Back"
  },
  JP: {
    title: "レイアウトサイズ選択",
    subtitle: "プリントして保存する写真のレイアウトを選択してください",
    nextBtn: "フレーム選択へ進む",
    tagline: "用紙レイアウト設定",
    slots: "ショット",
    backBtn: "戻る"
  }
};

export default function LayoutSelectionScreen({
  layouts,
  selectedLayout,
  onSelectLayout,
  onNext,
  onBack,
  lang
}: LayoutSelectionScreenProps) {
  const dict = DICTIONARY[lang];

  const handleCardClick = (id: LayoutType) => {
    playRetroBeep('select');
    onSelectLayout(id);
  };

  const currentLayoutObj = layouts.find(l => l.id === selectedLayout);

  return (
    <div className="flex-1 w-full bg-transparent flex flex-col justify-between p-4 sm:p-8 select-none text-stone-800">
      
      {/* Header Info */}
      <div className="flex items-center justify-between border-b border-[#F2E8DF] pb-3 shrink-0">
        <button 
          id="btn-back-to-payment"
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
            Layout: {selectedLayout}
          </p>
        </div>
      </div>

      {/* Main Interactive Grid Card Selectors */}
      <div className="flex-1 w-full max-w-5xl mx-auto flex flex-col lg:flex-row items-center justify-center gap-6 my-auto py-4 overflow-y-auto custom-scrollbar">
        
        {/* Left Column: Grid Options */}
        <div className="flex-1 w-full grid grid-cols-1 sm:grid-cols-2 gap-4">
          {layouts.map((layout) => {
            const isSelected = selectedLayout === layout.id;
            
            // Choose responsive icon based on layout size
            let layoutIcon = <User className="w-4 h-4 text-[#FFB7C5]" />;
            if (layout.slots >= 6) {
              layoutIcon = <Users className="w-4 h-4 text-indigo-400" />;
            } else if (layout.slots === 4) {
              layoutIcon = <Layout className="w-4 h-4 text-emerald-400" />;
            }

            return (
              <div 
                id={`layout-card-${layout.id}`}
                key={layout.id}
                onClick={() => handleCardClick(layout.id)}
                className={`p-5 rounded-3xl border cursor-pointer select-none transition-all duration-300 flex items-start gap-4.5 w-full bg-white relative ${
                  isSelected 
                    ? 'border-[#FFB7C5] bg-rose-50/15 shadow-[0_12px_30px_rgba(255,183,197,0.25)] scale-[1.01]' 
                     : 'border-[#F2E8DF] hover:border-[#FFB7C5]/60 hover:bg-stone-50/30 shadow-[0_4px_12px_rgba(0,0,0,0.01)]'
                }`}
              >
                <div className={`p-2.5 rounded-2xl border ${isSelected ? 'bg-rose-50 border-[#FFB7C5]' : 'bg-stone-50 border-[#F2E8DF]'}`}>
                  {layoutIcon}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-outfit font-extrabold text-sm text-stone-900 truncate">
                      {layout.name}
                    </h3>
                  </div>

                  <p className="text-[10px] text-stone-500 mt-1 leading-relaxed font-outfit line-clamp-2">
                    {layout.description}
                  </p>

                  <div className="flex gap-1.5 items-center mt-2.5 select-none animate-fade-in">
                    <span className="text-[9px] font-mono font-bold bg-[#FFB7C5] text-stone-900 px-2.5 py-0.5 rounded-full">
                      {layout.slots} {dict.slots}
                    </span>
                    <span className="text-[9px] font-mono font-semibold bg-stone-50 text-stone-500 px-2.5 py-0.5 border border-[#F2E8DF] rounded-full">
                      Ratio {layout.aspectRatio}
                    </span>
                  </div>
                </div>

                {/* Animated Cute tick badge */}
                {isSelected && (
                  <div className="absolute top-3.5 right-3.5 w-5 h-5 rounded-full bg-[#FFB7C5] border border-white flex items-center justify-center shadow-sm">
                    <span className="text-[9px] text-stone-900 font-black">✓</span>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Right Column: High Visual Layout Blueprint Preview */}
        <div className="w-full lg:w-80 shrink-0 flex justify-center">
          <div className="bg-white p-6 rounded-[32px] shadow-[0_20px_50px_-15px_rgba(255,183,197,0.2)] border border-[#F2E8DF] w-full flex flex-col items-center">
            
            <div className="w-full border-b border-dashed border-[#F2E8DF] pb-2 mb-3 text-center">
              <span className="text-[10px] font-mono tracking-widest text-[#FFB7C5] font-bold">
                LAYOUT PREVIEW
              </span>
            </div>

            {/* Simulated Live Grid Blueprint Card */}
            <div className="bg-[#FFFDFB] border border-[#F2E8DF] p-3 rounded-2xl flex flex-col items-center justify-center min-h-[220px] w-full transition-all duration-300">
              {currentLayoutObj && (
                <div 
                  className="bg-white border border-[#F2E8DF] shadow-[0_8px_20px_rgba(0,0,0,0.02)] p-2.5 rounded-xl flex flex-col items-center justify-between"
                  style={{ 
                    width: '140px', 
                     height: '240px',
                  }}
                >
                  {/* Grid cells renderer */}
                  <div className="grid gap-1.5 w-full h-[85%] self-stretch" style={{
                    gridTemplateColumns: `repeat(${currentLayoutObj.gridCols}, minmax(0, 1fr))`,
                    gridTemplateRows: `repeat(${currentLayoutObj.gridRows}, minmax(0, 1fr))`
                  }}>
                    {Array.from({ length: currentLayoutObj.slots }).map((_, i) => (
                      <div key={i} className="border border-dashed border-[#FFB7C5]/40 bg-stone-50 rounded-lg flex items-center justify-center relative overflow-hidden">
                        <span className="text-[9px] font-mono text-stone-400 font-bold">#{i+1}</span>
                      </div>
                    ))}
                  </div>

                  {/* Stamp Footer simulated */}
                  <div className="w-full flex justify-between items-center text-[7px] font-mono tracking-tight text-[#FFB7C5] mt-2">
                    <span>★ MOMOPHOTO PREVIEW</span>
                    <span>2026.05</span>
                  </div>
                </div>
              )}
            </div>

            {/* Quick action button for forward flow */}
            <button 
              id="btn-confirm-layout"
              onClick={() => { playRetroBeep('success'); onNext(); }}
              className="w-full mt-5 bg-[#2D2D2D] hover:bg-[#FFB7C5] hover:text-stone-900 text-white font-outfit py-3.5 rounded-2xl transition-all shadow-md hover:shadow-[0_10px_20px_rgba(255,183,197,0.3)] cursor-pointer font-bold tracking-widest text-[11px] uppercase flex items-center justify-center gap-1.5"
            >
              <span>{dict.nextBtn}</span>
              <Sparkles className="w-3.5 h-3.5 fill-current" />
            </button>
          </div>
        </div>

      </div>

      {/* Footer Info */}
      <div className="text-center font-mono text-[9px] text-stone-400 pt-3 border-t border-[#F2E8DF] shrink-0 uppercase tracking-widest">
        Layout module initialized &middot; scale: kiosk_1x
      </div>

    </div>
  );
}
