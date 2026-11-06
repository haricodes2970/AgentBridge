#!/usr/bin/env bash
set -euo pipefail

SCRATCH="/tmp/agentbridge-dogfood"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== AgentBridge dogfood setup ==="
echo "Scratch project: $SCRATCH"

# Idempotent: wipe and rebuild the scratch project on every run.
if [[ -d "$SCRATCH" ]]; then
  rm -rf "$SCRATCH"
fi
mkdir -p "$SCRATCH/src" "$SCRATCH/lib" "$SCRATCH/tests"
cd "$SCRATCH"
git init -q -b main

cat > package.json <<'PKGJSON'
{
  "name": "dogfood-invoice",
  "version": "1.0.0",
  "description": "Processes invoices and calculates tax totals",
  "main": "src/index.js",
  "scripts": {
    "test": "node tests/run-tests.js",
    "lint": "echo 'lint placeholder'"
  },
  "dependencies": {}
}
PKGJSON

cat > README.md <<'README'
# Dogfood Invoice Processor

Processes invoices and calculates tax totals.

## Structure
- `src/` - application entry point and business logic
- `lib/` - parsing, serialization, and config helpers
- `tests/` - test suite

## Usage
```
node src/index.js
```
README

cat > src/index.js <<'SRC'
const { calculateTotal } = require('./utils');
const { validateInvoice } = require('./validator');
const { parseInvoice } = require('./lib/parser');

const raw = '{"amount": 100, "taxRate": 0.08}';
const invoice = parseInvoice(raw);

if (validateInvoice(invoice)) {
  const total = calculateTotal(invoice.amount, invoice.taxRate);
  console.log(\`Total: \${total}\`);
} else {
  console.log('Invalid invoice');
}
SRC

cat > src/utils.js <<'SRC'
function calculateTotal(amount, taxRate) {
  return amount + amount * taxRate;
}

module.exports = { calculateTotal };
SRC

cat > src/validator.js <<'SRC'
function validateInvoice(invoice) {
  return invoice && typeof invoice.amount === 'number' && invoice.amount > 0;
}

module.exports = { validateInvoice };
SRC

cat > src/formatter.js <<'SRC'
function formatCurrency(value) {
  return value.toFixed(2);
}

module.exports = { formatCurrency };
SRC


cat > lib/parser.js <<'SRC'
function parseInvoice(raw) {
  try {
    return JSON.parse(raw);
  } catch (e) {
    return null;
  }
}

function serializeInvoice(invoice) {
  return JSON.stringify(invoice);
}

module.exports = { parseInvoice, serializeInvoice };
SRC

cat > lib/serializer.js <<'SRC'
function serialize(data) {
  return JSON.stringify(data, null, 2);
}

module.exports = { serialize };
SRC

cat > lib/config.js <<'SRC'
const defaults = require('./defaults');

function getConfig(key) {
  return defaults[key];
}

module.exports = { getConfig };
SRC

cat > lib/defaults.json <<'JSON'
{
  "taxRate": 0.08,
  "currency": "USD",
  "rounding": 2
}
JSON

cat > lib/tax-calculator.js <<'SRC'
function calculateTax(amount, rate) {
  // Bug: subtraction instead of multiplication.
  // Returns 92 for a $100 invoice at 8% instead of the correct 8.
  return amount - amount * rate;
}

module.exports = { calculateTax };
SRC

cat > tests/test-utils.js <<'SRC'
const { calculateTotal } = require('../src/utils');

function run() {
  const result = calculateTotal(100, 0.08);
  const expected = 108;
  if (result !== expected) {
    console.log(\`FAIL: calculateTotal(100, 0.08) = \${result}, expected \${expected}\`);
    return false;
  }
  console.log('PASS: test-utils');
  return true;
}

module.exports = { run };
SRC

cat > tests/test-validator.js <<'SRC'
const { validateInvoice } = require('../src/validator');

function run() {
  const valid = validateInvoice({ amount: 100, taxRate: 0.08 });
  const invalid = validateInvoice({ amount: 0, taxRate: 0.08 });
  if (valid && !invalid) {
    console.log('PASS: test-validator');
    return true;
  }
  console.log('FAIL: test-validator');
  return false;
}

module.exports = { run };
SRC

cat > tests/test-parser.js <<'SRC'
const { parseInvoice } = require('../lib/parser');

function run() {
  const result = parseInvoice('{"amount": 50, "taxRate": 0.1}');
  if (result && result.amount === 50) {
    console.log('PASS: test-parser');
    return true;
  }
  console.log('FAIL: test-parser');
  return false;
}

module.exports = { run };
SRC

cat > tests/run-tests.js <<'SRC'
const { run: runUtils } = require('./test-utils');
const { run: runValidator } = require('./test-validator');
const { run: runParser } = require('./test-parser');

let allPass = true;
if (!runUtils()) allPass = false;
if (!runValidator()) allPass = false;
if (!runParser()) allPass = false;

process.exit(allPass ? 0 : 1);
SRC


# Commit the scratch project so it has a clean baseline.
git add -A
git -c user.email='dogfood@example.com' -c user.name='dogfood' commit -q -m "chore: create dogfood scratch project with deliberate tax bug"

echo ""
BUG_LOCATION="lib/tax-calculator.js line 4: return amount - amount * rate (should be amount * rate)"
echo "BUG LOCATION (for the human): $BUG_LOCATION"
echo "(This is printed to stdout only — it is NOT written inside the project.)"
echo ""

# Install AgentBridge from the pinned v0.2.0 release.
echo "=== Installing AgentBridge (v0.2.0) ==="
curl -fsSL https://raw.githubusercontent.com/haricodes2970/AgentBridge/v0.2.0/install.sh | bash -s -- --platform auto --project "$SCRATCH"

# Seed a realistic bridge.
BRIDGE="$SCRATCH/.AgentBridge"

cat > "$BRIDGE/goal.md" <<'GOAL'
# Goal

## Objective
Fix the tax calculation bug in lib/tax-calculator.js where calculateTax uses subtraction instead of multiplication, causing it to return 92 instead of 8 for a $100 invoice at 8% tax.

## Constraints
- Node.js project, no external dependencies
- All tests must pass after fix
- Tax should be amount * rate (not amount - amount * rate)

## Definition of done
- [ ] calculateTax(100, 0.08) returns 8
- [ ] calculateTax(200, 0.10) returns 20
- [ ] All existing tests pass
- [ ] Bug documented in decisions.md
GOAL

cat > "$BRIDGE/next.md" <<'NEXT'
# Next action

## Do this next
Fix the tax calculation bug in lib/tax-calculator.js

## Open questions
- Should we add a test for tax-calculator? (developer to decide)
NEXT

cat > "$BRIDGE/state.md" <<'STATE'
# State

## Current focus
Investigating tax calculation discrepancy in lib/tax-calculator.js

## Files touched
- lib/tax-calculator.js

## Tests run
- `node tests/run-tests.js` — all pass (but tax-calculator not covered by tests)

## Blockers
- None

## Activity log
- 2026-11-06T13:00Z — Identified bug: calculateTax uses subtraction instead of multiplication
- 2026-11-06T13:01Z — Wrote bridge files (goal, next, state, decisions)
- 2026-11-06T13:02Z — Preparing to fix lib/tax-calculator.js
STATE

cat > "$BRIDGE/decisions.md" <<'DECISIONS'
# Decisions

Append-only. Newest last.

## 2026-11-06 13:00 — Fix tax-calculator formula
**Decision:** Change `amount - amount * rate` to `amount * rate` in lib/tax-calculator.js
**Reason:** The subtraction produces 92 for a $100 invoice at 8% instead of the correct 8
**Alternatives considered:** None — formula is clearly wrong
DECISIONS

cat > "$BRIDGE/code-map.md" <<'CODEMAP'
# Code map

Hand-maintained. Not auto-generated. Update when structure changes.

## Entry points
- src/index.js — application entry point, parses invoice and prints total

## Key modules
- lib/tax-calculator.js — computes tax from amount and rate (contains the bug)
- src/utils.js — calculates total including tax
- src/validator.js — validates invoice before processing

## Where things live
- tax calculation → lib/tax-calculator.js
- total calculation → src/utils.js
- invoice validation → src/validator.js
- invoice parsing → lib/parser.js
CODEMAP

# Run checkpoint once to create the session file and INDEX row.
AGENT_NAME=dogfood bash "$REPO_ROOT/scripts/checkpoint.sh" "$SCRATCH"

echo ""
echo "Setup complete. Follow docs/CROSS-AGENT-TEST.md."
