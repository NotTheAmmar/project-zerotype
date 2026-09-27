# KalaKriti Architecture

KalaKriti is a mobile application that allows rural artisans to create ONDC-compliant product catalogs using just their voice and smartphone camera.

## Core Flow
1. **Voice Input**: Artisan describes their product in their native language (e.g., Hindi).
2. **Image Input**: Artisan takes a raw photo of the product in their workshop.
3. **AI Processing**: 
   - **Voice**: Sent to Bhashini (Dhruva APIs) for Speech-to-Text (ASR) and Translation (NMT).
   - **Extraction**: English text is sent to Gemini 2.5 Flash to extract a strict ONDC Beckn schema JSON.
   - **TTS**: Product description is translated back to Hindi (NMT) and read aloud via Bhashini TTS.
   - **Image**: Sent to a backend running BiRefNet for background removal and professional studio compositing.
4. **Publish**: The final catalog item is published to an ONDC BPP endpoint.

## Tech Stack
- **Frontend**: Flutter (Mobile/Web)
- **Voice / NLP Pipeline**: Bhashini Cloud APIs (Govt. of India)
- **JSON Extraction**: Google Gemini 2.5 Flash
- **Image Processing**: Python FastAPI + BiRefNet (for background removal)
- **Deployment Strategy**: Serverless / Managed Cloud for APIs

## Environment Configuration
```env
API_BASE_URL=https://api.kalakriti.dev/v1
USE_MOCK_DATA=false

# Bhashini Configuration
BHASHINI_API_KEY=your_inference_api_key
BHASHINI_ULCA_KEY=your_ulca_api_key
BHASHINI_USER_ID=your_32_char_user_id
BHASHINI_PIPELINE_ID=64392f96daac500b55c543cd
BHASHINI_API_URL=https://dhruva-api.bhashini.gov.in

# Gemini Configuration
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-2.5-flash

# Backend (Image Processing & ONDC Publish)
BACKEND_URL=https://your-backend-domain.com
BPP_BACKEND_URL=https://your-bpp-domain.com
```
