# Goal

## Objective
Add Stripe Checkout integration to InvoicePro so users can pay invoices online, including webhook handling for payment success and failure.

## Constraints
- Node.js 18 + Express stack
- No storing raw card data (use Stripe Checkout hosted page)
- All monetary values in cents as integers
- Webhook endpoint must be idempotent

## Definition of done
- [ ] Checkout session creation API works
- [ ] Stripe webhook verifies signature and updates invoice status
- [ ] Payment success/failure pages render
- [ ] Tests pass for webhook handler
