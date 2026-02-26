---
name: competitor-research
description: >
  Research competitors by gathering and analyzing community feedback from
  Reddit, forums, and review sites. Use this skill whenever the user asks
  to research a competitor, gather community feedback about a product,
  analyze Reddit discussions, do competitive intelligence, or says things
  like "research [product]", "what do people say about X", "gather reddit
  feedback for", "analyze competitor", or "community sentiment about".
  Also use when the user provides a list of Reddit URLs to analyze.
---

# Competitor Research

Structured pipeline for gathering and analyzing community feedback about competitor products. Covers search, reading, analysis, and documentation.

## Why This Skill Exists

Different web tools work for different sites, and getting this wrong wastes credits and time. Reddit blocks most tools. Forums need different readers than blogs. This skill routes requests to the right tool automatically and enforces a consistent analysis format so competitive intelligence is comparable across competitors.

## Tool Routing

The single most important thing to internalize: **Reddit is special.** Most tools fail on Reddit. Check which tools are available in your environment. The skill works with basic web tools; specialized MCP servers improve Reddit coverage and result quality.

### Universal Approach (Default)

Works with commonly available tools (WebSearch, WebFetch, Jina read_url, etc.):

**Search:**
```
Step 1: WebSearch / Jina search_web — "{product name} review feedback"
Step 2: WebSearch / Jina search_web — "{product name} site:reddit.com"
```

**Read:**

| URL contains | Tool | Notes |
|---|---|---|
| `reddit.com` | **WebFetch** or **Jina `read_url`** | WebFetch typically doesn't work well for Reddit; Jina may have limited success. Try both — if neither captures comments, note the limitation and work with what you get |
| Everything else | **WebFetch** or **Jina `read_url`** | Either works well for blogs, forums, and review sites |

From the combined results, build a thread list. **Filter out:**
- The competitor's own website (e.g., competitor.com)
- Obvious affiliate/sponsored content
- Duplicate URLs

### Advanced Tool Routing (Reference — Benchmarked Feb 2026)

If you have ScrapingBee, Tavily, or Firecrawl MCP servers installed, these provide significantly better results — especially for Reddit.

**Search (with ScrapingBee):**

Use **ScrapingBee `fast_search`** as the primary search tool. It finds the most Reddit threads (3 vs 0-1 for others) and forum threads.

```
Step 1: SB fast_search — "{product name} review feedback", country_code: "us"
Step 2: SB fast_search — "{product name} site:reddit.com", country_code: "us"
Step 3: SB get_google_search_results — same query, for PAA/Related Searches
```

PAA (People Also Ask) and Related Searches are competitive intelligence gold — only available from `get_google_search_results`. Always run this as a supplement.

Always pass US geo: SB uses `country_code: "us"`, Jina uses `gl: "us"`, Firecrawl uses `location: "United States"`. Jina and Firecrawl return nearly identical search results (both use Google as backend) — pick one.

**Read (with specialized tools):**

**Reddit** — most tools fail. Only one reliable option:

| Tool | Reddit status | Use |
|------|---------------|-----|
| **SB `get_page_text`** | ✅ Only working reader | Actual comments, vote scores, timestamps |
| Tavily `tavily_extract` | ⚠️ Gets AI summary only | Cross-thread discovery (curated quotes from multiple subs) |
| WebFetch | ❌ Hardcoded block | — |
| Jina `read_url` | ❌ Network security block | — |
| Firecrawl `firecrawl_scrape` | ❌ Policy blocklist | — |

**Non-Reddit** (blogs, forums, review sites):

| Priority | Tool | Why |
|----------|------|-----|
| 1 | **Tavily `tavily_extract`** | Full article + all comments, clean markdown, fastest |
| 2 | **Firecrawl `firecrawl_scrape`** | Full article + comments + rich metadata (fallback) |
| 3 | **SB `get_page_text`** | Full content but noisy (nav, ads, sidebar) |
| 4 | **Jina `read_url`** | Cleanest article body, but misses comments |
| 5 | **WebFetch** | AI-summarized, no raw content — quick overview only |

**Tavily gotchas:**
- The `country` param requires `"United States"` — it rejects ISO codes like `"us"`
- Reddit extraction returns Reddit's AI "Related Answers" summary, not actual user comments
- Use `search_depth: "advanced"` for better results (slower but more thorough)

### Analyze: Reddit Thread Format

For each Reddit thread, produce a structured analysis:

```markdown
# Reddit Analysis: [Thread Title]

> Source: [full URL]
> Subreddit: r/{sub} | Date: {date} | Comments: ~{count} | Post Score: {score}

## Executive Summary
[2-3 sentences: what this thread is about and the main takeaway]

## Overall Sentiment
- **Dominant Sentiment**: Positive/Negative/Neutral/Mixed (X%)
- **Emotional Tone**: [excited/frustrated/skeptical/supportive/etc.]
- **Community Alignment**: High/Medium/Low

## Top Arguments

### In Favor
1. **[Main point]** (+XXX score)
   > "[Direct quote]" — u/username

### Against
1. **[Main point]** (+XXX score)
   > "[Direct quote]" — u/username

## Community Consensus
- [Point most people agree on]

## Controversial Topics
- [Divisive issue — community split]

## Notable Insights
- **Most Helpful**: [Most practical advice in thread]
- **Surprising Take**: [Unexpected perspective that gained traction]

## Key Quotes
> "[Memorable quote]" — u/username (+XXX score)

## Product Relevance
[How this discussion informs your product strategy — what can you learn?
What gaps do users describe that your product fills?]
```

Focus on **highly upvoted comments** for consensus. Include **exact scores** to show community agreement. **Quote directly** rather than paraphrasing. For threads where the product is just briefly mentioned (not the main topic), use a shorter format focusing on what's said about that product specifically.

### Document: File Structure

```
references/{domain}/
├── reddit/
│   ├── meta.md                        # Cross-thread synthesis
│   └── r-{subreddit}-{topic-slug}.md  # Individual thread analysis
```

**Naming:** `r-{subreddit}-{topic-slug}.md` — e.g., `r-personalfinance-is-mint-worth-it.md`

**meta.md** aggregates all individual analyses into:

```markdown
# {Product} — Reddit Community Analysis

> Analyzed: {count} threads across {subreddit list}
> Date: {date}

## Executive Summary
[3-5 sentences: overall community perception]

## Cross-Thread Sentiment
- Overall: Positive/Negative/Mixed with X% positive
- Trend: improving/declining/stable

## Recurring Themes

### What Users Love
1. [Theme] — evidence from N threads

### What Users Criticize
1. [Theme] — evidence from N threads

### What Users Wish For
1. [Feature/improvement]

## Competitive Positioning Insights
[What this competitor gets right that your product should learn from,
and where it falls short that you can exploit]

## Most Impactful Quotes
> "[Quote]" — u/username, r/{sub} (+score)

## Thread Index
| Thread | Subreddit | Sentiment | Key Theme | File |
|---|---|---|---|---|
```

## Execution Strategy

For efficiency, parallelize where possible:

1. **Wave 1:** Run all search queries in parallel (general search + reddit-specific search + PAA if available)
2. **Wave 2:** Read all discovered threads in parallel using the best available tool per domain
3. **Wave 3:** Analyze and write files (can use parallel subagents, one per competitor)
4. **Wave 4:** Write meta.md after all individual analyses are complete
5. **Wave 5:** Update doclog.md

When researching multiple competitors, launch one subagent per competitor for Wave 3 — they're fully independent.

## Example Invocations

**Full competitor research:**
> "Research [competitor] — gather Reddit feedback and community sentiment"

→ Search for threads, read them all, analyze each, write files, create meta.md

**Targeted thread analysis:**
> "Analyze these Reddit threads about [competitor]: [list of URLs]"

→ Skip search, read each URL, analyze, write files, create meta.md

**Quick sentiment check:**
> "What does Reddit think about [product name]?"

→ Search, read top 3-5 threads, summarize (may skip individual files for quick check)
