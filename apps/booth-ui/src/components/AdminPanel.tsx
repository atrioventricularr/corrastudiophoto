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
import { SessionLifecyclePanel } from './admin/SessionLifecyclePanel';
import { CameraSetupPanel } from './camera';
import { AdminMobileSectionNav, AdminSidebar, type AdminSectionId } from './admin/AdminSidebar';
import { PrinterProfilePanel } from './admin/PrinterProfilePanel';
import { LayoutAdminPanel } from './admin/LayoutAdminPanel';
import { TemplateAdminPanel } from './admin/TemplateAdminPanel';

interface AdminPanelProps {
  settings: AdminSettings;
  onUpdateSettings: (newSet: AdminSettings) => void;
  templates: FrameTemplate[];
  onAddTemplate: (tpl: FrameTemplate) => void;
  onRemoveTemplate: (id: string) => void;
  onClose: () => void;
  lang: 'ID' | 'EN' | 'JP';
}




function AdminPage({
  activeSection,
  section,
  children,
}: {
  activeSection: AdminSectionId;
  section: AdminSectionId;
  children: React.ReactNode;
}) {
  if (activeSection !== section) {
    return null;
  }

  return <div className="space-y-6">{children}</div>;
}

export default function AdminPanel({
  settings,
  onUpdateSettings,
  templates,
  onAddTemplate,
  onRemoveTemplate,
  onClose,
  lang,
}: AdminPanelProps) {
  const [activeSection, setActiveSection] =
    useState<AdminSectionId>('hardware');

  const pricingIDR =
    typeof settings.pricingIDR === 'number' ? settings.pricingIDR : 0;

  const templateCount = Array.isArray(templates) ? templates.length : 0;

  return (
    <div className="admin-sidebar-shell h-screen overflow-hidden bg-slate-100 p-4 lg:pl-80">
      <AdminSidebar
        activeSection={activeSection}
        onSectionChange={setActiveSection}
      />

      <main className="mx-auto h-[calc(100vh-2rem)] max-w-7xl overflow-y-auto pr-2 pb-10">
        <AdminMobileSectionNav
          activeSection={activeSection}
          onSectionChange={setActiveSection}
        />

        <header className="mb-6 rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.25em] text-slate-400">
                Corra Admin
              </p>
              <h1 className="mt-1 text-3xl font-black text-slate-950">
                {activeSection.charAt(0).toUpperCase() + activeSection.slice(1)}
              </h1>
              <p className="mt-1 text-sm font-semibold text-slate-500">
                Current language: {lang}
              </p>
            </div>

            <button
              type="button"
              onClick={onClose}
              className="rounded-2xl border border-slate-200 bg-slate-50 px-5 py-3 text-sm font-black text-slate-700"
            >
              Close Admin
            </button>
          </div>
        </header>

        <AdminPage activeSection={activeSection} section="hardware">
          <CameraSetupPanel />
          <PrinterProfilePanel />
        </AdminPage>

        <AdminPage activeSection={activeSection} section="billing">
          <section className="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Base Pricing
            </p>
            <h3 className="mt-1 text-2xl font-black text-slate-950">
              Session Price
            </h3>

            <label className="mt-4 block">
              <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                Base price per session
              </span>
              <input
                type="number"
                value={pricingIDR}
                onChange={(event) =>
                  onUpdateSettings({
                    ...settings,
                    pricingIDR: Number(event.target.value || 0),
                  })
                }
                className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
              />
            </label>
          </section>

          <PaymentSettingsPanel />
          <PaymentTransactionsPanel />
        </AdminPage>

        <AdminPage activeSection={activeSection} section="layout">
          <LayoutAdminPanel />
        </AdminPage>

        <AdminPage activeSection={activeSection} section="template">
          <TemplateAdminPanel />
        </AdminPage>

        <AdminPage activeSection={activeSection} section="branding">
          <BrandAppearancePanel />
          <AdminCredentialPanel />
        </AdminPage>

        <AdminPage activeSection={activeSection} section="sessions">
          <SessionLifecyclePanel />
        </AdminPage>
      </main>
    </div>
  );
}
