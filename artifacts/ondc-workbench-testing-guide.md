# 🌐 ONDC Workbench & Beckn Protocol Testing Guide

This guide explains how to test the **BazaarSetu Beckn Provider Platform (BPP)** backend against ONDC network standards using **ONDC Workbench**, **Webhook.site**, and **Curl/Postman**.

---

## 🧭 How ONDC / Beckn Discovery Works

ONDC uses an **asynchronous two-hop protocol**:

```
 ┌───────────────┐           ┌────────────────┐           ┌──────────────────────┐
 │ Buyer App     │  /search  │ ONDC Gateway / │  /search  │ BazaarSetu BPP Node  │
 │ (BAP/Workbench│ ────────> │ Beckn Router   │ ────────> │ (FastAPI on Render)  │
 └───────┬───────┘           └────────────────┘           └──────────┬───────────┘
         │                                                           │
         │ <────────────────────── ACK (< 1 sec) ────────────────────┤
         │                                                           │
         │ <────────────────── /on_search callback ──────────────────┘
         │               (Contains Full Catalog from Supabase)
```

1. **Inbound `/search`**: The Buyer App or Gateway sends a discovery request.
2. **Synchronous ACK**: BazaarSetu BPP immediately returns `{"message": {"ack": {"status": "ACK"}}}` within **< 1 second** (mandatory by ONDC SLA).
3. **Asynchronous `/on_search`**: In a background worker, the BPP queries the Supabase database for active artisan crafts and `POST`s the complete Beckn catalog directly back to the caller's `bap_uri/on_search`.

---

## ⚡ Method 1: Instant End-to-End Test (Zero Setup, 2 Minutes)

You can verify the entire ONDC discovery loop right now using **Webhook.site** (a free online webhook receiver) and `curl`.

### Step 1: Get a free callback URL
1. Open [webhook.site](https://webhook.site) in your browser.
2. Copy **"Your unique URL"** (e.g., `https://webhook.site/3b8f6c4a-1122-3344-5566-778899aabbcc`).
   *(This URL acts as our mock Buyer App `bap_uri`).*

### Step 2: Fire the Beckn `/search` request
Run this command in your terminal (replace `YOUR_WEBHOOK_URL` with the URL from Step 1 and use your live Render URL):

```bash
curl -X POST "https://project-zerotype-bpp.onrender.com/beckn/search" \
  -H "Content-Type: application/json" \
  -d '{
    "context": {
      "domain": "ONDC:RET12",
      "country": "IND",
      "city": "std:07542",
      "action": "search",
      "core_version": "1.2.0",
      "bap_id": "mock-buyer-app.ondc.org",
      "bap_uri": "YOUR_WEBHOOK_URL",
      "transaction_id": "txn_test_001",
      "message_id": "msg_test_001",
      "timestamp": "2026-11-07T07:30:00.000Z",
      "ttl": "PT30S"
    },
    "message": {
      "intent": {
        "category": {
          "id": "ONDC:RET12"
        },
        "item": {
          "descriptor": {
            "name": "silk"
          }
        }
      }
    }
  }'
```

### Step 3: Verify the Responses
1. **In your terminal**: You immediately receive a 200 OK synchronous ACK:
   ```json
   {
     "message": {
       "ack": {
         "status": "ACK"
       }
     }
   }
   ```
2. **On your Webhook.site tab**: Within **1–2 seconds**, a new `POST /on_search` request appears!
   Inspect the JSON body:
   - **BPP Provider**: `BazaarSetu Karigar Collective`
   - **Bilingual Content**:
     - English title & SEO description
     - Hindi title & description in `tags -> translation_hi`
   - **Craft Attributes**: Materials, artisan cluster, artisan name
   - **Pricing**: Recommended D2C fair price and 3-tier corridor
   - **Studio Image URL**: Ready for Buyer App presentation

---

## 🛠️ Method 2: Testing with ONDC Official Workbench

The **ONDC Developer Workbench** is the official testing tool for certifying network participants.

### Step 1: Access the Workbench
- Go to [workbench.ondc.org](https://workbench.ondc.org/) (or your staging environment portal).
- Log in with your network participant credentials.

### Step 2: Configure Your BPP Profile
Under **Test Configurations / Network Participants**:
- **Role**: `Seller App (BPP)`
- **Domain**: `ONDC:RET12` (Fashion & Handloom) or `ONDC:RET16` (Home & Decor)
- **Subscriber ID**: `bazaarsetu.bpp.org` (or your configured `BPP_SUBSCRIBER_ID`)
- **Subscriber URI**: `https://project-zerotype-bpp.onrender.com/beckn`
- **Signing Public Key**: The Ed25519 public key printed in Render startup logs (if signing is enabled).

### Step 3: Run the Test Suites
1. **Discovery Suite (`/search` $\rightarrow$ `/on_search`)**:
   - Click **Trigger Search**.
   - Workbench sends a test search to `https://project-zerotype-bpp.onrender.com/beckn/search`.
   - Workbench validates that the synchronous ACK returned within 1,000ms.
   - Workbench listens on its internal BAP endpoint for `/on_search` and validates:
     - `context.bpp_id` matches `bazaarsetu.bpp.org`.
     - Catalog contains valid `bpp/providers` and `items`.
     - Price currency is `INR` and values are valid decimals.
2. **Order Lifecycle Suites (`/select`, `/init`, `/confirm`)**:
   - BazaarSetu BPP returns automatic protocol ACKs for select, init, and confirm, satisfying test harness requirements.

---

## 📱 Method 3: Mobile App to Supabase to ONDC Flow

To test the full end-to-end integration starting from the artisan's phone:

1. **Launch BazaarSetu Mobile App**:
   - Run the app on your Android device: `flutter run`
2. **Create a Craft**:
   - Capture a photo of a craft.
   - Speak details in Hindi or regional language (e.g. *"यह चंदेरी सिल्क दुपट्टा है, 3 दिन लगे, ₹2500"*).
   - Review the generated bilingual catalog card.
3. **Tap "Publish Product • प्रकाशित करें"**:
   - The app sends a `POST /api/v1/bpp/publish` request to `https://project-zerotype-bpp.onrender.com`.
   - Render backend executes an `INSERT ... ON CONFLICT` into the **Supabase `artisan_listings` table**.
   - The app displays **Published to ONDC!** and switches to the **Live on ONDC** view with the green status badge and **Unlist** button.
4. **Verify in Supabase Dashboard**:
   - Log in to [supabase.com](https://supabase.com) $\rightarrow$ Your Project $\rightarrow$ **Table Editor**.
   - Select table `artisan_listings`.
   - You will see your newly published craft stored with its full JSON payload, fair price, artisan name, and cluster.
5. **Verify Discovery**:
   - Run the `curl` command from Method 1.
   - Your newly created craft from Supabase is now automatically returned in the `/on_search` payload!

---

## 🔍 Handy Inspection Endpoints

You can inspect the state of your BPP directly in any browser:

| Endpoint | Method | Purpose |
|---|---|---|
| `https://project-zerotype-bpp.onrender.com/` | `GET` / `HEAD` | Health check & active listing counter (used by UptimeRobot) |
| `https://project-zerotype-bpp.onrender.com/health` | `GET` / `HEAD` | Dedicated 200 OK monitoring endpoint |
| `https://project-zerotype-bpp.onrender.com/docs` | `GET` | Interactive Swagger UI API documentation |
| `https://project-zerotype-bpp.onrender.com/api/v1/bpp/listings` | `GET` | Returns all active listings currently served on ONDC |
| `https://project-zerotype-bpp.onrender.com/api/v1/bpp/listings/{id}` | `GET` | Fetch specific listing payload |
| `https://project-zerotype-bpp.onrender.com/api/v1/bpp/listings/{id}/unlist` | `POST` | Revert listing to unlisted / draft status |
