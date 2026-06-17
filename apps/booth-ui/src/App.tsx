import React, { useState, useEffect } from 'react';
import { DEFAULT_LAYOUTS, DEFAULT_TEMPLATES, INITIAL_ADMIN_SETTINGS } from './constants';
import { LayoutType, FrameTemplate, AdminSettings, ApplicationScreen } from './types';
import { playRetroBeep } from './utils/audio';
import { isCorraDesktop, readDesktopLicenseCache, type CorraVerifyLicenseResult } from './lib/desktop-api';

// Visual Screen Components
import WindowsOuterFrame from './components/WindowsOuterFrame';
import WelcomeScreen from './components/WelcomeScreen';
import PaymentScreen from './components/PaymentScreen';
import LayoutSelectionScreen from './components/LayoutSelectionScreen';
import TemplateSelectionScreen from './components/TemplateSelectionScreen';
import CameraCaptureScreen from './components/CameraCaptureScreen';
import ProcessingScreen from './components/ProcessingScreen';
import ResultScreen from './components/ResultScreen';
import AdminPanel from './components/AdminPanel';
import AdminLoginScreen from './components/AdminLoginScreen';
import LicenseActivationScreen from './components/LicenseActivationScreen';
import { useSessionLifecycle } from './sessions';

export default function App() {
  const {
    currentSession,
    startBoothSession,
    transitionBoothSession,
    cancelBoothSession,
  } = useSessionLifecycle();

  // Navigation active screen
  const [activeScreen, setActiveScreen] = useState<ApplicationScreen>('welcome');
  const [isAdminActive, setIsAdminActive] = useState<boolean>(false);
  const [isAdminAuthenticated, setIsAdminAuthenticated] = useState<boolean>(false);
  const [isLicenseReady, setIsLicenseReady] = useState<boolean>(false);
  const [licenseSummary, setLicenseSummary] = useState<string>('');
  
  // Localized dictionaries state
  const [lang, setLang] = useState<'ID' | 'EN' | 'JP'>('ID');

  // Interactive capture/frame options states
  const [selectedLayoutId, setSelectedLayoutId] = useState<LayoutType>('4_photo');
  const [selectedTemplateId, setSelectedTemplateId] = useState<string>('sweet_peach');
  const [capturedPhotos, setCapturedPhotos] = useState<string[]>([]);
  
  // Custom states synchronised with Admin
  const [adminSettings, setAdminSettings] = useState<AdminSettings>(INITIAL_ADMIN_SETTINGS);
  const [templates, setTemplates] = useState<FrameTemplate[]>(DEFAULT_TEMPLATES);

  // rolling system console logs
  const [systemLogs, setSystemLogs] = useState<string[]>([]);

  // Sound and log initializers
  const addLog = (msg: string) => {
    const timestamp = new Date().toISOString().substring(11, 19);
    setSystemLogs(prev => [...prev, `[${timestamp}] ${msg}`]);
  };

  useEffect(() => {
    addLog('[SYSTEM] Flutter self_service_kiosk compiled successfully.');
    addLog('[SYSTEM] Mounting Windows desktop execution frame host.');
    addLog('[IO System] Camera sensor test: READY');
    addLog('[IO System] Thermal Printer DNP RX1HS: ONLINE');
    addLog('[IO System] Waiting for touch sensor command event.');
  }, []);

  useEffect(() => {
    let isCancelled = false;

    async function checkLicenseCache() {
      if (!isCorraDesktop()) {
        setIsLicenseReady(true);
        setLicenseSummary('Browser preview mode');
        addLog('[LICENSE] Browser preview mode detected. License gate bypassed for development.');
        return;
      }

      const cache = await readDesktopLicenseCache();

      if (isCancelled) {
        return;
      }

      if (cache?.valid === true) {
        setIsLicenseReady(true);
        setLicenseSummary(cache.license?.licenseCode || 'ACTIVE LICENSE');
        addLog('[LICENSE] Cached license accepted. Device already activated.');
        setActiveScreen('welcome');
      } else {
        setIsLicenseReady(false);
        setLicenseSummary('');
        addLog('[LICENSE] No valid local license cache. Activation required.');
        setActiveScreen('license_activation');
      }
    }

    checkLicenseCache();

    return () => {
      isCancelled = true;
    };
  }, []);

  // Sync log whenever user changes language
  const handleLanguageChanged = (newLang: 'ID' | 'EN' | 'JP') => {
    setLang(newLang);
    addLog(`[ACTION] Language translation altered: ${newLang}`);
  };

  const handleLicenseActivated = (result: CorraVerifyLicenseResult) => {
    setIsLicenseReady(true);
    setLicenseSummary(result.license?.licenseCode || result.source || 'ACTIVE LICENSE');
    addLog('[LICENSE] License activated successfully. Customer loop unlocked.');
    setActiveScreen('welcome');
  };


  const handleAdminLoginCancel = () => {
    setIsAdminAuthenticated(false);
    setIsAdminActive(false);
    setActiveScreen('welcome');
    addLog('[ADMIN] Admin login cancelled.');
  };

  const handleAdminLoginSuccess = () => {
    setIsAdminAuthenticated(true);
  };

  const handleStartSession = () => {
    const session = startBoothSession({
      metadata: {
        source: 'welcome_screen',
      },
    });

    transitionBoothSession({
      toStatus: 'payment_pending',
      reason: 'session_started_from_welcome',
      metadata: {
        sessionId: session.id,
      },
    });

    if (isCorraDesktop() && !isLicenseReady) {
      addLog('[LICENSE] Start blocked. License activation required.');
      setActiveScreen('license_activation');
      return;
    }

    addLog('[ACTION] Touched START button. Sesi initialized.');
    addLog(`[SYSTEM] Cost per print set at Rp ${adminSettings.pricingIDR.toLocaleString('id-ID')}`);
    setActiveScreen('payment');
  };

  const handlePaymentCompleted = (activatedBy?: string) => {
    if (activatedBy === 'SIMULATED_QRIS') {
      addLog(`[PRINT] Dynamic QRIS signal verified! Activated successfully.`);
    } else {
      addLog(`[PRINT] Voucher code validated: "${activatedBy}". Bypassing checkout pricing.`);
    }
    setActiveScreen('layout_select');
  };

  const handleSelectLayout = (layoutId: LayoutType) => {
    setSelectedLayoutId(layoutId);
    addLog(`[ACTION] Selected photo layout: ${layoutId.toUpperCase()}`);
  };

  const handleSelectTemplate = (templateId: string) => {
    setSelectedTemplateId(templateId);
    const tplName = templates.find(t => t.id === templateId)?.name || templateId;
    addLog(`[ACTION] Swapped frame template theme to: "${tplName}"`);
  };

  const handlePhotosCaptured = (photosArr: string[]) => {
    addLog(`[IO System] Captured ${photosArr.length} pose samples securely.`);
    setCapturedPhotos(photosArr);
    setActiveScreen('processing');
  };

  const handleProcessingComplete = () => {
    addLog('[PRINT] Frame composited. Transmitting pixels to physical print buffers...');
    // Decrease paper counters as a mock of action
    setAdminSettings(prev => ({
      ...prev,
      paperRemainingCount: Math.max(0, prev.paperRemainingCount - 1),
      ribbonRemainingPercent: Math.max(1, prev.ribbonRemainingPercent - 1)
    }));
    setActiveScreen('result');
  };

  const handleSessionFinished = () => {
    addLog('[ACTION] Returned to home welcome screen safely. Sesi records purged.');
    setCapturedPhotos([]);
    setActiveScreen('welcome');
  };

  // Toggle admin console safely
  const handleToggleAdmin = () => {
    playRetroBeep('select');
    if (isAdminActive) {
      setIsAdminActive(false);
      setActiveScreen('welcome');
      addLog('[SYSTEM] Returned to the self-service terminal customer loop.');
    } else {
      setIsAdminActive(true);
      setActiveScreen('admin');
      addLog('[SYSTEM] Logged into administrator controller console authority.');
    }
  };

  // Admin dynamic updates
  const handleUpdateAdminSettings = (newSettings: AdminSettings) => {
    setAdminSettings(newSettings);
    addLog('[CONFIG] Settings variables restructured successfully.');
    addLog(`[CONFIG] Price calibrated: Rp ${newSettings.pricingIDR.toLocaleString('id-ID')}`);
    addLog(`[CONFIG] Countdown delay changed: ${newSettings.countdownDurationSec} seconds.`);
  };

  const handleAddTemplate = (newTpl: FrameTemplate) => {
    setTemplates(prev => [...prev, newTpl]);
    addLog(`[CONFIG] Deployed new custom theme: "${newTpl.name}"`);
  };

  const handleRemoveTemplate = (id: string) => {
    setTemplates(prev => prev.filter(t => t.id !== id));
    addLog(`[CONFIG] Deregistered custom frame ID: "${id}"`);
  };

  // Safe fallback descriptors
  const activeLayoutObj = DEFAULT_LAYOUTS.find(l => l.id === selectedLayoutId) || DEFAULT_LAYOUTS[1];
  const activeTemplateObj = templates.find(t => t.id === selectedTemplateId) || templates[0];

  return (
    <WindowsOuterFrame
      activeScreen={activeScreen}
      adminSettings={adminSettings}
      systemLogs={systemLogs}
      onToggleAdmin={handleToggleAdmin}
      isAdminActive={isAdminActive}
    >
      {isAdminActive && !isAdminAuthenticated && (
        <AdminLoginScreen
          onLoginSuccess={handleAdminLoginSuccess}
          onCancel={handleAdminLoginCancel}
        />
      )}

      {/* ADMIN_LOGIN_GATE_HARD_FIX */}
      {isAdminActive && !isAdminAuthenticated && (
        <AdminLoginScreen
          onLoginSuccess={handleAdminLoginSuccess}
          onCancel={handleAdminLoginCancel}
        />
      )}

      {/* Screen Render routers */}
      {activeScreen === 'license_activation' && (
        <LicenseActivationScreen
          onLicenseActivated={handleLicenseActivated}
        />
      )}

      {activeScreen === 'welcome' && (
        <WelcomeScreen 
          onStart={handleStartSession} 
          lang={lang} 
          setLang={handleLanguageChanged} 
        />
      )}

      {activeScreen === 'payment' && (
        <PaymentScreen 
          adminSettings={adminSettings} 
          onPaymentSuccess={handlePaymentCompleted} 
          onBack={() => {
            playRetroBeep('click');
            addLog('[ACTION] Aborted pay selection. Session canceled.');
            setActiveScreen('welcome');
          }}
          lang={lang}
        />
      )}

      {activeScreen === 'layout_select' && (
        <LayoutSelectionScreen
          layouts={DEFAULT_LAYOUTS}
          selectedLayout={selectedLayoutId}
          onSelectLayout={handleSelectLayout}
          onNext={() => {
            addLog('[ACTION] Layout chosen. Stepping into theme selection.');
            setActiveScreen('template_select');
          }}
          onBack={() => {
            addLog('[ACTION] Stepped backward to registration hub.');
            setActiveScreen('payment');
          }}
          lang={lang}
        />
      )}

      {activeScreen === 'template_select' && (
        <TemplateSelectionScreen
          templates={templates}
          selectedTemplateId={selectedTemplateId}
          onSelectTemplate={handleSelectTemplate}
          onNext={() => {
            addLog('[ACTION] Frame theme calibrated. Entering webcam lens loop.');
            setActiveScreen('camera_capture');
          }}
          onBack={() => {
            addLog('[ACTION] Stepped back to collage layout selectors.');
            setActiveScreen('layout_select');
          }}
          lang={lang}
        />
      )}

      {activeScreen === 'camera_capture' && (
        <CameraCaptureScreen
          layout={activeLayoutObj}
          template={activeTemplateObj}
          countdownDuration={adminSettings.countdownDurationSec}
          onCaptureComplete={handlePhotosCaptured}
          onBack={() => {
            addLog('[ACTION] Disengaged camera module. Stepping back.');
            setActiveScreen('template_select');
          }}
          lang={lang}
        />
      )}

      {activeScreen === 'processing' && (
        <ProcessingScreen 
          onComplete={handleProcessingComplete} 
          lang={lang} 
        />
      )}

      {activeScreen === 'result' && (
        <ResultScreen
          layout={activeLayoutObj}
          template={activeTemplateObj}
          photos={capturedPhotos}
          onFinish={handleSessionFinished}
          lang={lang}
        />
      )}

      {activeScreen === 'admin' && (
        <AdminPanel
          settings={adminSettings}
          onUpdateSettings={handleUpdateAdminSettings}
          templates={templates}
          onAddTemplate={handleAddTemplate}
          onRemoveTemplate={handleRemoveTemplate}
          onClose={handleToggleAdmin}
          lang={lang}
        />
      )}
    </WindowsOuterFrame>
  );
}
