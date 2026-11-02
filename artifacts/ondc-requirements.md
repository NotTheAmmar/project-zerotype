# ONDC Beckn 1.2.0 Catalog Requirements: Fashion & Handicrafts (ONDC:RET12 / RET16)

This document provides a strictly structured, comprehensive technical reference for the ONDC Beckn 1.2.0 schema, specifically tailored for **BazaarSetu (Project ZeroType) Seller Node (BPP)**. 

---

## 1. Zero-Typing via Automated Background Prefill

ONDC mandates strict statutory and protocol fields. Under the **Strict Modality Partitioning Architecture**, BazaarSetu eliminates manual form filling by auto-injecting verified merchant defaults:

| Required ONDC Attribute | Automated Value / Source |
| :--- | :--- |
| `country_of_origin` | `"IND"` (Default ISO 3166-1 alpha-3 for Indian artisans) |
| `@ondc/org/time_to_ship` | `"PT24H"` (Standard next-day handoff SLA) |
| `@ondc/org/return_window` | `"P7D"` (7 days standard return window) |
| `@ondc/org/returnable` | `true` |
| `@ondc/org/cancellable` | `true` |
| `@ondc/org/available_on_cod`| `true` |
| `@ondc/org/contact_details_consumer_care` | Artisan Guild Federation helpline |
| `currency` | `"INR"` |
| `maximum_value` (MRP) | Derived: `round(active_price * 1.25)` |

---

## 2. Dynamic Attribute Extraction via Qwen-2.5-32B

The remaining dynamic product attributes are extracted purely from the artisan's spoken voice and camera feed:

```json
{
  "title_en": "Handcrafted Terracotta Diya with Floral Etchings",
  "title_hi": "हाथ से बना नक्काशीदार मिट्टी का दीया",
  "category": "pottery",
  "materials": ["Terracotta Clay", "Natural Earth Pigments"],
  "dimensions": "12 x 12 x 6 cm",
  "care_instructions": "Handle with care, clean with dry cloth",
  "origin_cluster": "Pune Craft Cluster, Maharashtra",
  "fair_price": 350,
  "available_quantity": 5
}
```

---

## 3. Mandatory Protocol Attributes (Beckn Level)

| JSON Path | Type | Description | BazaarSetu Handling |
| :--- | :--- | :--- | :--- |
| `id` | `String` | Unique SKU identifier | Auto-generated UUID `item_<timestamp>` |
| `quantity.available.count` | `Integer` | Physical stock | Selected via Tactile Pills `[1][2][5][10]` or Stepper |
| `quantity.maximum.count` | `Integer` | Max order quantity | Defaults to `min(5, available.count)` |
| `price.currency` | `String` | Currency | `"INR"` |
| `price.value` | `String` | Selling price | Formatted from selected Fair-Price Corridor tier |
| `price.maximum_value` | `String` | MRP | 25% markup over selling price |
| `category_id` | `String` | ONDC taxonomy | Auto-mapped: `"ONDC:RET16"` (Crafts/Pottery) or `"ONDC:RET12"` (Apparel) |
| `fulfillment_id` | `String` | Fulfillment linkage | `"F1"` (Standard Delivery) |
| `location_id` | `String` | Location linkage | Linked to artisan's registered cluster |

---

## 4. Complete Valid Beckn Catalog JSON Example

```json
{
  "id": "item_terracotta_diya_001",
  "parent_item_id": "terracotta_diya_collection",
  "category_id": "ONDC:RET16",
  "fulfillment_id": "F1",
  "location_id": "L1",
  "descriptor": {
    "name": "Handcrafted Terracotta Diya with Floral Etchings",
    "short_desc": "Handmade clay diya by rural artisan guild.",
    "long_desc": "Molded from riverbed terracotta clay with hand-carved floral motifs, fired in traditional pit kilns.",
    "images": [
      "https://cdn.bazaarsetu.in/images/terracotta_diya_studio.jpg"
    ],
    "symbol": "https://cdn.bazaarsetu.in/guild/logo.png"
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
    "value": "350.00",
    "maximum_value": "440.00"
  },
  "@ondc/org/returnable": true,
  "@ondc/org/cancellable": true,
  "@ondc/org/return_window": "P7D",
  "@ondc/org/seller_pickup_return": true,
  "@ondc/org/time_to_ship": "PT24H",
  "@ondc/org/available_on_cod": true,
  "@ondc/org/contact_details_consumer_care": "BazaarSetu Guild Support, support@bazaarsetu.in, +91-9999999999",
  "@ondc/org/statutory_reqs_packaged_commodities": {
    "manufacturer_or_packer_name": "Gramin Karigar Samiti",
    "manufacturer_or_packer_address": "Kumbharwada, Pune, Maharashtra 411002",
    "common_or_generic_name_of_commodity": "Terracotta Diya",
    "net_quantity_or_measure_of_commodity_in_pkg": "1 unit",
    "month_year_of_manufacture_packing_import": "11/2026",
    "country_of_origin": "IND"
  },
  "tags": [
    {
      "code": "attribute",
      "list": [
        { "code": "brand", "value": "BazaarSetu Crafts" },
        { "code": "material", "value": "Terracotta Clay" },
        { "code": "technique", "value": "Hand-carved" }
      ]
    },
    {
      "code": "translation_hi",
      "list": [
        { "code": "name", "value": "हाथ से बना नक्काशीदार मिट्टी का दीया" }
      ]
    },
    {
      "code": "origin",
      "list": [
        { "code": "cluster", "value": "Pune Craft Cluster" }
      ]
    }
  ]
}
```
