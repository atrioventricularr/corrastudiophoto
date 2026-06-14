#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 7C2 Connect Brand Panel"
echo "========================================"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

[ -f "package.json" ] || fail "Run this from repo root."
[ -f "apps/booth-ui/src/components/AdminPanel.tsx" ] || fail "AdminPanel.tsx not found."
[ -f "apps/booth-ui/src/components/WelcomeScreen.tsx" ] || fail "WelcomeScreen.tsx not found."
[ -f "apps/booth-ui/src/branding/index.ts" ] || fail "Branding foundation not found. Run Phase 7C1 first."
[ -f "apps/booth-ui/src/components/admin/BrandAppearancePanel.tsx" ] || fail "BrandAppearancePanel not found. Run Phase 7C1 first."

echo ""
echo "Patching AdminPanel, WelcomeScreen, LicenseActivationScreen, CSS..."

python - <<'PY'
from pathlib import Path

def patch_file(path: str, patcher):
    file_path = Path(path)
    text = file_path.read_text()
    new_text = patcher(text)
    if new_text != text:
        file_path.write_text(new_text)
        print(f"PATCH file: {path}")
    else:
        print(f"SKIP file: {path}")

def patch_admin(text: str) -> str:
    if "BrandAppearancePanel" not in text:
        text = text.replace(
            "import { playRetroBeep } from '../utils/audio';",
            "import { playRetroBeep } from '../utils/audio';\nimport BrandAppearancePanel from './admin/BrandAppearancePanel';"
        )

    if "<BrandAppearancePanel />" not in text:
        marker = """      {/* Main double column form container */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-3 gap-6 my-6 overflow-y-visible">
"""
        replacement = """      {/* White-label brand/theme/background settings */}
      <div className="mt-6">
        <BrandAppearancePanel />
      </div>

      {/* Main double column form container */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-3 gap-6 my-6 overflow-y-visible">
"""
        if marker not in text:
            raise SystemExit("Could not find AdminPanel main grid marker.")
        text = text.replace(marker, replacement)

    return text

def patch_welcome(text: str) -> str:
    if "useBrandTheme" not in text:
        text = text.replace(
            "import { playRetroBeep } from '../utils/audio';",
            "import { playRetroBeep } from '../utils/audio';\nimport { useBrandTheme } from '../branding';"
        )

    if "const { brandConfig } = useBrandTheme();" not in text:
        text = text.replace(
            "  const dict = DICTIONARY[lang];",
            "  const dict = DICTIONARY[lang];\n  const { brandConfig } = useBrandTheme();"
        )

    old_brand_header = """              <h1 className="text-2xl sm:text-3xl font-display font-black text-[#2D2D2D] tracking-tight">
                MOMO PHOTO <span className="text-[#FFB7C5] text-lg sm:text-xl font-medium">モモフォト</span>
              </h1>
              <p className="text-[10px] uppercase tracking-[0.2em] text-[#A0A0A0] font-bold">Y2K Self-Service Studio • Est. 2004</p>
"""
    new_brand_header = """              <h1 className="text-2xl sm:text-3xl font-display font-black text-[var(--corra-text)] tracking-tight">
                {brandConfig.businessName}
              </h1>
              <p className="text-[10px] uppercase tracking-[0.2em] text-[var(--corra-muted)] font-bold">
                {brandConfig.tagline || 'Self-Service Photo Booth'}
              </p>
"""
    if old_brand_header in text:
        text = text.replace(old_brand_header, new_brand_header)

    old_main_title = """          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-serif italic font-light text-[#2D2D2D] tracking-tight leading-none mt-1">
            Momo Selfie Club ♡
          </h1>
"""
    new_main_title = """          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-serif italic font-light text-[var(--corra-text)] tracking-tight leading-none mt-1">
            {brandConfig.businessName}
          </h1>
"""
    if old_main_title in text:
        text = text.replace(old_main_title, new_main_title)

    old_ribbon = """            <div className="absolute -top-3 bg-[#FFB7C5] text-white px-4 py-1 rounded-full text-[9px] font-bold tracking-widest uppercase shadow-sm">
              Sweet Studio
            </div>
"""
    new_ribbon = """            <div className="absolute -top-3 bg-[var(--corra-primary)] text-white px-4 py-1 rounded-full text-[9px] font-bold tracking-widest uppercase shadow-sm">
              {brandConfig.businessName}
            </div>
"""
    if old_ribbon in text:
        text = text.replace(old_ribbon, new_ribbon)

    text = text.replace("bg-[#FFB7C5]", "bg-[var(--corra-primary)]")
    text = text.replace("text-[#FFB7C5]", "text-[var(--corra-primary)]")
    text = text.replace("fill-[#FFB7C5]", "fill-[var(--corra-primary)]")
    text = text.replace("border-[#FFB7C5]/30", "border-[var(--corra-border)]")
    text = text.replace("border-[#FFB7C5]/35", "border-[var(--corra-border)]")
    text = text.replace("border-[#FDA4AF]/35", "border-[var(--corra-border)]")
    text = text.replace("text-rose-500", "text-[var(--corra-primary)]")
    text = text.replace("fill-rose-500", "fill-[var(--corra-primary)]")

    return text

def patch_license(text: str) -> str:
    if "useBrandTheme" not in text:
        text = text.replace(
            "} from '../lib/desktop-api';",
            "} from '../lib/desktop-api';\nimport { useBrandTheme } from '../branding';"
        )

    if "const { brandConfig } = useBrandTheme();" not in text:
        text = text.replace(
            "  const [isClearing, setIsClearing] = useState(false);",
            "  const [isClearing, setIsClearing] = useState(false);\n  const { brandConfig } = useBrandTheme();"
        )

    text = text.replace(
        "Aktivasi Corra Booth",
        "Aktivasi {brandConfig.businessName}"
    )
    text = text.replace(
        "Device ini sudah siap menjalankan Corra Booth.",
        "Device ini sudah siap menjalankan {brandConfig.businessName}."
    )

    return text

def patch_css(text: str) -> str:
    if "#root" not in text:
        text += """

#root {
  position: relative;
  z-index: 1;
  min-height: 100vh;
}
"""
    elif "z-index: 1" not in text:
        text += """

/* Ensure app content stays above the white-label background layer */
#root {
  position: relative;
  z-index: 1;
  min-height: 100vh;
}
"""
    return text

patch_file("apps/booth-ui/src/components/AdminPanel.tsx", patch_admin)
patch_file("apps/booth-ui/src/components/WelcomeScreen.tsx", patch_welcome)

license_path = Path("apps/booth-ui/src/components/LicenseActivationScreen.tsx")
if license_path.exists():
    patch_file("apps/booth-ui/src/components/LicenseActivationScreen.tsx", patch_license)
else:
    print("SKIP LicenseActivationScreen.tsx not found")

patch_file("apps/booth-ui/src/index.css", patch_css)
PY

echo ""
echo "Writing docs..."

cat > docs/phase-7c2-connect-brand-panel.md <<'MD'
# Phase 7C2 - Connect Brand Panel

This phase connects the brand/theme/background foundation to the visible UI.

## Added

- BrandAppearancePanel inserted into AdminPanel
- WelcomeScreen now reads business name and tagline from brand config
- LicenseActivationScreen uses customer brand name when available
- Root app layer placed above background layer

## Current Limit

Background value is still manual text input:
- CSS gradient
- solid color
- image URL
- MP4 URL

Local PNG/MP4 file picker and encrypted Electron settings should be added in Phase 7C3.
MD

echo ""
echo "Verifying..."

grep -q "BrandAppearancePanel" apps/booth-ui/src/components/AdminPanel.tsx || fail "AdminPanel missing BrandAppearancePanel."
grep -q "useBrandTheme" apps/booth-ui/src/components/WelcomeScreen.tsx || fail "WelcomeScreen missing useBrandTheme."
grep -q "brandConfig.businessName" apps/booth-ui/src/components/WelcomeScreen.tsx || fail "WelcomeScreen missing businessName."
grep -q "#root" apps/booth-ui/src/index.css || fail "index.css missing root layer."

echo ""
echo "========================================"
echo " Phase 7C2 completed."
echo "========================================"
echo ""
echo "Next:"
echo "  pnpm --filter @corra/booth-ui typecheck"
echo "  pnpm --filter @corra/booth-ui dev -- --host 0.0.0.0 --port 5173"
echo "  git add ."
echo "  git commit -m \"feat: connect brand appearance panel\""
echo "  git push origin main"
echo ""
