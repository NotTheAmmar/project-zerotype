# Project ZeroType: BazaarSetu Technical Specification

> **Project Name:** Project ZeroType  
> **Brand Name:** BazaarSetu / बाज़ारसेतु  
> **Target Network:** Open Network for Digital Commerce (ONDC) v1.2.0  
> **Framework:** Flutter 3.x (Dart 3.x)  
> **Pattern:** MVC (Model–View–Controller) with Provider State Management  

---

## 1. System Philosophy: Strict Modality Partitioning

Project ZeroType addresses the fundamental barrier preventing rural Indian artisans from listing their craft on digital commerce: **literacy and complex text-entry forms**. By establishing a **Strict Modality Partitioning Architecture**, the application never forces the artisan to write text or type numerals.

```
┌─────────────────────────────────────────────────────────────────┐
│                      Screen Architecture                        │
│                                                                 │
│  WelcomeScreen   ──>  ExploreScreen  ──>  CaptureScreen        │
│  (6 Indic Langs)      (Craft Hub)         (Vision + Slots)      │
│                                                   │             │
│                                                   ▼             │
│  CatalogScreen   <──  ProcessingScreen <── VoiceScreen         │
│  (Tactile Zero-Typing) (BiRefNet + Qwen)  (Adaptive Anchor)    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Screen & Interaction Specifications

### 2.1 WelcomeScreen (`/welcome`)
- **Purpose**: Welcoming first-time artisans with zero literacy hurdles.
- **Components**:
  - Indic language cards: Hindi (हिन्दी), Marathi (मराठी), Gujarati (ગુજરાતી), Bengali (বাংলা), Tamil (தமிழ்), Telugu (తెలుగు).
  - Spoken audio greeting button playing native welcome instructions via TTS.
  - Tactile continue button: *"आगे बढ़ें • Continue"*.

### 2.2 ExploreScreen (`/`)
- **Purpose**: Home dashboard for craft discovery, quick view, and catalog launching.
- **Components**:
  - Horizontal Category Filter Pills (`All Crafts`, `Pottery & Clay`, `Clothing & Weaves`, `Home Decor`, `Tribal Metalcraft`, `Festive Special`).
  - Search & Mic action bar.
  - Direct Karigar Fair Pledge Prototype Banner.
  - Responsive Grid of Artisan listings with handmade and status badges.
  - Interactive **Product Quick View Modal**:
    - Image preview, cluster provenance, GI origin.
    - **Karigar Story Audio Snippet**: Native spoken artisan narrative with play/pause controls.
    - Action buttons: *"Add to Guild Basket"* and *"View Catalog / ONDC Node"*.

### 2.3 CaptureScreen (`/capture`)
- **Purpose**: Visual modality capture with real-time heuristic category detection.
- **Components**:
  - 4:3 Camera Viewfinder with golden artisan corner brackets and center crosshairs.
  - Audio Tips interactive guidance pill (*"दीया बीच में रखें और अच्छी रोशनी रखें"* with TTS playback).
  - Detection Status Chip: Real-time visual categorization (`Apparel & Weaves RET12`, `Pottery & Terracotta RET16`, `Tribal Metalcraft RET16`, `Packaged Food RET10`).
  - 4-Slot Multi-Angle Progress Bar: Tracks Front, Side, Back, and Detail shots.
  - Shutter button with animated glow ring + Flash & Grid toggles.
  - Continue CTA requiring at least 1 captured photo.

### 2.4 VoiceScreen (`/voice`)
- **Purpose**: Audio modality capture with category-adaptive spoken anchors.
- **Components**:
  - **Category-Adaptive Audio Anchor**: Automatically plays a 5–8s spoken dialect prompt before recording opens:
    - *Pottery*: *"यह दीया किस मिट्टी से बना है और इसपर क्या नक्काशी है?"*
    - *Apparel*: *"यह कपड़ा किस धागे से बुना गया है और इसपर क्या कढ़ाई की गई है?"*
    - *Food*: *"यह खाद्य सामग्री कैसे तैयार की गई है और इसमें कौन से मसाले हैं?"*
    - *Wood/Metal*: *"यह हस्तशिल्प किस धातु या लकड़ी से गढ़ा गया है?"*
  - **Open-Ended Voice Capture**: No 15-second cap. An open-ended count-up timer (`MM:SS`) is displayed.
  - Live 30-bar amplitude waveform visualizer.
  - Silence warning with auto-recovery prompt.

### 2.5 ProcessingScreen (`/processing`)
- **Purpose**: Asynchronous execution of multimodal AI pipelines.
- **Pipelines**:
  1. *Studio Image Compositing*: Background isolation via BiRefNet backend with subtle shadow and warm neutral canvas.
  2. *ASR & NMT*: Speech-to-Text via Bhashini Cloud / Whisper.
  3. *Qwen Extraction*: LLM structuring of spoken transcript into ONDC Beckn JSON.
  4. *TTS Generation*: Hindi catalog confirmation readback synthesis.

### 2.6 CatalogScreen (`/catalog`)
- **Purpose**: Tactile Zero-Typing verification and 1-tap ONDC broadcasting.
- **Components**:
  - Raw vs. Studio image toggle with multi-thumbnail strip.
  - Provenance & GI Cluster Origin badge.
  - **3 Fair-Price Corridor Cards**:
    - Floor Price ($P_{\text{floor}}$) — Non-negotiable statutory wage floor.
    - Fair Price ($P_{\text{fair}}$) — Recommended D2C market price.
    - Premium Price ($P_{\text{prem}}$) — Gifted / Institutional price tier.
  - **Tactile Adjustment Controls**:
    - `[- ₹50]` and `[+ ₹50]` nudge buttons (clamped above floor).
    - Stock preset pills: `[1]`, `[2]`, `[5]`, `[10]` + tactile stepper.
  - Voice Edit Drawer with real-time spoken price/detail override.
  - **Statutory Spoken Readback Bar**: *"सुनें: ऑडियो पुष्टि • Listen to audio summary"* triggers TTS readback (*"आपका कैटलॉग तैयार है: $cat $title, कीमत ₹$price। क्या यह सही है?"*).
  - ONDC Statutory KYC prefill badges (`Origin: IND`, `Ship: PT24H`, `Return: P7D`, `Cancellable: Yes`).
  - Action Bar: *"Save Draft"* and *"Publish Product"*.

---

## 3. Qwen Extraction Architecture

### 3.1 Endpoint Configuration (`constants.dart`)
```dart
static const String aiExtractionProvider = 'groq_qwen'; // or 'custom_qwen'
static const String qwenModel = 'qwen-2.5-32b-it';
static const String qwenApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
```

### 3.2 Target Beckn Extraction Schema
```json
{
  "title_en": "Product title in English",
  "title_hi": "उत्पाद का हिंदी नाम",
  "category": "apparel|pottery|metalcraft|woodwork|food|jewelry|decor|handicrafts",
  "materials": ["primary material", "secondary material"],
  "dimensions": "length x width x height or size",
  "care_instructions": "Care instructions",
  "craft_technique": "Name of technique",
  "lead_time": "Production lead time",
  "origin_cluster": "Craft cluster / village",
  "fair_price": 350,
  "available_quantity": 5,
  "description_en": "Evocative English story",
  "description_hi": "विस्तृत हिंदी विवरण"
}
```

---

## 4. ONDC Statutory KYC & Regulatory Defaults

To ensure zero typing for statutory compliance under Indian e-commerce regulations, BazaarSetu automatically injects merchant defaults:
- `country_of_origin`: `"IND"`
- `time_to_ship`: `"PT24H"` (Standard next-day handoff)
- `return_window`: `"P7D"` (7 days)
- `is_cancellable`: `true`
- `is_returnable`: `true`
- `contact_details_consumer_care`: Pre-filled from artisan guild federation profile.
