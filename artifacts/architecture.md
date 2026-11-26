# Project ZeroType: BazaarSetu Architecture

**Project ZeroType** (User-facing brand: **BazaarSetu** / **बाज़ारसेतु**) is a mobile cataloging engine designed to onboard non-literate and semi-literate rural Indian artisans into the Open Network for Digital Commerce (ONDC) without requiring them to type a single character.

---

## 1. Core Paradigm: Strict Modality Partitioning

Rather than overloading a single unconstrained voice prompt, BazaarSetu strictly segments data acquisition by input modality:

```
┌─────────────────┐       ┌────────────────────────┐       ┌────────────────────────┐
│  Vision/Camera  │ ────> │ Guided Voice Interview │ ────> │ Tactile Corridor /     │
│  (Open-ended)   │       │ (Open-ended Speech)    │       │ Stepper (Zero-Typing)  │
└─────────────────┘       └────────────────────────┘       └────────────────────────┘
        │                             │                                 │
        ▼                             ▼                                 ▼
Raw + Optional Kaggle        Bhashini / Whisper STT            Fair-Price Corridor
BiRefNet Studio Cutout       + Bhashini NMT -> Qwen            Floor/Fair/Premium
+ Deferred BG Sync           (23 Languages Supported)          Tactile Pill [1][2][5][10]
```

1. **Multilingual & Bilingual Onboarding (`LanguageSelectionScreen`)**:
   - Supports **all 23 Bhashini languages** (22 Scheduled Indian Languages + English).
   - Artisans choose between **Single Language mode** (1 chosen language across the UI and catalog) or **Bilingual mode** (any 2 chosen languages displayed side by side).
   - **Data & ONDC Contract**: In-app screens and catalog cards display in the artisan's chosen language(s), while Supabase PostgreSQL and ONDC (`on_search`) always receive **English (`title_en`, `description_en`) + Hindi (`title_hi`, `description_hi`)**, with `localized_titles` / `localized_descriptions` preserved in JSONB.
2. **Vision / Camera Modality (Open-Ended Capture)**:
   - Open-ended multi-photo capture (`#1 Main` + optional unlimited additional angles) with grid, hardware torch auto-off on navigation/pause, and fast downscaled Laplacian blur + luminance checks.
   - Real-time category detection (`ONDC:RET12` Apparel, `ONDC:RET16` Pottery & Crafts, `ONDC:RET10` Packaged Food).
3. **Guided 4-Step Voice Interview (Speech Input)**:
   - Structured 4-stage guided prompts: (1) Craft Name, (2) Materials & Craft Technique, (3) Selling Price, Raw Cost & Labor Days, (4) Dimensions & Weight (with optional manual dimensions entry).
   - Open-ended recording (16 kHz Mono WAV, no 15-second limit).
   - Supports **Bhashini Cloud ASR + Bhashini NMT + Bhashini TTS** (22.05 kHz 16-bit PCM WAV) and an A/B **Voice Mode (Test)** toggle on the Explore screen for **Groq `whisper-large-v3-turbo` STT + Bhashini NMT + Device Neural TTS**.
4. **Decoupled Cloud Persistence & Deferred Kaggle Studio Sync**:
   - **24/7 BPP + Supabase Backend (Render)**: Hosts ONDC Beckn webhooks (`/beckn/*`), catalog CRUD (`/api/v1/bpp/draft`, `/publish`, `/listings`), and dual Supabase Storage buckets:
     - `raw-craft-images` — Original camera photos (displayed in-app only with an `Original Raw` badge; **never** sent to ONDC).
     - `processed-craft-images` — AI-processed BiRefNet studio cutouts & gallery angles (exposed on ONDC `on_search`).
   - **Optional Kaggle Dual-T4 GPU Server (`KAGGLE_URL`)**: Configured via the green/red GPU status icon. If Kaggle is offline, drafts and ONDC publishes still succeed cleanly via Render; once Kaggle comes back online, `CatalogController.syncPendingWithBackendAndKaggle()` automatically processes missing studio/gallery photos in the background and syncs them to Supabase.
   - **Clean Deletion**: Deleting a catalog permanently removes both its PostgreSQL/SQLite record and its image objects from both Supabase Storage buckets.
5. **Tactile Controls & Auditory Readback**:
   - Tactile stock preset pills (`1`, `2`, `5`, `10`, `25`, `50`) + custom batch dialog (`+10` to `+500`), Fair-Price Corridor cards (**Floor**, **Fair**, **Premium**), and Custom Price dialog.
   - Auditory readback and non-blocking post-publish confirmation in the artisan's selected language.

---

## 2. Tech Stack

- **Frontend**: Flutter (Cross-platform Android / iOS / Web) with Provider state management
- **Speech Pipeline**: Bhashini Cloud ASR (`itn` + `punctuation`) / NMT / TTS (22.05 kHz PCM16) + testing toggle for Groq `whisper-large-v3-turbo` STT & Device Neural TTS
- **Catalog Structuring LLM**: **Qwen** (`qwen/qwen3.8-27b` / `qwen-2.5-32b-instruct` via OpenAI-compatible `QWEN_API_URL`)
- **Backend & Storage**: FastAPI BPP on Render (`https://project-zerotype-bpp.onrender.com`), Supabase PostgreSQL + Dual Storage Buckets (`raw-craft-images`, `processed-craft-images`), and standalone `backend/scripts/reset_backend.py` CLI
- **Studio Image Matting**: Optional Kaggle Dual-T4 BiRefNet-HR server with automatic offline fallback and deferred sync

---

## 3. Environment Configuration (`.env`)

```env
# Persistent ONDC BPP + Supabase Backend (Render Cloud or local FastAPI)
BPP_BACKEND_URL=https://project-zerotype-bpp.onrender.com

# Optional Temporary Kaggle GPU Tunnel (BiRefNet studio processing; blank when offline)
KAGGLE_URL=
BACKEND_URL=
API_BASE_URL=https://api.bazaarsetu.in/v1

# AI Extraction Provider (Qwen via OpenAI-compatible / Groq endpoint)
AI_EXTRACTION_PROVIDER=qwen
QWEN_MODEL=qwen/qwen3.8-27b
QWEN_API_URL=https://api.groq.com/openai/v1/chat/completions
QWEN_API_KEY=your_qwen_api_key_here

# Bhashini Configuration (Govt. of India Indic NLP)
BHASHINI_API_KEY=your_bhashini_api_key
BHASHINI_ULCA_KEY=your_bhashini_ulca_key
BHASHINI_USER_ID=your_bhashini_user_id
BHASHINI_PIPELINE_ID=64392f96daac500b55c543cd
BHASHINI_API_URL=https://dhruva-api.bhashini.gov.in
```
