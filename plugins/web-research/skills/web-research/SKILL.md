---
name: web-research
description: >
  Use when researching any topic online — debugging issues, finding
  solutions, gathering information from multiple sources. Trigger phrases:
  "research this", "find information about", "what's the latest on",
  "search the web for", "look up", "investigate", "detailed research on",
  "in-depth investigation", "deep dive into".
---

# Web Research

## Why This Skill Exists

Research methodology (wave strategy, query generation, debugging heuristics) is reusable across projects. Packaging it as a skill makes it available to any Claude Code session, not just a single repo's agent. The research execution pattern, output format, and quality assurance steps are domain-independent.

---

## Tool Routing

Invoke the `web-tool-routing` skill for tool detection (capability levels 0-4), page reading fallback chain (7 tiers), web search fallback chain, and credit budget management.

Below are **quality-optimized overrides** for research workflows. These differ from the default cost-optimized chains — research prioritizes content completeness and source discovery over minimizing credit spend.

### Search Priority (Quality-Optimized Override)

> Differs from default chain: SB `fast_search` first for Reddit discovery (finds 3x more threads). Default chain starts with free WebSearch/Jina.

| Priority | Tool | Strength |
|----------|------|----------|
| 1 | **SB `fast_search`** | Primary search — finds 3x more Reddit threads than alternatives |
| 2 | **SB `get_google_search_results`** | PAA (People Also Ask) and Related Searches — unavailable elsewhere |
| 3 | **Jina `search_web`** / **WebSearch** | Fallback when SB unavailable |

### Reading: Non-Reddit URLs (Quality-Optimized Override)

> Differs from default chain: prioritizes content completeness (comments + article) over cost. Default chain starts with free WebFetch/Jina; this override starts with Tavily/Firecrawl for richer extraction.

| Priority | Tool | Why |
|----------|------|-----|
| 1 | **Tavily `tavily_extract`** | Full article + all comments, clean markdown, fastest |
| 2 | **Firecrawl `firecrawl_scrape`** | Full article + comments + rich metadata (fallback) |
| 3 | **SB `get_page_text`** | Full content but noisy (nav, ads, sidebar) |
| 4 | **Jina `read_url`** | Cleanest article body, but misses comments |
| 5 | **WebFetch** | AI-summarized, no raw content — quick overview only |

### Reading: Reddit URLs

Reddit blocks most reading tools. Only one reliably works:

| Tool | Reddit Status | Notes |
|------|---------------|-------|
| **SB `get_page_text`** | Only working reader | Actual comments, vote scores, timestamps |
| Tavily `tavily_extract` | Gets AI summary only | Cross-thread discovery (curated quotes from multiple subs), not raw comments |
| WebFetch | Hardcoded block | — |
| Jina `read_url` | Network security block | — |
| Firecrawl `firecrawl_scrape` | Policy blocklist | — |

### Geo Targeting

Always pass geographic context when available:

| Tool | Country Param | Example |
|------|--------------|---------|
| ScrapingBee | `country_code: "us"` | US results |
| Jina `search_web` | `gl: "us"` | US results |
| Firecrawl | `location: "United States"` | Full name required |
| Tavily | `country: "United States"` | Rejects ISO codes like "us" |

### Tool Gotchas

- **Tavily on Reddit:** Returns Reddit's AI "Related Answers" summary, not actual user comments
- **Tavily:** Use `search_depth: "advanced"` for better results (slower but more thorough)
- **Jina vs Firecrawl search:** Nearly identical results (both use Google backend) — pick one, don't run both

---

## Research Execution (Wave Strategy)

Parallelize research into waves for maximum efficiency.

### Wave 1: Search (parallel)

Run all search queries simultaneously:

- **General queries:** `"{topic} review feedback"`, `"{topic} best practices"`, `"{topic} issues problems"`
- **Site-specific:** `"{topic} site:reddit.com"`, `"{topic} site:github.com"`
- **PAA/Related Searches** via `get_google_search_results` (if SB available)

**Query generation:** Always generate **5-10 query variations** per research topic:
- Include technical terms, error messages, library names
- Think of how different people might describe the same issue
- Include `site:reddit.com` variants for community discussions
- Consider searching for both the problem AND potential solutions
- Vary specificity: broad ("React state management") and narrow ("useReducer vs Redux toolkit 2024")

From combined results, build a URL list. **Filter out:**
- The topic's own official website (when researching a product/tool)
- Obvious affiliate/sponsored content
- Duplicate URLs

### Wave 2: Read (parallel)

Read all discovered URLs in parallel, using the best tool per domain:

- **Reddit URLs** → SB `get_page_text`
- **Everything else** → Tavily `tavily_extract` (preferred) or next available tool per the quality-optimized reading chain above

### Wave 3: Analyze

- Identify patterns across sources
- Cross-reference claims and solutions
- Note conflicting information
- Rank findings by relevance and reliability
- Distinguish between official solutions and community workarounds

### Wave 4: Compile Report

Synthesize into the structured output format below.

---

## Debugging Assistance

When researching errors or technical problems:

- **Search for exact error messages** in quotes — this is the highest-signal query
- Look for **issue templates** that match the problem pattern
- Find **workarounds**, not just explanations
- Check if it's a **known bug** with existing patches or PRs
- Look for **similar issues** even if not exact matches (same library, same version range)
- Check GitHub Issues (both open AND closed), changelogs, and migration guides
- Search for the **error + library version** — version-specific behavior is common
- Check Stack Overflow answers sorted by recent activity, not just votes — use `?tab=active` URL parameter to sort by recent activity (default sort is by votes, which often surfaces outdated answers)

---

## Comparative Research

When comparing tools, libraries, or approaches:

- Create structured comparisons with clear criteria
- Find real-world usage examples and case studies
- Look for performance benchmarks and user experiences
- Identify trade-offs and decision factors
- Include both popular opinions and contrarian views
- Note the date of comparisons — tool landscapes change fast

---

## Quality Assurance

- **Multi-source verification** — Verify information across 2+ independent sources when possible
- **Date-stamping** — Note when findings were published; solutions from 2020 may be outdated
- **Source credibility** — Distinguish official docs vs. blog posts vs. forum answers vs. AI-generated content
- **Clearly mark uncertainty** — When information is speculative or unverified, say so
- **Distinguish solutions from workarounds** — A workaround may break in the next version; a fix is stable
- **Recency bias check** — Newer isn't always better; check if older solutions are actually more battle-tested

---

## Output Format

Structure research findings as:

1. **Executive Summary** — Key findings in 2-3 sentences
2. **Detailed Findings** — Organized by relevance or approach, with source attribution
3. **Sources and References** — Direct links with brief descriptions of what each source contributed
4. **Recommendations** — Actionable next steps (if applicable)
5. **Additional Notes** — Caveats, warnings, areas needing more research, conflicting information

---

## Model Recommendation

Research is tool-call heavy, not reasoning-heavy. When spawning research agents, `model: sonnet` is the right default — it handles search/read loops efficiently at lower cost. Opus adds cost without improving search/read quality. Use Opus only if the synthesis step requires deep domain reasoning (e.g., comparing complex architectural trade-offs).
