# 📝 BazaarSetu Research Document Updates & Google Doc Sync Guide

This document records the exact updates synchronized to the master Google Docs research paper:
**Document Link:** [BazaarSetu Research Document](https://docs.google.com/document/d/1DrWxZN5sRfWaw0orcC3O8-4F5_fap7gc9LICLZOarGM/edit?usp=drive_link)  
**Document ID:** `1DrWxZN5sRfWaw0orcC3O8-4F5_fap7gc9LICLZOarGM`

---

## 📌 Summary of Synchronized Tabs

The following tabs in the master research document were populated and updated directly via `gdocs`:

| Tab ID | Tab Name | Status | Key Information Synchronized |
| :--- | :--- | :--- | :--- |
| `t.8u5mh3etf5v5` | **App Workflow** | **Populated** | Full end-to-end user workflow: Language selection, streamlined explore feed, 4:3 viewfinder with torch flash, guided 4-step voice interview, modern Karigar AI creation experience, tactile corridor, dual editing, unlisting, and 1-tap ONDC broadcast. |
| `t.h69hmic7trsv` | **Pricing Recommedation** | **Populated** | Distress selling problem, MoSJE statutory minimum wage floor formula, batch quantity division ($Q_{\text{items}}$), explicit recognition of seller proposed price ($P_{\text{proposed}}$), fair price alignment, 1.20x export tier, 20% strike-through MRP derivation, and tactile nudges. |
| `t.rhfxd8onk3g8` | **Voice Note Structures** | **Populated** | Guided 4-step interview structure (Craft details, dimensions & weight with manual modal fallback, pricing & labor, artisan heritage story), Qwen bilingual Devanagari + English schema, conversational voice update commands, and audio interruption safety. |
| `t.u1d0tw26n0c3` | **Voice Pipeline** | **Referenced** | Core ASR/NMT/TTS architecture, latency budget, unit economics analysis, and error recovery flows. |
| `t.qo0vm1edbq43` | **Beckn Backend** | **Referenced** | FastAPI architecture, Ed25519 cryptography, asynchronous handshake, catalog schema mapping, and ONDC protocol webhooks. |
| `t.3pf6zqxj5emv` | **Backend Architecture**| **Referenced** | Client-side payload reduction, decoupled async processing, progressive delivery, and offline-first queue. |
| `t.4ho4nsrg7odi` | **Product Listing** | **Referenced** | Allowed categories (crafts, homemade food with FSSAI, apparel, local kirana) vs restricted items (electronics, uncertified medicines, dangerous goods). |

---

## 🔍 Detailed Tab Content Reference

### 1. Tab `t.8u5mh3etf5v5`: App Workflow

#### Paradigm: Strict Modality Partitioning
BazaarSetu replaces complex e-commerce desktop forms with a strict, zero-typing mobile workflow tailored for non-literate and semi-literate rural artisans. The interface segments data ingestion across three dedicated modalities:
- **Camera / Vision**: Framing, multi-angle slots, category detection.
- **Voice**: Guided 4-step conversational interview in the artisan's mother tongue.
- **Tactile Touch**: Corridor cards, numerical price nudges, and preset inventory pills.

#### Step-by-Step Screen Walkthrough:
1. **Language Preference & Vernacular Onboarding (`/welcome`)**:
   - Offers 6 Indic regional languages: Hindi, Marathi, Gujarati, Bengali, Tamil, Telugu.
   - Dual-Language UI Standard: English is always shown as the primary anchor for national discovery, while natural regional translations appear directly beneath every title, button, and description.
2. **Artisan Hub & Catalog Feed (`/explore`)**:
   - Streamlined catalog feed displaying active and published crafts with provenance, GI tags, and direct Karigar Fair Pledge banner.
   - Craft Quick View Modal with artisan audio story playback.
   - **Audio Lifecycle Safety**: Audio playback immediately halts when dismissing modals or navigating away.
3. **Multi-Angle Visual Capture & Category Detection (`/capture`)**:
   - 4:3 Camera Viewfinder with golden corner brackets, crosshairs, grid, and hardware torch flash controls.
   - Automatic classification into ONDC retail categories (`ONDC:RET12`, `ONDC:RET16`, `ONDC:RET10`).
   - 4-Slot Multi-Angle Tracker (Front, Side, Back, Detail macro).
4. **Guided 4-Step Voice Interview (`/voice`)**:
   - Stage 1: Craft & Material Details
   - Stage 2: Dimensions & Weight (with optional manual dimensions fallback dialog)
   - Stage 3: Pricing & Labor Effort
   - Stage 4: Story & Heritage
   - Open-ended recording (no arbitrary 15s limit) with 30-bar amplitude waveform.
5. **Modern Karigar AI Creation Experience (`/processing`)**:
   - Hero craft photo centerpiece framed by an animated breathing pulse ring.
   - Dynamic pipeline phase indicator (transcription, studio enhancement, bilingual storytelling, statutory corridor, ONDC packaging).
   - Rotating artisan wisdom tips updated dynamically every 3.5s.
6. **Interactive Catalog Card & Tactile Controls (`/catalog`)**:
   - Bilingual presentation (English primary + Devanagari translation directly below).
   - Tactile 3-tier price corridor (Floor, Fair, Premium) + `[±₹50]` nudges + direct "Set Exact Price" numeric entry.
   - Tactile stock pills (`1`, `2`, `5`, `10`, `25`, `50`) + custom quantity dialog with batch chips (`+10` to `+500`).
   - Dual editing: Manual touch or conversational voice updates (*"कीमत ₹650 कर दो"*).
   - ONDC lifecycle: 1-tap live publish, auto-save drafts, unlisting back to draft, and safe audio readback.

---

### 2. Tab `t.h69hmic7trsv`: Pricing Recommendation & Corridor Engine

#### The Problem: Distress Selling
Rural Indian craftspeople frequently succumb to predatory pricing by middlemen, distress-selling authentic handmade products for 30% to 50% below the cost of basic subsistence labor.

#### Mathematical Formulations:
1. **Statutory Minimum Cost Floor ($C_{\text{floor}}$)**:
   $$\text{Total Base Cost} = M_{\text{raw}} + (T_{\text{days}} \times W_{\text{statutory}} \times K_{\text{skill}}) + O_{\text{overhead}}$$
   $$C_{\text{floor}} = \text{round}\left(\frac{\text{Total Base Cost}}{Q_{\text{items}}}\right)$$
   - $M_{\text{raw}}$: Stated material cost (clay, yarn, metal, wood, dyes).
   - $T_{\text{days}}$: Production effort in artisan days.
   - $W_{\text{statutory}}$: Central/State minimum wage for skilled crafts (₹450–₹600/day, default ₹500/day).
   - $K_{\text{skill}}$: Skill multiplier (1.0 for basic craft, 1.25 for GI clusters, 1.5 for Master Weavers).
   - $O_{\text{overhead}}$: 10% allowance for firing, packaging, and local transport.
   - $Q_{\text{items}}$: Total batch items produced (defaults to 1, or extracted stock count).

2. **Fair Price & Seller Proposed Price Alignment**:
   When the artisan explicitly states their selling price ($P_{\text{proposed}} > 0$):
   $$P_{\text{fair}} = P_{\text{proposed}}$$
   $$P_{\text{floor}} = \min(C_{\text{floor}}, \text{round}(P_{\text{proposed}} \times 0.85))$$
   $$P_{\text{prem}} = \text{round}(P_{\text{fair}} \times 1.20)$$

   When no price is proposed by the seller:
   $$P_{\text{fair}} = \text{round}(C_{\text{floor}} \times 1.50)$$
   $$P_{\text{prem}} = \text{round}(P_{\text{fair}} \times 1.20)$$

3. **Consumer Strike-Through & ONDC MRP Derivation**:
   $$\text{MRP} = \text{round}(P_{\text{active}} \times 1.25)$$
   $$\text{Discount \%} = \text{round}\left(\frac{\text{MRP} - P_{\text{active}}}{\text{MRP}} \times 100\right)$$
   Generates a compliant, attractive 20% strike-through discount on ONDC buyer search grids.

---

### 3. Tab `t.rhfxd8onk3g8`: Voice Note Structures & Schema

#### Guided 4-Step Voice Interview:
- **Step 1: Product & Craft Details**: Category, materials, and crafting technique.
- **Step 2: Dimensions, Measure & Weight**: Length, width, height, weight, with optional tactile manual modal fallback.
- **Step 3: Pricing, Cost & Production Effort**: Labor days, raw material cost, selling price.
- **Step 4: Artisan Story & Heritage**: Generational tradition, occasion, cultural significance.

#### Structured Qwen Extraction Schema:
```json
{
  "commodity_name": "string (e.g. Diya, Saree, Kurta, Basket, Idol)",
  "craft_type": "string (e.g. Terracotta Pottery, Handloom Silk, Dokra)",
  "material": "string (e.g. Terracotta Clay, Pure Silk, Brass)",
  "work_type": "string (e.g. Hand-carved, Handwoven, Lost-wax cast)",
  "net_quantity": "string (e.g. 1 unit, 500g, 6.2 meters)",
  "cluster_location": "string (e.g. Pune, Chanderi, Bastar, Jaipur)",
  "dimensions": "string or null (e.g. 5x5 inches, 6.2 meters)",
  "weight": "string or null (e.g. 250g, 1.2kg)",
  "title_en": "SEO-friendly product title in English (max 70 chars)",
  "title_hi": "सरल और स्वाभाविक हिंदी शीर्षक (देवनागरी)",
  "description_en": "Engaging artisan storytelling description in English (80-120 words)",
  "description_hi": "स्वाभाविक बोलचाल की हिंदी में शिल्प विवरण",
  "pricing_inputs": {
    "raw_material_cost": "integer or null",
    "labor_days": "integer or null"
  },
  "spoken_price": "integer or null (if seller explicitly stated selling price)",
  "spoken_quantity": "integer or null (if seller explicitly stated inventory count)"
}
```

#### Dual Editing Voice Commands:
- Price Update: *"कीमत ₹650 कर दो"* / *"Make price 650 rupees"*
- Material Update: *"सामग्री शुद्ध पीतल करो"*
- Title Update: *"इसका नाम रॉयल चंदेरी दुपट्टा रखो"*
