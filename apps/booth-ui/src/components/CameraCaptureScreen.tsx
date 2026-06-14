import React, { useRef, useState, useEffect } from 'react';
import { Camera, RefreshCw, Sparkles, CheckCircle, ChevronRight, AlertCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { LayoutOptions, FrameTemplate } from '../types';
import { playRetroBeep } from '../utils/audio';
import { SAMPLE_MOCK_PHOTOS } from '../constants';

interface CameraCaptureScreenProps {
  layout: LayoutOptions;
  template: FrameTemplate;
  countdownDuration: number;
  onCaptureComplete: (photos: string[]) => void;
  onBack: () => void;
  lang: 'ID' | 'EN' | 'JP';
}

const DICTIONARY = {
  ID: {
    ready: "SIAP-SIAP!",
    countdown: "COUNTDOWN",
    snapIndicator: "Posisikan wajah Anda di dalam kamera",
    snapCount: "Foto ke-",
    retake: "Retake Foto Sebelumnya",
    webcamBlocked: "WEBCAM BELUM DIAKTIFKAN",
    webcamInstruct: "Aktifkan kamera Anda untuk pengalaman penuh atau gunakan model Y2K instan di bawah ini:",
    completeBtn: "Selesai & Cetak Foto ✨",
    shutterIndicator: "SMILE! ♥",
    flashWarning: "Hati-hati terhadap kilatan cahaya!"
  },
  EN: {
    ready: "GET READY!",
    countdown: "COUNTDOWN",
    snapIndicator: "Align your face within the camera preview box",
    snapCount: "Snap #",
    retake: "Retake Last Photo",
    webcamBlocked: "WEBCAM INACTIVE",
    webcamInstruct: "Please allow camera permissions or browse cute Japanese mock models instead:",
    completeBtn: "Finish & Development Frame ✨",
    shutterIndicator: "SMILE! ♥",
    flashWarning: "Prepare for soft flashes!"
  },
  JP: {
    ready: "笑って！準備はいい？",
    countdown: "カウントダウン",
    snapIndicator: "カメラの枠内に顔を合わせてください",
    snapCount: "カット数:",
    retake: "前のカットを撮り直す",
    webcamBlocked: "ウエッブカメラ未連携",
    webcamInstruct: "カメラを許可するか、以下の2000年代風モデルポートレートを選択して遊べます:",
    completeBtn: "完成写真へ進む ✨",
    shutterIndicator: "はいチーズ！♥",
    flashWarning: "ストロボの点滅にご注意ください"
  }
};

export default function CameraCaptureScreen({
  layout,
  template,
  countdownDuration,
  onCaptureComplete,
  onBack,
  lang
}: CameraCaptureScreenProps) {
  const dict = DICTIONARY[lang];
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  const [stream, setStream] = useState<MediaStream | null>(null);
  const [cameraActive, setCameraActive] = useState<boolean>(false);
  const [photos, setPhotos] = useState<string[]>([]);
  const [currentSlotIdx, setCurrentSlotIdx] = useState<number>(0);
  
  // Countdown state
  const [countdown, setCountdown] = useState<number | null>(null);
  const [isCounting, setIsCounting] = useState<boolean>(false);
  
  // Flash visual overlay triggers
  const [flashOn, setFlashOn] = useState<boolean>(false);

  // Fallback selection state
  const [chosenFallbackId, setChosenFallbackId] = useState<string>('m1');

  // Request actual camera stream upon mounting
  useEffect(() => {
    async function setupCamera() {
      try {
        const userStream = await navigator.mediaDevices.getUserMedia({
          video: {
            width: { ideal: 1280 },
            height: { ideal: 720 },
            facingMode: 'user'
          },
          audio: false
        });
        setStream(userStream);
        if (videoRef.current) {
          videoRef.current.srcObject = userStream;
          videoRef.current.play();
        }
        setCameraActive(true);
      } catch (err) {
        console.warn('Webcam stream not accessible. Falling back to cute simulated assets:', err);
        setCameraActive(false);
      }
    }
    setupCamera();

    return () => {
      if (stream) {
        stream.getTracks().forEach(track => track.stop());
      }
    };
  }, []);

  // Countdown clock ticker
  useEffect(() => {
    if (countdown === null) return;
    
    if (countdown === 0) {
      triggerShutter();
      return;
    }

    const timer = setTimeout(() => {
      playRetroBeep('countdown');
      setCountdown(prev => (prev !== null ? prev - 1 : null));
    }, 1000);

    return () => clearTimeout(timer);
  }, [countdown]);

  const startCountdown = () => {
    if (isCounting || photos.length >= layout.slots) return;
    setIsCounting(true);
    setCountdown(countdownDuration);
  };

  const triggerShutter = () => {
    setCountdown(null);
    setIsCounting(false);
    
    // Play camera sound and blinking white overlay
    playRetroBeep('shutter');
    setFlashOn(true);

    // Disable flash visual quickly (200ms)
    setTimeout(() => {
      setFlashOn(false);
    }, 220);

    let photoUrl = '';

    if (cameraActive && videoRef.current && canvasRef.current) {
      // Draw web-cam frame on canvas
      const canvas = canvasRef.current;
      const video = videoRef.current;
      const ctx = canvas.getContext('2d');
      if (ctx) {
        canvas.width = 640;
        canvas.height = 480;
        
        // Flip horizontally for user friendly mirrored webcam feeds
        ctx.translate(canvas.width, 0);
        ctx.scale(-1, 1);
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        
        // Reset transform
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        
        // Convert to dataurl
        photoUrl = canvas.toDataURL('image/jpeg', 0.9);
      }
    } else {
      // Webcam disabled fallback - pick rotating photo template sequence
      const selectedFallback = SAMPLE_MOCK_PHOTOS.find(p => p.id === chosenFallbackId);
      photoUrl = selectedFallback ? selectedFallback.url : SAMPLE_MOCK_PHOTOS[0].url;
      
      // Shuffle the selected simulation avatar forward for variation on the next photo!
      const currentIdx = SAMPLE_MOCK_PHOTOS.findIndex(p => p.id === chosenFallbackId);
      const nextIdx = (currentIdx + 1) % SAMPLE_MOCK_PHOTOS.length;
      setChosenFallbackId(SAMPLE_MOCK_PHOTOS[nextIdx].id);
    }

    if (photoUrl) {
      const updatedPhotos = [...photos, photoUrl];
      setPhotos(updatedPhotos);
      
      if (updatedPhotos.length < layout.slots) {
        setCurrentSlotIdx(updatedPhotos.length);
      } else {
        // Complete! Call parent processor callback
        setTimeout(() => {
          onCaptureComplete(updatedPhotos);
        }, 1200);
      }
    }
  };

  const handleRetakeLast = () => {
    if (photos.length === 0) return;
    playRetroBeep('click');
    const popped = [...photos];
    popped.pop();
    setPhotos(popped);
    setCurrentSlotIdx(popped.length);
  };

  return (
    <div className="flex-1 w-full bg-transparent flex flex-col justify-between p-4 sm:p-6 select-none relative overflow-hidden">
      
      {/* Absolute White Shutter Flash overlay */}
      <AnimatePresence>
        {flashOn && (
          <motion.div 
            id="shutter-flash-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.1 }}
            className="absolute inset-0 bg-white z-[9999] opacity-95 pointer-events-none"
          ></motion.div>
        )}
      </AnimatePresence>

      {/* Camera Capture Panel Title Header */}
      <div className="flex justify-between items-center pb-2.5 border-b border-[#F2E8DF] shrink-0">
        <div className="flex items-center gap-1.5 text-stone-400 text-xs font-mono lowercase tracking-wider">
          <Camera className="w-4 h-4 text-[#FFB7C5]" />
          <span>session: {layout.slots} snaps active</span>
        </div>
        <div className="bg-rose-50 border border-[#FFB7C5]/30 px-3 py-1 rounded-xl text-xs font-outfit text-rose-800 font-bold">
          {dict.snapCount} {photos.length + 1} / {layout.slots}
        </div>
      </div>

      {/* Main split dashboard view */}
      <div className="flex-1 max-w-5xl w-full mx-auto flex flex-col lg:flex-row items-stretch justify-center gap-6 my-auto py-3 min-h-0 overflow-y-auto">
        
        {/* Left Side: Live Capture Frame Container */}
        <div id="camera-view-container" className="flex-1 bg-white border border-[#F2E8DF] shadow-[0_20px_50px_-15px_rgba(255,183,197,0.15)] rounded-[32px] p-4 flex flex-col justify-between relative overflow-hidden min-h-[340px]">
          
          {/* Upper banner subtitle */}
          <div className="flex items-center justify-between text-stone-400 text-[10px] pb-2 border-b border-stone-50 uppercase font-mono">
            <span>PREVIEW FEED (MIRRORED)</span>
            <span className="text-[#E11D48] font-bold">READY TO CAPTURE</span>
          </div>

          <div className="flex-1 relative rounded-2xl bg-stone-900 border border-[#F2E8DF] overflow-hidden mt-2.5 flex items-center justify-center shadow-inner">
            
            {cameraActive ? (
              // Real webcam hardware element
              <video 
                id="camera-video-feed"
                ref={videoRef} 
                className="w-full h-full object-cover scale-x-[-1]"
                playsInline
                muted
              ></video>
            ) : (
              // Cute Japanese vintage model collage if camera blocked
              <div className="w-full h-full relative group">
                <img 
                  id="camera-mock-fallback"
                  src={SAMPLE_MOCK_PHOTOS.find(p => p.id === chosenFallbackId)?.url || SAMPLE_MOCK_PHOTOS[0].url} 
                  alt="Simulated Model Selfie" 
                  className="w-full h-full object-cover brightness-[0.95]"
                  referrerPolicy="no-referrer"
                />
                
                {/* Visual Camera lens overlay mockup */}
                <div className="absolute inset-0 bg-rose-500/10 pointer-events-none mix-blend-color-burn"></div>
              </div>
            )}

            {/* Simulated viewfinder elements */}
            <div className="absolute top-4 left-4 border-t-2 border-l-2 border-white/50 w-6 h-6"></div>
            <div className="absolute top-4 right-4 border-t-2 border-r-2 border-white/50 w-6 h-6"></div>
            <div className="absolute bottom-4 left-4 border-b-2 border-l-2 border-white/50 w-6 h-6"></div>
            <div className="absolute bottom-4 right-4 border-b-2 border-r-2 border-white/50 w-6 h-6"></div>

            {/* Interactive Countdown Numbers centered as massive retro graphics */}
            <AnimatePresence>
              {countdown !== null && (
                <motion.div 
                  id="countdown-overlay-number"
                  initial={{ scale: 0.5, opacity: 0 }}
                  animate={{ scale: 1.2, opacity: 1 }}
                  exit={{ scale: 0.3, opacity: 0 }}
                  transition={{ type: 'spring', damping: 10 }}
                  className="absolute z-50 bg-stone-950/80 backdrop-blur-md text-white rounded-full w-24 h-24 flex flex-col items-center justify-center border-4 border-rose-400 font-display font-extrabold text-4xl shadow-2xl"
                >
                  <span className="text-rose-400 text-[10px] tracking-widest font-mono uppercase font-bold mt-2">COUNTDOWN</span>
                  <span className="mb-2 text-[#F43F5E]">{countdown}</span>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Small Shutter notification */}
            {isCounting && (
              <div className="absolute bottom-4 left-1/2 -translate-x-1/2 bg-yellow-400 text-[#78350F] text-[9px] font-bold px-3 py-1 rounded-full border-2 border-stone-100 flex items-center gap-1 animate-pulse">
                <AlertCircle className="w-3.5 h-3.5 fill-[#78350F] text-yellow-400" />
                <span>{dict.flashWarning}</span>
              </div>
            )}
          </div>

          {/* Trigger Capture Button */}
          <div className="pt-3 flex gap-3 select-none">
            {/* Countdown click */}
            <button 
              id="btn-click-shutter"
              onClick={startCountdown}
              disabled={isCounting || photos.length >= layout.slots}
              className="flex-1 bg-[#2D2D2D] hover:bg-[#FFB7C5] hover:text-stone-950 text-white font-outfit py-3.5 rounded-2xl shadow-sm transition-all cursor-pointer font-bold tracking-widest text-xs uppercase relative overflow-hidden flex items-center justify-center gap-1.5 disabled:opacity-40"
            >
              <Camera className="w-4 h-4 fill-white" />
              <span>{isCounting ? 'CAPTURING...' : 'SNAP PHOTO'}</span>
            </button>

            {/* Clear last snap button */}
            {photos.length > 0 && (
              <button 
                id="btn-retake-photo"
                onClick={handleRetakeLast}
                disabled={isCounting}
                className="px-4.5 bg-rose-50 text-rose-700 border border-[#FFB7C5]/30 rounded-2xl hover:bg-[#FFE3E8] cursor-pointer text-xs font-semibold shrink-0"
              >
                <RefreshCw className="w-4 h-4 stroke-[2.5]" />
              </button>
            )}
          </div>
          
        </div>

        {/* Right Side: Photo slots sequence panel */}
        <div className="w-full lg:w-80 shrink-0 flex flex-col justify-between bg-white border border-[#F2E8DF] shadow-[0_20px_50px_-15px_rgba(255,183,197,0.15)] p-4 rounded-[32px] gap-4 min-h-[300px]">
          
          <div>
            <div className="border-b border-dashed border-[#F2E8DF] pb-2 mb-3 text-center">
              <span className="text-[10px] font-mono tracking-widest text-[#FFB7C5] font-bold">
                POSE MATRIX FLOW
              </span>
            </div>

            {/* List of pose frame slots showing active/completed states */}
            <div className="space-y-2.5">
              {Array.from({ length: layout.slots }).map((_, i) => {
                const capturedUrl = photos[i];
                const isActive = currentSlotIdx === i;
                const isCaptured = !!capturedUrl;

                return (
                  <div 
                    id={`matrix-slot-${i}`}
                    key={i} 
                    className={`p-2 rounded-xl border flex items-center gap-3 transition-colors ${
                      isActive 
                        ? 'border-[#FFB7C5] bg-rose-50/20' 
                        : isCaptured 
                          ? 'border-emerald-350 bg-emerald-50/25' 
                          : 'border-[#F2E8DF] bg-stone-50/60 opacity-60'
                    }`}
                  >
                    {/* Tiny visual image preview or slot index */}
                    <div className="w-12 h-10 rounded-lg border border-[#F2E8DF] bg-stone-900 overflow-hidden shrink-0 flex items-center justify-center">
                      {isCaptured ? (
                        <img src={capturedUrl} alt="Captured" className="w-full h-full object-cover scale-x-[-1]" referrerPolicy="no-referrer" />
                      ) : (
                        <span className="font-mono text-stone-500 text-xs font-bold">#{i+1}</span>
                      )}
                    </div>

                    <div className="flex-1 min-w-0">
                      <h4 className="font-outfit font-extrabold text-[11px] text-stone-800 leading-none">
                        Pose {i + 1}
                      </h4>
                      <p className="text-[9px] font-mono mt-1 leading-none text-stone-400">
                        {isCaptured ? 'Captured ✓' : isActive ? '🎯 Live slot' : 'Awaiting camera'}
                      </p>
                    </div>

                    {isCaptured && (
                      <CheckCircle className="w-4.5 h-4.5 text-emerald-500 fill-emerald-100 shrink-0" />
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Fallback Selector widgets ONLY if physical webcam is blocked/denied */}
          {!cameraActive && (
            <div className="bg-[#FFF1F2] border border-[#FFB7C5]/30 p-3 rounded-2xl">
              <div className="flex items-center gap-1 text-[#8C1D40] text-[10px] font-bold uppercase mb-1.5 selection:bg-rose-100">
                <Sparkles className="w-3.5 h-3.5" />
                <span>Simulated Selfie Avatar</span>
              </div>
              
              <div id="simulated-avatars-grid" className="grid grid-cols-4 gap-1.5 scrollbar-none max-h-20 overflow-y-auto">
                {SAMPLE_MOCK_PHOTOS.map((pm) => (
                  <button 
                    key={pm.id}
                    onClick={() => { playRetroBeep('click'); setChosenFallbackId(pm.id); }}
                    className={`w-full aspect-square rounded-lg border overflow-hidden relative cursor-pointer ${chosenFallbackId === pm.id ? 'border-[#FFB7C5] shadow-sm' : 'border-[#F2E8DF]'}`}
                  >
                    <img src={pm.url} alt={pm.name} className="w-full h-full object-cover" referrerPolicy="no-referrer" />
                    {chosenFallbackId === pm.id && (
                      <div className="absolute inset-0 bg-[#FFB7C5]/20"></div>
                    )}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Quick finish/proceed CTA once all photos captured */}
          {photos.length >= layout.slots && (
            <button 
              id="btn-processing-proceed"
              onClick={() => onCaptureComplete(photos)}
              className="w-full bg-[#2D2D2D] hover:bg-[#FFB7C5] hover:text-stone-900 border border-[#F2E8DF] py-2.5 rounded-2xl font-outfit font-extrabold text-xs shadow-md flex items-center justify-center gap-1 cursor-pointer transition-all"
            >
              <span>{dict.completeBtn}</span>
              <ChevronRight className="w-4 h-4" />
            </button>
          )}

        </div>

      </div>

      <canvas ref={canvasRef} style={{ display: 'none' }}></canvas>

      {/* Footer System Details */}
      <div className="text-center font-mono text-[9px] text-stone-400 pt-3 border-t border-[#F2E8DF] shrink-0 select-text uppercase tracking-wider">
        Shutter telemetry ready &middot; stream: activated &middot; slot: sync
      </div>

    </div>
  );
}
