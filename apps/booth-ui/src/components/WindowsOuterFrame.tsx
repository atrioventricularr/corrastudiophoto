import React, { useState, useEffect } from 'react';
import { 
  Monitor, 
  Terminal, 
  Cpu, 
  Printer, 
  Camera, 
  Settings as SettingsIcon,
  HelpCircle,
  Clock,
  Sparkles,
  Layout,
  RefreshCw,
  AppWindow,
  Maximize2,
  Minimize2,
  ChevronRight,
  Database
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { AdminSettings } from '../types';

interface WindowsOuterFrameProps {
  children: React.ReactNode;
  activeScreen: string;
  adminSettings: AdminSettings;
  systemLogs: string[];
  onToggleAdmin: () => void;
  isAdminActive: boolean;
}

export default function WindowsOuterFrame({
  children,
  activeScreen,
  adminSettings,
  systemLogs,
  onToggleAdmin,
  isAdminActive
}: WindowsOuterFrameProps) {
  const [isFullscreen, setIsFullscreen] = useState<boolean>(true);
  const [currentTime, setCurrentTime] = useState<string>('');
  
  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTime(now.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
    };
    updateTime();
    const timer = setInterval(updateTime, 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <div id="windows-workspace" className="min-h-screen bg-[#F5F2EB] text-[#1E293B] relative flex flex-col font-sans selection:bg-[#FED7AA] overflow-x-hidden">
      
      {/* Decorative Year-2000s Vaporwave Desktop Header */}
      {!isFullscreen && (
        <div className="bg-[#1A1A24] text-white px-4 py-2 flex items-center justify-between text-xs font-mono border-b-2 border-black selection:bg-rose-600">
          <div className="flex items-center gap-3">
            <span className="flex items-center gap-1.5 text-rose-300 font-bold tracking-wider">
              <span className="w-2.5 h-2.5 rounded-full bg-rose-500 animate-pulse"></span>
              FLUTTER ENGINE V3.56.0
            </span>
            <span className="text-gray-400">|</span>
            <span className="text-emerald-400">Target: Windows Desktop (x64_64)</span>
            <span className="text-gray-400">|</span>
            <span className="hidden sm:inline text-gray-300 bg-[#2D2D3F] px-2 py-0.5 rounded text-[10px]">
              Platform: self_service_kiosk_mode
            </span>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-1.5 text-gray-300">
              <Clock className="w-3.5 h-3.5 text-[#FDBA74]" />
              <span>TIME: {currentTime}</span>
            </div>
            <button 
              id="btn-switch-admin"
              onClick={onToggleAdmin}
              className={`flex items-center gap-1 px-2.5 py-1 rounded transition-all cursor-pointer ${
                isAdminActive 
                  ? 'bg-rose-500 text-white shadow-inner font-bold' 
                  : 'bg-[#2E2E3E] text-slate-300 hover:bg-[#3E3E52]'
              }`}
            >
              <SettingsIcon className="w-3.5 h-3.5" />
              <span>{isAdminActive ? 'Kiosk Mode' : 'Admin Area'}</span>
            </button>
          </div>
        </div>
      )}

      {/* Main Body */}
      <div className="flex-1 flex flex-col lg:flex-row">
        
        {/* Left Side: System Diagnostics / Flutter Inspector Window (Only visible in Sandbox view) */}
        {!isFullscreen && (
          <div className="w-full lg:w-72 bg-[#FAF8F5] border-r-2 border-stone-200 p-4 font-mono text-xs flex flex-col gap-4 shrink-0">
            <div className="bg-stone-100 p-3 rounded-2xl border border-stone-200 purikura-shadow">
              <div className="flex items-center justify-between font-bold text-[#4B5563] border-b border-stone-200 pb-2 mb-2">
                <span className="flex items-center gap-1">
                  <Cpu className="w-4 h-4 text-rose-400" /> SYSTEM HEALTH
                </span>
                <span className="text-[10px] bg-stone-200 px-1.5 py-0.5 rounded text-stone-600">ONLINE</span>
              </div>
              
              <div className="space-y-1.5 text-stone-600 text-[11px]">
                <div id="metric-printer" className="flex justify-between">
                  <span>Printer Status:</span>
                  <span className="text-emerald-600 font-bold">READY</span>
                </div>
                <div id="metric-paper" className="flex justify-between">
                  <span>Paper Remaining:</span>
                  <span className="text-amber-600 font-bold">{adminSettings.paperRemainingCount} pcs</span>
                </div>
                <div id="metric-ribbon" className="flex justify-between">
                  <span>Ribbon level:</span>
                  <span className="text-rose-500 font-bold">{adminSettings.ribbonRemainingPercent}%</span>
                </div>
                <div id="metric-pricing" className="flex justify-between border-t border-dashed border-stone-200 pt-1.5 mt-1.5">
                  <span>Cost per strip:</span>
                  <span className="text-indigo-600 font-medium">Rp {adminSettings.pricingIDR.toLocaleString('id-ID')}</span>
                </div>
              </div>
            </div>

            <div className="flex-1 flex flex-col bg-stone-900 text-[#C0C0D0] p-3.5 rounded-2xl border-2 border-stone-950 shadow-inner relative max-h-[300px] lg:max-h-none overflow-hidden">
              <div className="flex items-center justify-between border-b border-[#2E2E3E] pb-2 mb-2">
                <span className="flex items-center gap-1 text-[10px] tracking-wider text-rose-400 font-bold">
                  <Terminal className="w-3.5 h-3.5" /> FLUTTER_STDOUT_LOGS
                </span>
                <div className="flex gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-red-400"></span>
                  <span className="w-1.5 h-1.5 rounded-full bg-yellow-400"></span>
                  <span className="w-1.5 h-1.5 rounded-full bg-green-400"></span>
                </div>
              </div>

              <div id="diagnostic-stdout" className="flex-1 overflow-y-auto font-mono text-[10px] space-y-1.5 custom-scrollbar pr-1 select-text">
                <AnimatePresence initial={false}>
                  {systemLogs.slice(-15).map((log, index) => {
                    // Check severity color
                    let logColor = 'text-stone-300';
                    if (log.includes('[ERROR]')) logColor = 'text-red-400 font-bold';
                    else if (log.includes('[SYSTEM]')) logColor = 'text-cyan-300';
                    else if (log.includes('[ACTION]')) logColor = 'text-amber-300';
                    else if (log.includes('[PRINT]')) logColor = 'text-emerald-400';

                    return (
                      <motion.div 
                        key={index}
                        initial={{ opacity: 0, x: -10 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0 }}
                        transition={{ duration: 0.15 }}
                        className={`leading-relaxed break-all ${logColor}`}
                      >
                        <span className="opacity-40">❯</span> {log}
                      </motion.div>
                    );
                  })}
                </AnimatePresence>
              </div>

              <div className="absolute bottom-2 right-3 text-[9px] text-[#5A5A6E] select-none font-bold">
                FLUTTER DEV SHELL v1.4
              </div>
            </div>

            {/* Simulated Desktop Widgets */}
            <div className="bg-gradient-to-br from-rose-50 to-pink-50 border border-pink-100 p-3 rounded-2xl text-stone-700">
              <div className="flex items-center gap-1.5 text-rose-400 font-bold text-[11px] mb-1">
                <Sparkles className="w-3.5 h-3.5 stroke-[2.5]" />
                <span>DECORATION TIP</span>
              </div>
              <p className="text-[10px] leading-relaxed text-stone-500">
                Aplikasi ini mereplikasi aesthetic <b>Purikura jepang tahun 2000-an</b>. Warna-warna pastel, sticker strip, countdown ceria, dan interface touch friendly.
              </p>
            </div>
          </div>
        )}

        {/* Right Side: The interactive simulator wrapper */}
        <div className="flex-1 bg-[#EBE7DF] p-2 sm:p-4 lg:p-6 flex flex-col items-center justify-center relative">
          
          {/* Interactive Floating Action Menu inside Workspace */}
          <div className="absolute top-2 left-4 right-4 sm:top-4 z-50 flex items-center justify-between select-none">
            {/* Control View Toggles & Workspace info */}
            <div className="flex items-center gap-2 bg-stone-900/80 backdrop-blur-md text-white px-3 py-1.5 rounded-full text-xs purikura-shadow">
              <button 
                id="toggle-view-sandbox"
                onClick={() => setIsFullscreen(false)} 
                className={`px-3 py-1 rounded-full cursor-pointer transition-colors flex items-center gap-1 ${!isFullscreen ? 'bg-rose-500 font-bold' : 'hover:bg-white/10'}`}
              >
                <Monitor className="w-3.5 h-3.5" />
                <span className="hidden sm:inline">Desktop Frame</span>
              </button>
              <button 
                id="toggle-view-fullscreen"
                onClick={() => {
                  setIsFullscreen(true);
                  if (isAdminActive) onToggleAdmin(); // Reset admin pane when returning to pure full kiosk mode
                }} 
                className={`px-3 py-1 rounded-full cursor-pointer transition-colors flex items-center gap-1 ${isFullscreen ? 'bg-rose-500 font-bold' : 'hover:bg-white/10'}`}
              >
                <AppWindow className="w-3.5 h-3.5" />
                <span className="hidden sm:inline">Kiosk Mode </span>
              </button>
            </div>

            {/* Quick Admin Access (Tiny cute vintage keychain button at top right) */}
            <div className="flex items-center gap-2">
              <button
                id="btn-quick-admin-toggle"
                onClick={onToggleAdmin}
                className="bg-[#FFFDFB] text-[#9A3412] hover:bg-[#FFF5ED] border-2 border-[#EA580C] px-3 py-1.5 rounded-full text-xs font-bold purikura-shadow flex items-center gap-1 cursor-pointer"
              >
                <SettingsIcon className="w-3.5 h-3.5" />
                <span>{isAdminActive ? 'Kiosk UI' : 'ADMIN PANEL'}</span>
              </button>
            </div>
          </div>

          {/* Simulated Windows Executable Chassis Wrapper */}
          <div className={`w-full max-w-[1200px] h-auto aspect-[16/9] bg-[#FAF8F5] transition-all duration-300 flex flex-col relative overflow-hidden ${
            isFullscreen 
              ? 'rounded-none shadow-none border-0 w-full h-full' 
              : 'rounded-[32px] border-[5px] border-stone-900 shadow-[10px_10px_0px_#9A3412] md:my-4'
          }`}>
            
            {/* Windows Window Title Bar (Only in windowed mode) */}
            {!isFullscreen && (
              <div className="bg-[#FAF8F5] border-b-3 border-stone-900 px-6 py-3 flex items-center justify-between select-none shrink-0 bg-gradient-to-r from-[#FAF8F5] to-[#F1ECE4]">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-full bg-[#FF7E7E]/10 flex items-center justify-center">
                    <Sparkles className="w-5 h-5 text-rose-500 animate-spin" style={{ animationDuration: '6s' }} />
                  </div>
                  <div>
                    <span className="font-outfit font-bold text-stone-900 text-sm tracking-wide">
                      NEO_BOOTH_2000.exe
                    </span>
                    <span className="ml-2 font-mono text-[10px] text-stone-500 border border-stone-300 px-1.5 py-0.2 rounded bg-stone-100">
                      v1.2 // Flutter Desktop x64
                    </span>
                  </div>
                </div>

                {/* Windows 11/Classic Window Controls */}
                <div className="flex items-center gap-1.5">
                  <button onClick={() => setIsFullscreen(true)} className="w-[30px] h-[30px] rounded-lg bg-stone-100 hover:bg-stone-200 flex items-center justify-center cursor-pointer border border-stone-300 group">
                    <Minimize2 className="w-3.5 h-3.5 text-stone-700 transition-transform group-hover:scale-90" />
                  </button>
                  <button onClick={() => setIsFullscreen(true)} className="w-[30px] h-[30px] rounded-lg bg-stone-100 hover:bg-stone-200 flex items-center justify-center cursor-pointer border border-stone-300 group">
                    <Maximize2 className="w-3.5 h-3.5 text-stone-700 transition-transform group-hover:scale-110" />
                  </button>
                  <button onClick={() => alert('This is a simulated photobooth terminal applet!')} className="w-[30px] h-[30px] rounded-lg bg-[#FEE2E2] hover:bg-[#FCA5A5] flex items-center justify-center cursor-pointer border-2 border-stone-900 text-red-700 font-bold text-xs select-none">
                    ✕
                  </button>
                </div>
              </div>
            )}

            {/* Core Kiosk Application Workspace viewport */}
            <div className="flex-1 relative overflow-hidden bg-[#FDF8F5] flex flex-col pt-2">
              {/* Retro Arcade Garnish - Clean Minimalism Accent */}
              <div className="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-[#FFB7C5] via-[#BDE0FE] to-[#C1D3FE] z-50"></div>
              {children}
            </div>

            {/* Cute mini Footer bar to mimic real kiosk footer with support lines */}
            <div className="bg-[#FFFDFB] border-t-2 border-stone-200 px-6 py-2.5 flex items-center justify-between text-[11px] text-stone-500 shrink-0 select-none">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                <span className="font-outfit font-medium">Virtual Cash Terminal Connected // QRIS Core API</span>
              </div>
              <div className="flex items-center gap-4">
                <span className="hidden md:inline font-mono text-[#78716C]">Session Status: <b className="text-stone-800 uppercase">{activeScreen}</b></span>
                <span className="bg-[#FEF3C7] text-[#D97706] px-2.5 py-0.5 rounded-full font-outfit font-bold text-[10px]">
                  ♥ MADE WITH FLUTTER RETRO DESIGN v3.56
                </span>
              </div>
            </div>

          </div>

          {/* Outer Frame Retro Vinyl Decals & Toys (Only in windowed mode) */}
          {!isFullscreen && (
            <div className="absolute right-[-40px] top-[150px] hidden xl:flex flex-col gap-6 select-none opacity-80 rotate-12 transition-transform hover:rotate-6 duration-300">
              <div className="bg-[#FFE4E6] border-2 border-stone-950 p-2.5 shadow-[4px_4px_0px_0px_#1A1A24] rounded-2xl flex flex-col items-center">
                <span className="text-[10px] font-bold font-display text-rose-500">ときめき</span>
                <span className="text-xs font-bold text-stone-900 border-2 border-stone-900 px-1 py-0.5 mt-1 bg-white rounded">PRINT CLUB</span>
              </div>
              <div className="bg-[#FEF3C7] border-2 border-stone-950 p-2 shadow-[4px_4px_0px_0px_#1A1A24] rounded-full flex items-center justify-center rotate-45">
                <Sparkles className="w-6 h-6 text-amber-500 animate-pulse" />
              </div>
            </div>
          )}

          {!isFullscreen && (
            <div className="absolute left-[-50px] bottom-[100px] hidden xl:flex flex-col gap-4 select-none opacity-80 -rotate-12 transition-transform hover:rotate-0 duration-300">
              <div className="bg-[#E0F2FE] border-2 border-stone-950 p-3 shadow-[4px_4px_0px_0px_#1A1A24] rounded-3xl flex flex-col items-center">
                <span className="text-[11px] font-mono font-bold text-cyan-600">★ 2000s ★</span>
                <span className="text-[12px] font-outfit font-bold text-stone-900">SODA CANDY</span>
              </div>
            </div>
          )}

        </div>
      </div>
    </div>
  );
}
