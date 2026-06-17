import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import './index.css';
import { BrandThemeProvider, ThemedBackground } from './branding';
import { PaymentSettingsProvider, PaymentTransactionProvider } from './payments';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrandThemeProvider>
      <PaymentSettingsProvider>
        <PaymentTransactionProvider>
          <ThemedBackground />
          <App />
        </PaymentTransactionProvider>
      </PaymentSettingsProvider>
    </BrandThemeProvider>
  </StrictMode>,
);
