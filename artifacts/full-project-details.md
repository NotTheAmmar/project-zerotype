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
   - Filter crafts by category pills (`All Crafts`, `Pottery & Clay`, `Clothing & Weaves`, `Home Decor`, `Tribal Metalcraft`, `Festive Special`).
   - Product cards with craft provenance, GI tags, and direct Karigar Fair Pledge banner.
   - **Product Quick View Modal**: Preview craft details, listen to the Karigar story audio snippet with play/pause, add to Guild Basket, or inspect full ONDC catalog node.
3. **Capture Screen (`/capture`)**:
   - 4:3 Camera Viewfinder with golden corner brackets, crosshairs, grid, and flash controls.
   - Real-time detection status chip (`Apparel RET12`, `Pottery RET16`, `Food RET10`).
   - Spoken tips banner (*"दीया बीच में रखें और अच्छी रोशनी रखें"*).
   - 4-slot multi-angle capture tracker (Front, Side, Back, Detail).
4. **Voice Screen (`/voice`)**:
   - Plays localized category-adaptive question via TTS before opening the mic.
   - Open-ended recording (unlimited duration; no 15-second cap).
   - Real-time 30-bar waveform and silence warning.
5. **Processing Screen (`/processing`)**:
   - Studio background matting via BiRefNet backend.
   - Speech-to-text via Bhashini ASR.
   - Entity extraction and schema structuring via **Qwen-2.5-32B-Instruct**.
   - Readback TTS audio generation.
6. **Catalog Screen (`/catalog`)**:
   - Raw photo vs. studio photo comparison.
   - GI Cluster Origin badge.
   - **Tactile Price Corridor**: Floor (₹200), Fair (₹350), Premium (₹450) cards + `[±₹50]` quick adjustment nudges.
   - Tactile stock selection pills: `[1]`, `[2]`, `[5]`, `[10]` + stepper.
   - Voice Edit modal drawer for spoken corrections.
   - Audio readback banner: *"सुनें: ऑडियो पुष्टि • Listen to audio summary"*.
   - 1-tap live publish to ONDC BPP.

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
