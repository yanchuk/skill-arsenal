# Team Orchestration

Guide for creating parallel agent teams in a subagent-capable runtime to verify large item sets across multiple categories. Only applicable in a subagent-capable runtime with team capabilities.

---

## When to Create a Team

All conditions must be met:
- **Items >= 15** across all categories
- **Categories >= 3** distinct product categories
- **Tool level >= 3** (Jina + at least Firecrawl or ScrapingBee)
- **Running in a subagent-capable runtime** with access to the runtime's team or subagent tools

If any condition is not met, use sequential verification in the current session instead.

---

## Team Structure

```
Brain-model lead (you)
├── Worker agent 1 — Category A
├── Worker agent 2 — Category B
├── Worker agent 3 — Category C
├── Worker agent 4 — Category D
├── Worker agent 5 — Category E
└── Worker agent 6 — Category F
```

- **Max 6 workers** — one per category
- **Workers use a lower-cost model** when the runtime supports model selection
- **Lead uses the strongest available model** for compilation and quality control
- If fewer than 3 categories, don't create a team — run sequentially

---

## Team Lifecycle

### 1. Create Team Or Work Group

```text
Create a work group named "consumer-research" for parallel consumer goods
verification.
```

### 2. Create Tasks (one per category)

```text
for category in categories:
    create a visible task:
      subject: "Verify {category} items"
      description: "Verify {count} {category} items for availability and pricing in {country}"
```

### 3. Spawn Workers (parallel)

Spawn all workers in a single message for maximum parallelism:

```text
for category in categories:
    spawn a worker agent with:
      name: "{category}-researcher"
      model: "<worker-model>" when supported
      group: "consumer-research"
      prompt: WORKER_PROMPT with category, items, geo context,
              tool chain, credit budget, and output path
```

### 4. Monitor Progress

- Workers send messages when they complete tasks or encounter issues
- Messages are automatically delivered — no need to poll
- If a worker is stuck on anti-bot blocks, suggest tool tier escalation
- Redistribute credit budget if some workers finish under budget

### 5. Compile Results (Leader)

After all workers complete:
1. Read all `verify-{category}.md` files
2. Cross-reference data across categories
3. Generate `verify-SUMMARY.md`, `BEST-PICKS.md`, `FINAL-REPORT.md`

### 6. Shutdown Team

```python
# Send shutdown to each worker
for worker in workers:
    SendMessage(
        type="shutdown_request",
        recipient=worker,
        content="Verification complete, shutting down"
    )

# After all workers confirm shutdown:
TeamDelete()
```

---

## Worker Prompt Template

Each worker receives this context:

```markdown
You are a consumer goods verification agent. Your task is to verify
availability and pricing for {category} items in {country}.

## Your Items
{item_list_with_details}

## Geo Context
- Country: {country}
- Language: {language}
- Currency: {currency}
- Local marketplaces: {marketplaces}
- International stores: {international_stores}

## Tool Fallback Chain
{use the web-tool-routing skill for the complete fallback chain}

## Credit Budget
- Firecrawl: {firecrawl_budget} credits
- ScrapingBee: {scrapingbee_budget} credits
- Built-in tools (WebSearch, WebFetch): baseline — ALWAYS AVAILABLE
- Free MCP tools (Jina, Tavily): free tier (consumable — Jina: 10M tokens, Tavily: limited) — USE BEFORE PAID

## Output
Write results to: {output_path}
Use the per-category verification template (tool log, per-item tables,
summary table, credit usage).

## Rules
1. Check local price aggregators first (Ceneo, Idealo, Google Shopping for {country}) — one page reveals multiple stores and prices
2. Exhaust free tools before paid tools
3. Verify aggregator prices on actual stores (aggregator data may be cached/stale)
4. Check ALL color/size variants before marking OOS — different colors can have different prices and size availability, report per variant
5. Save interesting alternatives to Backlog section
4. Track credit usage in your output file
5. Alert if approaching 80% of credit budget
6. Mark items UNVERIFIED if all tools fail (include manual-check URL)
```

---

## Credit Distribution

### Formula
```
per_agent = total_credits / (num_agents + 1_reserve)
```

### Example (500 Firecrawl, 1000 ScrapingBee, 6 agents)
| Resource | Total | Per Agent | Reserve |
|----------|-------|-----------|---------|
| Firecrawl | 500 | 71 | 71 |
| ScrapingBee | 1000 | 142 | 142 |

### Rebalancing
If a worker finishes under budget, the leader can redistribute remaining credits to workers still verifying. Send a message with the updated budget:

```python
SendMessage(
    type="message",
    recipient="goggles-researcher",
    content="Extra Firecrawl budget: you now have 90 credits (was 71)",
    summary="Redistributing Firecrawl credits"
)
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Worker stuck on one item | Message: "Skip this item, mark UNVERIFIED, move to next" |
| Worker exhausts credit budget | Message: "Switch to free tools only for remaining items" |
| Worker finds all items OOS | Complete task, note pattern in output file |
| Worker goes idle unexpectedly | Check if task is complete, send follow-up message |
| Tool MCP server goes down | Broadcast: "Switch to alternative tools, {tool} is down" |
