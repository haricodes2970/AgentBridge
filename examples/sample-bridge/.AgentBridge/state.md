# State

## Current focus
Implementing the Stripe webhook endpoint to mark invoices as paid.

## Files touched
- src/routes/payments.js
- src/controllers/webhookController.js
- src/models/Invoice.js
- test/webhook.test.js

## Tests run
- `npm test` — 34/42 passing, 8 failing (webhook tests not yet written)
- `npm run lint` — clean

## Blockers
- Stripe webhook signature verification failing in local dev (CLI vs real signatures)

## Activity log
- 2026-11-04T09:12Z — Created Checkout session route; returns session URL — success
- 2026-11-04T10:05Z — Added STRIPE_WEBHOOK_SECRET env var name to environment.md — success
- 2026-11-04T14:30Z — Drafted webhook controller skeleton; signature verification not yet implemented — in progress
- 2026-11-05T08:15Z — Updated Invoice model to add status enum and stripePaymentIntentId — success
- 2026-11-05T11:40Z — Ran `npm test`; 34/42 passing, webhook tests failing — recorded
- 2026-11-05T16:20Z — Documented webhook idempotency decision in decisions.md — success
