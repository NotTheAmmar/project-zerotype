# Project ZeroType: BazaarSetu Prototype Specification

**Code Name:** Project ZeroType  
**Product Name:** BazaarSetu (बाज़ारसेतु)  
**Target Network:** Open Network for Digital Commerce (ONDC) v1.2.0  
**Target Group:** Rural artisans, weavers, and self-help groups (SHGs)  

---

## 1. Prototype Scope: Zero-Typing Magic Ingestion Loop

The prototype demonstrates that an unschooled or low-literacy rural craftsperson can produce a professional, ONDC-compliant product catalog using only camera, voice, and tactile touch controls:

| Domain | Prototype Implementation | Production Scaling |
|---|---|---|
| **Visual Ingestion** | 4:3 Camera Viewfinder, real-time category detection chip, golden framing guides, 4-angle slot tracker (Front, Side, Back, Detail). | Edge ONNX INT8 BiRefNet matting directly on budget smartphones. |
| **Voice Processing** | Category-adaptive spoken anchor (5–8s localized audio prompt) + Open-ended recording (no 15s limit) + 30-bar waveform + Bhashini ASR. | Dialect acoustic models across 22 scheduled Indian languages with background loom noise cancellation. |
| **Structuring Engine**| **Qwen-2.5-32B-Instruct** structuring speech into ONDC Beckn schema JSON, extracting title, materials, dimensions, spoken price/quantity. | Fine-tuned Qwen / Indic LLM deployed on sovereign cluster. |
| **Tactile Controls** | 3 Fair-Price Corridor Cards (Floor, Fair, Premium) + `[±₹50]` tactile nudges + quantity preset pills `[1][2][5][10]` and stepper. | Real-time market demand pricing telemetry across ONDC buyer nodes. |
| **Verification Loop** | Spoken readback banner in Hindi (*"आपका कैटलॉग तैयार है: $cat $title, कीमत ₹$price। क्या यह सही है?"*). | Dynamic dialect synthesis via Bhashini TTS. |
| **Commerce Rails** | 1-Tap broadcast to ONDC Beckn Provider Platform (BPP). | Live sandbox broadcast and automated 3PL waybill QR generation. |

---

## 2. Screen-by-Screen User Experience

### Screen 1: Welcome & Language Choice (`/welcome`)
- **Objective:** Provide a comforting, zero-text barrier entry in the artisan's preferred mother tongue.
- **Features:**
  - 6 Indic language selection cards: Hindi (हिन्दी), Marathi (मराठी), Gujarati (ગુજરાતી), Bengali (বাংলা), Tamil (தமிழ்), Telugu (తెలుగు).
  - Audio guide pill with TTS playback in the chosen language.
  - Large continue button (*"आगे बढ़ें • Continue"*).

### Screen 2: Explore & Karigar Hub (`/`)
- **Objective:** Discover community crafts, manage existing listings and drafts, and inspect ONDC node details.
- **Features:**
   - Direct artisan craft feed showing authentic listings with craft provenance, GI tags, and direct Karigar Fair Pledge banner.
   - Product cards displaying handmade origin and live ONDC / Draft status badges.
   - **Product Quick View Modal**:
     - High-resolution craft preview.
     - **Karigar Story Audio Snippet**: Tap to listen to the artisan's spoken story via audio TTS; halts immediately when closed.
     - Actions: *"Add to Guild Basket"* (artisan pledge) and *"View Catalog / ONDC Node"*.

### Screen 3: Visual Capture & Category Detection (`/capture`)
- **Objective:** Acquire clean visual angles with automated category recognition.
- **Features:**
   - 4:3 Camera Viewfinder with golden corner brackets and center crosshair.
   - Heuristic Category Detection Chip (`Apparel & Weaves RET12`, `Pottery & Terracotta RET16`, `Packaged Food RET10`).
   - Spoken guidance banner: *"दीया बीच में रखें और अच्छी रोशनी रखें"* with audio playback.
   - 4-slot angle tracker (Front, Side, Back, Detail).
   - Shutter button with animated glow ring, grid and hardware torch flash controls.

### Screen 4: Guided 4-Step Voice Interview (`/voice`)
- **Objective:** Capture open-ended spoken artisan context through structured, natural conversational prompts.
- **Features:**
   - **4 Guided Stages**:
     1. *Product & Craft Details*: Category, materials, and crafting technique.
     2. *Dimensions & Weight*: Dimensions and measurements (with optional manual input fallback dialog).
     3. *Pricing & Production Effort*: Selling price, raw material expense, and labor days.
     4. *Story & Heritage*: Generational heritage, tradition, and craft significance.
   - Category-adaptive audio question prompt before each stage.
   - Open-ended recording (no arbitrary time limits) with 30-bar amplitude waveform.

### Screen 5: Modern Karigar AI Processing (`/processing`)
- **Objective:** Keep the artisan engaged with inspiring visual feedback and craft wisdom while AI runs.
- **Features:**
   - Central hero craft photo centerpiece with breathing animated pulse ring.
   - Dynamic stage indicator tracking live phase (transcription, studio lighting, bilingual storytelling, statutory corridor, ONDC packaging).
   - Smooth percentage progress bar.
   - Rotating carousel of artisan craft wisdom and selling tips updated dynamically every 3.5s.
   - Safe retry / fallback actions for network interruptions.

### Screen 6: Interactive Catalog Card & Tactile Controls (`/catalog`)
- **Objective:** Enable effortless review, verification, and broadcast without typing.
- **Features:**
   - Bilingual presentation (English primary title and descriptions with Devanagari translation directly below).
   - **Tactile 3-Tier Price Corridor**: Floor, Fair, and Premium cards + `[±₹50]` quick adjustment nudges + direct **Set Exact Price** numeric input.
   - **Flexible Inventory Management**: Tactile pills (`1`, `2`, `5`, `10`, `25`, `50`) + custom quantity dialog with batch chips (`+10`, `+25`, `+50`, `+100`, `+250`, `+500`).
   - **Dual Editing**: Edit manually or use conversational voice updates (*"कीमत ₹650 कर दो"*).
   - **Catalog Lifecycle Management**: 1-tap live publish to ONDC, auto-save drafts, unlist active listings back to draft, and audio playback that halts immediately on navigation.
- **Objective:** Tactile verification with zero keyboard input.
- **Features:**
  - Raw photo vs. studio photo toggle with multi-angle thumbnails.
  - Provenance & GI Cluster Origin badge.
  - **3 Fair-Price Corridor Cards**:
    - **Floor Price**: Non-negotiable statutory wage floor.
    - **Fair Price**: Recommended D2C price.
    - **Premium Price**: Gifted / Institutional tier.
  - **Tactile Adjustment Nudges**: `[- ₹50]` and `[+ ₹50]` buttons clamped above floor price.
  - **Tactile Stock Selection**: Preset pills `[1]`, `[2]`, `[5]`, `[10]` and `+`/`-` stepper.
  - **Voice Edit Drawer**: Artisan can speak adjustments (e.g. *"कीमत साढ़े तीन सौ करो"*).
  - **Statutory Spoken Readback Bar**: Audio readback of item name, category, and price for non-literate verification.
  - ONDC Statutory KYC prefill badges (`Origin: IND`, `Ship: PT24H`, `Return: P7D`).
  - 1-Tap *"Publish Product"* broadcasting to ONDC BPP.

---

## 3. Design System & Accessibility Rules

- **Zero-Typing Mandate**: No soft keyboard is summoned anywhere in the application.
- **Oversized Hit Geometry**: Primary touch targets are sized at 64–72 dp.
- **Auditory Verification**: All critical decisions (welcome, category anchor, photo advice, catalog summary) have corresponding audio speech triggers.
- **Statutory Safeguards**: The app actively prohibits pricing below the calculated statutory minimum wage floor.
