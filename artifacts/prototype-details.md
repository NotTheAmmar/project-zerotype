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
- **Objective:** Discover community crafts, check previous listings, and inspect ONDC node details.
- **Features:**
  - Category filter pills (`All Crafts`, `Pottery & Clay`, `Clothing & Weaves`, `Home Decor`, `Tribal Metalcraft`, `Festive Special`).
  - Direct Karigar Fair Pledge banner.
  - Product cards displaying handmade origin and ONDC Live/Draft badges.
  - **Product Quick View Modal**:
    - High-resolution craft preview.
    - **Karigar Story Audio Snippet**: Tap *"सुनें"* to listen to the artisan's spoken story via audio TTS.
    - Actions: *"Add to Guild Basket"* (artisan pledge) and *"View Catalog / ONDC Node"*.

### Screen 3: Visual Capture & Category Detection (`/capture`)
- **Objective:** Acquire clean visual angles with automated category recognition.
- **Features:**
  - 4:3 Camera Viewfinder with golden corner brackets and center crosshair.
  - Heuristic Category Detection Chip (`Apparel & Weaves RET12`, `Pottery & Terracotta RET16`, `Packaged Food RET10`).
  - Spoken guidance banner: *"दीया बीच में रखें और अच्छी रोशनी रखें"* with audio playback.
  - 4-slot angle tracker (Front, Side, Back, Detail).
  - Shutter button with animated glow ring, grid and flash toggles.

### Screen 4: Category-Adaptive Voice Narration (`/voice`)
- **Objective:** Capture open-ended spoken artisan context without forcing arbitrary time limits.
- **Features:**
  - Automatically plays a 5–8s localized spoken dialect question tailored to the detected category:
    - *Pottery*: *"यह दीया किस मिट्टी से बना है और इसपर क्या नक्काशी है?"*
    - *Apparel*: *"यह कपड़ा किस धागे से बुना गया है और इसपर क्या कढ़ाई की गई है?"*
    - *Food*: *"यह खाद्य सामग्री कैसे तैयार की गई है और इसमें कौन से मसाले हैं?"*
    - *Metal/Wood*: *"यह हस्तशिल्प किस धातु या लकड़ी से गढ़ा गया है?"*
  - Open-ended recording (unlimited duration; count-up timer `MM:SS`).
  - Live 30-bar amplitude waveform and silence warning.

### Screen 5: Multimodal Processing State (`/processing`)
- **Objective:** Keep user engaged while AI runs in the background.
- **Features:**
  - Visual status steps: *Studio Safai* (BiRefNet), *Aawaz ki Pehchan* (ASR), *Qwen Structuring* (ONDC JSON), *Sahi Daam Ganana* (Fair pricing).

### Screen 6: Interactive Catalog Card & Tactile Controls (`/catalog`)
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
