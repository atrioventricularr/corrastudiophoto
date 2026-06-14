import React, { useRef, useState, useEffect } from 'react';
import { 
  Printer, 
  Download, 
  Home, 
  CheckCircle2, 
  Layers
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { LayoutOptions, FrameTemplate } from '../types';
import { playRetroBeep } from '../utils/audio';

interface ResultScreenProps {
  layout: LayoutOptions;
  template: FrameTemplate;
  photos: string[];
  onFinish: () => void;
  lang: 'ID' | 'EN' | 'JP';
}

const DICTIONARY = {
  ID: {
    title: "Hasil Foto Cantik Anda!",
    subtitle: "Sesi foto selesai. Silakan unduh file digital atau cetak strip fisik",
    btnPrint: "Cetak Foto Sekarang",
    btnFinish: "Kembali ke Beranda",
    downloadBtn: "Unduh Gambar (PNG)",
    qrPopupTitle: "Pindai untuk mengunduh GIF & Foto",
    qrPopupDesc: "Gunakan kamera smartphone Anda untuk memindai kode QRIS agar dapat mengunduh foto strip dalam format resolusi tinggi lengkap dengan animasi GIF.",
    printingTitle: "Sedang Mencetak...",
    printingSuccess: "Cetak berhasil! Kertas foto sedang meluncur keluar.",
    gifTab: "🎬 Animasi GIF",
    stripTab: "📷 Photo Strip"
  },
  EN: {
    title: "Your Sweet Photo Strip!",
    subtitle: "Shooting session completed. You can print physical cards or download files.",
    btnPrint: "Print Physical Photo Strip",
    btnFinish: "Finish Session",
    downloadBtn: "Download File (PNG)",
    qrPopupTitle: "Scan QR Code for GIF & Strip",
    qrPopupDesc: "Point your smartphone camera to this QR code to download high-res files along with looping stop-motion GIF formats instantly.",
    printingTitle: "Printing Paper...",
    printingSuccess: "Print completed! Photo paper is sliding out of Kiosk.",
    gifTab: "🎬 Animation GIF",
    stripTab: "📷 Photo Strip"
  },
  JP: {
    title: "オリジナルプリ完成！",
    subtitle: "撮影が無事に完了しました。画像を保存、または用紙をプリントできます。",
    btnPrint: "プリシートを印刷する",
    btnFinish: "終了して最初に戻る",
    downloadBtn: "画像として保存 (PNG)",
    qrPopupTitle: "スマホで読込・無料ダウンロード",
    qrPopupDesc: "携帯のカメラでこのバーコードをスキャンすると、高画質なレイアウト画像とレトロなコマ撮りアニメーション（GIF）が無料で保存できます。",
    printingTitle: "印刷中です...",
    printingSuccess: "印刷が完了しました！写真シートをお受け取りください。",
    gifTab: "🎬 コマアニメーション (GIF)",
    stripTab: "📷 プリシート"
  }
};

export default function ResultScreen({
  layout,
  template,
  photos,
  onFinish,
  lang
}: ResultScreenProps) {
  const dict = DICTIONARY[lang];
  const hiddenCanvasRef = useRef<HTMLCanvasElement | null>(null);

  const [activeTab, setActiveTab] = useState<'strip' | 'gif'>('strip');
  const [showQr, setShowQr] = useState<boolean>(true);
  
  // Printing simulation state
  const [printProgress, setPrintProgress] = useState<number | null>(null);
  const [printSuccessMessage, setPrintSuccessMessage] = useState<string>('');

  // GIF stop motion active frame state
  const [gifFrameIdx, setGifFrameIdx] = useState<number>(0);

  // Automatically cycle through frames if on GIF tab to mimic stop motion
  useEffect(() => {
    if (activeTab !== 'gif' || photos.length === 0) return;
    const interval = setInterval(() => {
      setGifFrameIdx(prev => (prev + 1) % photos.length);
    }, 450);
    return () => clearInterval(interval);
  }, [activeTab, photos]);

  const handleDownloadCombined = () => {
    playRetroBeep('success');
    const canvas = hiddenCanvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Determine target compile dimensions
    const cWidth = layout.canvasWidth * 2;
    const cHeight = layout.canvasHeight * 2;
    canvas.width = cWidth;
    canvas.height = cHeight;

    // 1. Draw frame solid background
    ctx.fillStyle = template.bgColor;
    ctx.fillRect(0, 0, cWidth, cHeight);

    // 2. Patterns overlay if needed
    if (template.pattern === 'grid') {
      ctx.strokeStyle = '#f2e8df';
      ctx.lineWidth = 2;
      const step = 20;
      for (let x = 0; x < cWidth; x += step) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, cHeight);
        ctx.stroke();
      }
      for (let y = 0; y < cHeight; y += step) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(cWidth, y);
        ctx.stroke();
      }
    }

    // 3. Draw Photos in matrix slots
    const borderSpacingX = 24;
    const borderSpacingY = 28;
    const paddingInternal = 16;
    
    // Space available for matrix grid (leave bottom for sticker)
    const availableHeightForGrid = cHeight - 100;
    const gridWidth = cWidth - (borderSpacingX * 2);
    const gridHeight = availableHeightForGrid - (borderSpacingY * 2);

    const cellWidth = (gridWidth - (paddingInternal * (layout.gridCols - 1))) / layout.gridCols;
    const cellHeight = (gridHeight - (paddingInternal * (layout.gridRows - 1))) / layout.gridRows;

    let loadedCount = 0;
    
    // Stitch each photo frame
    photos.forEach((photoDataUrl, index) => {
      const col = index % layout.gridCols;
      const row = Math.floor(index / layout.gridCols);

      const cellX = borderSpacingX + col * (cellWidth + paddingInternal);
      const cellY = borderSpacingY + row * (cellHeight + paddingInternal);

      const img = new Image();
      img.onload = () => {
        // Draw thin border around photo cells first
        ctx.fillStyle = template.borderColor;
        ctx.fillRect(cellX - 4, cellY - 4, cellWidth + 8, cellHeight + 8);
        
        ctx.strokeStyle = '#f2e8df';
        ctx.lineWidth = 1;
        ctx.strokeRect(cellX - 4, cellY - 4, cellWidth + 8, cellHeight + 8);

        // Draw image frame
        ctx.drawImage(img, cellX, cellY, cellWidth, cellHeight);

        loadedCount++;
        if (loadedCount === photos.length) {
          // Completed drawing photos - draw sticker text
          ctx.fillStyle = template.textColor;
          ctx.font = 'bold 22px "Outfit", sans-serif';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(template.stickerText, cWidth / 2, cHeight - 50);

          // Sub line date stamp
          ctx.font = '10px "JetBrains Mono", monospace';
          ctx.fillStyle = '#6b7280';
          ctx.fillText(`★ PRINT CLUB 2000s • ${new Date().toLocaleDateString('en-US')}`, cWidth / 2, cHeight - 22);

          // Force download link trigger
          const downloadUrl = canvas.toDataURL('image/png');
          const element = document.createElement('a');
          element.href = downloadUrl;
          element.download = `MomoPhoto_${layout.id}_${Date.now()}.png`;
          document.body.appendChild(element);
          element.click();
          document.body.removeChild(element);
        }
      };
      img.src = photoDataUrl;
    });
  };

  const startFakePrinting = () => {
    if (printProgress !== null) return;
    playRetroBeep('success');
    setPrintProgress(0);
    setPrintSuccessMessage('');

    const interval = setInterval(() => {
      setPrintProgress(prev => {
        if (prev === null) return null;
        const next = prev + 10;
        if (next >= 100) {
          clearInterval(interval);
          playRetroBeep('success');
          setPrintSuccessMessage(dict.printingSuccess);
          return 100;
        }
        return next;
      });
    }, 450);
  };

  return (
    <div className="flex-1 w-full bg-transparent flex flex-col justify-between p-4 sm:p-8 select-none text-stone-800">
      
      {/* Header Info */}
      <div className="flex items-center justify-between border-b border-[#F2E8DF] pb-3 shrink-0">
        <div className="flex items-center gap-1.5 text-stone-400 font-mono text-xs uppercase tracking-widest">
          <span className="w-2.5 h-2.5 rounded-full bg-[#FFB7C5] shrink-0 animate-pulse"></span>
          <span>Development Finished &middot; Code Online</span>
        </div>

        <div className="text-right">
          <h2 className="font-serif italic font-bold text-sm tracking-wide text-stone-900 uppercase">
            {dict.title}
          </h2>
        </div>
      </div>

      {/* Main split display section */}
      <div className="flex-1 max-w-5xl w-full mx-auto flex flex-col lg:flex-row items-stretch justify-center gap-8 my-auto py-4 min-h-0 overflow-y-auto custom-scrollbar">
        
        {/* Left Column: Visual Collage rendering and strip layout previews */}
        <div className="flex-1 flex flex-col items-center justify-center gap-4">
          
          {/* Tab switches for Static collage vs Looping stop-motion GIF */}
          <div className="flex bg-white p-1 rounded-2xl border border-[#F2E8DF] shadow-sm select-none">
            <button 
              id="tab-view-strip"
              onClick={() => { playRetroBeep('click'); setActiveTab('strip'); }}
              className={`px-4 py-1.5 rounded-xl font-outfit text-xs font-bold transition-all cursor-pointer ${activeTab === 'strip' ? 'bg-[#FFB7C5] text-stone-950 shadow-sm' : 'text-stone-550 hover:text-stone-800'}`}
            >
              {dict.stripTab}
            </button>
            <button 
              id="tab-view-gif"
              onClick={() => { playRetroBeep('click'); setActiveTab('gif'); }}
              className={`px-4 py-1.5 rounded-xl font-outfit text-xs font-bold transition-all cursor-pointer ${activeTab === 'gif' ? 'bg-[#FFB7C5] text-stone-950 shadow-sm' : 'text-stone-550 hover:text-stone-800'}`}
            >
              {dict.gifTab}
            </button>
          </div>

          {/* Interactive Frame Canvas frame layout wrapper */}
          <div 
            id="strip-result-canvas"
            className="p-4 bg-white border border-[#F2E8DF] rounded-[32px] max-w-[270px] w-full aspect-[4/9] flex flex-col items-center justify-between relative overflow-hidden transition-all duration-300 pointer-events-none select-none shadow-[0_20px_50px_-15px_rgba(255,183,197,0.2)]"
            style={{ 
              backgroundColor: template.bgColor, 
            }}
          >
            {/* Pattern Background Overlays */}
            {template.pattern === 'grid' && (
              <div className="absolute inset-0 bg-[linear-gradient(to_right,#ccc_1px,transparent_1px),linear-gradient(to_bottom,#ccc_1px,transparent_1px)] bg-[size:10px_10px] opacity-15 pointer-events-none"></div>
            )}
            {template.pattern === 'dots' && (
              <div className="absolute inset-0 bg-[radial-gradient(#ccc_1px,transparent_1px)] bg-[size:10px_10px] opacity-20 pointer-events-none"></div>
            )}
            {template.pattern === 'stars' && (
              <div className="absolute top-2 left-2 text-[#C084FC] opacity-45 font-mono text-xs pointer-events-none font-bold animate-pulse">★</div>
            )}

            {activeTab === 'strip' ? (
              // Option A: Full static grid collage based on layout choice
              <div className="w-full grid gap-2" style={{
                gridTemplateColumns: `repeat(${layout.gridCols}, minmax(0, 1fr))`,
                gridTemplateRows: `repeat(${layout.gridRows}, minmax(0, 1fr))`,
                height: '84%'
              }}>
                {Array.from({ length: layout.slots }).map((_, i) => (
                  <div 
                    key={i} 
                    style={{ borderColor: template.borderColor }}
                    className="border rounded-xl overflow-hidden bg-stone-900 shadow-sm relative group"
                  >
                    <img 
                      src={photos[i] || "https://images.unsplash.com/photo-1518837695005-2083093ee35b?auto=format&fit=crop&q=80&w=300"} 
                      alt={`Snap #${i+1}`} 
                      className="w-full h-full object-cover scale-x-[-1]"
                      referrerPolicy="no-referrer"
                    />
                    
                    {/* Retro sparkler watermark badge */}
                    <div className="absolute top-1 left-1.5 text-rose-500 fill-rose-500 font-mono text-[9px] drop-shadow-lg scale-90">
                      ★
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              // Option B: Interactive Stop motion GIF loop player
              <div className="w-full h-[84%] bg-stone-950 rounded-xl overflow-hidden shadow-inner border border-[#F2E8DF] relative flex items-center justify-center">
                <img 
                  src={photos[gifFrameIdx]} 
                  alt="Stop motion Loop" 
                  className="w-full h-full object-cover scale-x-[-1]"
                  referrerPolicy="no-referrer"
                />
                
                {/* Visual GIF indicator sticker in corner */}
                <div className="absolute bottom-2 left-2 bg-[#FFB7C5] text-stone-900 font-mono text-[8px] px-1.5 py-0.5 rounded-full font-bold uppercase z-20 shadow-sm">
                  GIF LOOP
                </div>
              </div>
            )}

            {/* Print Sticker labels footer */}
            <div className="w-full text-center mt-2.5 flex flex-col items-center">
              <span 
                style={{ color: template.textColor }} 
                className="font-outfit font-extrabold text-[12px] truncate w-full tracking-wide uppercase select-none leading-none mb-1 text-center"
              >
                {template.stickerText || 'MOMO'}
              </span>
              <div className="text-stone-400 opacity-60 text-[7px] font-mono leading-none tracking-wider">
                ★ COATING GLOSSY // 300DPI
              </div>
            </div>

          </div>

          {/* Action CTAs */}
          <div className="flex gap-2 w-full max-w-[270px]">
            <button 
              id="btn-download-trigger"
              onClick={handleDownloadCombined}
              className="flex-1 bg-stone-50 hover:bg-stone-100 text-stone-800 border border-[#F2E8DF] py-3 rounded-2xl text-[11px] font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer font-outfit shadow-sm"
            >
              <Download className="w-3.5 h-3.5" />
              <span>{dict.downloadBtn}</span>
            </button>
          </div>

        </div>

        {/* Right Column: Print operations progress & QRIS digital downloader */}
        <div className="flex-1 flex flex-col justify-between bg-white border border-[#F2E8DF] shadow-[0_20px_50px_-15px_rgba(255,183,197,0.15)] p-6 rounded-[32px] gap-5 transition-all">
          
          {/* Section 1: Printed sliding outputs simulation box */}
          <div className="bg-[#FFFDFB] border border-[#F2E8DF] rounded-2xl p-4 flex flex-col justify-between shadow-sm">
            <h3 className="font-outfit font-bold text-xs tracking-wide text-stone-900 uppercase flex items-center gap-1.5">
              <Printer className="w-4 h-4 text-emerald-500" />
              <span>PRINTER OUTLET DISPENSER</span>
            </h3>

            {printProgress === null ? (
              // Non active printing initial screen
              <div className="mt-3 flex flex-col items-center justify-center py-4 bg-stone-50/50 border border-[#F2E8DF] rounded-2xl select-none">
                <p className="text-[10px] text-stone-500 font-outfit text-center px-4 leading-relaxed">
                  Sentuh tombol cetak di bawah ini untuk mensimulasikan kertas foto mencetak langsung di mesin booth Kiosk.
                </p>

                <button 
                  id="btn-start-printing"
                  onClick={startFakePrinting}
                  className="mt-3.5 px-6 py-2.5 bg-[#2D2D2D] hover:bg-[#FFB7C5] hover:text-stone-900 text-white rounded-xl text-xs font-bold transition-all shadow-sm flex items-center justify-center gap-1.5 cursor-pointer font-outfit"
                >
                  <Printer className="w-4 h-4" />
                  <span>{dict.btnPrint}</span>
                </button>
              </div>
            ) : (
              // Active printing telemetry tracker
              <div className="mt-3 space-y-3.5 select-none">
                <div className="flex justify-between items-center text-[10px] font-mono">
                  <span className="text-rose-500 animate-pulse font-bold">{dict.printingTitle}</span>
                  <span className="font-bold">{printProgress}%</span>
                </div>

                <div className="w-full h-2.5 bg-stone-50 rounded-full overflow-hidden p-0.5 border border-[#F2E8DF] shadow-inner">
                  <div 
                    id="printing-progressbar-fill"
                    className="h-full bg-emerald-400 rounded-full transition-all duration-300" 
                    style={{ width: `${printProgress}%` }}
                  ></div>
                </div>

                {printSuccessMessage && (
                  <motion.div 
                    id="print-success-alert"
                    initial={{ opacity: 0, y: 5 }} 
                    animate={{ opacity: 1, y: 0 }} 
                    className="p-3 bg-emerald-50/50 text-emerald-950 border border-emerald-250 rounded-xl text-[10px] font-bold leading-relaxed flex items-start gap-2 select-text"
                  >
                    <CheckCircle2 className="w-4 text-emerald-600 shrink-0 mt-0.5" />
                    <span>{printSuccessMessage}</span>
                  </motion.div>
                )}
              </div>
            )}
          </div>

          {/* Section 2: Real smartphone QR scanner code */}
          {showQr && (
            <div className="bg-[#FFFDFB] border border-[#F2E8DF] rounded-2xl p-4 flex flex-col sm:flex-row items-center gap-4 shadow-sm relative">
              <div className="shrink-0 w-24 h-24 p-1 border border-[#F2E8DF] rounded-xl bg-white flex items-center justify-center relative shadow-inner">
                {/* Embed high resolution real QR Code pointing to Google or mockup link */}
                <img 
                  id="result-download-qrcode"
                  src={`https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${encodeURIComponent('https://ais-dev-wjupbvmqh4kovvq4aphfic-750071244509.asia-east1.run.app')}`}
                  alt="Dynamic mock URL QR Code" 
                  className="w-full h-full object-contain"
                  referrerPolicy="no-referrer"
                />
              </div>

              <div className="flex-1 text-center sm:text-left">
                <h4 className="font-outfit font-extrabold text-[#8C1D40] text-xs">
                  {dict.qrPopupTitle}
                </h4>
                <p className="text-[10px] text-stone-500 leading-relaxed font-outfit mt-1">
                  {dict.qrPopupDesc}
                </p>
              </div>
            </div>
          )}

          {/* Core finish back to welcome button */}
          <button 
            id="btn-finish-or-restart"
            onClick={() => { playRetroBeep('success'); onFinish(); }}
            className="w-full bg-[#2D2D2D] hover:bg-[#FFB7C5] hover:text-stone-900 text-white py-3.5 rounded-2xl font-outfit font-extrabold text-xs shadow-md flex items-center justify-center gap-1.5 cursor-pointer transition-all"
          >
            <Home className="w-4 h-4 text-red-100 fill-current" />
            <span>{dict.btnFinish}</span>
          </button>

        </div>

      </div>

      <canvas ref={hiddenCanvasRef} style={{ display: 'none' }}></canvas>

      {/* Footer step details */}
      <div className="text-center font-mono text-[9px] text-stone-400 pt-3 border-t border-[#F2E8DF] shrink-0 uppercase tracking-widest">
        Session Finished &middot; Counter sync success
      </div>

    </div>
  );
}
