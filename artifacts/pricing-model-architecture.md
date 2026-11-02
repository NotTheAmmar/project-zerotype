# BazaarSetu: Pricing Architecture & Tactile Corridor (Project ZeroType)

**BazaarSetu** (Project ZeroType) protects artisans from predatory pricing and distress selling while eliminating manual price entry through **Tactile Corridor Selection**.

---

## 1. Zero-Typing Tactile Corridor Interface

Rather than typing numerals on a mobile keyboard, the artisan interacts with 3 visual **Corridor Cards** and tactile delta nudges:

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   FLOOR PRICE   │  │   FAIR PRICE    │  │  PREMIUM PRICE  │
│      ₹200       │  │      ₹350       │  │      ₹500       │
│  Min Wage Floor │  │ Recommended D2C │  │  Export/Gifted  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
         ▲                    ▲
    [Selected]             [Tap to switch]
    
  [ - ₹50 ]   [ + ₹50 ]  <-- Tactile Nudges (Zero Typing)
  
  Stock: [ 1 ]  [ 2 ]  [ 5 ]  [ 10 ]  + / - Stepper
```

### Corridor Tiers:
1. **Floor Price ($P_{\text{floor}}$)**: Non-negotiable statutory wage floor calculated from material cost and labour days. Below this threshold, publishing is prevented to protect artisan livelihood.
2. **Fair Price ($P_{\text{fair}}$)**: The AI-recommended D2C selling price reflecting market equilibrium on ONDC buyer applications.
3. **Premium Price ($P_{\text{prem}}$)**: Recommended price ($1.20 \times - 1.40 \times$) for institutional, export, or festive packaging.

### Tactile Nudges:
- `[- ₹50]` and `[+ ₹50]` buttons allow artisans to adjust their target price without typing. The floor constraint ensures the price cannot drop below $P_{\text{floor}}$.

---

## 2. Mathematical Formulations

### Stage 1: Statutory Cost Floor ($C_{\text{floor}}$)
Actively calculated to guarantee basic remuneration:
$$C_{\text{floor}} = M_{\text{raw}} + (T_{\text{days}} \times W_{\text{statutory}} \times K_{\text{skill}}) + O_{\text{overhead}}$$

- $M_{\text{raw}}$: Stated material cost (clay, yarn, metal, wood, dyes).
- $T_{\text{days}}$: Production effort in artisan days.
- $W_{\text{statutory}}$: Central/State minimum wage for skilled crafts (₹450–₹600/day).
- $K_{\text{skill}}$: Skill multiplier (1.0 for basic craft, 1.25 for GI clusters, 1.5 for Master Weavers).
- $O_{\text{overhead}}$: 10% allowance for firing, packaging, and local transport.

### Stage 2: MRP & Buyer Discount Calculation
ONDC buyer applications (e.g. Paytm, Mystore, Magicpin) prioritize products showing clear consumer value. BazaarSetu automatically derives the Maximum Retail Price (MRP):
$$\text{MRP} = \text{round}(P_{\text{active}} \times 1.25)$$
$$\text{Discount \%} = \text{round}\left(\frac{\text{MRP} - P_{\text{active}}}{\text{MRP}} \times 100\right)$$
This yields a compliant, attractive listing with a 15–20% strike-through discount on ONDC buyer search grids.

---

## 3. Spoken Price & Quantity Extraction
When an artisan speaks their price or batch size (e.g., *"मैं इसे तीन सौ पचास में बेचूँगा और दस पीस तैयार हैं"*), the **Qwen** structuring model extracts:
- `fair_price`: `350`
- `available_quantity`: `10`

These values automatically populate the selected corridor tier and quantity pill upon entering the catalog screen.
