---
name: web-tool-routing
description: >
  Use when building or running any workflow that reads web pages or searches
  the web and needs to pick a tool. Invoked by web-research, competitor-research,
  and researching-consumer-goods as shared routing infrastructure; agents that
  can't load skills at runtime reference it as the canonical source. Trigger
  phrases: "which scraper", "fetch this URL", "route the web call", "pick a
  web tool", "credit-aware fetch".
---

# Web Tool Routing

Shared routing logic for web access. Detects available tools, selects the cheapest one that works, escalates on failure, tracks credit spend.

## Why This Exists

Different MCP tools have different free tiers, credit costs, and capabilities. Some sites block some tools. Getting the order wrong wastes paid credits on things free tools could handle, or wastes time on tools that will fail. This skill encodes the optimal routing so every research skill benefits from the same logic.

---

## Tool Inventory

| Tool | Category | Free Tier | Renewable? | Operations |
|------|----------|-----------|------------|------------|
| **WebSearch** | Built-in | Unlimited | — | Web search |
| **WebFetch** | Built-in | Unlimited | — | Page read (AI-summarized) |
| **Jina** | Free MCP | 10M tokens | One-time | `read_url` (page read), `search_web` (search) |
| **Tavily** | Free MCP | 1,000 credits/mo | Monthly | `tavily_search`, `tavily_extract`, `tavily_crawl`, `tavily_map` |
| **Firecrawl** | Paid MCP | 1,000 credits | One-time | `firecrawl_scrape`, `firecrawl_search`, `firecrawl_crawl` |
| **ScrapingBee** | Paid MCP | 1,000 credits | One-time | `get_page_text`, `fast_search`, `get_google_search_results` |
| **Playwright** | Browser | Unlimited | — | `browser_navigate`, `browser_snapshot` |
| **Chrome MCP** | Browser | Unlimited | — | `navigate`, `read_page`, `computer` |

### Cost per Operation

| Tool | Operation | Credits | Notes |
|------|-----------|---------|-------|
| WebSearch | search | **FREE** | Always available |
| WebFetch | read page | **FREE** | Returns AI summary, not raw content |
| Jina `search_web` | search | ~tokens | Free tier (10M tokens shared across all Jina ops) |
| Jina `read_url` | read page | ~2-10K tokens | Depends on page size |
| Tavily `tavily_search` | search (basic) | 1 credit | `search_depth: "basic"` |
| Tavily `tavily_search` | search (advanced) | 2 credits | `search_depth: "advanced"` — slower, more thorough |
| Tavily `tavily_extract` | read page | 1 credit/URL | Clean markdown extraction |
| Tavily `tavily_crawl` | crawl site | 1 credit/page | Multi-page crawl |
| Firecrawl `firecrawl_scrape` | read page | 1 credit | Supports `waitFor` for JS rendering |
| Firecrawl `firecrawl_search` | search + scrape | 1 credit | Returns scraped content, not just snippets |
| ScrapingBee `get_page_text` | read page (basic) | 1 credit | Plain text extraction |
| ScrapingBee `get_page_text` | read page + JS | 5 credits | `render_js=true` |
| ScrapingBee `get_page_text` | Cloudflare bypass | 10 credits | `premium_proxy=true` |
| ScrapingBee + AI query | read + extract | +5 credits | Added on top of base cost |
| ScrapingBee `fast_search` | search | 1 credit | Good for Reddit discovery |
| ScrapingBee `get_google_search_results` | SERP features | 1 credit | PAA, Related Searches |
| Playwright | browser session | **FREE** | Slow, context-heavy |
| Chrome MCP | browser session | **FREE** | Slowest, requires extension |

### Routing Principle

**Unlimited → Renewable → One-time → Browser**

1. Built-in tools first (WebSearch, WebFetch) — truly unlimited, no MCP needed
2. Jina next — generous free tier (10M tokens), but one-time and shared across operations
3. Tavily next — smaller free tier (1,000 credits) but **renews monthly**
4. Firecrawl — 1,000 one-time credits, best for JS-rendered pages
5. ScrapingBee — 1,000 one-time credits, best for anti-bot bypass (but expensive: 5-10 credits for JS/proxy)
6. Browser tools last — free but slow, context-heavy, use only when all API tools fail

---

## Tool Detection

Before starting any web research, probe which MCP tools are available. Run these ToolSearch queries:

```
ToolSearch("+jina read")
ToolSearch("+firecrawl scrape")
ToolSearch("+scrapingbee")
ToolSearch("+tavily search")
ToolSearch("+playwright navigate")
ToolSearch("+chrome navigate")
```

Classify capability level:

| Level | Tools Available | What You Can Do |
|-------|----------------|-----------------|
| **4 (FULL)** | Built-in + Jina + Firecrawl + ScrapingBee + Browser | Everything — JS rendering, anti-bot bypass, full browser fallback |
| **3 (STRONG)** | Built-in + Jina + (Firecrawl OR ScrapingBee) | Most sites — JS rendering OR anti-bot, not both |
| **2 (BASIC)** | Built-in + (Jina OR Tavily) | Good coverage — clean pages, no anti-bot bypass |
| **1 (BASELINE)** | WebSearch + WebFetch only | Always available. Search + AI-summarized reads |
| **0 (NONE)** | No web tools at all | Recommend MCP installs (see below) |

**At Level 0**, output MCP installation commands:
```
claude mcp add jina -s user -- npx -y @anthropic/jina-mcp-server
claude mcp add firecrawl-mcp -s user -- npx -y firecrawl-mcp
claude mcp add scrapingbee -s user -- npx -y scrapingbee-mcp
```

---

## Page Reading Fallback Chain

When you need to read a web page (product page, article, forum thread, etc.), follow this chain. Stop at the first tier that returns usable content.

```
TIER 1: WebFetch(url, prompt="extract [what you need]")
  Cost: FREE | Speed: Fast | Always available
  Returns AI-summarized content. Good enough for simple pages.
  ↓ fails? (JS content invisible, complex pages, empty response)

TIER 2: Jina read_url(url)
  Cost: FREE (10M token budget) | Speed: Fast
  Better extraction than WebFetch. Clean markdown output.
  Best for: EU stores, documentation, simple product pages.
  ↓ fails? (cookie wall, Cloudflare, JS-only content, network block)

TIER 3: Tavily tavily_extract(urls=[url])
  Cost: 1 credit/URL (renewable monthly) | Speed: Fast
  Good for pages where WebFetch and Jina return empty or blocked.
  ↓ fails? (blocked, timeout, anti-bot)

TIER 4: Firecrawl firecrawl_scrape(url, formats=["markdown"], waitFor=2000)
  Cost: 1 credit/page (one-time budget) | Speed: Medium
  Best for: JS-heavy pages (size selectors, dynamic pricing).
  Use waitFor=2000+ for pages that render content with JavaScript.
  ↓ fails? (credits exhausted, still blocked)

TIER 5: ScrapingBee get_page_text(url, render_js=true)
  Cost: 5 credits (one-time budget) | Speed: Medium
  For Cloudflare/heavy anti-bot: add premium_proxy=true (10 credits).
  Best for: Anti-bot protected sites, Cloudflare-fronted pages.
  ↓ fails? (credits exhausted)

TIER 6: Playwright browser_navigate(url) → browser_snapshot
  Cost: FREE | Speed: SLOW
  Full browser rendering. Context-heavy — use sparingly.
  ↓ fails? (page blocks headless browsers)

TIER 7: Chrome MCP navigate(url) → read_page
  Cost: FREE | Speed: SLOWEST
  Real browser fingerprint. Requires Chrome extension.
  ↓ ALL failed?

MARK AS: "⚠️ UNVERIFIED — all tools failed, manual check required" + include URL
```

---

## Web Search Fallback Chain

When you need to search the web for pages, follow this chain.

```
TIER 1 (run in parallel when both available):
  WebSearch(query)                                    — FREE, built-in, broad coverage
  ∥ Jina search_web(query, gl="{code}", hl="{lang}") — FREE, adds geo-targeting
  Combine and deduplicate results from both.
  ↓ insufficient results?

TIER 2: Tavily tavily_search(query, include_domains=[...])
  Cost: 1 credit (renewable monthly) | Best for: domain-filtered search
  ↓ still insufficient?

TIER 3: Firecrawl firecrawl_search(query, limit=5)
  Cost: 1 credit (one-time budget) | Returns scraped content, not just snippets
  ↓ still insufficient?

TIER 4: ScrapingBee fast_search(query)
  Cost: 1 credit (one-time budget) | Best Reddit discovery (finds 3x more threads)
  ↓ ALL failed?

MARK AS: "SEARCH FAILED — manual check required"
```

---

## Geo-Targeting Quick Reference

Always pass geographic context when available. Different tools use different parameter names:

| Tool | Country Param | Language Param | Example (US English) |
|------|--------------|----------------|---------------------|
| Jina `search_web` | `gl: "us"` | `hl: "en"` | `gl: "us", hl: "en"` |
| ScrapingBee `fast_search` | `country_code: "us"` | — | `country_code: "us"` |
| Firecrawl | `location: "United States"` | — | `location: "United States"` |
| Tavily `tavily_search` | `country: "United States"` | — | Rejects ISO codes like "us" |

**Tavily gotcha:** The `country` parameter requires full country name (`"United States"`), not ISO codes (`"us"`). It will silently ignore invalid values.

---

## Credit Budget Management

### Tracking Template

Every research session should track credit usage:

```markdown
## Credit Usage
| Tool | Credits Used | Free Tier | Remaining | Status |
|------|-------------|-----------|-----------|--------|
| WebSearch | — | unlimited | — | ✅ |
| WebFetch | — | unlimited | — | ✅ |
| Jina | ~X tokens | 10M tokens | ~Y tokens | ✅ |
| Tavily | X | 1,000/mo | Y | ✅ |
| Firecrawl | X | 1,000 | Y | ✅ |
| ScrapingBee | X | 1,000 | Y | ✅ |
```

### Budget Alerts

- **At 80% of a paid tool's budget:** Switch to free tools for remaining items where possible
- **At 100% of a paid tool's budget:** Stop using that tool entirely, rely on remaining tiers
- **Jina tokens running low:** Fall back to WebFetch (free, unlimited) + Tavily
- **All paid tools exhausted:** Built-in tools only + UNVERIFIED marks for failures

### Team Budget Formula (for parallel agent workflows)

```
per_agent_budget = total_credits / (num_agents + 1_reserve)
```

Example: 1,000 Firecrawl credits, 4 agents → 200 credits each, 200 reserve for leader.

---

## When to Escalate vs. Mark UNVERIFIED

**Escalate to next tier when:**
- Current tool returns empty/blocked content
- Content is clearly incomplete (page loaded but key data missing)
- Anti-bot page detected (Cloudflare challenge, CAPTCHA text in response)

**Mark UNVERIFIED when:**
- All tiers exhausted for that URL
- Item found via search snippets but product page inaccessible
- Only partial information available

**Stop and skip when:**
- Page returns 404 (content removed)
- Site is geo-blocked for user's country
- Content is behind login/paywall with no free access

---

## Domain-Specific Overrides

This skill provides the **default routing.** Domain skills may override the order for specific use cases:

- **Reddit content:** Most tools fail on Reddit. ScrapingBee `get_page_text` is typically the only working reader. See the invoking skill for Reddit-specific routing.
- **Comment-heavy pages:** When capturing user comments matters (forums, review sites), tools that return full page content (Tavily, Firecrawl) may be preferred over those that return article body only (Jina).
- **E-commerce anti-bot:** Marketplace sites (Amazon, Allegro, eBay) have heavy anti-bot. Search-based approaches work better than direct page scraping. See the invoking skill for site-specific patterns.
- **JS-rendered content:** Size selectors, dynamic pricing, configuration dropdowns need JS rendering. Jump to Firecrawl (waitFor=2000) or ScrapingBee (render_js=true) — free tools won't see this content.

The invoking skill's overrides take precedence over the default chain for their specific scenarios.
