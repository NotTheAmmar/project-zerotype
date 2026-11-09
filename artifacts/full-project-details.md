# Project ZeroType: BazaarSetu (बाज़ारसेतु)
## Autonomous Voice-First Cataloging & Tactile Decentralized Commerce Engine for Rural Artisans

**Code Name:** Project ZeroType  
**Product Name:** BazaarSetu / बाज़ारसेतु  
**Target Network:** Open Network for Digital Commerce (ONDC) v1.2.0  
**Theme:** Sovereign Heritage & Inclusive Digital Economy  

---

## Executive Summary
Traditional artisans and handloom weavers across India face severe barriers when trying to sell online: over 80% of artisans abandon e-commerce onboarding due to complex, English-first, desktop text forms.

**Project ZeroType (BazaarSetu)** is a voice-first, zero-typing mobile application that enables any rural artisan to create an ONDC-compliant, studio-quality product catalog using only their camera, voice, and tactile touch controls. Operating under a **Strict Modality Partitioning Architecture**, BazaarSetu removes all text entry:
1. **Camera / Vision Model First**: The artisan snaps photos (Front, Side, Back, Detail slots). A real-time heuristic vision model classifies the craft category (`ONDC:RET12` Apparel, `ONDC:RET16` Pottery & Crafts, `ONDC:RET10` Food).
2. **Category-Adaptive Audio Anchor**: A localized spoken dialect question (5–8 seconds) plays automatically before the microphone opens, priming the artisan to speak naturally.
3. **Open-Ended Voice Narration**: The artisan speaks without arbitrary time limits (no 15-second cap).
4. **Qwen Structuring Engine**: **Qwen-2.5-32B-Instruct** parses the speech into a compliant ONDC Beckn schema JSON, extracting title, materials, cluster, dimensions, and any spoken price/quantity.
5. **Tactile Zero-Typing Controls**: The artisan adjusts stock via preset pills (`[1]`, `[2]`, `[5]`, `[10]`) and chooses their price through 3 Fair-Price Corridor Cards (**Floor**, **Fair**, **Premium**) with `[±₹50]` tactile nudges.
6. **Statutory KYC Prefill**: Legal and logistics attributes (`country_of_origin="IND"`, `time_to_ship="PT24H"`, `return_window="P7D"`, consumer care details) are prefilled automatically.
7. **Spoken Readback & Verification**: The artisan hears a natural Hindi readback summary before broadcasting live to ONDC in 1 tap.

---

## Technical Architecture

```text
┌────────────────────────────────────────────────────────────────────────┐
│                 BazaarSetu Client (Flutter Mobile)                     │
│   • Welcome (6 Indic Langs)          • Explore & Karigar Quick View    │
│   • Multi-Angle Slot Viewfinder      • Category-Adaptive Audio Anchor  │
│   • Tactile 3-Tier Price Corridor    • Tactile Quantity Pills & Stepper│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTPS / REST (Multipart Payloads)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   High-Performance Backend (FastAPI)                   │
│   • Auth & Ingestion Gateways         • PostGIS Cluster Mapping        │
│   • Redis Task Queue                  • PostgreSQL Stores              │
└───────┬───────────────────────────┬───────────────────────────┬────────┘
        │                           │                           │
        ▼                           ▼                           ▼
┌──────────────────┐        ┌──────────────────┐        ┌────────────────┐
│ Edge / Vision    │        │ Speech & LLM     │        │ Commerce Rails │
│ • BiRefNet INT8  │        │ • Bhashini ASR   │        │ • Beckn v1.2.0 │
│ • OpenCV Engine  │        │ • Qwen-2.5-32B   │        │ • ONDC Gateway │
│ • Heuristic Class│        │ • Indic TTS      │        │ • GeM / 3PL API│
└──────────────────┘        └──────────────────┘        └────────────────┘
```

---

## Screen Architecture & User Walkthrough

1. **Welcome Screen (`/welcome`)**:
   - Offers 6 Indic regional languages: Hindi, Marathi, Gujarati, Bengali, Tamil, Telugu.
   - Spoken audio greeting button playing native guidance.
2. **Explore Screen (`/`)**:
   - Streamlined artisan catalog feed displaying active and published crafts with provenance, GI tags, and direct Karigar Fair Pledge banner.
   - **Product Quick View Modal**: Preview craft details, listen to the Karigar story audio snippet with automatic lifecycle stop on dismissal, or inspect full ONDC catalog node.
3. **Capture Screen (`/capture`)**:
   - 4:3 Camera Viewfinder with golden corner brackets, crosshairs, grid, and hardware torch flash controls.
   - Real-time detection status chip (`Apparel RET12`, `Pottery RET16`, `Food RET10`).
   - Spoken tips banner (*"दीया बीच में रखें और अच्छी रोशनी रखें"*).
   - 4-slot multi-angle capture tracker (Front, Side, Back, Detail).
4. **Voice Screen (`/voice`)**:
   - **Guided 4-Step Voice Interview**: Step 1: Product & Craft Details; Step 2: Dimensions & Weight (with optional manual dimensions fallback); Step 3: Pricing & Labor; Step 4: Story & Heritage.
   - Category-adaptive audio question prompt before each step.
   - Open-ended recording (no arbitrary 15s limit) with 30-bar live waveform.
5. **Processing Screen (`/processing`)**:
   - Modern Karigar AI experience featuring artisan craft photo centerpiece with breathing glow ring.
   - Dynamic stage indicator (transcription, studio enhancement, bilingual storytelling, statutory corridor, ONDC packaging).
   - Sleek progress bar with smooth percentage transitions and rotating artisan wisdom tips every 3.5s.
6. **Catalog Screen (`/catalog`)**:
   - Bilingual presentation (English primary + regional vernacular translation directly below).
   - High-impact photo gallery with GI Cluster Origin badge.
   - **Tactile Price Corridor**: Floor, Fair, and Premium cards + `[±₹50]` nudges + direct exact numeric price entry.
   - **Flexible Inventory Controls**: Tactile pills (`1`, `2`, `5`, `10`, `25`, `50`) + custom quantity dialog with batch chips (`+10`, `+25`, `+50`, `+100`, `+250`, `+500`).
   - **Dual Editing**: Edit attributes manually or use conversational voice updates (*"कीमत ₹650 कर दो"*).
   - **ONDC Lifecycle Management**: Publish to ONDC, auto-save drafts, unlist active listings back to draft, and audio playback that halts immediately on navigation.

---

## Competitive Differentiation

| Feature / Capability | Project ZeroType (BazaarSetu) | Traditional ONDC Apps | Generic E-Commerce Portals |
| :--- | :--- | :--- | :--- |
| **Strict Modality Partitioning** | **Yes (Vision -> Voice -> Tactile)** | No (Text forms) | No (Text forms) |
| **Structuring Engine** | **Qwen-2.5-32B-Instruct** | None / Manual | Manual form data |
| **Voice Recording Duration** | **Open-ended (No arbitrary cap)** | None | None |
| **Category-Adaptive Anchors**| **Yes (Tailored dialect question)** | No | No |
| **Tactile Zero-Typing Pricing**| **Yes (3-tier cards + [±₹50] nudges)** | No (Keyboard input) | No (Keyboard input) |
| **Statutory KYC Prefill** | **Yes (Automatic ONDC defaults)** | No (Manual typing) | No (Manual typing) |
| **Auditory Verification Readback**| **Yes (Native spoken audio summary)** | No | No |
| **Decentralized ONDC Sync** | **Yes (Beckn v1.2.0 BPP)** | Yes | No (Walled garden) |
