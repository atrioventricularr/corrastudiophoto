import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import './index.css';
import { BrandThemeProvider, ThemedBackground } from './branding';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrandThemeProvider>
      <ThemedBackground />
      <App />
    </BrandThemeProvider>
  </StrictMode>,
);
