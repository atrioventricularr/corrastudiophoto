export const DEFAULT_ADMIN_USERNAME = 'admin';
export const DEFAULT_ADMIN_PASSWORD = 'admin123';

export type AdminCredentialConfig = {
  username: string;
  passwordHash: string | null;
  isDefaultCredential: boolean;
  updatedAt: string | null;
};

const STORAGE_KEY = 'corra.adminCredential.v1';

async function sha256(value: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(value);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);

  return Array.from(new Uint8Array(hashBuffer))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

export function getAdminCredentialConfig(): AdminCredentialConfig {
  if (typeof window === 'undefined') {
    return {
      username: DEFAULT_ADMIN_USERNAME,
      passwordHash: null,
      isDefaultCredential: true,
      updatedAt: null,
    };
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);

    if (!raw) {
      return {
        username: DEFAULT_ADMIN_USERNAME,
        passwordHash: null,
        isDefaultCredential: true,
        updatedAt: null,
      };
    }

    const parsed = JSON.parse(raw) as Partial<AdminCredentialConfig>;

    return {
      username: parsed.username || DEFAULT_ADMIN_USERNAME,
      passwordHash: parsed.passwordHash || null,
      isDefaultCredential: Boolean(parsed.isDefaultCredential),
      updatedAt: parsed.updatedAt || null,
    };
  } catch {
    return {
      username: DEFAULT_ADMIN_USERNAME,
      passwordHash: null,
      isDefaultCredential: true,
      updatedAt: null,
    };
  }
}

export async function verifyAdminCredential(
  username: string,
  password: string,
): Promise<boolean> {
  const config = getAdminCredentialConfig();
  const normalizedUsername = username.trim();
  const normalizedPassword = password.trim();

  if (!config.passwordHash) {
    return (
      normalizedUsername === DEFAULT_ADMIN_USERNAME &&
      normalizedPassword === DEFAULT_ADMIN_PASSWORD
    );
  }

  if (normalizedUsername !== config.username) {
    return false;
  }

  return (await sha256(normalizedPassword)) === config.passwordHash;
}

export async function saveAdminCredential(
  username: string,
  password: string,
): Promise<AdminCredentialConfig> {
  const nextConfig: AdminCredentialConfig = {
    username: username.trim() || DEFAULT_ADMIN_USERNAME,
    passwordHash: await sha256(password),
    isDefaultCredential: false,
    updatedAt: new Date().toISOString(),
  };

  if (typeof window !== 'undefined') {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(nextConfig));
  }

  return nextConfig;
}
