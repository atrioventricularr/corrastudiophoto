import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import './index.css';
import { BrandThemeProvider, ThemedBackground } from './branding';
import { PaymentSettingsProvider, PaymentTransactionProvider } from './payments';
import { SessionLifecycleProvider } from './sessions';
import { PrinterProfileProvider } from './print';
import { LayoutProvider } from './layouts';
import { TemplateProvider } from './templates';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrandThemeProvider>
      <PaymentSettingsProvider>
        <PaymentTransactionProvider>
          <SessionLifecycleProvider>
            <PrinterProfileProvider>
              <LayoutProvider>
                <TemplateProvider>
                  <ThemedBackground />
                  <App />
                </TemplateProvider>
              </LayoutProvider>
            </PrinterProfileProvider>
          </SessionLifecycleProvider>
        </PaymentTransactionProvider>
      </PaymentSettingsProvider>
    </BrandThemeProvider>
  </StrictMode>,
);
