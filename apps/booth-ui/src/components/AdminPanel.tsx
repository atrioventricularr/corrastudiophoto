import React, { useState } from 'react';
import { 
  Settings, 
  Printer, 
  Layers, 
  CreditCard, 
  Ticket, 
  Timer,
  Save, 
  X, 
  Plus, 
  Trash2, 
  Activity, 
  AlertTriangle,
  Info 
} from 'lucide-react';
import { motion } from 'motion/react';
import { AdminSettings, FrameTemplate } from '../types';
import { playRetroBeep } from '../utils/audio';
import BrandAppearancePanel from './admin/BrandAppearancePanel';
import AdminCredentialPanel from './admin/AdminCredentialPanel';
import PaymentSettingsPanel from './admin/PaymentSettingsPanel';
import PaymentTransactionsPanel from './admin/PaymentTransactionsPanel';

interface AdminPanelProps {
  settings: AdminSettings;
  onUpdateSettings: (newSet: AdminSettings) => void;
  templates: FrameTemplate[];
  onAddTemplate: (tpl: FrameTemplate) => void;
  onRemoveTemplate: (id: string) => void;
  onClose: () => void;
  lang: 'ID' | 'EN' | 'JP';
}

export default function AdminPanel({
  settings,
  onUpdateSettings,
  templates,
  onAddTemplate,
  onRemoveTemplate,
  onClose,
  lang
}: AdminPanelProps) {
  // Direct state handlers
  const [pricing, setPricing] = useState<number>(settings.pricingIDR);
  const [countdown, setCountdown] = useState<number>(settings.countdownDurationSec);
  const [sessionTimeout, setSessionTimeout] = useState<number>(settings.sessionTimeoutSec);
  const [paper, setPaper] = useState<number>(settings.paperRemainingCount);
  const [ribbon, setRibbon] = useState<number>(settings.ribbonRemainingPercent);
  const [vouchersInput, setVouchersInput] = useState<string>(settings.activeVouchers.join(', '));
  const [qrUrl, setQrUrl] = useState<string>(settings.qrisImageUrl);
  const [printerModel, setPrinterModel] = useState<string>(settings.printerModelName);
  const [autoPrint, setAutoPrint] = useState<boolean>(settings.autoPrintEnabled);

  // Custom frame template builder state
  const [newTplName, setNewTplName] = useState('');
  const [newTplBgColor, setNewTplBgColor] = useState('#FEF2F4');
  const [newTplBorderColor, setNewTplBorderColor] = useState('#FDA4AF');
  const [newTplPattern, setNewTplPattern] = useState<'solid' | 'grid' | 'dots' | 'stars' | 'cherry' | 'vintage'>('stars');
  const [newTplSticker, setNewTplSticker] = useState('SWEET HEART ♥');
  const [newTplTextColor, setNewTplTextColor] = useState('#9F1239');

  // Simulated paper jam toggle
  const [isJamSimulated, setIsJamSimulated] = useState<boolean>(false);

  // Saving settings handler
  const handleSaveSettings = () => {
    playRetroBeep('success');
    
    // Convert comma-separated clean voucher array
    const cleanVouchers = vouchersInput
      .split(',')
      .map(v => v.trim().toUpperCase())
      .filter(v => v.length > 0);

    onUpdateSettings({
      pricingIDR: pricing,
      sessionTimeoutSec: sessionTimeout,
      countdownDurationSec: countdown,
      paperRemainingCount: paper,
      ribbonRemainingPercent: ribbon,
      activeVouchers: cleanVouchers,
      qrisImageUrl: qrUrl,
      printerModelName: printerModel,
      autoPrintEnabled: autoPrint,
      currencySymbol: 'Rp'
    });

    alert('Settings successfully updated! All Kiosk rules synchronised live.');
  };

  const handleCreateTemplate = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTplName.trim()) return;

    playRetroBeep('success');
    const customTpl: FrameTemplate = {
      id: `custom_${Date.now()}`,
      name: `✨ ${newTplName}`,
      bgColor: newTplBgColor,
      borderColor: newTplBorderColor,
      pattern: newTplPattern,
      stickerText: newTplSticker.toUpperCase(),
      stickerColor: newTplBorderColor,
      textColor: newTplTextColor,
      isCustom: true
    };
    
    onAddTemplate(customTpl);

    // Reset template fields
    setNewTplName('');
  };

  return (
    <div className="flex-1 w-full bg-stone-900 text-stone-100 flex flex-col justify-between p-4 sm:p-8 select-none overflow-y-auto custom-scrollbar">
      
      {/* Top Admin Navigation Header */}
      <div className="flex items-center justify-between border-b border-stone-800 pb-4 shrink-0">
        <div className="flex items-center gap-2.5">
          <div className="w-10 h-10 rounded-2xl bg-rose-500/10 flex items-center justify-center border border-rose-500/30">
            <Settings className="w-5 h-5 text-rose-500 animate-spin" style={{ animationDuration: '8s' }} />
          </div>
          <div>
            <h2 className="font-display font-extrabold text-sm tracking-wide text-white uppercase leading-none">
              ADMINISTRATOR CONTROLLER
            </h2>
            <p className="text-[10px] text-stone-400 font-mono mt-1">
              Terminal: terminal_kiosk_x44 // session_status: listening
            </p>
          </div>
        </div>

        {/* Exit back to terminal button */}
        <button 
          id="btn-admin-close"
          onClick={() => { playRetroBeep('click'); onClose(); }}
          className="p-2 bg-stone-800 hover:bg-stone-700 hover:text-white rounded-xl border border-stone-700 cursor-pointer transition-colors"
        >
          <X className="w-4.5 h-4.5" />
        </button>
      </div>

      {/* White-label brand/theme/background settings */}
      <div className="mt-6">
        <BrandAppearancePanel />
        <div className="mt-6">
          <AdminCredentialPanel />
        <div className="mt-6">
          <PaymentSettingsPanel />
        <div className="mt-6">
          <PaymentTransactionsPanel />
        </div>
        </div>
        </div>
      </div>

      {/* Main double column form container */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-3 gap-6 my-6 overflow-y-visible">
        
        {/* Column 1: Financial & Printer settings */}
        <div className="space-y-5 bg-stone-950 border border-stone-800 p-5 rounded-3xl">
          
          <div className="flex items-center gap-2 text-rose-400 uppercase text-[11px] font-mono border-b border-stone-800 pb-2">
            <CreditCard className="w-4 h-4" />
            <span>Pricing & Payment Setup</span>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-xs text-stone-300 font-outfit mb-1.5 font-bold">Base Price per Sesi (IDR):</label>
              <input 
                id="admin-pricing"
                type="number"
                step="5000"
                value={pricing}
                onChange={(e) => setPricing(Number(e.target.value))}
                className="w-full px-3.5 py-2 bg-stone-900 border border-stone-700 rounded-xl text-xs text-white focus:outline-none focus:border-rose-500 font-mono font-bold"
              />
            </div>

            <div>
              <label className="block text-xs text-stone-300 font-outfit mb-1.5 font-bold">QRIS Merchant QR-URL:</label>
              <input 
                id="admin-qris-url"
                type="text"
                value={qrUrl}
                onChange={(e) => setQrUrl(e.target.value)}
                className="w-full px-3.5 py-2 bg-stone-900 border border-stone-700 rounded-xl text-xs text-stone-300 font-mono text-[10px] focus:outline-none"
              />
            </div>
          </div>

          {/* Printer status modules */}
          <div className="flex items-center gap-2 text-cyan-400 uppercase text-[11px] font-mono border-b border-stone-800 pb-2 pt-2">
            <Printer className="w-4 h-4" />
            <span>Printer Hardware Telemetry</span>
          </div>

          <div className="space-y-4 text-xs font-outfit">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-stone-300 mb-1.5 font-bold">Kertas Tersisa (pcs):</label>
                <input 
                  id="admin-paper-count"
                  type="number"
                  value={paper}
                  onChange={(e) => setPaper(Number(e.target.value))}
                  className="w-full px-3.5 py-2 bg-stone-900 border border-stone-700 rounded-xl text-[#059669] font-mono font-bold"
                />
              </div>

              <div>
                <label className="block text-stone-300 mb-1.5 font-bold">Ribbon Level (%):</label>
                <input 
                  id="admin-ribbon-lvl"
                  type="number"
                  max="100"
                  value={ribbon}
                  onChange={(e) => setRibbon(Number(e.target.value))}
                  className="w-full px-3.5 py-2 bg-stone-900 border border-stone-700 rounded-xl text-rose-400 font-mono font-bold"
                />
              </div>
            </div>

            <div>
              <label className="block text-stone-300 mb-1.5 font-bold">Model Nama Printer:</label>
              <input 
                id="admin-printer-name"
                type="text"
                value={printerModel}
                onChange={(e) => setPrinterModel(e.target.value)}
                className="w-full px-3 py-2 bg-stone-900 border border-stone-700 rounded-xl text-stone-300 font-mono text-[10px]"
              />
            </div>

            {/* Paper jam hardware simulator button with alerts */}
            <div className="p-3.5 bg-stone-900 border border-stone-800 rounded-2xl">
              <div className="flex items-center justify-between mb-2">
                <span className="font-semibold text-stone-300 text-[11px]">Simulasi Jam Kertas</span>
                <span className={`px-2 py-0.5 rounded text-[9px] font-bold ${isJamSimulated ? 'bg-red-900 text-red-200' : 'bg-emerald-950 text-emerald-300'}`}>
                  {isJamSimulated ? 'PAPER_JAM' : 'NORMAL'}
                </span>
              </div>
              <button 
                id="btn-simulate-jam"
                type="button"
                onClick={() => {
                  playRetroBeep('click');
                  setIsJamSimulated(!isJamSimulated);
                }}
                className={`w-full py-2 rounded-xl text-[10px] font-bold border ${
                  isJamSimulated 
                    ? 'bg-red-800/10 text-red-400 border-red-800 hover:bg-red-800/20' 
                    : 'bg-stone-800 text-stone-300 border-stone-700 hover:bg-stone-700'
                } cursor-pointer`}
              >
                {isJamSimulated ? 'Clear Virtual Paper Jam' : 'Trigger Virtual Paper Jam'}
              </button>
            </div>
          </div>

        </div>

        {/* Column 2: Coupon management & session timers */}
        <div className="space-y-5 bg-stone-950 border border-stone-800 p-5 rounded-3xl">
          
          <div className="flex items-center gap-2 text-[#D97706] uppercase text-[11px] font-mono border-b border-stone-800 pb-2">
            <Ticket className="w-4 h-4" />
            <span>Vouchers & Security Options</span>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-xs text-stone-300 font-outfit mb-1.5 font-bold">Daftar Voucher Aktif (Koma):</label>
              <textarea 
                id="admin-vouchers-list"
                rows={3}
                value={vouchersInput}
                onChange={(e) => setVouchersInput(e.target.value)}
                placeholder="NEOBOOT2026, RETRO20, WEDDINGPASS"
                className="w-full px-3 py-2 bg-stone-900 border border-stone-700 rounded-xl text-xs text-amber-500 font-mono font-bold focus:outline-none focus:border-[#D97706]"
              />
              <span className="text-[9px] text-stone-500 mt-1 block">Masukkan kode dipisah dengan tanda koma (,), misal: <b>HARUMUKU, PROMO20</b></span>
            </div>
          </div>

          {/* Core Session calibrators */}
          <div className="flex items-center gap-2 text-amber-400 uppercase text-[11px] font-mono border-b border-stone-800 pb-2 pt-2">
            <Timer className="w-4 h-4" />
            <span>Session Timers & Auto-Prints</span>
          </div>

          <div className="space-y-4 text-xs font-outfit">
            <div>
              <div className="flex justify-between items-center mb-1.5">
                <label className="text-stone-300 font-bold">Countdown Capture (Detik):</label>
                <span className="font-mono text-emerald-400 font-bold">{countdown}s</span>
              </div>
              <input 
                id="admin-countdown-range"
                type="range"
                min="3"
                max="10"
                step="1"
                value={countdown}
                onChange={(e) => setCountdown(Number(e.target.value))}
                className="w-full accent-rose-500"
              />
            </div>

            <div>
              <div className="flex justify-between items-center mb-1.5">
                <label className="text-stone-300 font-bold">Beban Timeout Sesi (Detik):</label>
                <span className="font-mono text-indigo-400 font-bold">{sessionTimeout}s</span>
              </div>
              <input 
                id="admin-timeout-range"
                type="range"
                min="60"
                max="300"
                step="10"
                value={sessionTimeout}
                onChange={(e) => setSessionTimeout(Number(e.target.value))}
                className="w-full accent-indigo-500"
              />
            </div>
          </div>

        </div>

        {/* Column 3: Live Custom Theme borders Frame Maker! */}
        <div className="space-y-4 bg-stone-950 border border-stone-800 p-5 rounded-3xl">
          
          <div className="flex items-center gap-2 text-rose-400 uppercase text-[11px] font-mono border-b border-stone-800 pb-2">
            <Layers className="w-4 h-4" />
            <span>Add Custom Photo Frames</span>
          </div>

          <form onSubmit={handleCreateTemplate} className="space-y-3.5 text-xs font-outfit">
            <div>
              <label className="block text-stone-300 mb-1 font-bold">Nama Frame Template:</label>
              <input 
                id="admin-tpl-name"
                type="text"
                placeholder="Retro Sakura Sunset..."
                value={newTplName}
                onChange={(e) => setNewTplName(e.target.value)}
                className="w-full px-3 py-2 bg-stone-900 border border-stone-700 rounded-xl text-white"
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-stone-300 mb-1 font-bold">Bg Color (Hex):</label>
                <input 
                  id="admin-tpl-bg"
                  type="color"
                  value={newTplBgColor}
                  onChange={(e) => setNewTplBgColor(e.target.value)}
                  className="w-full h-8 bg-stone-900 border border-stone-700 rounded-xl p-1 cursor-pointer"
                />
              </div>

              <div>
                <label className="block text-stone-300 mb-1 font-bold">Border Color:</label>
                <input 
                  id="admin-tpl-border"
                  type="color"
                  value={newTplBorderColor}
                  onChange={(e) => setNewTplBorderColor(e.target.value)}
                  className="w-full h-8 bg-stone-900 border border-stone-700 rounded-xl p-1 cursor-pointer"
                />
              </div>
            </div>

            <div>
              <label className="block text-stone-300 mb-1 font-bold">Pattern Lapis:</label>
              <select 
                id="admin-tpl-pattern"
                value={newTplPattern}
                onChange={(e) => setNewTplPattern(e.target.value as any)}
                className="w-full px-3 py-2 bg-stone-900 border border-stone-700 rounded-xl text-white outline-none"
              >
                <option value="solid">Polos (Solid)</option>
                <option value="grid">Kotak-Kotak (Grid)</option>
                <option value="dots">Titik Pastel (Dots)</option>
                <option value="stars">Bintang Retro (Stars)</option>
                <option value="cherry">Ceri Kawaii (Cherry)</option>
                <option value="vintage">Lomo Vignette (vintage)</option>
              </select>
            </div>

            <div>
              <label className="block text-stone-300 mb-1 font-bold">Teks Sticker Bawah:</label>
              <input 
                id="admin-tpl-sticker"
                type="text"
                value={newTplSticker}
                onChange={(e) => setNewTplSticker(e.target.value.toUpperCase())}
                className="w-full px-3 py-2 bg-stone-900 border border-stone-700 rounded-xl text-white uppercase font-sans font-bold"
              />
            </div>

            <button 
              id="btn-add-custom-tpl"
              type="submit"
              className="w-full bg-rose-500 hover:bg-rose-600 text-white font-bold py-2.5 rounded-xl transition-colors cursor-pointer flex items-center justify-center gap-1 mt-2.5"
            >
              <Plus className="w-4 h-4" />
              <span>Deploy Custom Theme</span>
            </button>
          </form>

        </div>

      </div>

      {/* Templates currently active gallery manager list with deletion */}
      <div className="bg-stone-950 border border-stone-800 p-5 rounded-3xl mb-6">
        <h3 className="text-white text-xs font-display font-medium uppercase border-b border-stone-800 pb-2 mb-3 tracking-wider">
          Currently Deployed Templates Frame ({templates.length})
        </h3>
        
        <div id="admin-templates-grid" className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3 overflow-y-auto max-h-48 custom-scrollbar">
          {templates.map((tpl) => (
            <div 
              key={tpl.id} 
              style={{ backgroundColor: tpl.bgColor, color: tpl.textColor }}
              className="p-3 rounded-2xl border-2 border-stone-800 flex items-center justify-between"
            >
              <div>
                <span className="font-outfit font-extrabold text-xs">{tpl.name}</span>
                <span className="text-[8px] font-mono block opacity-60 mt-0.5">Pattern: {tpl.pattern} &middot; sticker: &quot;{tpl.stickerText}&quot;</span>
              </div>
              
              {tpl.isCustom && (
                <button 
                  id={`btn-delete-tpl-${tpl.id}`}
                  onClick={() => { playRetroBeep('shutter'); onRemoveTemplate(tpl.id); }}
                  className="p-1.5 bg-red-950 hover:bg-red-900 border border-red-800 hover:text-white rounded-lg text-red-400 cursor-pointer text-xs"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Floating Save/Footer bars */}
      <div className="border-t border-stone-800 pt-5 flex items-center justify-between shrink-0">
        <div className="flex items-center gap-2 select-text">
          <Activity className="w-4.5 h-4.5 text-emerald-500 animate-pulse" />
          <span className="text-[10px] text-stone-500 font-mono text-xs">
            KIOSK CORE TELEMETRY STATUS: HIGH-GRADE // DECONNECTS: 0
          </span>
        </div>

        <button 
          id="btn-admin-save"
          onClick={handleSaveSettings}
          className="px-6 py-3 bg-gradient-to-r from-emerald-500 to-emerald-600 text-stone-950 font-display rounded-2xl font-black text-xs hover:translate-y-0.5 transition-all cursor-pointer flex items-center gap-1.5 shadow-md shadow-emerald-500/10"
        >
          <Save className="w-4 h-4 fill-stone-950" />
          <span>Save Framework Variables</span>
        </button>
      </div>

    </div>
  );
}
