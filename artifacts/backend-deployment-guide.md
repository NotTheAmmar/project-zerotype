# 🚀 BazaarSetu Backend, Database & Media Deployment Guide

This guide provides direct, step-by-step instructions for deploying the **BazaarSetu Beckn Provider Platform (BPP) backend**, **Supabase PostgreSQL database**, **Supabase Storage (for craft images)**, and **UptimeRobot (for 24/7 always-on uptime)**.

---

## 📌 Architecture Overview

```
 ┌──────────────────────────────────────┐
 │          Flutter Mobile App          │
 │             (BazaarSetu)             │
 └──────────────────┬───────────────────┘
                    │
         ┌──────────┴──────────┐
         │ HTTP / JSON         │ Image Upload
         ▼                     ▼
 ┌──────────────────────────────────────┐        ┌─────────────────────────────┐
 │         FastAPI BPP Backend          │        │      Supabase Storage       │
 │       (Hosted 24/7 on Render)        │───────>│  Bucket: craft-images (CDN) │
 │  • /api/v1/bpp/publish               │        │  • Raw Camera Photos        │
 │  • /api/v1/bpp/upload-image          │        │  • AI Studio Images         │
 │  • /beckn/search, select, init       │        └──────────────┬──────────────┘
 └──────────────────┬───────────────────┘                       │
                    │                                           │ Public CDN URL
         ┌──────────┴──────────┐                                │
         ▼                     ▼                                ▼
 ┌──────────────────┐    ┌────────────────────────┐    ┌────────────────────────┐
 │ Supabase Postgres│    │ UptimeRobot (Free)     │    │ ONDC Buyer Apps / BAP  │
 │ (artisan_listings│    │ 5-Min HEAD Ping        │    │ (Paytm, Mystore, etc.) │
 │  & sellers table)│    │ (Prevents Spindown)    │    │ (Fetches Craft + Photo)│
 └──────────────────┘    └────────────────────────┘    └────────────────────────┘
```

---

## 1. 🗄️ Supabase: Database & Image Storage Setup

### Step 1: Create Supabase Project
1. Go to [supabase.com](https://supabase.com) and log in with GitHub (`NotTheAmmar`).
2. Click **New Project** $\rightarrow$ select your organization.
3. **Name**: `bazaarsetu-db`
4. **Database Password**: Set a strong password (save this).
5. **Region**: `Mumbai (ap-south-1)` or `Singapore (ap-southeast-1)` for lowest latency with India.
6. Click **Create new project** and wait 2 minutes for provisioning.

---

### Step 2: Get Database Connection URI (Connection Pooler for Render IPv4)

> [!IMPORTANT]
> **Why Connection Pooler?** Render free web services **do not support IPv6 routing**. Supabase's direct host (`db.[ref].supabase.co`) resolves to IPv6 on new projects and cannot be reached by Render. You **must use the Supabase Connection Pooler** (IPv4).

1. In Supabase Dashboard, go to **Project Settings** (gear icon) $\rightarrow$ **Database**.
2. Scroll to **Connection string** $\rightarrow$ select **Connection Pooler** (or select the **URI** tab under Connection Pooler).
3. **Mode**: Choose **Transaction (Port 6543)** or **Session (Port 5432)**.
4. Note that the username in the connection pooler is `postgres.[YOUR-PROJECT-REF]`, NOT just `postgres`.
5. Format your `DATABASE_URL` as:
   ```properties
   postgresql+asyncpg://postgres.[YOUR-PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
   ```
   *(e.g., if region is `ap-south-1`, host is `aws-0-ap-south-1.pooler.supabase.com:6543`)*

---

### Step 3: Configure Supabase Storage for Images
ONDC buyer apps mandate **public HTTPS image URLs** to display artisan crafts. We store both **raw camera photos** and **AI studio images** in Supabase Storage.

1. In Supabase Dashboard, click **Storage** in the left sidebar.
2. Click **New bucket**.
3. **Bucket Name**: `craft-images`
4. **Public bucket**: **Enable this toggle (ON)**.  
   *(Crucial: Public access allows ONDC buyer apps to display craft photos without requiring authentication tokens).*
5. Click **Save bucket**.

#### Image Storage Strategy:
- **Raw Camera Photos**: Stored at `craft-images/<catalog_id>_raw.jpg`. Preserves authentic reference photos, useful for dispute resolution and retraining vision models.
- **AI Studio Images**: Stored at `craft-images/<catalog_id>_studio.jpg`. Features cleaned backgrounds, professional studio lighting, and color balancing for high conversion on ONDC buyer apps.
- **Public CDN URL format**:
  ```
  https://[YOUR-PROJECT-REF].supabase.co/storage/v1/object/public/craft-images/<catalog_id>_studio.jpg
  ```

---

### Step 4: Get Supabase API Keys (for Backend Image Uploads)
1. Go to **Project Settings** $\rightarrow$ **API**.
2. Copy:
   - **Project URL**: `https://[YOUR-PROJECT-REF].supabase.co`
   - **Service Role Secret** (under Project API keys, or `anon` key if preferred).

---

### Step 5: Database Tables (Auto-Provisioned)
The FastAPI backend automatically provisions and migrates the database schema on boot. If you want to verify or run it manually in **SQL Editor**:

```sql
-- 1. Sellers Table (Ready for future artisan profiles & KYC)
CREATE TABLE IF NOT EXISTS sellers (
    seller_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    cluster_name TEXT,
    state TEXT,
    upi_vpa TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Main Artisan Listings Table
CREATE TABLE IF NOT EXISTS artisan_listings (
    catalog_id TEXT PRIMARY KEY,
    seller_id TEXT DEFAULT 'default_artisan',
    artisan_name TEXT NOT NULL,
    cluster_name TEXT,
    title_en TEXT NOT NULL,
    title_hi TEXT,
    description_en TEXT,
    description_hi TEXT,
    craft_category TEXT,
    category_id TEXT,
    dimensions TEXT,
    floor_price DOUBLE PRECISION,
    fair_price DOUBLE PRECISION,
    premium_price DOUBLE PRECISION,
    raw_image_url TEXT,
    studio_image_url TEXT,
    gallery_images JSONB DEFAULT '[]'::jsonb,
    available_qty INTEGER DEFAULT 1,
    status TEXT DEFAULT 'PUBLISHED',
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 2. ☁️ Render: Backend Web Service Setup

### Step 1: Create Web Service
1. Visit [render.com](https://render.com) and log in with GitHub (`NotTheAmmar`).
2. Click **New +** $\rightarrow$ **Web Service**.
3. Select **Build and deploy from a Git repository** $\rightarrow$ choose `NotTheAmmar/project-zerotype`.

### Step 2: Service Configuration
| Field | Value |
|---|---|
| **Name** | `project-zerotype-bpp` |
| **Region** | `Singapore (Southeast Asia)` |
| **Branch** | `main` |
| **Root Directory** | `backend` |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `uvicorn main:app --host 0.0.0.0 --port $PORT` |
| **Instance Type** | `Free` |

### Step 3: Environment Variables
Under the **Environment Variables** tab, configure the variables. You only need to provide the ones you want to override (built-in defaults handle the rest):

#### 🚨 Mandatory Variables for Render:
```properties
# 1. BPP Callback URI (Required so ONDC knows your live URL)
BPP_PUBLIC_URI=https://project-zerotype-bpp.onrender.com/beckn

# 2. Database Connection (MUST use IPv4 Pooler — direct db.[ref].supabase.co fails on Render)
DATABASE_URL=postgresql+asyncpg://postgres.[YOUR-PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
```

#### 🖼️ Image Storage Variables (Supabase Storage CDN):
```properties
# Only required if storing craft photos in Supabase Storage CDN (recommended for ONDC)
SUPABASE_URL=https://[YOUR-PROJECT-REF].supabase.co
SUPABASE_KEY=[YOUR-SUPABASE-SERVICE-ROLE-KEY]
SUPABASE_STORAGE_BUCKET=craft-images
```

#### 🔐 ONDC Registry & Signing (Optional / Defaults provided):
```properties
# Built-in defaults: bazaarsetu.bpp.org / key-1
# Leave signing keys blank for ONDC Workbench / mock testing.
BPP_SUBSCRIBER_ID=bazaarsetu.bpp.org
BPP_UK_ID=key-1
BPP_SIGNING_PRIVATE_KEY=
BPP_SIGNING_PUBLIC_KEY=
```

### Step 4: Configure Automated Deploy Hook & Build Trigger Scope
1. **Build Filter Scope**: Because **Root Directory** is set to `backend`, Render will **only** trigger a redeploy when files inside `backend/` are modified. Commits affecting solely client Flutter code (`lib/`, `test/`) or markdown documents do **not** trigger redundant backend rebuilds.
2. Go to your Render service **Settings** $\rightarrow$ scroll down to **Deploy Hook**.
3. Copy the URL (`https://api.render.com/deploy/srv-xxxx?key=yyyy`).
4. In GitHub repo `NotTheAmmar/project-zerotype` $\rightarrow$ **Settings** $\rightarrow$ **Secrets and variables** $\rightarrow$ **Actions**.
5. Add repository secret: `RENDER_DEPLOY_HOOK_URL` = `<your-render-deploy-hook-url>`.
6. Now, whenever you push changes to `backend/**`, Render automatically redeploys.

---

## 3. ⏱️ UptimeRobot: 24/7 Always-On Setup ($0)

Render's free tier spins down after 15 minutes of inactivity. Cold starts take 50–90 seconds, violating the ONDC 1-second ACK mandate. UptimeRobot pings the backend every 5 minutes to keep it permanently awake.

### Step 1: Create Monitor
1. Sign up / log in at [uptimerobot.com](https://uptimerobot.com) (free forever).
2. Click **+ Add New Monitor**.
3. Fill in:
   - **Monitor Type**: `HTTP(s)`
   - **Friendly Name**: `BazaarSetu Render BPP`
   - **URL (or IP)**: `https://project-zerotype-bpp.onrender.com/` (or `https://project-zerotype-bpp.onrender.com/health`)
   - **Monitoring Interval**: `Every 5 minutes`
   - **HTTP Method**: `HEAD` (or `GET`)
4. Click **Create Monitor**.

### Step 2: Verification
- UptimeRobot will send a `HEAD /` request every 5 minutes.
- FastAPI returns `200 OK`.
- Status shows green **Up (100%)**.
- **Result: Render never sleeps.**

---

## 4. 📱 Connecting the Flutter App

In your local `.env` file on your development machine:

```properties
USE_MOCK_DATA=false
BACKEND_URL=https://project-zerotype-bpp.onrender.com
BPP_BACKEND_URL=https://project-zerotype-bpp.onrender.com
```

### Complete End-to-End Publishing Flow:
1. Artisan photographs craft and speaks details in Hindi or regional language.
2. Flutter app calls `POST /api/v1/bpp/upload-image` to upload raw and studio photos to **Supabase Storage**.
3. Flutter app calls `POST /api/v1/bpp/publish` with the craft payload and public image URLs.
4. FastAPI backend inserts the listing into **Supabase `artisan_listings` table**.
5. When an ONDC buyer app searches for handicrafts (`/beckn/search`), BazaarSetu returns an instant ACK and responds with the full catalog and public CDN images via `/on_search`!

---

## 5. 📋 Production Architecture Checklist

| Component | Status | Purpose |
|---|---|---|
| **Catalog Store** | ✅ Live | Stores active craft listings in Supabase PostgreSQL |
| **Media CDN** | ✅ Live | Supabase Storage bucket `craft-images` hosting raw & studio photos |
| **FastAPI BPP Node** | ✅ Live | Hosted on Render with Ed25519 Beckn signatures |
| **24/7 Keep-Alive** | ✅ Live | UptimeRobot `HEAD /` pinging every 5 minutes |
| **Bilingual Retails** | ✅ Live | English titles & descriptions with Hindi Devanagari ONDC tags |
| **Seller Profiles** | 🔜 Phase 3 | `sellers` table schema ready; user profile UI will be added in app |
| **Order Processing** | 🔜 Phase 3 | `/beckn/confirm` atomic inventory decrement and logistics waybill generation |
