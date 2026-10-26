# RePlated — AIESEC Hackathon 2026

**RePlated** is a food-surplus coordination platform that connects donors, NGOs, and delivery partners to rescue unserved food and match it to local recipient kitchens. It was built as an AIESEC Hackathon MVP with a focus on traceable, role-specific handoffs.

---

## 📦 Projects in this Repository

| Folder | Description | Tech Stack |
|--------|-------------|------------|
| **`replated-app/`** | Full mobile app (Expo / React Native) for Android, iOS, and web. Supports local demo mode and a Supabase-backed team mode. | React Native 0.88, Expo 58, Supabase, react-native-maps, lucide-react-native |
| **`replated-mvp/`** | Simplified browser prototype (`index.html` + `app.js` + `styles.css`). Runs in any current browser without install. | Vanilla HTML/CSS/JS, localStorage demo data |

Both projects share the same core concept: **donor lists surplus → dispatcher reviews → NGO confirms capacity → rider claims pickup → photo evidence at each handoff → NGO inspects → review/score.**

---

## 🚀 Quick Start

### Mobile App (`replated-app`)

```powershell
cd C:\Users\sheeb\Downloads\AIESEC_Hackathon\replated-app
npm start              # Start Expo Go
# On phone: scan QR with Expo Go
# Or: npm run android  # Android emulator
# Or: npm run web      # Browser web view
```

### Browser Demo (`replated-mvp`)

```powershell
cd C:\Users\sheeb\Downloads\AIESEC_Hackathon\replated-mvp
# Open index.html in any modern browser
# Use the top bar to reset/clear synthetic data
```

---

## 🛠️ Development & Setup

### Mobile App Environment

1. **Create a Supabase project** (optional for local demo):
   - Go to <https://supabase.com> and create a new project
   - Copy the **Project URL** and **Anonymous (Publishable) Key**

2. **Configure environment variables**:
   ```bash
   cp replated-app/.env.example replated-app/.env
   # Then edit .env:
   EXPO_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```
   - Never commit real Supabase keys — keep them in `.env` which is gitignored
   - The `.env.example` shows the expected variable names only

3. **Run database migrations** (Supabase SQL Editor):
   ```sql
   -- In filename order:
   0001_replated.sql
   20261024211555_add_replated_workflows.sql
   20261024215116_add_delivery_tracking_receipt_evidence.sql
   -- If 0001 already applied, run only the second migration
   ```

4. **Restart the app** to load environment variables:
   ```bash
   npm start
   ```

5. **Create team accounts**:
   - New signups create donor accounts
   - Use SQL editor to promote NGO/rider accounts:
   ```sql
   -- Example: make operator@example.com a dispatcher
   update public.profiles p set role='dispatcher'
   from auth.users u where p.id=u.id and u.email='operator@example.com';
   ```

### Browser Demo

No setup needed. Just open `index.html` — data is stored in browser `localStorage` and is synthetic/demo-only.

---

## ⚠️ Security & Boundaries (Important)

This is a **hackathon prototype** with explicit boundaries. Please read before extending:

- **No live GPS / maps**: Location is foreground-only and depends on the rider keeping the app open and having granted permission. Store-bought builds need a Google Maps API key.
- **No payments, identity checks, or push notifications**: Not implemented. Demo data is synthetic.
- **No FSSAI / food-safety certification**: The app records allergens and temperature as evidence, **but does not certify food as safe**. Real-world distribution requires proper licensing and handling procedures.
- **Camera evidence is not safety verification**: Photos are stored as audit trail evidence only.
- **Local demo mode is the default**: Without Supabase credentials, the app runs in local-only mode — data stays in that browser/device and does not sync across devices.
- **Supabase RLS controls access**: Row-level security ensures participants can only read/write their own data. Never expose service_role keys in client code.
- **Admin verification required**: NGO and rider accounts must be verified/administrator-approved before operational use.

**The project explicitly states**: "Validate real operating procedures and FSSAI alignment before live distribution."

---

## 📁 Project Structure

```
replated-app/
├── App.tsx              # Main React Native component
├── package.json         # Dependencies (Expo, Supabase, React Native, etc.)
├── tsconfig.json        # TypeScript config
├── app.json             # Expo configuration
├── .env.example         # Environment variable names (no real values)
├── .gitignore           # Git ignore rules
├── supabase/
│   └── migrations/      # SQL migrations for Supabase
├── components/
│   ├── ui/              # Reusable UI components
│   ├── safety/          # Food safety configuration
│   └── AdminConsole.tsx # Admin workspace
└── lib/
    └── supabase.ts      # Supabase client setup

replated-mvp/
├── index.html           # Browser prototype entry point
├── app.js               # Application logic
└── styles.css           # Styling
```

---

## 🏗️ Architecture Overview

### Mobile App Data Flow

1. **Donor workspace**: Submits a batch with food description, portions, temperature, allergens, prepared/pickup times, address, and a live photo
2. **Capacity gating**: NGO must accept capacity before a rider can be assigned — prevents premature pickup assignment
3. **Rider workflow**: Claims pickup, documents with photo, shares live location during delivery, confirms drop-off
4. **NGO inspection**: Takes receipt photo, reviews the batch, can accept or reject with reason
5. **Audit trail**: Every handoff is recorded with batch ID, timestamps, and evidence paths

### Key Design Decisions

- **Single batch code** follows the item through every role transition (donor → NGO → rider)
- **Capacity acceptance gates rider assignment** — the product matches evidence to recipient readiness, not the other way around
- **Evidence at every handoff**: Camera, measured temperature, allergen notes, pickup address
- **Graceful decline preserves records**: An NGO decline excludes that NGO from later offers for the same batch
- **Role-verified accounts**: NGO and rider accounts are administrator-verified

### Browser Demo Data Flow

Same role flow, but all data is synthetic stored in browser `localStorage`. No backend, no accounts, no sync.

---

## 🎯 Hackathon Context & Boundaries

This project was built for the **AIESEC Hackathon 2026**. It is an **MVP prototype** — not a production-ready food-safety system.

**What it does:**
- Coordinates food surplus handoffs from donors to NGOs through delivery partners
- Records a chain of custody with one batch code
- Captures evidence (photos, temperature, allergens) at each handoff
- Provides role-specific workspaces (donor, NGO, rider)
- Runs in local demo mode without any backend

**What it does NOT do:**
- No live GPS / real-time tracking (foreground-only, app-must-be-open)
- No payments, identity verification, or push notifications
- No FSSAI or food-safety certification
- No backend jobs, automated temperature validation, or legal compliance
- No open marketplace — riders are known (assigned after recipient confirmation)

**Next steps for a real pilot:**
- Validate operating procedures and FSSAI alignment
- Run Supabase migrations and create team accounts
- Configure Google Maps API key for store builds
- Test on real hardware with proper permissions
- Conduct food-safety training with actual operators

---

## 📄 License

This project is licensed under the **MIT License** — see the `LICENSE` file in `replated-app/` for details. The Expo portion is copyright (c) 2015-present 650 Industries, Inc.

---

## 🙏 Acknowledgments

- Built for AIESEC Hackathon 2026
- Design tokens from `DESIGN.md` (warm off-white canvas, deep forest green, restrained lime accents)
- Brand imagery from Unsplash (credit in `replated-app/assets/IMAGE_SOURCES.md`)
- Supabase for backend infrastructure (with RLS and private storage)
- All contributors and hackathon participants

---

*Generated for the AIESEC Hackathon. This README covers both the mobile app (`replated-app/`) and the browser demo (`replated-mvp/`). For project-specific details, see each folder's own README.*