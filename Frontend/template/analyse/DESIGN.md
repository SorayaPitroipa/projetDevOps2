---
name: L'Écosystème Wave
colors:
  surface: '#fff8f6'
  surface-dim: '#efd5ca'
  surface-bright: '#fff8f6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff1eb'
  surface-container: '#ffeae1'
  surface-container-high: '#fee3d8'
  surface-container-highest: '#f8ddd2'
  on-surface: '#261812'
  on-surface-variant: '#5a4136'
  inverse-surface: '#3d2d26'
  inverse-on-surface: '#ffede6'
  outline: '#8e7164'
  outline-variant: '#e2bfb0'
  surface-tint: '#a04100'
  primary: '#a04100'
  on-primary: '#ffffff'
  primary-container: '#ff6b00'
  on-primary-container: '#572000'
  inverse-primary: '#ffb693'
  secondary: '#5f5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e2dfde'
  on-secondary-container: '#636262'
  tertiary: '#0062a1'
  on-tertiary: '#ffffff'
  tertiary-container: '#059eff'
  on-tertiary-container: '#003357'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbcc'
  primary-fixed-dim: '#ffb693'
  on-primary-fixed: '#351000'
  on-primary-fixed-variant: '#7a3000'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474746'
  tertiary-fixed: '#d0e4ff'
  tertiary-fixed-dim: '#9ccaff'
  on-tertiary-fixed: '#001d35'
  on-tertiary-fixed-variant: '#00497b'
  background: '#fff8f6'
  on-background: '#261812'
  surface-variant: '#f8ddd2'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  container-max: 1200px
  gutter: 24px
---

## Brand & Style

The design system for this financial platform is built on the pillars of **clarity, authority, and modern professionalism**. Designed specifically for the French fintech market, it avoids the cold, clinical feel of traditional banking in favor of a "Corporate Modern" aesthetic that feels accessible yet secure.

The visual language focuses on high readability and a structured information hierarchy, ensuring users can interpret complex financial data (credit scores, debt ratios, and history) at a glance. The user experience should evoke a sense of financial empowerment and transparency, moving away from the anxiety usually associated with credit reporting.

**Design Principles:**
- **Clarity First:** No unnecessary decorative elements. Every line and shade serves a functional purpose.
- **Trusted Momentum:** The use of "Wave Orange" provides an energetic, forward-moving feel, balanced by stable, neutral grays.
- **Precision:** Tight alignment and consistent spacing to reflect the accuracy of financial calculations.

## Colors

The palette is anchored by **Wave Orange**, used strategically for primary actions and brand presence. The interface relies heavily on a clean, light-gray background (`#F9F9F9`) to allow white cards to pop with subtle depth.

**Status Palette:**
- **Excellent (#10B981):** A vibrant emerald green used for high credit scores and positive financial indicators.
- **Bon (#F59E0B):** A warm amber for stable, mid-range scores.
- **À améliorer (#EF4444):** A clear, urgent red for high-risk indicators or low scores.

**Functional Grays:**
- **Primary Text (#1A1A1A):** High-contrast black for headlines and core data points.
- **Muted Text (#6B7280):** A soft gray for labels, helper text, and secondary metadata.

## Typography

This design system utilizes **Inter** for all roles. Inter provides the necessary neutrality and high legibility required for data-dense financial applications.

**Usage Guidelines:**
- **Numerical Data:** For credit scores, use `display-lg` with medium or bold weights to ensure the score is the most prominent element on the page.
- **Labels:** Use `label-md` for small captions or section headers in uppercase to create clear structural breaks.
- **Hierarchy:** Maintain a clear distinction between `title-lg` (card titles) and `body-md` (descriptive text).

## Layout & Spacing

The layout follows a **Fixed Grid** philosophy for the desktop experience to maintain a professional, organized dashboard feel. The content is centered within a 1200px container.

- **Grid System:** A 12-column grid with 24px gutters.
- **Vertical Rhythm:** Built on a 4px baseline. Most components use `16px` (md) or `24px` (lg) padding to ensure the UI feels "airy" and professional.
- **Card Spacing:** Use `32px` (xl) spacing between major dashboard widgets to provide clear visual separation between different financial data sets.

## Elevation & Depth

To convey a sense of security and modern "Fintech" polish, the design system uses a combination of **low-contrast outlines** and **ambient shadows**.

- **Level 0 (Background):** `#F9F9F9` - The canvas.
- **Level 1 (Cards):** `#FFFFFF` surface with a 1px solid border in `#E5E7EB` and a very soft, diffused shadow: `0px 4px 6px -1px rgba(0, 0, 0, 0.05)`.
- **Level 2 (Dropdowns/Modals):** High-elevation shadows to indicate temporary interaction: `0px 10px 15px -3px rgba(0, 0, 0, 0.1)`.

Surfaces should feel flat and structural, avoiding heavy gradients or skeuomorphism.

## Shapes

The design system employs a "Soft Geometric" approach to shapes.

- **Cards:** Use a `12px` radius to soften the dashboard and make the data feel approachable.
- **Interactive Elements:** Buttons and input fields use an `8px` radius, providing a crisp, professional look that distinguishes them from the larger layout containers.
- **Status Badges:** Use a smaller `4px` radius or a full pill shape to differentiate them from functional buttons.

## Components

**Buttons (Boutons)**
- **Primary:** Background `#FF6B00`, Text `#FFFFFF`, 8px radius.
- **Secondary:** Background transparent, Border 1px `#FF6B00`, Text `#FF6B00`.
- **Iconography:** Use Tabler Icons (outline style) at 20px size within buttons, positioned 8px from the text.

**Status Badges (Badges de Statut)**
- **Excellent:** Background `rgba(16, 185, 129, 0.1)`, Text `#10B981`.
- **Bon:** Background `rgba(245, 158, 11, 0.1)`, Text `#F59E0B`.
- **À améliorer:** Background `rgba(239, 68, 68, 0.1)`, Text `#EF4444`.

**Cards (Cartes)**
- All data containers must use the 12px radius, white background, and the Level 1 shadow/border combination.
- Inner padding should be consistently `24px`.

**Input Fields (Champs de saisie)**
- Border: 1px `#D1D5DB`.
- Active State: Border 1px `#FF6B00` with a 2px outer glow of `rgba(255, 107, 0, 0.2)`.

**Icons (Icônes)**
- Use **Tabler Icons** with a stroke width of `1.5px` or `2px`. Icons should typically be `#6B7280` when used in navigation or labels, and `#FF6B00` when highlighting key features.