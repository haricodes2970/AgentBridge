# Decisions

Append-only. Newest last.

## 2026-11-05 16:20 — Use Stripe Checkout instead of Elements
**Decision:** Use Stripe Checkout (hosted) rather than Stripe Elements (embedded) for the payment flow.
**Reason:** Faster to ship; PCI scope handled by Stripe; less frontend custom UI work.
**Alternatives rejected:** Stripe Elements (more PCI responsibility, more frontend build time).

## 2026-11-04 09:12 — Store amounts in cents as integers
**Decision:** All monetary values stored as integer cents, never floats.
**Reason:** Avoids floating-point rounding errors in financial calculations.
**Alternatives rejected:** Decimal type in JS (no native support, library overhead).
