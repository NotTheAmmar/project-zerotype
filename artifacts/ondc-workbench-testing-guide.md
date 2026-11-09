# 🌐 ONDC Workbench & Beckn Protocol Testing Guide

This guide provides the complete, authoritative specification and testing workflow for certifying the **BazaarSetu Beckn Provider Platform (BPP)** backend against ONDC network standards using the **Official ONDC Workbench**, **Webhook.site**, and **Postman/Curl**.

---

## 🧭 1. What is ONDC Workbench & How Discovery Works

The **ONDC Developer Workbench** ([workbench.ondc.org](https://workbench.ondc.org/)) is the official testing sandbox provided by ONDC. Because joining the production ONDC network requires extensive legal and commercial accreditation, the Workbench acts as a certified **Simulated Gateway** and **Buyer App (BAP)**.

Its role in BazaarSetu is to verify that our backend successfully acts as a **Beckn Provider Platform (BPP) / Seller Node**, returning compliant catalogs and meeting statutory Beckn network SLAs.

### The Asynchronous Two-Hop Architecture:

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
2. **Synchronous ACK**: BazaarSetu BPP immediately returns `{"message": {"ack": {"status": "ACK"}}}` within **< 1 second** (mandatory by Beckn SLA).
3. **Asynchronous `/on_search`**: In a background worker, the BPP queries the database for active artisan crafts and `POST`s the complete Beckn catalog directly back to the caller's `bap_uri/on_search`.

---

## ⚙️ 2. Official Workbench Session Parameters

When configuring a test session in the ONDC Developer Workbench, enter the following parameters:

| Parameter | Value | Description |
| :--- | :--- | :--- |
| **Subscriber Type** | `BAP` | Workbench acts as a Buyer App (e.g. Paytm, Mystore) requesting catalog data. |
| **Domain** | `ONDC:RET12` | ONDC Retail domain for **Fashion, Apparel & Handlooms** (or `ONDC:RET16` for Home Decor). |
| **Version** | `1.2.0` | Active stable Beckn retail protocol version. |
| **Use Case** | `FASHION` | Configures schema rules and validation checks for textiles and crafts. |
| **Environment** | `PRE-PRODUCTION` | ONDC staging test environment. |
| **BPP Subscriber ID** | `bazaarsetu.bpp.org` | Registered BPP subscriber identifier (matches `BPP_SUBSCRIBER_ID`). |
| **BPP Subscriber URI** | `https://project-zerotype-bpp.onrender.com/beckn` | Public HTTPS callback endpoint hosted on Render. |

---

## 🔄 3. The Beckn Protocol Dance (Protocol Lifecycle)

ONDC relies on paired, asynchronous API interactions. For every inbound request from a Buyer (BAP), the Seller (BPP) must immediately return an `ACK`, followed by the asynchronous `on_<action>` payload.

### Phase 1: Discovery (Cataloging) — *Core Active Focus*
1. **`/search`** *(Workbench $\rightarrow$ BazaarSetu)*: The simulated buyer searches for crafts (e.g. `"saree"`, `"silk"`, or `"handloom"`).
2. **`/on_search`** *(BazaarSetu $\rightarrow$ Workbench)*: BPP maps active listings from Supabase into the ONDC schema and dispatches the catalog to `bap_uri/on_search`.

### Phase 2: Order Lifecycle & Fulfillment
3. **`/select` & `/on_select`**: Buyer selects an artisan item. BPP verifies stock (`available_qty`) and returns a quote.
4. **`/init` & `/on_init`**: Buyer enters shipping and delivery address. BPP calculates shipping terms.
5. **`/confirm` & `/on_confirm`**: Buyer authorizes payment. BPP confirms order, allocates inventory, and returns an Order ID.
6. **`/status` & `/on_status`**: Queries order fulfillment progress (Packed, Dispatched, In-Transit, Delivered).
7. **`/issue` & `/on_issue`**: ONDC Issue & Grievance Management (IGM Level 1) handling.

---

## ⚡ 4. Method 1: Instant Verification with Webhook.site & Curl (Zero Setup)

You can verify the entire ONDC discovery loop right now using **Webhook.site** (a free webhook listener) and `curl`.

### Step 1: Get a free callback URL
1. Open [webhook.site](https://webhook.site) in any browser.
2. Copy **"Your unique URL"** (e.g. `https://webhook.site/3b8f6c4a-1122-3344-5566-778899aabbcc`).  
   *(This URL acts as the mock Buyer App's `bap_uri`).*

### Step 2: Fire the Beckn `/search` request
Run this command in your terminal (replace `YOUR_WEBHOOK_URL` with your URL from Step 1):

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
      "timestamp": "2026-11-09T07:30:00.000Z",
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
1. **In Terminal**: You immediately receive a 200 OK synchronous ACK (< 200ms):
   ```json
   {
     "message": {
       "ack": {
         "status": "ACK"
       }
     }
   }
   ```
2. **On Webhook.site**: Within **1–2 seconds**, an incoming `POST /on_search` request appears with the full catalog payload!
   Inspect the JSON body:
   - **Provider**: `BazaarSetu Karigar Collective`
   - **Bilingual Content**: English title & description, plus Hindi Devanagari translation in `tags`
   - **Craft Attributes**: Materials, artisan cluster, artisan name
   - **Pricing**: Recommended fair price and 3-tier corridor
   - **Studio Image URL**: Public HTTPS URL ready for Buyer App presentation

---

## 🛠️ 5. Method 2: Testing with Official ONDC Workbench

### Step 1: Access the Workbench
- Log in to [workbench.ondc.org](https://workbench.ondc.org/) with your network participant credentials.

### Step 2: Configure Your BPP Profile
Under **Test Configurations / Network Participants**:
- **Role**: `Seller App (BPP)`
- **Domain**: `ONDC:RET12` (Fashion & Handloom)
- **Subscriber ID**: `bazaarsetu.bpp.org`
- **Subscriber URI**: `https://project-zerotype-bpp.onrender.com/beckn`
- **Signing Public Key**: Ed25519 public key generated by `python backend/generate_keys.py`.

### Step 3: Run the Test Suites
1. **Discovery Suite (`/search` $\rightarrow$ `/on_search`)**:
   - Click **Trigger Search**.
   - Workbench sends a test search to `https://project-zerotype-bpp.onrender.com/beckn/search`.
   - Workbench validates that the synchronous ACK returned within 1,000ms.
   - Workbench validates the `/on_search` callback:
     - `context.bpp_id` matches `bazaarsetu.bpp.org`.
     - Catalog contains valid `bpp/providers` and `items`.
     - Price currency is `INR` and values are valid decimals.
2. **Order Lifecycle Suites (`/select`, `/init`, `/confirm`)**:
   - BazaarSetu BPP returns automatic protocol ACKs, passing test harness compliance criteria.

---

## 📋 6. Catalog Field Mapping (`/on_search`)

When serving catalogs to the network, BazaarSetu formats the data to strictly pass the Workbench's `ONDC:RET12` validation schemas:

* **`bpp/providers`**: Identifies the artisan cluster (e.g., `Chanderi Handloom Collective`).
* **`items`**:
  * `id`: Unique craft SKU / `catalog_id`.
  * `descriptor.name`: Product title (`title_en`).
  * `descriptor.short_desc` / `long_desc`: Story-driven craft description.
  * `descriptor.images`: Array of public HTTPS CDN image URLs (AI studio and raw photos).
  * `category_id`: `ONDC:RET12` for fashion/textiles.
* **`price`**:
  * `currency`: `INR`.
  * `value`: Fair selling price (guaranteed $\ge$ statutory floor price $C_{\text{floor}}$).
  * `maximum_value`: Premium price corridor ceiling.
* **`quantity.available`**: Current inventory quantity (`available_qty`).
* **`tags` (Legal Metrology & Bilingual)**:
  * Manufacturer / Artisan details and cluster location.
  * Country of origin (`IND`).
  * Hindi translation tags for vernacular buyer apps.

---

## 🔍 7. Handy Inspection & Monitoring Endpoints

You can inspect the live state of your BPP directly in any browser:

| Endpoint | Method | Purpose |
| :--- | :--- | :--- |
| `https://project-zerotype-bpp.onrender.com/` | `GET` / `HEAD` | Health check & active listing counter (used by UptimeRobot) |
| `https://project-zerotype-bpp.onrender.com/health` | `GET` / `HEAD` | Dedicated 200 OK monitoring endpoint |
| `https://project-zerotype-bpp.onrender.com/docs` | `GET` | Interactive Swagger UI API documentation |
| `https://project-zerotype-bpp.onrender.com/api/v1/bpp/listings` | `GET` | Returns all active listings currently served on ONDC |
| `https://project-zerotype-bpp.onrender.com/api/v1/bpp/listings/{id}` | `GET` | Fetch specific listing payload |
| `https://project-zerotype-bpp.onrender.com/api/v1/bpp/listings/{id}/unlist` | `POST` | Revert listing to unlisted / draft status |
