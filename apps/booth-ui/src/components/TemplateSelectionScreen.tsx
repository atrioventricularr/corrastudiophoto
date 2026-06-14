import React, { useState } from 'react';
import { Palette, Edit3, ArrowLeft, Layers } from 'lucide-react';
import { FrameTemplate } from '../types';
import { playRetroBeep } from '../utils/audio';

interface TemplateSelectionScreenProps {
  templates: FrameTemplate[];
  selectedTemplateId: string;
  onSelectTemplate: (id: string) => void;
  onNext: () => void;
  onBack: () => void;
  lang: 'ID' | 'EN' | 'JP';
}

const DICTIONARY = {
  ID: {
    title: "Pilih Desain Frame",
    subtitle: "Pilih corak bingkai retro-clean yang melambangkan nuansa foto Anda",
    nextBtn: "Lanjut ke Kamera",
    backBtn: "Kembali",
    customLabel: "Kustomisasi Teks Cetak:",
    placeholderSticker: "Ketik teks sticker di frame...",
    previewTag: "PREVIEW TEMPLATE FRAME"
  },
  EN: {
    title: "Select Frame Style",
    subtitle: "Browse artistic retro borders symbolizing your session vibe",
    nextBtn: "Proceed to Camera",
    backBtn: "Back",
    customLabel: "Sticker Custom Text:",
    placeholderSticker: "Type sticker title on frame...",
    previewTag: "LIVE CANVAS STYLER"
  },
  JP: {
    title: "フレームテーマ選択",
    subtitle: "プリクラを彩るレトロモダンなデザインと模様を選びましょう",
    nextBtn: "カメラ撮影へ進む",
    backBtn: "戻る",
    customLabel: "カスタムステッカー用文字列:",
    placeholderSticker: "フレームロゴを入力...",
    previewTag: "選択フレームプレビュー"
  }
};

export default function TemplateSelectionScreen({
  templates,
  selectedTemplateId,
  onSelectTemplate,
  onNext,
  onBack,
  lang
}: TemplateSelectionScreenProps) {
  const dict = DICTIONARY[lang];
  const [customText, setCustomText] = useState<string>('');

  const currentTemplate = templates.find(t => t.id === selectedTemplateId) || templates[0];

  const handleTemplateClick = (id: string) => {
    playRetroBeep('select');
    onSelectTemplate(id);
    
    // Auto-update to template's standard text if user hasn't explicitly customized it
    const chosen = templates.find(t => t.id === id);
    if (chosen) {
      setCustomText(chosen.stickerText);
    }
  };

  // Sync custom text to the active template state in the app session
  React.useEffect(() => {
    if (currentTemplate && !customText) {
      setCustomText(currentTemplate.stickerText);
    }
  }, [selectedTemplateId]);

  const handleTextChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setCustomText(e.target.value.toUpperCase());
    currentTemplate.stickerText = e.target.value.toUpperCase(); // Live edit mutable object for quick mock preview representation
  };

  return (
    <div className="flex-1 w-full bg-transparent flex flex-col justify-between p-4 sm:p-8 select-none text-stone-800">
      
      {/* Header Info */}
      <div className="flex items-center justify-between border-b border-[#F2E8DF] pb-3 shrink-0">
        <button 
          id="btn-back-to-layout"
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
            Frame: {currentTemplate.name}
          </p>
        </div>
      </div>

      {/* Main split selector dashboard */}
      <div className="flex-1 w-full max-w-5xl mx-auto flex flex-col lg:flex-row items-center justify-center gap-6 my-auto py-4 overflow-y-auto custom-scrollbar">
        
        {/* Left column: Grid patterns selection */}
        <div className="flex-1 w-full flex flex-col gap-4">
          
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {templates.map((tpl) => {
              const isSelected = selectedTemplateId === tpl.id;
              
              return (
                <div 
                  id={`template-item-${tpl.id}`}
                  key={tpl.id}
                  onClick={() => handleTemplateClick(tpl.id)}
                  style={{ backgroundColor: tpl.bgColor, borderColor: isSelected ? '#FFB7C5' : '#F2E8DF' }}
                  className={`p-4 rounded-2xl border cursor-pointer select-none transition-all duration-300 flex items-center justify-between relative ${
                    isSelected 
                      ? 'shadow-[0_12px_30px_rgba(255,183,197,0.25)] scale-[1.01]' 
                      : 'hover:border-[#FFB7C5]/60 hover:bg-stone-50/10 shadow-[0_4px_12px_rgba(0,0,0,0.01)] bg-white'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    {/* Visual pattern swatch indicator */}
                    <div 
                      style={{ backgroundColor: tpl.borderColor, color: tpl.textColor }}
                      className="w-10 h-10 rounded-xl border border-white/20 flex items-center justify-center font-mono font-bold text-xs shrink-0 select-none shadow-sm"
                    >
                      {tpl.pattern === 'grid' && '田'}
                      {tpl.pattern === 'cherry' && '🍒'}
                      {tpl.pattern === 'stars' && '★'}
                      {tpl.pattern === 'dots' && '●'}
                      {tpl.pattern === 'vintage' && '📷'}
                    </div>

                    <div className="text-left">
                      <h4 className="font-outfit font-extrabold text-xs text-stone-900">
                        {tpl.name}
                      </h4>
                      <p className="text-[9px] font-mono mt-0.5 text-stone-400">
                        Sticker Decal: &quot;{tpl.stickerText}&quot;
                      </p>
                    </div>
                  </div>

                  {/* Tick marker */}
                  {isSelected && (
                    <div className="w-5 h-5 rounded-full bg-[#FFB7C5] border border-white flex items-center justify-center shadow-sm select-none">
                      <span className="text-[9px] text-stone-900 font-extrabold">✓</span>
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Quick custom text panel inside template page */}
          <div className="bg-white border border-[#F2E8DF] shadow-[0_4px_12px_rgba(0,0,0,0.02)] p-5 rounded-2xl mt-1.5">
            <label className="flex items-center gap-1.5 text-stone-700 font-outfit font-bold text-xs mb-2">
              <Edit3 className="w-4 h-4 text-[#FFB7C5]" />
              <span>{dict.customLabel}</span>
            </label>
            <input 
              id="input-frame-text"
              type="text"
              maxLength={22}
              placeholder={dict.placeholderSticker}
              value={customText}
              onChange={handleTextChange}
              className="w-full px-3.5 py-3 bg-stone-50/55 border border-[#F2E8DF] rounded-xl font-outfit text-xs font-semibold text-stone-800 placeholder-stone-400 focus:outline-none focus:border-[#FFB7C5] focus:bg-white transition-all"
            />
            <span className="text-[9px] text-stone-400 font-mono mt-1.5 block">
              Character limit: {customText.length}/22 (Always CAPITALIZED for aesthetic custom decals)
            </span>
          </div>

        </div>

        {/* Right column: Large mockup representation */}
        <div className="w-full lg:w-80 shrink-0 flex justify-center">
          <div className="bg-white p-6 rounded-[32px] shadow-[0_20px_50px_-15px_rgba(255,183,197,0.25)] border border-[#F2E8DF] w-full flex flex-col items-center">
            
            <span className="text-[10px] font-mono tracking-wider text-[#FFB7C5] font-bold mb-3 uppercase">
              {dict.previewTag}
            </span>

            {/* Simulated Printed Strip Object */}
            <div 
              style={{ 
                backgroundColor: currentTemplate.bgColor, 
                borderColor: '#F2E8DF'
              }}
              className="w-36 h-64 border rounded-2xl p-3 flex flex-col justify-between items-center transition-all duration-300 relative overflow-hidden shadow-[0_12px_24px_rgba(0,0,0,0.03)]"
            >
              
              {/* Pattern Mock SVG Overlays */}
              {currentTemplate.pattern === 'grid' && (
                <div className="absolute inset-0 bg-[linear-gradient(to_right,#ccc_1px,transparent_1px),linear-gradient(to_bottom,#ccc_1px,transparent_1px)] bg-[size:10px_10px] opacity-15 pointer-events-none"></div>
              )}
              {currentTemplate.pattern === 'dots' && (
                <div className="absolute inset-0 bg-[radial-gradient(#ccc_1px,transparent_1px)] bg-[size:10px_10px] opacity-20 pointer-events-none"></div>
              )}
              {currentTemplate.pattern === 'stars' && (
                <div className="absolute top-2 left-2 text-[#C084FC] opacity-35 font-mono text-xs pointer-events-none font-bold animate-pulse">★</div>
              )}

              {/* Styled mock image container */}
              <div style={{ borderColor: currentTemplate.borderColor }} className="w-full flex-1 border-2 border-stone-100/10 rounded-lg flex items-center justify-center bg-stone-50 flex-col gap-1.5 relative overflow-hidden group">
                <div className="w-8 h-8 rounded-full bg-stone-200 flex items-center justify-center relative">
                  <Palette className="w-4 h-4 text-stone-400" />
                </div>
                <span className="text-[8px] font-mono text-stone-400 LTR tracking-tight">SHOT AREA</span>
                
                {/* Visual sticker labels inside mock photo strip */}
                <div style={{ backgroundColor: currentTemplate.stickerColor, color: '#FFFFFF' }} className="absolute bottom-1 right-1 px-1.5 py-0.5 rounded text-[7px] font-semibold tracking-tighter shadow-sm select-none">
                  SMILE! ♥
                </div>
              </div>

              {/* Sticker text bottom panel */}
              <div className="w-full pt-2 flex flex-col items-center">
                <span 
                  style={{ color: currentTemplate.textColor }} 
                  className="font-outfit font-extrabold text-[10px] text-center tracking-wide uppercase leading-tight select-none truncate max-w-full"
                >
                  {customText || 'MOMO'}
                </span>
                
                {/* Sparkles / date decor */}
                <div className="flex gap-2 text-[#E11D48] opacity-60 text-[6px] font-mono mt-1">
                  <span>★ MOMOPHOTO</span>
                  <span>{new Date().toLocaleDateString('en-US', { year: '2-digit', month: '2-digit' })}</span>
                </div>
              </div>

            </div>

            {/* Confirm proceed action */}
            <button 
              id="btn-confirm-template"
              onClick={() => { playRetroBeep('success'); onNext(); }}
              className="w-full mt-5 bg-[#2D2D2D] hover:bg-[#FFB7C5] hover:text-stone-900 text-white font-outfit py-3.5 rounded-2xl transition-all shadow-md hover:shadow-[0_10px_20px_rgba(255,183,197,0.3)] cursor-pointer font-bold tracking-widest text-[11px] uppercase flex items-center justify-center gap-1.5"
            >
              <span>{dict.nextBtn}</span>
              <Layers className="w-4 h-4 fill-current" />
            </button>
          </div>
        </div>

      </div>

      {/* Footer System Info */}
      <div className="text-center font-mono text-[9px] text-stone-400 pt-3 border-t border-[#F2E8DF] shrink-0 uppercase tracking-widest">
        Themes module &middot; printer: 300dpi &middot; calibrated
      </div>

    </div>
  );
}
