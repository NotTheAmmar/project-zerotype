# 🛍️ BazaarSetu

### From a simple photo to a digital storefront.

**Bas photo kheencho, bol kar batao, aur apne product ko online bechne ke liye taiyaar karo.**

BazaarSetu is a voice-first mobile application designed to help **artisans, small businesses, and local sellers** transform their physical products into digital catalogs without complicated forms, lengthy typing, or advanced technical skills.

📸 Capture a product.  
🎙️ Describe it in your own words.  
✨ Build a catalog.  
🛒 Take the first step toward online selling.

[🚀 Explore the Project](https://github.com/NotTheAmmar/project-zerotype) · [🐛 Report an Issue](https://github.com/NotTheAmmar/project-zerotype/issues)

---

## 🌟 The Idea Behind BazaarSetu

Selling online should not require a laptop, professional photography skills, or the ability to write perfect product descriptions.

Yet many small sellers face exactly these barriers when trying to bring their products online.

BazaarSetu aims to bridge that gap with a simpler, more accessible experience built around something sellers already know how to do: **show their product and talk about it.**

Our goal is to make digital catalog creation easier, especially for sellers who are more comfortable speaking than typing.

> **Less typing. Less complexity. More opportunities to sell.**

---

## ⚡ How BazaarSetu Works

The experience is designed around a straightforward workflow.

### 01 — 📸 Capture

Take a picture of a product using your phone or choose an existing image from your gallery.

### 02 — 🎙️ Describe

Record a voice note explaining the product, its materials, features, or other important details.

### 03 — 🧠 Process

The catalog workflow brings together product information, image handling, and pricing-related features. Mock data is available for demonstrating the workflow.

### 04 — 🏷️ Review

Review the catalog information and pricing suggestions, and save the listing locally.

### 05 — 🛒 Prepare to Sell

Use the publishing flow intended to connect product catalogs with an ONDC-compatible backend. Actual marketplace publication depends on a configured and tested integration.

---

## ✨ What Makes BazaarSetu Different?

| Feature | What it does |
|---|---|
| 📷 Product Capture | Capture photos or select images from your gallery. |
| 🎤 Voice-First Input | Record product descriptions instead of relying entirely on typing. |
| 🗣️ Spoken Readback | Audio playback and Hindi text-to-speech support. |
| 🖼️ Image Quality Checks | Basic checks for blur and low brightness. |
| 🏷️ Digital Catalogs | Organize product details, descriptions, images, and attributes. |
| 💰 Pricing Support | Represent floor, fair, and premium price points in the catalog workflow. |
| 💾 Local Storage | Save catalog information on the device. |
| 🌐 Publishing Workflow | Prepare catalog data for submission to a configured backend. |
| 🧪 Demo Mode | Use mock data to demonstrate parts of the experience without every live service being available. |

**Our design principle:** make the process easier for the seller, not more complicated.

---

## 🎯 Who Is BazaarSetu For?

🧵 **Artisans and Craft Makers**  
Give handmade products a clearer path toward digital discovery.

🏪 **Small Business Owners**  
Create product catalogs without having to write every detail manually.

🏡 **Home-Based Sellers**  
Organize product listings using a phone-first workflow.

🌱 **First-Time Digital Sellers**  
Reduce the initial learning curve of preparing products for online selling.

BazaarSetu is designed to support small businesses broadly, rather than limiting the idea to a single craft or product category.

---

## 🛠️ Built With

BazaarSetu is built as a Flutter mobile application with separate layers for screens, application state, models, and services.

| Technology | Purpose |
|---|---|
| Flutter & Dart | Mobile application |
| Provider | State management |
| Camera & Image Picker | Product image capture |
| Record & AudioPlayers | Audio recording and playback |
| Flutter TTS | Spoken text readback |
| HTTP | Backend communication |
| Shared Preferences | Local preferences and storage support |
| Path Provider | Device file access |
| Flutter Dotenv | Environment configuration |
| Google Fonts | Typography |

---

## 🏗️ Under the Hood

The application separates its main responsibilities into dedicated directories.

```text
lib/
├── main.dart
├── app.dart
├── config/
├── controllers/
├── models/
├── services/
├── views/
│   ├── screens/
│   └── widgets/
├── utils/
└── data/
```

- **Controllers** coordinate app state and catalog workflows.
- **Models** represent catalog information and pricing data.
- **Services** handle API requests, image operations, audio, and storage.
- **Views** contain screens and reusable interface components.
- **Data** supports sample and mock catalog scenarios.

This structure helps keep the interface separate from the logic that powers the app.

---

## 🚧 Project Status

BazaarSetu is a **prototype in active development**. Some functionality is implemented in the mobile app, while other workflows depend on mock data or external services.

| Component | Current status |
|---|---|
| Flutter mobile interface | Implemented |
| Camera and gallery workflow | Implemented in app code |
| Audio recording and playback | Implemented in app code |
| Hindi text-to-speech support | Available in app code |
| Basic image-quality checks | Implemented in app code |
| Catalog processing | Mock-data support and API integration path |
| Studio-style image processing | Basic simulation; production background removal needs further integration |
| Local catalog persistence | Storage service available |
| Pricing suggestions | Pricing models and workflow; recommendation quality requires validation |
| ONDC publishing | Backend request flow; end-to-end marketplace connectivity requires verification |

The presence of an interface or API request does not, by itself, establish that an external integration works end to end.

We aim to make BazaarSetu useful in practice, so testing, integration, and reliability remain important parts of development.

---

## 🗺️ What's Next?

Our development roadmap includes:

- [ ] Complete and validate live catalog generation.
- [ ] Integrate and test reliable product-background removal.
- [ ] Expand language and regional-language support.
- [ ] Validate pricing suggestions against real product costs and market data.
- [ ] Test the publishing workflow with a properly configured ONDC-compatible backend.
- [ ] Improve offline behavior and error handling.
- [ ] Add automated tests and improve reliability.
- [ ] Publish screenshots and a working demonstration of the app.

---

## 🚀 Run BazaarSetu Locally

Want to explore the code or contribute?

### Prerequisites

- Flutter SDK
- Compatible Dart SDK
- Android Studio or another Flutter development environment
- Android device or emulator

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/NotTheAmmar/project-zerotype.git
cd project-zerotype
```

**2. Install dependencies**

```bash
flutter pub get
```

**3. Check configuration**

Review `lib/config/constants.dart` and the API service to understand the required environment variables and backend configuration. If a `.env` file is required, create one using the variable names expected by the code.

Never commit API keys, passwords, or other secrets.

**4. Run the application**

```bash
flutter run
```

**5. Check the code**

```bash
flutter analyze
```

Live API functionality may require a separately running backend and valid configuration. Mock mode can be useful for exploring supported demo flows.

---

## 🤝 Contributing

We welcome practical improvements, bug reports, and ideas that make digital selling more accessible.

1. Explore the existing code before making changes.
2. Describe the problem your contribution addresses.
3. Keep changes focused and explain how you tested them.
4. Never commit secrets, personal data, or unnecessary build files.
5. Update documentation when behavior or setup instructions change.

Found something that could work better? [Open an issue on GitHub](https://github.com/NotTheAmmar/project-zerotype/issues).

---

## 📄 License

Check the repository for a `LICENSE` file before reusing or redistributing this code. If no license is present, the project's reuse terms need to be clarified by its owners.

---

## 💚 The Vision

We believe a small seller should not need to become a photographer, copywriter, or technology expert just to start selling online.

**BazaarSetu is being built to make that first step simpler.**

From a product on a table to a catalog on a phone, the goal is to help more local businesses participate in the digital economy.

### 📸 One product. One voice note. A simpler start to selling online.

**Built with the vision of making digital commerce more accessible to India's small businesses.**

[⭐ Explore BazaarSetu on GitHub](https://github.com/NotTheAmmar/project-zerotype)
