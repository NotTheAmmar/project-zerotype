# Project ZeroType: BazaarSetu Technical Specification

> **Project Name:** Project ZeroType  
> **Brand Name:** BazaarSetu / बाज़ारसेतु  
> **Target Network:** Open Network for Digital Commerce (ONDC) v1.2.0 (`ONDC:RET12`)  
> **Framework:** Flutter 3.x (Dart 3.x) + FastAPI (Python 3.12)  
> **Pattern:** MVC (Model–View–Controller) with Provider State Management  

---

## 1. System Philosophy: Strict Modality Partitioning

Project ZeroType removes typing and literacy barriers for rural Indian artisans by partitioning catalog creation into Camera, Voice, and Tactile Touch steps while keeping backend Supabase + ONDC persistence independent of temporary GPU hardware.

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Screen Architecture                          │
│                                                                      │
│  LanguageSelection ──> ExploreScreen ──> CaptureScreen               │
│  (23 Langs / 1 or 2)   (Hub + Sync)      (Open-ended + Auto-Flash Off)│
│                                                    │                 │
│                                                    ▼                 │
│  CatalogScreen     <── ProcessingScreen <── VoiceScreen              │
│  (Tactile Corridor)    (Render + Kaggle)    (4-Step Guided Interview)│
└──────────────────────────────────────────────────────────────────────┘
```

---

## 2. Backend Separation, Dual Buckets & Offline Resilience

| Component | URL Source (`AppConstants`) | Role |
| :--- | :--- | :--- |
| **Persistent BPP Server** | `bppBackendUrl` (`BPP_BACKEND_URL` -> Render) | Always-on ONDC `/beckn/*` webhooks, Supabase Postgres catalog storage, and raw/processed image storage (`/api/v1/bpp/*`). Never overridden by temporary Kaggle URLs. |
| **Optional GPU Server** | `kaggleUrl` (`KAGGLE_URL` / in-app GPU modal) | Temporary Kaggle Dual-T4 BiRefNet-HR server for studio background removal. Status indicated by the green/red `Icons.sensors_rounded` button on ExploreScreen. |

- **Dual Supabase Storage Buckets**:
  - `raw-craft-images`: Stores `<catalog_id>_raw.<ext>` (always uploaded directly via Render when online; displayed in-app only, **never** included in ONDC `on_search`).
  - `processed-craft-images`: Stores `<catalog_id>_studio.<ext>` and processed gallery angles (`gallery_*`), which are exposed in `ondc_mapper.py`.
- **Offline Kaggle Fallback & Deferred Background Sync**:
  - When Kaggle is offline, `isKaggleHealthy()` fails fast (4s timeout) and catalog creation/publish proceeds cleanly via Render with `studioImagePath = null`.
  - When Kaggle later comes online, `CatalogController.syncPendingWithBackendAndKaggle()` automatically processes pending raw and gallery photos in the background, saves permanent URLs to `processed-craft-images`, and updates Supabase + ONDC.
- **Storage Cleanup on Delete & Test Reset**:
  - `DELETE /api/v1/bpp/listings/{catalog_id}` deletes the PostgreSQL/SQLite row **and** removes associated objects from both `raw-craft-images` and `processed-craft-images` buckets (plus local `uploads/`).
  - `backend/scripts/reset_backend.py` clears remote Render in-memory cache, Supabase PostgreSQL tables, SQLite, and both Supabase Storage buckets.

---

## 3. Key Screens & Controls

1. **`LanguageSelectionScreen` (`/language-selection`)**:
   - All 23 Bhashini languages (`hi`, `en`, `mr`, `gu`, `bn`, `ta`, `te`, `kn`, `ml`, `or`, `pa`, `as`, `ur`, `brx`, `doi`, `ks`, `kok`, `mai`, `mni`, `ne`, `sa`, `sat`, `sd`).
   - User picks **Single Language** or **Bilingual (2 languages)**.
2. **`ExploreScreen` (`/explore`)**:
   - Compact AppBar (`BazaarSetu`, green/red GPU settings icon, selected-language pill, `Add` button).
   - Search bar with voice search + compact `Voice Mode (Test)` (`Bhashini` / `Whisper`) segmented toggle below search.
   - Craft grid, Quick View modal with localized Craft Story TTS playback, and pull-to-refresh / network sync.
3. **`CaptureScreen` (`/capture`)**:
   - Open-ended multi-photo tray (`Main #1`, `#2`, ...) at `ResolutionPreset.medium` with downscaled (200px width) isolate quality checks.
   - Strict shutter/quality timeouts and `try/finally` state cleanup so shutter never hangs; hardware flash automatically turns off on Next, Back, Pop, Retake, Dispose, or App background.
4. **`VoiceScreen` (`/voice`)**:
   - 4-step guided voice interview + Step 4 optional manual dimensions/weight form.
   - Spoken questions in the user's selected language via Bhashini TTS (`22050 Hz` PCM16) or Device Neural TTS (in Whisper test mode).
5. **`ProcessingScreen` (`/processing`)**:
   - Fully localized progress headlines, rotating tips, and draft fallback controls; generates deterministic `catalogId` before Stage 0 upload.
6. **`CatalogScreen` (`/catalog`)**:
   - Localized UI respecting `AppStrings` & `BilingualText` in Single/Bilingual mode.
   - **3 Fair-Price Corridor Cards** (Floor, Recommended Fair, Premium) + Custom Price dialog + Tactile Stock chips + Custom Stock dialog.
   - Manual Edit form, AI Voice Edit sheet, Unlist/Delete dialogs, Network Info modal, and 1-tap `Publish to ONDC` with immediate confirmation dialog.
