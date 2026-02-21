# External AI Prompts

Parameterized prompt templates for when the user prefers to use an external AI tool (ChatGPT Deep Research, Gemini Deep Research, Claude Extended Thinking) for Stage 2 industry research.

---

## When to Use

- User prefers Path B in Stage 2
- Tool level is 0-1 (no MCP web tools available)
- Research scope is very broad (many categories, many items)
- User wants the deepest possible research coverage

---

## Main Research Prompt Template

Fill in the variables from Stage 1 requirements, then give the complete prompt to the user to paste into their chosen AI tool.

### Variables

| Variable | Source | Example |
|----------|--------|---------|
| `{CATEGORY}` | Product domain from Stage 1 | ski equipment |
| `{SUBCATEGORIES}` | Specific product types | helmets, jackets, fleeces, goggles, gloves, balaclavas |
| `{COUNTRY}` | User's country | Poland |
| `{LANGUAGE}` | User's language | Polish |
| `{CURRENCY}` | Local currency | PLN (zł) |
| `{BUDGET}` | Budget range per category | 200-800 zł per item |
| `{PRIORITY}` | Quality/value/balance | price-quality balance |
| `{SPECIFIC_REQUIREMENTS}` | Domain-specific needs | Size M or L, MIPS certification for helmets |
| `{REVIEW_SITES}` | Authoritative sources | outdoorgearlab.com, switchbacktravel.com |
| `{STORES}` | Local + international stores | 8a.pl, bergfreunde.eu, decathlon.pl, allegro.pl |
| `{ITEMS_PER_CATEGORY}` | How many items to find | 8-12 |

### Prompt

```
I need to research {CATEGORY} for purchase in {COUNTRY}.

## What I Need

Find the best {ITEMS_PER_CATEGORY} items per subcategory for:
{SUBCATEGORIES}

## Requirements
- Budget: {BUDGET} per item (in {CURRENCY})
- Priority: {PRIORITY}
- Specific needs: {SPECIFIC_REQUIREMENTS}

## Research Sources

Consult these review sites for expert recommendations:
{REVIEW_SITES}

Also check availability on these stores (which ship to {COUNTRY}):
{STORES}

## For Each Item, Provide

| Field | Description |
|-------|-------------|
| Brand + Model | Full product name |
| Category | Which subcategory |
| Price Range | In {CURRENCY} if possible, or EUR/USD |
| Where to Buy | Store name + URL (stores that ship to {COUNTRY}) |
| Review Score | From which source |
| Why Recommended | 1-2 sentence justification |
| Key Specs | Most relevant specifications |

## Output Format

Return results as a markdown table per subcategory. Include:
1. Table with all columns above
2. Brief notes on each subcategory (what to look for, common pitfalls)
3. Any seasonal or timing considerations (sales, new model releases)

## Important

- Focus on items actually available for purchase in {COUNTRY}
- Prefer items from stores that ship to {COUNTRY} with reasonable delivery
- Search in both {LANGUAGE} and English for best coverage
- Include both budget and premium options within the range
- Note if any items are end-of-season clearance (may sell out fast)

After you provide results, I will verify prices and availability using
automated tools. Please prioritize finding specific, purchasable items
with URLs rather than general recommendations.
```

---

## Generating the Prompt

When generating this prompt for the user:

1. Fill ALL variables from Stage 1 requirements
2. Remove any subcategories not relevant to the user's request
3. Adjust `{ITEMS_PER_CATEGORY}` based on scope (fewer for focused research, more for broad)
4. Add any domain-specific instructions from `expert-questions.md`
5. Present the filled prompt to the user with instructions:

```
Here's a research prompt you can paste into ChatGPT Deep Research,
Gemini Deep Research, or Claude with extended thinking.

[filled prompt]

After you get results, come back here and paste the item list.
I'll verify prices, check size/variant availability, and find
the best deals across your local marketplaces.
```
