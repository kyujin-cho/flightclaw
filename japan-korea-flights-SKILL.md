---
name: japan-korea-flights
description: >
  Search for flights from Japan to South Korea across all known nonstop airport pairs.
  Use this skill whenever the user asks about flights from Japan to Korea, Japan to Seoul,
  Japan to Busan, or any flight search involving Japanese airports and Korean destinations.
  Also trigger when the user mentions flying from specific Japanese cities (Tokyo, Osaka,
  Fukuoka, Sapporo, Nagoya, Okinawa, etc.) to Korean cities (Seoul, Busan, Daegu, Jeju, etc.),
  or asks about the cheapest way to fly between the two countries. This skill knows every
  nonstop airport pair and searches them efficiently in batches.
---

# Japan → Korea Flight Search Skill

## Overview

This skill searches for economy flights from Japan to South Korea across all known nonstop
routes. It uses a pre-built airport route map to avoid redundant lookups, batching searches
efficiently via the `flightclaw:search_flights` tool.

## Airport Route Map

Below is the complete set of Japanese origin airports with nonstop service to South Korean
destinations, current as of early 2026. Some routes are seasonal (noted below) and may not
return results on every date.

### Korean Destination Airports

| Code | Airport                    | City       |
|------|----------------------------|------------|
| ICN  | Incheon International      | Seoul      |
| GMP  | Gimpo International        | Seoul      |
| PUS  | Gimhae International       | Busan      |
| TAE  | Daegu International        | Daegu      |
| CJU  | Jeju International         | Jeju       |
| CJJ  | Cheongju International     | Cheongju   |

### Japanese Origin Airports → Korean Destinations

The table below maps each Japanese airport to the Korean airports it serves nonstop.
Use this to construct search queries — no need to search routes that don't exist.

#### Major Hubs (high frequency, many airlines)

| Code | Airport / City              | Nonstop to            |
|------|-----------------------------|-----------------------|
| NRT  | Narita / Tokyo              | ICN, PUS, TAE, CJU¹, CJJ¹ |
| HND  | Haneda / Tokyo              | ICN, GMP              |
| KIX  | Kansai / Osaka              | ICN, PUS              |
| FUK  | Fukuoka                     | ICN, PUS              |
| CTS  | New Chitose / Sapporo       | ICN                   |
| OKA  | Naha / Okinawa              | ICN                   |
| NGO  | Chubu Centrair / Nagoya     | ICN                   |

¹ NRT→CJU and NRT→CJJ typically require a connection (via PUS or ICN), but Korean Air
operates seasonal nonstop NRT→CJU. Include in search but expect connecting results.

#### Regional Airports (lower frequency, 1–2 airlines)

| Code | Airport / City              | Nonstop to     | Notes               |
|------|-----------------------------|----------------|----------------------|
| KOJ  | Kagoshima                   | ICN            | KE, seasonal 7C/ZE   |
| KMJ  | Kumamoto                    | ICN            | KE, TW               |
| HIJ  | Hiroshima                   | ICN            | 7C                   |
| SDJ  | Sendai                      | ICN            | OZ                   |
| MYJ  | Matsuyama                   | ICN, PUS       | 7C (ICN), BX (PUS)  |
| NGS  | Nagasaki                    | ICN, PUS²      | KE, BX seasonal     |
| UKB  | Kobe                        | ICN            | KE                   |
| KIJ  | Niigata                     | ICN³           | KE (low freq)       |
| OKJ  | Okayama                     | ICN            | KE                   |
| KMQ  | Komatsu / Kanazawa          | ICN³           | KE (low freq)       |
| OIT  | Oita                        | ICN            | 7C                   |
| KMI  | Miyazaki                    | ICN            | OZ                   |
| AOJ  | Aomori                      | ICN            | KE                   |
| TAK  | Takamatsu                   | ICN            | RS, LJ               |
| HSG  | Saga                        | ICN            | TW                   |
| FSZ  | Shizuoka                    | ICN            | 7C                   |
| YGJ  | Yonago                      | ICN            | RS                   |
| TKS  | Tokushima                   | ICN³           | ZE (low freq)       |
| HKD  | Hakodate                    | ICN³           | 7C seasonal          |
| SHI  | Shimojishima                | ICN            | LJ                   |
| ISG  | Ishigaki                    | ICN³           | LJ (low freq)       |
| UBJ  | Ube                         | ICN³           | OZ (new, Feb 2026)  |
| IBR  | Ibaraki                     | ICN            | RF seasonal (Feb–Mar)|
| OBO  | Obihiro                     | ICN³           | RF seasonal (Feb–Mar)|

² NGS→PUS is seasonal and may not return nonstop results.
³ These airports have very low frequency nonstop service. Searches may only return
connecting flights on many dates. Still worth including for completeness.

### Airline Codes Reference

| Code | Airline          | Type     |
|------|------------------|----------|
| KE   | Korean Air       | FSC      |
| OZ   | Asiana Airlines  | FSC      |
| NH   | ANA              | FSC      |
| JL   | JAL              | FSC      |
| 7C   | Jeju Air         | LCC      |
| LJ   | Jin Air          | LCC      |
| TW   | Tway Air         | LCC      |
| BX   | Air Busan        | LCC      |
| RS   | Air Seoul        | LCC      |
| ZE   | Eastar Jet       | LCC      |
| MM   | Peach Aviation   | LCC      |
| RF   | Aero K           | LCC      |
| ZG   | ZIPAIR           | LCC      |
| NQ   | Air Japan        | LCC      |
| YP   | Air Premia       | Hybrid   |

## Search Strategy

The flightclaw:search_flights tool accepts up to 5 comma-separated origin codes and up to
5 comma-separated destination codes per call. Use this to batch searches efficiently.

### Batching Plan

Organize searches into batches. Each batch should group origins that share the same
destination set, up to 5 origins per call. Here's the recommended batching:

**Batch 1 — Major hubs → ICN** (the most popular route)
```
origins: NRT,KIX,FUK,CTS,OKA    dest: ICN
origins: NGO,KOJ,KMJ,HIJ,SDJ    dest: ICN
origins: MYJ,UKB,OIT,KMI,AOJ    dest: ICN
origins: TAK,HSG,FSZ,YGJ,SHI    dest: ICN
origins: IBR,NGS,OKJ,HKD,TKS    dest: ICN  (low-freq group, may have few nonstops)
origins: ISG,UBJ,OBO,KIJ,KMQ    dest: ICN  (low-freq group)
```

**Batch 2 — HND → GMP** (Haneda–Gimpo is a unique city-center route)
```
origins: HND    dest: GMP
```

**Batch 3 — PUS routes** (Busan nonstops from select airports)
```
origins: NRT,KIX,FUK,MYJ    dest: PUS
```

**Batch 4 — TAE, CJU, CJJ from NRT** (Daegu/Jeju/Cheongju, NRT-only nonstops)
```
origins: NRT    dest: TAE,CJU,CJJ
```

Total: ~10 search calls to cover all routes comprehensively.

### Parameters

- **adults**: Default 1 unless user specifies
- **cabin**: Default ECONOMY unless user specifies
- **date**: Required — ask user if not provided
- **sort_by**: Use CHEAPEST to surface best deals
- **results**: Use 3–5 per route for manageable output. Use more (up to 10) if user wants
  comprehensive listings.

### Handling User Filters

If the user narrows the search:
- **Specific origin city**: Only search routes from that airport (e.g., "from Osaka" → KIX only)
- **Specific destination**: Only search routes to that airport (e.g., "to Busan" → PUS only)
- **Price cap**: Use `max_price` parameter
- **Nonstop only**: Use `stops: NON_STOP`
- **Specific airline**: Use `airlines` parameter with IATA code

When the user asks broadly ("flights from Japan to Korea"), run the full batch plan.
When they ask narrowly ("cheapest flight from Fukuoka to Seoul"), run only FUK → ICN,GMP.

## Google Flights Booking Links

Every flight result should include a clickable link to the corresponding Google Flights
search page so the user can easily book. Construct the URL as follows:

### URL Format

```
https://www.google.com/travel/flights?hl=en#flt={ORIGIN}.{DEST}.{DATE};c:KRW;e:{CABIN_CODE};sd:1;t:f
```

**Parameters:**
- `{ORIGIN}` — 3-letter IATA code of departure airport (e.g., `NRT`)
- `{DEST}` — 3-letter IATA code of arrival airport (e.g., `ICN`)
- `{DATE}` — Departure date in `YYYY-MM-DD` format (e.g., `2026-03-05`)
- `{CABIN_CODE}` — Cabin class: `1` = Economy, `2` = Premium Economy, `3` = Business, `4` = First
- `sd:1` — One-way flight. For round trips, omit `sd:1` and append the return segment:
  `flt={ORIGIN}.{DEST}.{DATE}.{DEST}.{ORIGIN}.{RETURN_DATE}`
- `t:f` — Type: flight

**Example (one-way economy, FUK→ICN on 2026-03-05):**
```
https://www.google.com/travel/flights?hl=en#flt=FUK.ICN.2026-03-05;c:KRW;e:1;sd:1;t:f
```

### How to Include in Tables

Add a **Book** column to every flight results table. Use a markdown link with a ✈️ emoji
or short text like `[Book ➜](url)`. Example:

```markdown
| Route | Flight | Price | Book |
|-------|--------|-------|------|
| FUK→ICN | TW 260 | ₩198,400 | [Book ➜](https://www.google.com/travel/flights?hl=en#flt=FUK.ICN.2026-03-05;c:KRW;e:1;sd:1;t:f) |
```

Always construct the link using the specific origin, destination, and date from the search,
and match the cabin class the user requested.

---

## Output Format

After collecting all results, present them in this structure:

### 1. Top 10 Cheapest Nonstop Flights (ranked table)

Show rank, route, flight number, airline name, departure→arrival times, duration, price,
and a Google Flights **Book** link (see above).
Highlight the overall cheapest with an emoji (🥇🥈🥉).

### 2. Breakdown by Origin Airport

Group results by origin, showing all nonstop options with prices and **Book** links.
Use sub-tables for each major hub and a combined table for regional airports.

### 3. Summary

At the end, provide:
- Cheapest overall route and price
- Shortest flight time
- Airport with most options
- Note any airports that had no nonstop service on the searched date

### 4. Follow-up Offer

Always offer to:
- Track specific routes for price drops (`flightclaw:track_flight`)
- Search different dates (`flightclaw:search_dates` for cheapest date in a range)
- Filter results further (airline, time of day, etc.)

## Important Notes

- Prices from the API may be in KRW (₩), USD ($), or occasionally show as ₩0 / $0 for
  routes where pricing data is unavailable. Flag these to the user as "price not available."
- Some seasonal routes (HKD, IBR, OBO, NGS→PUS) may return no results or only connecting
  flights outside their operating season.
- The KIJ (Niigata) and KMQ (Komatsu) nonstops to ICN are very low frequency and often
  only return connecting itineraries. Don't be surprised if no nonstop shows up.
- Always mention that Gimpo (GMP) is closer to central Seoul than Incheon (ICN) — this
  is useful context for travelers.
