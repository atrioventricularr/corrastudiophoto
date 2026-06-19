#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/AdminPanel.tsx"

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

# Hapus activeSection yang nyasar di parameter function
text = text.replace(
    "  const [activeSection, setActiveSection] = useState<AdminSectionId>('hardware');\n\n",
    ""
)

# Pastikan import React punya useState
text = text.replace(
    "import React from 'react';",
    "import React, { useState } from 'react';"
)

# Kalau import React sudah ada tapi useState belum masuk
text = re.sub(
    r"import React, \{([^}]*)\} from 'react';",
    lambda m: "import React, {" + (
        m.group(1) if "useState" in m.group(1) else m.group(1).strip() + ", useState"
    ) + "} from 'react';",
    text,
    count=1,
)

# Pastikan AdminSectionId ikut diimport
text = text.replace(
    "import { AdminMobileSectionNav, AdminSidebar } from './admin/AdminSidebar';",
    "import { AdminMobileSectionNav, AdminSidebar, type AdminSectionId } from './admin/AdminSidebar';"
)

# Masukkan activeSection setelah function opening yang benar
target = "}: AdminPanelProps) {\n"
insert = "}: AdminPanelProps) {\n  const [activeSection, setActiveSection] = useState<AdminSectionId>('hardware');\n\n"

if "const [activeSection, setActiveSection]" not in text:
    if target not in text:
        raise SystemExit("Could not find AdminPanelProps function opening.")
    text = text.replace(target, insert, 1)

# Bersihin quote escape kalau ada
text = text.replace("\\'block\\'", "'block'")
text = text.replace("\\'hidden\\'", "'hidden'")

path.write_text(text)
print("PATCHED:", path)
PY

echo ""
echo "Check lines 38-55:"
nl -ba "$FILE" | sed -n '38,55p'
