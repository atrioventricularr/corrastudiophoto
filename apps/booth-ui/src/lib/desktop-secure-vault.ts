export type CorraSecretKey =
  | 'DOKU_SECRET_KEY'
  | 'MAYAR_CHECKOUT_API_KEY';

export type CorraSecretStatus = {
  key: string;
  configured: boolean;
  label: string | null;
  maskedValue: string;
  updatedAt: string | null;
  error?: string;
};

export type SetDesktopSecretInput = {
  key: CorraSecretKey;
  value: string;
  label?: string;
};

export function isDesktopSecureVaultAvailable(): boolean {
  return typeof window !== 'undefined' && Boolean(window.corraDesktop?.secureVault);
}

export async function setDesktopSecret(
  input: SetDesktopSecretInput,
): Promise<CorraSecretStatus> {
  if (!window.corraDesktop?.secureVault) {
    return {
      key: input.key,
      configured: false,
      label: input.label || input.key,
      maskedValue: '',
      updatedAt: null,
      error: 'Secure vault is only available inside Electron.',
    };
  }

  return window.corraDesktop.secureVault.setSecret(input);
}

export async function getDesktopSecretStatus(
  key: CorraSecretKey,
): Promise<CorraSecretStatus> {
  if (!window.corraDesktop?.secureVault) {
    return {
      key,
      configured: false,
      label: key,
      maskedValue: '',
      updatedAt: null,
      error: 'Secure vault is only available inside Electron.',
    };
  }

  return window.corraDesktop.secureVault.getSecretStatus({ key });
}

export async function deleteDesktopSecret(
  key: CorraSecretKey,
): Promise<CorraSecretStatus> {
  if (!window.corraDesktop?.secureVault) {
    return {
      key,
      configured: false,
      label: key,
      maskedValue: '',
      updatedAt: null,
      error: 'Secure vault is only available inside Electron.',
    };
  }

  return window.corraDesktop.secureVault.deleteSecret({ key });
}

export async function listDesktopSecretStatuses(): Promise<CorraSecretStatus[]> {
  if (!window.corraDesktop?.secureVault) {
    return [];
  }

  return window.corraDesktop.secureVault.listSecretStatuses();
}
