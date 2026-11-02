# 🚀 BazaarSetu Backend Free Deployment Guide

This guide details how to deploy the **BazaarSetu Beckn Provider Platform (BPP) backend** (`backend/`) on free cloud infrastructure with automatic CI/CD redeployments.

---

## 📌 Architecture Overview

```
┌─────────────────────────────────┐
│     Flutter Mobile App          │
│        (BazaarSetu)             │
└──────────────┬──────────────────┘
               │ HTTP / JSON
               ▼
┌─────────────────────────────────┐
│     FastAPI BPP Backend         │ ◄── Hosted Free (Render / Koyeb / HF)
│   • /api/v1/bpp/catalog         │
│   • /beckn/search, select, init │
└──────────────┬──────────────────┘
               │ Beckn Protocol / Ed25519 Signed
               ▼
┌─────────────────────────────────┐
│    ONDC Network / Buyer Apps    │
└─────────────────────────────────┘
```

The backend is built with **FastAPI**, **Uvicorn**, and **PyNaCl** (for Ed25519 Beckn cryptographic signatures). It is stateless and containerized, making it ideal for free container or Python PaaS hosting.

---

## 🥇 Recommended Option: Render (Free Web Service)

Render provides a 100% free web service tier with automated SSL certificates, custom domains, and native GitHub deploy hooks.

### Step 1: Sign Up
1. Visit [render.com](https://render.com) and sign in with your GitHub account (`NotTheAmmar`).

### Step 2: Create a New Web Service
1. In the Render Dashboard, click **New +** $\rightarrow$ **Web Service**.
2. Select **Build and deploy from a Git repository**.
3. Search and select `NotTheAmmar/project-zerotype`.

### Step 3: Configure Build & Start Settings
Fill in the service details:

| Configuration Field | Recommended Value |
|---|---|
| **Name** | `bazaarsetu-bpp` |
| **Region** | `Oregon (US West)` or `Singapore (Southeast Asia)` |
| **Branch** | `main` |
| **Root Directory** | `backend` |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `uvicorn main:app --host 0.0.0.0 --port $PORT` |
| **Instance Type** | `Free` (0.5 CPU, 512 MB RAM) |

> [!TIP]
> Alternatively, select **Docker** as the Runtime and leave Dockerfile Path as `Dockerfile` (Render will build directly from `backend/Dockerfile`).

### Step 4: Configure Environment Variables
Under the **Environment Variables** tab, add the following:

| Key | Value | Purpose |
|---|---|---|
| `BPP_SUBSCRIBER_ID` | `bazaarsetu-bpp.onrender.com` | Your unique ONDC subscriber identifier |
| `BPP_PUBLIC_URI` | `https://bazaarsetu-bpp.onrender.com` | Public base URL of the service |
| `BPP_COUNTRY` | `IND` | Country code |
| `BPP_CITY` | `std:080` | ONDC city code (std:080 = Bengaluru) |
| `BPP_SIGNING_PRIVATE_KEY` | *(Generate via `python backend/generate_keys.py`)* | Ed25519 private key for signing Beckn requests |
| `BPP_SIGNING_PUBLIC_KEY` | *(Generated public key)* | Ed25519 public key registered on ONDC registry |
| `BPP_ENCRYPTION_PRIVATE_KEY` | *(Generate via `python backend/generate_keys.py`)* | X25519 key for encrypted buyer payloads |
| `BPP_ENCRYPTION_PUBLIC_KEY` | *(Generated public key)* | X25519 public key |

*(If you haven't generated keys yet, run `python backend/generate_keys.py` locally and copy the printed Base64 strings).*

### Step 5: Deploy
Click **Create Web Service**. Render will clone the repository, install dependencies, and launch Uvicorn. Once active, your service URL will be:
`https://bazaarsetu-bpp.onrender.com`

Verify by visiting:
`https://bazaarsetu-bpp.onrender.com/` $\rightarrow$ should return `{"status":"ok","service":"BazaarSetu BPP",...}`.
`https://bazaarsetu-bpp.onrender.com/docs` $\rightarrow$ interactive Swagger documentation.

---

## 🔄 Connect Automatic CI/CD Redeployments

We have already configured `.github/workflows/backend-deploy.yml` in your repository. To connect it:

1. In Render, go to your service $\rightarrow$ **Settings** $\rightarrow$ scroll down to **Deploy Hook**.
2. Click **Create Deploy Hook** and copy the resulting URL (e.g. `https://api.render.com/deploy/srv-xxxx?key=yyyy`).
3. In your GitHub repository (`NotTheAmmar/project-zerotype`), go to:
   **Settings $\rightarrow$ Secrets and variables $\rightarrow$ Actions**.
4. Click **New repository secret**:
   - **Name:** `RENDER_DEPLOY_HOOK_URL`
   - **Secret:** *(Paste your Render Deploy Hook URL)*
5. Click **Add secret**.

🎉 **Done!** From now on, whenever any commit touching `backend/**` is merged into `main`, GitHub Actions will automatically call the deploy hook to update your live backend!

---

## 🥈 Alternative Free Platforms

### Option B: Koyeb (Free Nano Service)
- **URL:** [koyeb.com](https://www.koyeb.com/)
- **Features:** True micro-VMs, ultra-low latency, Docker native.
- **Setup:** Connect GitHub $\rightarrow$ Docker build $\rightarrow$ set Dockerfile to `backend/Dockerfile` $\rightarrow$ set environment variables $\rightarrow$ Deploy.

### Option C: Hugging Face Spaces (Free Docker 16GB RAM)
- If you expand the backend in the future to host heavy AI matting models (like **BiRefNet** for studio background removal) or local Speech-to-Text:
- Create a Space with the **Docker** SDK (Free tier provides 2 vCPUs and 16 GB RAM).
- Connect repository or push `backend/` as the Space root.

---

## 📱 Connect Live Backend to Flutter App

Once your backend is live, update your local `.env`:
```properties
# Backend Endpoints
BACKEND_URL=https://bazaarsetu-bpp.onrender.com
BPP_BACKEND_URL=https://bazaarsetu-bpp.onrender.com
USE_MOCK_DATA=false
```
Now the Flutter app will publish live catalog items straight to your cloud backend!
