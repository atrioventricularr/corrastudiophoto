import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import './index.css';
import { BrandThemeProvider, ThemedBackground } from './branding';
import { PaymentSettingsProvider, PaymentTransactionProvider } from './payments';
import { SessionLifecycleProvider } from './sessions';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrandThemeProvider>
      <PaymentSettingsProvider>
        <PaymentTransactionProvider>
          <SessionLifecycleProvider>
            <ThemedBackground />
            <App />
          </SessionLifecycleProvider>
        </PaymentTransactionProvider>
      </PaymentSettingsProvider>
    </BrandThemeProvider>
  </StrictMode>,
);
