# Environment

## Commands
- Install: `npm install`
- Dev: `npm run dev`
- Test: `npm test`
- Lint: `npm run lint`

## Ports
- app — 3000

## Env var names (no values)
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PUBLISHABLE_KEY`
- `DATABASE_URL`

## Known quirks
- Stripe CLI webhook signatures differ from live signatures in local dev
