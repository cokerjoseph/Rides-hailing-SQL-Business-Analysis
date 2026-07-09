# Ride-Hailing SQL Business Analysis

PostgreSQL analysis of a ride-hailing platform's operations data (June 2021 – December 2024), covering data cleaning and 8 business questions on riders, drivers, revenue, and cancellations.

## Dataset

Four raw tables, ~50,000 records each:

| Table | Description |
|---|---|
| `rides_raw` | Ride records: rider/driver IDs, timestamps, cities, distance, status, fare |
| `payment_raw` | Payment transactions linked to rides |
| `riders_raw` | Rider profiles and signup dates |
| `drivers_raw` | Driver profiles and ratings |

Source data: [Google Drive folder](https://drive.google.com/drive/folders/11jUavkLeNUsso4dDj886y_KZ0mlJ4Vvo)

## Data Cleaning

Built a `rides_cleaned` table (35,305 records) by:
- Removing duplicate records
- Standardizing city names (uppercase, trimmed)
- Keeping only completed rides (`amount > 0`)
- Restricting to valid date range: June 2021 – December 2024
- Removing invalid fares/distances (`<= 0`)
- Inner-joining rides with payments

## Business Questions & Key Findings

1. **Top 10 longest rides** — Longest ride was 30km, mostly Ottawa–Vancouver routes; PayPal was the most common payment method for these.
2. **2021 signups still active in 2024** — 1,815 riders retained.
3. **Quarterly revenue YoY growth** — Q2 2022 had the biggest jump (+200.08%); overall trend has been declining since.
4. **Top 5 drivers by avg. monthly rides** — Highest average was 1.73 rides/month.
5. **Cancellation rate by city** — Chicago highest at 19.26%; platform-wide average is 17.91%.
6. **Riders with 10+ rides, no cash payments** — Rider_7823 stood out.
7. **Top 3 revenue drivers per city** — Revenue leadership varies significantly by city.
8. **Bonus-eligible drivers** (30+ rides, rating ≥4.5, cancellation <5%) — Only 4 drivers qualified.

## Tools

- PostgreSQL
- Window functions (`ROW_NUMBER`), CTEs, `STRING_AGG`, date/time extraction

## Files

- [`8_Business_questions.sql`](./8_Business_questions.sql) — full schema, cleaning script, and all 8 queries
- Full write-up with query screenshots and results in the analysis report


