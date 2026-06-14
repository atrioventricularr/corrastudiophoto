import React, { useMemo, useState } from 'react';
import {
  DEFAULT_ADMIN_PASSWORD,
  DEFAULT_ADMIN_USERNAME,
  getAdminCredentialConfig,
  verifyAdminCredential,
} from '../lib/admin-auth';
import { useBrandTheme } from '../branding';

type AdminLoginScreenProps = {
  onLoginSuccess: () => void;
  onCancel: () => void;
};

export default function AdminLoginScreen({
  onLoginSuccess,
  onCancel,
}: AdminLoginScreenProps) {
  const { brandConfig } = useBrandTheme();
  const credentialConfig = useMemo(() => getAdminCredentialConfig(), []);
  const [username, setUsername] = useState(credentialConfig.username || DEFAULT_ADMIN_USERNAME);
  const [password, setPassword] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  const handleSubmit = async () => {
    setErrorMessage('');

    const isValid = await verifyAdminCredential(username, password);

    if (!isValid) {
      setErrorMessage('Username atau password salah.');
      return;
    }

    onLoginSuccess();
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 999999,
        background: 'rgba(0, 0, 0, 0.45)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 24,
      }}
    >
      <div
        style={{
          width: '100%',
          maxWidth: 460,
          borderRadius: 28,
          background: 'white',
          border: '1px solid var(--corra-border)',
          boxShadow: '0 32px 120px rgba(0,0,0,0.30)',
          padding: 28,
          color: 'var(--corra-text)',
          fontFamily: 'var(--corra-font-body)',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 16 }}>
          <div>
            <p
              style={{
                margin: 0,
                fontSize: 12,
                fontWeight: 900,
                letterSpacing: '0.16em',
                textTransform: 'uppercase',
                color: 'var(--corra-primary)',
              }}
            >
              Admin Login
            </p>
            <h1
              style={{
                margin: '8px 0 0',
                fontFamily: 'var(--corra-font-heading)',
                fontSize: 32,
                lineHeight: 1.05,
              }}
            >
              {brandConfig.businessName || 'Corra Booth'}
            </h1>
          </div>

          <button
            type="button"
            onClick={onCancel}
            style={{
              width: 40,
              height: 40,
              borderRadius: 999,
              border: '1px solid var(--corra-border)',
              background: 'white',
              cursor: 'pointer',
              fontWeight: 900,
            }}
          >
            ×
          </button>
        </div>

        {credentialConfig.isDefaultCredential && (
          <div
            style={{
              marginTop: 18,
              padding: 14,
              borderRadius: 18,
              background: '#FFF7ED',
              border: '1px solid #FED7AA',
              color: '#9A3412',
              fontSize: 13,
              lineHeight: 1.5,
            }}
          >
            Default login aktif: <b>{DEFAULT_ADMIN_USERNAME}</b> /{' '}
            <b>{DEFAULT_ADMIN_PASSWORD}</b>. Nanti ganti di Admin Settings.
          </div>
        )}

        <div style={{ marginTop: 20 }}>
          <label style={{ display: 'block', fontSize: 12, fontWeight: 900, marginBottom: 8 }}>
            Username
          </label>
          <input
            value={username}
            onChange={(event) => setUsername(event.target.value)}
            style={{
              width: '100%',
              height: 50,
              borderRadius: 16,
              border: '1px solid var(--corra-border)',
              padding: '0 14px',
              fontSize: 15,
              boxSizing: 'border-box',
            }}
          />
        </div>

        <div style={{ marginTop: 14 }}>
          <label style={{ display: 'block', fontSize: 12, fontWeight: 900, marginBottom: 8 }}>
            Password
          </label>
          <input
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter') {
                handleSubmit();
              }
            }}
            type="password"
            placeholder="admin123"
            style={{
              width: '100%',
              height: 50,
              borderRadius: 16,
              border: '1px solid var(--corra-border)',
              padding: '0 14px',
              fontSize: 15,
              boxSizing: 'border-box',
            }}
          />
        </div>

        {errorMessage && (
          <div
            style={{
              marginTop: 14,
              padding: 12,
              borderRadius: 14,
              background: '#FEF2F2',
              border: '1px solid #FECACA',
              color: '#B91C1C',
              fontSize: 13,
              fontWeight: 800,
            }}
          >
            {errorMessage}
          </div>
        )}

        <button
          type="button"
          onClick={handleSubmit}
          style={{
            marginTop: 20,
            width: '100%',
            height: 54,
            borderRadius: 18,
            border: 0,
            background: 'var(--corra-primary)',
            color: 'white',
            fontWeight: 900,
            fontSize: 14,
            letterSpacing: '0.08em',
            cursor: 'pointer',
          }}
        >
          LOGIN ADMIN
        </button>
      </div>
    </div>
  );
}
