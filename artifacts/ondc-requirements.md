# ONDC Beckn 1.2.0 Catalog Requirements: Fashion & Handicrafts (ONDC:RET12)

This document provides a strictly structured, comprehensive technical reference for the ONDC Beckn 1.2.0 schema, specifically tailored for the **KalaKriti Seller Node (BPP)**. 

ONDC categorizes catalog fields into **Mandatory Critical** (network/protocol routing), **Mandatory Informational** (statutory/legal compliance), and **Optional Enrichments**. Failing to provide correct JSON types or valid values for mandatory fields will result in a `NACK` (Validation Error) at the ONDC Gateway.

---

## 1. Mandatory Critical Attributes (Protocol Level)

These fields are strictly enforced by the Beckn protocol. If they are missing or incorrectly formatted, Buyer Apps (like Paytm, Mystore) will silently drop the item.

| JSON Path | Type | Description & Format | Valid Values / Example |
| :--- | :--- | :--- | :--- |
| `id` | `String` | Unique SKU identifier. No spaces. | `"item_chanderi_saree_001"` |
| `quantity.available.count` | `Integer` | Physical stock currently ready to sell. | `5`, `10`, `0` |
| `quantity.maximum.count` | `Integer` | Max quantity a single buyer can order at once. | `1`, `5` |
| `price.currency` | `String` | ISO 4217 Currency Code. | `"INR"` |
| `price.value` | `String` | **Selling Price** (Decimal string, not float). | `"2640.00"` |
| `price.maximum_value` | `String` | **MRP** (Maximum Retail Price). Must be $\ge$ `value`. | `"3168.00"` |
| `category_id` | `String` | Maps item to ONDC taxonomy. | `"ONDC:RET12"` (Fashion) |
| `fulfillment_id` | `String` | ID linking to `bpp/fulfillments` array (Shipping). | `"F1"`, `"delivery_01"` |
| `location_id` | `String` | ID linking to `bpp/locations` array (Workshop). | `"L1"`, `"chanderi_store"` |

### 1.1 Item Descriptors (`descriptor`)
Describes the physical product visually and textually.
*   **`descriptor.name`** (`String`): Product title (Max 80 chars). Ex: `"Handwoven Chanderi Saree"`
*   **`descriptor.images`** (`Array<String>`): Publicly accessible, high-resolution HTTPS URLs. Minimum 1 required, 3 recommended. Ex: `["https://cdn.kalakriti.in/img_1.jpg"]`

### 1.2 ONDC SLA Flags (`@ondc/org/...`)
These define the commercial terms of fulfillment and returns.

| JSON Path | Type | Valid Formats / Constraints | Example |
| :--- | :--- | :--- | :--- |
| `@ondc/org/returnable` | `Boolean` | Is the item eligible for returns? | `true`, `false` |
| `@ondc/org/cancellable` | `Boolean` | Can buyer cancel before dispatch? | `true`, `false` |
| `@ondc/org/available_on_cod` | `Boolean` | Can be purchased via Cash on Delivery? | `true`, `false` |
| `@ondc/org/seller_pickup_return`| `Boolean` | Does the seller arrange reverse pickup? | `true`, `false` |
| `@ondc/org/time_to_ship` | `String` | **ISO 8601 Duration.** Time taken to hand over to courier. | `"PT24H"` (24 hrs), `"PT48H"` (48 hrs), `"P3D"` (3 Days) |
| `@ondc/org/return_window` | `String` | **ISO 8601 Duration.** Mandatory if `returnable: true`. | `"P7D"` (7 days), `"P14D"` |
| `@ondc/org/contact_details_consumer_care` | `String` | Comma-separated: Name, Email, Phone. | `"Support, help@kalakriti.in, 9999999999"` |

---

## 2. Mandatory Informational Attributes (Statutory Compliance)

Under the **Legal Metrology (Packaged Commodities) Rules, 2011**, all e-commerce products in India must explicitly declare statutory information. In ONDC 1.2.0, this is passed either as an `@ondc/org/statutory_reqs_packaged_commodities` object or via the `tags` array.

### ONDC Statutory Object format:

```json
"@ondc/org/statutory_reqs_packaged_commodities": {
  "manufacturer_or_packer_name": "Ramesh Handlooms Pvt Ltd",
  "manufacturer_or_packer_address": "Weaver Colony, Chanderi, MP - 473446",
  "common_or_generic_name_of_commodity": "Saree",
  "net_quantity_or_measure_of_commodity_in_pkg": "1 unit",
  "month_year_of_manufacture_packing_import": "11/2026",
  "country_of_origin": "IND"
}
```
*Note: `country_of_origin` must strictly be a 3-letter ISO 3166-1 alpha-3 code (e.g., `IND` for India).*

---

## 3. Optional Attributes (Discovery & Conversion Boosters)

These fields are **not** strictly enforced by protocol validation, but leaving them out results in lower search rankings on buyer apps. They greatly enrich the buyer experience.

### 3.1 Extended Descriptors (`descriptor`)
*   **`descriptor.short_desc`** (`String`): Brief 1-2 line summary used in mobile search preview cards.
*   **`descriptor.long_desc`** (`String`): Extended artisanal story, historical background, and detailed styling copy (Markdown allowed).
*   **`descriptor.symbol`** (`String`): URL to the brand's logo or artisan's profile picture.
*   **`descriptor.audio`** (`String`): URL to an audio snippet. **Perfect for KalaKriti:** We can map the artisan's 15-second dialect voice narration here!
*   **`descriptor.3d_render`** (`String`): URL to a 3D model for AR viewing.

### 3.2 Variants & Customization (`parent_item_id`)
If an item has multiple colors or sizes, group them by assigning them the same `parent_item_id`.
*   **`parent_item_id`** (`String`): The ID of the overarching product (e.g., `"saree_group_01"`).

### 3.3 Optional `tags` Schemas (RET12 Enums & Measurements)
Buyer apps use these tags to power their filters (e.g., filtering by "Material" or calculating dynamic shipping rates based on dimensions).

| Tag Code | Purpose | Expected Key-Value Pairs |
| :--- | :--- | :--- |
| `physical_dimensions` | Calculates courier volumetric weight | `length`, `width`, `height`, `unit` (e.g., `cm`) |
| `item_weight` | Calculates standard shipping weight | `value`, `unit` (e.g., `gram` or `kg`) |
| `care_instructions` | Washing/Maintenance guidance | `instruction` (e.g., `"Dry Clean Only"`) |
| `trade_identifiers` | Barcodes / Global standards | `hsn_code`, `ean`, `upc` |

---

## 4. Extending via Beckn `tags` (KalaKriti Specifics)

We map our AI-extracted attributes into the ONDC `tags` array using standard `code` blocks.

```json
"tags": [
  {
    "code": "attribute",
    "list": [
      { "code": "brand", "value": "KalaKriti Artisans" },
      { "code": "material", "value": "Pure Silk, Gold Zari" },
      { "code": "pattern", "value": "Handwoven" }
    ]
  },
  {
    "code": "translation_hi",
    "list": [
      { "code": "name", "value": "हाथ से बुनी चंदेरी सिल्क साड़ी" },
      { "code": "long_desc", "value": "..." }
    ]
  }
]
```

---

## 5. Complete Valid JSON Payload Example (RET12)

This is a complete `item` object representing a single product in an ONDC `/on_search` payload, **including both mandatory fields and optional enrichments**.

```json
{
  "id": "item_chanderi_001",
  "parent_item_id": "chanderi_group_emerald",
  "category_id": "ONDC:RET12",
  "fulfillment_id": "F1",
  "location_id": "L1",
  "descriptor": {
    "name": "Handwoven Chanderi Silk Saree with Zari",
    "short_desc": "Authentic Chanderi silk saree woven by master artisans.",
    "long_desc": "This exquisite piece takes 5 days to weave on a traditional pit loom...",
    "images": [
      "https://cdn.kalakriti.in/images/chanderi_001_studio.jpg"
    ],
    "audio": "https://cdn.kalakriti.in/audio/artisan_story.mp3",
    "symbol": "https://cdn.kalakriti.in/brand/logo.png"
  },
  "quantity": {
    "available": {
      "count": 5
    },
    "maximum": {
      "count": 2
    }
  },
  "price": {
    "currency": "INR",
    "value": "4200.00",
    "maximum_value": "5000.00"
  },
  "@ondc/org/returnable": true,
  "@ondc/org/cancellable": true,
  "@ondc/org/return_window": "P7D",
  "@ondc/org/seller_pickup_return": true,
  "@ondc/org/time_to_ship": "PT48H",
  "@ondc/org/available_on_cod": true,
  "@ondc/org/contact_details_consumer_care": "KalaKriti Support, support@kalakriti.in, +91-9999999999",
  "@ondc/org/statutory_reqs_packaged_commodities": {
    "manufacturer_or_packer_name": "Ramesh Weavers",
    "manufacturer_or_packer_address": "Cluster Ward 4, Chanderi, MP 473446",
    "common_or_generic_name_of_commodity": "Saree",
    "net_quantity_or_measure_of_commodity_in_pkg": "1 unit",
    "month_year_of_manufacture_packing_import": "09/2026",
    "country_of_origin": "IND"
  },
  "tags": [
    {
      "code": "attribute",
      "list": [
        { "code": "brand", "value": "KalaKriti" },
        { "code": "color", "value": "Emerald Green" },
        { "code": "material", "value": "Silk, Zari" }
      ]
    },
    {
      "code": "translation_hi",
      "list": [
        { "code": "name", "value": "एमराल्ड ग्रीन चंदेरी सिल्क साड़ी" }
      ]
    },
    {
      "code": "physical_dimensions",
      "list": [
        { "code": "length", "value": "25" },
        { "code": "width", "value": "20" },
        { "code": "height", "value": "5" },
        { "code": "unit", "value": "cm" }
      ]
    },
    {
      "code": "item_weight",
      "list": [
        { "code": "value", "value": "450" },
        { "code": "unit", "value": "gram" }
      ]
    }
  ]
}
```
