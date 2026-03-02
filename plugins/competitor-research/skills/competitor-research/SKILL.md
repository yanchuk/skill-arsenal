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

Invoke the `web-tool-routing` skill for tool detection, fallback chains, and credit management. Below are domain-specific overrides for competitor research.

### Reddit Override (Special Case)

> Differs from default chain: only ScrapingBee works for Reddit. Default chain's preferred free tools (WebFetch, Jina) and mid-tier tools (Tavily, Firecrawl) are all blocked by Reddit.

Reddit blocks most tools. Only one reliable reader:

| Tool | Reddit status | Cost | Use |
|------|--------------|------|-----|
| **ScrapingBee `get_page_text`** | ✅ Only working reader | 1 credit | Actual comments, votes, timestamps |
| **Tavily `tavily_extract`** | ⚠️ AI summary only | 1 credit | Cross-thread discovery (curated quotes) |
| WebFetch | ❌ Blocked | — | — |
| Jina `read_url` | ❌ Blocked | — | — |
| Firecrawl `firecrawl_scrape` | ❌ Blocked | — | — |

### Non-Reddit Override (Forums, Review Sites)

> Differs from default chain: prioritizes comment-capturing tools (Tavily, Firecrawl) over clean-article tools. Default chain starts with free WebFetch/Jina which extract article body but miss user comments — critical data for competitive intelligence.

For competitor research, prioritize tools that capture **comments** (not just article body):

| Priority | Tool | Why |
|----------|------|-----|
| 1 | Tavily `tavily_extract` | Full article + comments, 1 credit (renewable) |
| 2 | Firecrawl `firecrawl_scrape` | Full article + comments + metadata, 1 credit |
| 3 | ScrapingBee `get_page_text` | Full content but noisy, 1 credit |
| 4 | Jina `read_url` | Clean body but misses comments, free |
| 5 | WebFetch | AI-summarized, free — quick overview only |

### Search Enhancement (if ScrapingBee available)

ScrapingBee `get_google_search_results` provides PAA (People Also Ask) and Related Searches — competitive intelligence gold. Always run as supplement alongside the standard search chain.

### Tavily Gotchas
- `country` param requires `"United States"` — rejects ISO codes
- Reddit extraction returns AI summary, not actual user comments
- Use `search_depth: "advanced"` for better results

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
