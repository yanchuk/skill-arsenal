# Tool Fallback Chain

Complete tiered strategy for web scraping and searching during consumer goods research. Always exhaust free tiers before using paid tools. Browser tools are last resort.

---

## Page Reading (checking product pages for prices, sizes, stock)

```
TIER 1: WebFetch(url, prompt="extract product name, sizes, stock status, price")
  Cost: FREE | Speed: Fast
  Built-in tool, always available, no MCP required.
  ↓ fails? (JS content invisible, complex pages, empty response)

TIER 2: mcp__jina__read_url(url)
  Cost: FREE | Speed: Fast
  Free MCP tool (10M token free tier — consumable), better extraction than WebFetch for some sites.
  Best for: Clean HTML pages, EU stores, simple product pages.
  ↓ fails? (empty page, cookie wall, Cloudflare, JS-only content)

TIER 3: mcp__tavily__tavily_extract(urls=[url])
  Cost: FREE | Speed: Fast
  Best for: Pages where WebFetch and Jina return empty or blocked
  ↓ fails? (blocked, timeout, anti-bot)

TIER 4: mcp__firecrawl-mcp__firecrawl_scrape(url, formats=["markdown"], waitFor=2000)
  Cost: 1 credit/page | Speed: Medium
  Best for: JS-heavy pages (size selectors, dynamic pricing)
  Use waitFor=2000 for pages that render content with JavaScript
  ↓ fails? (credits exhausted, still blocked)

TIER 5: mcp__scrapingbee__get_page_text(url, render_js=true)
  Cost: 1-10 credits | Speed: Medium
  For Cloudflare/heavy anti-bot: add premium_proxy=true (10 credits)
  Best for: Anti-bot protected sites, Cloudflare-fronted stores
  ↓ fails? (credits exhausted)

TIER 6: mcp__playwright__browser_navigate(url) → browser_snapshot
  Cost: FREE | Speed: SLOW
  Full browser rendering. Context-heavy — use sparingly.
  ↓ fails? (page blocks headless browsers)

TIER 7: mcp__claude-in-chrome__navigate(url) → read_page
  Cost: FREE | Speed: SLOWEST
  Real browser fingerprint. Requires Chrome extension.
  ↓ ALL failed?

MARK AS: "UNVERIFIED — all tools failed, manual check required" + include URL
```

---

## Web Searching (finding items on stores, discovering retailers)

```
TIER 1 (parallel): WebSearch(query) ∥ mcp__jina__search_web(query, gl="{country_code}", hl="{language}")
  WebSearch: built-in, always available, broad coverage
  Jina: free MCP (10M token free tier — consumable), adds geo-targeting (gl/hl params)
  Run BOTH in parallel when Jina available — different indexes, better coverage.
  If only built-in available, WebSearch alone is the baseline.
  ↓ insufficient results?

TIER 2: mcp__tavily__tavily_search(query, include_domains=[...])
  Cost: FREE | Speed: Fast
  Best for: Domain-filtered search (e.g., only search allegro.pl, ceneo.pl)
  ↓ still insufficient?

TIER 3: mcp__firecrawl-mcp__firecrawl_search(query, limit=5)
  Cost: 1 credit/search | Speed: Medium
  Returns scraped content from results, not just snippets.
  ↓ ALL failed?

MARK AS: "SEARCH FAILED — manual check required"
```

---

## Decision: When to Escalate vs. Mark UNVERIFIED

**Escalate to next tier when:**
- Current tool returns empty/blocked content
- Content is clearly incomplete (page loaded but sizes/prices missing)
- Anti-bot page detected (Cloudflare challenge, CAPTCHA text in response)

**Mark UNVERIFIED when:**
- All tiers exhausted for that URL
- Item found via search snippets but product page inaccessible
- Only partial information available (price but not sizes)

**Stop and skip when:**
- Item clearly discontinued (404, product removed from store)
- Store doesn't serve user's country (geo-blocked)

---

## Credit Budget Management

### Budget Formula

For team-based verification with paid tools:
```
per_agent_budget = total_credits / (num_agents + 1_reserve)
```

Example with 500 Firecrawl credits and 6 agents:
```
per_agent = 500 / (6 + 1) ≈ 71 credits each
reserve = 71 credits for leader/browser fallback
```

### Tracking

Every verification file MUST include a credit usage table:
```markdown
## Credit Usage
| Tool | Credits Used | Budget | Remaining |
|------|-------------|--------|-----------|
| Firecrawl | 11 | 40 | 29 |
| ScrapingBee | 3 | 50 | 47 |
| Jina | free tier | 10M tokens | monitor usage |
| WebSearch | free | unlimited | — |
```

### Budget Alerts

- **At 80% paid usage:** Prefer built-in tools (WebSearch, WebFetch) for remaining items
- **At 100% paid usage:** Stop using paid tools entirely, rely on built-in + free MCP tiers (if quota remains) + UNVERIFIED marks
- **Jina/Tavily quota exhausted:** Fall back to built-in tools (WebSearch, WebFetch) which are truly unlimited
- **Across team:** Leader monitors total usage across agents, redistributes if one agent under-uses

### Cost Reference

| Tool | Operation | Cost | Category |
|------|-----------|------|----------|
| WebSearch | Web search | FREE | Built-in |
| WebFetch | Read page | FREE | Built-in |
| Jina read_url | Read page | Free tier (10M tokens) | Free MCP |
| Jina search_web | Web search | Free tier (10M tokens) | Free MCP |
| Tavily search | Web search | Free tier (limited) | Free MCP |
| Tavily extract | Read page | Free tier (limited) | Free MCP |
| Firecrawl scrape | Read page (JS) | 1 credit | Paid MCP |
| Firecrawl search | Web search + scrape | 1 credit | Paid MCP |
| ScrapingBee basic | Read page | 1 credit | Paid MCP |
| ScrapingBee render_js | Read + JS render | 5 credits | Paid MCP |
| ScrapingBee premium_proxy | Cloudflare bypass | 10 credits | Paid MCP |
| Playwright | Browser session | FREE (slow) | Browser |
| Chrome MCP | Browser session | FREE (slowest) | Browser |

---

## Color/Variant Strategy

### Critical: variants ≠ same item

A single product page often lists multiple color options or modifications (e.g., "Black", "Navy", "Gore-Tex version"). Each variant can have:
- **Different price** — colorways on sale, limited editions at premium, material upgrades cost more
- **Different size availability** — black M in stock, blue M sold out
- **Different stock status entirely** — one color discontinued while others are current season

Do NOT report just the default/first variant's price and availability. When scraping a product page:
1. Check if the page has a color/variant selector
2. If yes, extract price and size availability **per variant** (or at minimum for the user's preferred variant + 2-3 alternatives)
3. Note which variant the reported price applies to — "299 zł" means nothing without "Navy, size M"

### OOS fallback

When an item appears OOS in one variant, ALWAYS check alternatives before marking NOT AVAILABLE:

1. Search for other colors/variants on the same store
2. Check at least 3 color/size variants before declaring OOS
3. Some stores list each color as a separate product page — search for the model name to find all variants
4. Record which variants were checked in the verification table

---

## Backlog Strategy

While searching for target items, save interesting alternatives found in results:
- Items from same category at good prices
- Items recommended by review sites but not on original list
- Store-wide sales or clearance finds

Save to a "Backlog" section in each verification file. These may become valuable alternatives if primary items are unavailable.
