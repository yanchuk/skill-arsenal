# Report Templates

Output file templates for each stage of consumer goods research. Use these exact structures for consistency across all research sessions.

---

## Per-Category Verification File

**Filename:** `verify-{category}.md`

```markdown
# {Category} — Verification Report ({date})

**Task:** Verify availability for {N} {category} items
**Agent:** {model name}
**Geo:** {country}, {currency}

---

## Tool Usage Log

| # | URL/Query | Tool Used | Tier | Result | Notes |
|---|-----------|-----------|------|--------|-------|
| 1 | {store} search "{item}" | jina search | 1 | SUCCESS | Found 3 listings |
| 2 | {store url} | jina read_url | 1 | FAILED | Cookie wall |
| 3 | {store url} | scrapingbee | 4 | SUCCESS | JS rendered |

---

## Item Verification Results

### Item 1: {Brand} {Model}

| Source | URL | Tool | {Size1}? | {Size2}? | Price | Stock | Variants Checked |
|--------|-----|------|----------|----------|-------|-------|------------------|
| {store1} ({variant}) | https://... | firecrawl | NO | NO | 300 zł | OOS | {color1} |
| {store1} ({variant2}) | https://... | firecrawl | YES | NO | 300 zł | In stock | {color2} |
| {store2} | https://... | jina | YES | YES | €130 | In stock | {color3} |
| {marketplace} | https://... | scrapingbee | YES | YES | 350 zł | Available | {color4} |
| {aggregator} | https://... | jina | YES | YES | from 280 zł | 5 shops | — |

**VERDICT: AVAILABLE {sizes}** — Best: {store} {price}
OR
**VERDICT: NOT AVAILABLE {sizes}** — Checked {N} sources, {N} variants. All OOS.
OR
**VERDICT: UNVERIFIED** — {reason}, manual check needed at [{URL}]

---

[Repeat for each item]

---

## Backlog (interesting items found during search)

| Item | Store | Price | URL | Notes |
|------|-------|-------|-----|-------|
| {alt item} | {store} | {price} | https://... | Found during search for {original item} |

---

## Summary Table

| # | Item | {Size1}? | {Size2}? | Best Price | Store | Link | Confidence |
|---|------|----------|----------|-----------|-------|------|------------|
| 1 | {Brand} {Model} | YES | YES | {price} | {store} | [link] | HIGH |
| 2 | {Brand} {Model} | NO | NO | — | — | — | HIGH (OOS) |
| 3 | {Brand} {Model} | ? | ? | — | — | [link] | LOW |

---

## Credit Usage

| Tool | Credits Used | Budget | Remaining |
|------|-------------|--------|-----------|
| Firecrawl | {n} | {budget} | {remaining} |
| ScrapingBee | {n} | {budget} | {remaining} |
| Jina | free tier | 10M tokens | monitor usage |
| Tavily | free tier | limited | monitor usage |
| WebSearch | free | unlimited | — |
| WebFetch | free | unlimited | — |

---

## Key Notes

1. {Notable finding about store/brand behavior}
2. {Size system notes for brands with non-standard sizing}
3. {Stock pattern observations}
```

---

## BEST-PICKS.md

**Filename:** `BEST-PICKS.md`

```markdown
# Best 2-3 Value Picks Per Category — {Season/Date}
*Updated {date} after verification*

## {Category 1}
1. **{Brand} {Model}** — {price} [{store}]({url}) | {sizes} VERIFIED
2. **{Brand} {Model}** — {price} [{store}]({url}) | {sizes} VERIFIED
3. **{Brand} {Model}** — {price} [{store}]({url}) | {sizes} VERIFIED

~~{N}. {Brand} {Model} — SOLD OUT / PRICE INCREASED~~

## {Category 2}
[Same format]

---

## Promo Codes (VERIFIED {date})

| Code | Store | Discount | Status |
|------|-------|----------|--------|
| {CODE} | {store} | {discount} | CONFIRMED ACTIVE |
| {CODE} | {store} | {discount} | EXPIRED |
| Newsletter signup | {store} | {discount} | Always active |

---

## Verification Notes

- **{N} of {total} items confirmed available** ({rate}% availability)
- **{Category} hardest hit**: {reason}
- **{Category} best availability**: {reason}
- **Major price changes**: {item} {change}
- **Best overall retailer**: {store} — {reason}
- Full verification data: see `verify-*.md` files and `verify-SUMMARY.md`
```

---

## verify-SUMMARY.md

**Filename:** `verify-SUMMARY.md`

```markdown
# Verification Summary
*Date: {date}*
*Method: {description of verification method}*

---

## Cross-Category Results

| Category | Total Items | Available | Partial | Not Available | Availability Rate |
|----------|:-----------:|:---------:|:-------:|:-------------:|:-----------------:|
| {Cat1} | {n} | {n} | {n} | {n} | {pct}% |
| {Cat2} | {n} | {n} | {n} | {n} | {pct}% |
| **TOTAL** | **{n}** | **{n}** | **{n}** | **{n}** | **{pct}%** |

---

## Items NOT AVAILABLE (removed)

| Category | Item | Reason | Last Known Price |
|----------|------|--------|-----------------|
| {Cat} | {Brand} {Model} | {OOS reason} | {price} |

## Items PARTIALLY Available

| Category | Item | {Size1} | {Size2} | Best Source | Price |
|----------|------|---------|---------|-------------|-------|
| {Cat} | {Brand} {Model} | NO | YES | {store} | {price} |

---

## Price Changes Detected

| Item | Research Price | Verified Price | Change | Store |
|------|--------------|----------------|--------|-------|
| {item} | {old price} | {new price} | {+/-pct}% | {store} |

---

## Confirmed Best Sources

### {Category 1}
| Item | Source | Price | Sizes |
|------|--------|-------|-------|
| {Brand} {Model} | {store} | {price} | {sizes} |

[Repeat per category]

---

## Credit Usage

| Agent/Phase | Firecrawl | ScrapingBee | Free MCP (Jina/Tavily) | Built-in (WebSearch/WebFetch) |
|-------------|-----------|-------------|------------------------|-------------------------------|
| {agent/phase} | {n} | {n} | {n} | {n} |
| **TOTAL** | **{n} / {max}** | **{n} / {max}** | **{n} (free tier)** | Unlimited |

Budget utilization: {pct}% Firecrawl, {pct}% ScrapingBee.

---

## Key Insights

1. {Insight about category availability patterns}
2. {Insight about retailer reliability}
3. {Insight about deal expiration / price volatility}
4. {Insight about tool effectiveness}
5. {Insight about geo-specific patterns}
```

---

## FINAL-REPORT.md

**Filename:** `FINAL-REPORT.md`

```markdown
# Consumer Goods Research Report — {Domain}
*Date: {date}*
*Geo: {country} | Currency: {currency} | Budget: {range}*

## Executive Summary

{2-3 sentence overview: how many items researched, availability rate, key findings}

## Requirements

{Copy from requirements.md or summarize key parameters}

## Research Methodology

- **Sources consulted:** {list of review sites and stores}
- **Verification method:** {tool levels used, team vs sequential}
- **Items researched:** {total} across {N} categories

## Results by Category

### {Category 1}
{Summary table from verify-{category}.md}

[Repeat per category]

## Recommendations

### Top Picks
{Condensed version of BEST-PICKS.md}

### Action Items
1. {Specific purchase recommendation with URL}
2. {Time-sensitive deal to act on}
3. {Item to wait on / watch for restock}

## Appendix

- Full verification data: `verify-*.md`
- Best picks: `BEST-PICKS.md`
- Cross-category summary: `verify-SUMMARY.md`
```
