# Site Strategies

Pattern-based anti-bot strategies for common site protection types encountered during consumer goods research. These are general patterns — not per-site configurations — that apply to categories of protection.

---

## Pattern 1: Cloudflare-Protected Sites

**Symptoms:** 403 Forbidden, "Checking your browser" page, empty response from Jina/Tavily, challenge page HTML in response.

**Examples:** Decathlon (many regions), some Amazon storefronts, various EU retailers.

**Strategy:**
```
1. ScrapingBee(url, render_js=true, premium_proxy=true)     [10 credits, best for CF]
2. Firecrawl(url, formats=["markdown"], waitFor=3000)        [1 credit, sometimes works]
3. Search-based: WebSearch/Jina("{item} site:{domain}")        [FREE, broader coverage]
4. Tavily search with include_domains=["{domain}"]            [FREE, snippets only]
5. LAST: Playwright browser_navigate → snapshot               [Slow, may still be blocked]
```

**Key insight:** ScrapingBee with premium_proxy is the most reliable Cloudflare bypass. Firecrawl sometimes succeeds with longer waitFor. If both fail, use search-based approach to get pricing from snippets (less reliable but free).

---

## Pattern 2: JS-Rendered Size/Variant Selectors

**Symptoms:** Page loads but sizes/variants are missing. Jina returns product description without size availability. Price visible but stock status invisible.

**Examples:** Specialized outdoor stores (8a.pl), fashion retailers with color pickers, electronics stores with configuration dropdowns.

**Strategy:**
```
1. Firecrawl(url, formats=["markdown"], waitFor=2000)        [1 credit, renders JS]
2. ScrapingBee(url, render_js=true)                           [5 credits, full render]
3. Jina(url) — check for indirect signals:                    [FREE]
   - "Powiadom mnie" / "Notify me" = OOS
   - "Dodaj do koszyka" / "Add to cart" = in stock
   - "Ostatnia sztuka" / "Last piece" = limited stock
   - "Produkt już nie wróci" / "Won't restock" = permanently OOS
4. Search for variant URLs: "{brand} {model} {color} site:{domain}"
5. LAST: Playwright → navigate → click size selector → snapshot
```

**Key insight:** Even when JS sizes aren't rendered, stock status text often appears in the raw HTML. Look for translated OOS indicators in the user's language.

---

## Pattern 3: Marketplace Anti-Bot (Allegro, Amazon, eBay)

**Symptoms:** Aggressive bot detection, CAPTCHAs, blank pages, redirects to login/verification pages.

**Examples:** Allegro.pl, Amazon (various TLDs), eBay, Mercado Libre, Rakuten.

**Strategy:**
```
1. Search-based (DON'T scrape product pages directly):
   - WebSearch("{item} {marketplace_name}")                    [FREE, built-in]
   - Jina search("{item} site:{marketplace}")                  [FREE, MCP]
   - Tavily search(query, include_domains=["{marketplace}"])   [FREE, MCP]
   - Firecrawl(listing_url, waitFor=3000)                      [1 credit, search results]
   - ScrapingBee(listing_url, render_js=true, premium_proxy=true)
2. Parse search result snippets for prices and availability
3. LAST: Playwright → navigate to search → snapshot results
```

**Key insight:** Marketplace product pages have the heaviest anti-bot. Search result pages and listing pages are much easier to access. Search for the item on the marketplace rather than scraping individual product URLs.

---

## Pattern 4: Simple HTML Sites

**Symptoms:** Clean, fast-loading pages. No JavaScript required for content. Standard HTML structure.

**Examples:** Bergfreunde.eu, many EU outdoor stores, independent retailers, aggregator sites like Ceneo.

**Strategy:**
```
1. WebFetch(url, prompt="extract price, sizes, stock")        [FREE, built-in]
2. Jina(url)                                                   [FREE, MCP]
3. Tavily extract(urls=[url])                                  [FREE, MCP]
```

**Key insight:** Don't waste paid tool credits on simple sites. WebFetch handles most clean HTML retailers as the built-in baseline. Jina and Tavily are free MCP enhancements if WebFetch returns incomplete data.

---

## Pattern 5: Price Aggregators / Comparison Sites

**Symptoms:** Pages list multiple stores with prices. Data is aggregated, not direct product pages.

**Examples:** Ceneo.pl, PriceRunner, Idealo, Google Shopping.

**When to use:** Check aggregators FIRST for each item — before searching individual stores. One aggregator page can replace 5-10 individual store lookups.

**Strategy:**
```
1. Search aggregator: WebSearch("{item} site:{aggregator_domain}")  [FREE, built-in]
   or navigate directly: {aggregator_domain}/search?q={item}
2. WebFetch(aggregator_url, prompt="extract stores, prices, availability")  [FREE, built-in]
3. Jina(aggregator_url) if WebFetch returns incomplete data         [FREE, MCP]
4. Parse for: store name, price, stock status, "Go to store" links
5. Verify best prices on actual stores (follow link, apply appropriate pattern)
```

**Key insight:** Aggregator data is excellent for finding which stores carry an item and approximate pricing, but prices may be cached/stale. Always verify the final price on the actual store for items you plan to recommend.

---

## General Anti-Bot Principles

1. **Respect rate limits.** Space requests to the same domain. Don't hammer a site with 20 requests in 10 seconds.

2. **Start with the lightest tool.** Free API tools leave no browser fingerprint. Only escalate when necessary.

3. **Search before scrape.** For anti-bot sites, search results are easier to access than product pages. Get what you can from search snippets first.

4. **Check multiple domains.** If one store blocks you, try the same item at another retailer. Don't burn credits fighting one site.

5. **Look for indirect signals.** Stock status text, "notify me" buttons, and "last piece" warnings often appear even when JS rendering fails.

6. **Record what works.** Note which tool succeeded for each domain in the tool usage log. This helps the team learn which strategy works for which stores.

---

## Common OOS Indicators by Language

| Language | In Stock | OOS / Notify | Permanently Gone | Last Piece |
|----------|----------|-------------|------------------|------------|
| Polish | Dodaj do koszyka | Powiadom mnie | Produkt już nie wróci | Ostatnia sztuka |
| German | In den Warenkorb | Benachrichtigen | Nicht mehr verfügbar | Letztes Stück |
| English | Add to cart | Notify me | Discontinued | Last one |
| French | Ajouter au panier | Prévenir | Indisponible | Dernier article |
| Spanish | Añadir al carrito | Avísame | Agotado | Última unidad |
