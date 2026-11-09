# Project ZeroType: BazaarSetu Architecture

**Project ZeroType** (User-facing brand: **BazaarSetu** / **बाज़ारसेतु**) is a mobile cataloging engine designed to onboard non-literate and semi-literate rural Indian artisans into the Open Network for Digital Commerce (ONDC) without requiring them to type a single character.

---

## 1. Core Paradigm: Strict Modality Partitioning

Rather than overloading a single unconstrained voice prompt, BazaarSetu strictly segments data acquisition by input modality:

```
┌─────────────────┐       ┌────────────────────────┐       ┌────────────────────────┐
│  Vision/Camera  │ ────> │ Spoken Dialect Anchor  │ ────> │ Tactile Corridor /     │
│  (Multi-angle)  │       │ (Open-ended Speech)    │       │ Stepper (Zero-Typing)  │
└─────────────────┘       └────────────────────────┘       └────────────────────────┘
        │                             │                                 │
        ▼                             ▼                                 ▼
Detect Category &             Dialect Prompt played             Fair-Price Corridor
Bounding Geometry             MIC opened (No 15s limit)         Floor/Fair/Premium
(RET12, RET16, RET10)         ASR -> Qwen Structuring           Tactile Pill [1][2][5][10]
```

1. **Vision / Camera Modality (Primary Anchor)**:
   - Guided multi-angle capture (Front, Side, Back, Detail slots).
   - Real-time heuristic/vision classifier detects craft category (`ONDC:RET12` Apparel, `ONDC:RET16` Pottery & Crafts, `ONDC:RET10` Packaged Food).
2. **Guided 4-Step Voice Interview (Speech Input)**:
   - Structured 4-stage guided prompts: (1) Craft & Material, (2) Dimensions & Weight with manual fallback dialog, (3) Price & Labor Effort, (4) Artisan Story & Heritage.
   - Mic opens for open-ended spoken narration (unlimited recording duration; no 15-second cap).
   - Speech transcribed via Bhashini ASR / Whisper and structured via **Qwen** (Qwen-2.5 / Qwen-3.8 via Groq free API or dedicated backend).
3. **Tactile & Direct Zero-Typing Controls (Quantities & Pricing)**:
   - Available stock configured via tactile preset pills (`[1]`, `[2]`, `[5]`, `[10]`, `[25]`, `[50]`) or custom quantity dialog with batch chips (`+10` to `+500`).
   - Pricing selected via 3 Fair-Price Corridor Cards (**Floor Price**, **Fair Price**, **Premium Price**) with `[±₹50]` quick adjustment nudges, or direct **Set Exact Price** numeric entry. Stated selling prices are respected directly.
4. **Automated Background Prefill & Persistence**:
   - Zero typing for statutory, regulatory, and logistics fields. Automated merchant KYC prefill (`country_of_origin="IND"`, `time_to_ship="PT24H"`, `return_window="P7D"`, `cancellable=true`, `contact_details_consumer_care`).
   - Active catalogs and drafts persistently saved in Supabase PostgreSQL with real-time in-memory caching for sub-millisecond Beckn discovery responses.
5. **Auditory Verification & Readback Loop**:
   - Readback in artisan's native language (*"आपका कैटलॉग तैयार है: $cat $title, कीमत ₹$price। क्या यह सही है?"*).
   - Audio halts safely immediately when leaving or dismissing screens.
   - Instant 1-tap broadcast to ONDC BPP.

---

## 2. Tech Stack

- **Frontend**: Flutter (Cross-platform Android / iOS / Web)
- **Speech Pipeline**: Bhashini Cloud ASR / NMT / TTS (Govt. of India Dhruva platform) + On-device Flutter TTS fallback
- **Catalog Structuring LLM**: **Qwen-2.5-32B-Instruct** (via free Groq API endpoint or custom OpenAI-compatible server)
- **Computer Vision / Image Processing**: BiRefNet background isolation & studio composite pipeline via FastAPI backend
- **ONDC Integration**: Beckn protocol v1.2.0 BPP adapter (`/api/v1/bpp/publish`)

---

## 3. Environment Configuration (`.env`)

```env
# Application Settings
API_BASE_URL=https://api.bazaarsetu.in/v1
USE_MOCK_DATA=true

# AI Extraction Provider (Qwen)
AI_EXTRACTION_PROVIDER=groq_qwen
QWEN_MODEL=qwen-2.5-32b-it
QWEN_API_URL=https://api.groq.com/openai/v1/chat/completions
GROQ_API_KEY=gsk_your_groq_api_key_here

# Bhashini Configuration (Govt. of India Indic NLP)
BHASHINI_API_KEY=your_bhashini_api_key
BHASHINI_ULCA_KEY=your_bhashini_ulca_key
BHASHINI_USER_ID=your_bhashini_user_id
BHASHINI_PIPELINE_ID=64392f96daac500b55c543cd
BHASHINI_API_URL=https://dhruva-api.bhashini.gov.in

# Backend Services
BACKEND_URL=https://your-backend-domain.com
BPP_BACKEND_URL=https://your-bpp-domain.com
```
