# Marketing Mix Model — Lightweight

A **lightweight Marketing Mix Model** using adstock transformation, Hill saturation, and ordinary least squares regression. No Meridian, no PyMC — just numpy, scipy, and scikit-learn.

I built this because I got tired of explaining the difference between attribution and incrementality to clients. This is the *simpler* version — if you want the full Bayesian approach with Google's Meridian library, see [bigquery-meridian-mmm](https://github.com/GlitchG/bigquery-meridian-mmm).

## The basic idea

Three things happen when you run an ad:

1. It works for a while. A TV spot doesn't just affect the day it airs — people remember it, talk about it, search for your brand later. This is called **adstock** or carryover. I model it as geometric decay: the impact of week N fades by a fixed percentage each subsequent week.

2. It has diminishing returns. Your first 100 impressions reach new people. Your next 100 reach some of the same people. A Hill function captures this — spend goes up, response goes up, but slower and slower until it plateaus.

3. You can take those transformed spend columns and fit them against revenue with ordinary least squares. The coefficients tell you how much each channel contributes per euro spent.

That's the whole model. No neural nets, no gradient boosting. Just domain knowledge encoded as math.

## Running it

```bash
git clone https://github.com/GlitchG/bigquery-meridian-mmm.git
cd bigquery-meridian-mmm
pip install -r requirements.txt
python models/simple_mmm.py
```

The demo generates fake 2-year data and fits the model. Output looks like:

```
Simple MMM Results
  Adstock decay: 0.500
  R²: 0.972
  Baseline: 1012
  Channel ROIs:
    tv           ROI=2.47x
    digital      ROI=1.82x
    search       ROI=3.14x
    social       ROI=0.91x
```

Search delivers €3.14 for every euro. Social barely breaks even. If this were real, I'd be looking at reallocating budget.

## How to use it with your own data

There are three SQL files that prepare everything in BigQuery. They're written against GA4's public sample dataset, so you can test them without your own data.

### 1. Get media spend by channel

`sql/01_media_spend.sql` pulls weekly spend, impressions, and clicks from Facebook, Google, TikTok, TV, radio, and OOH tables. If you don't have some of these channels, just comment out that `UNION ALL` block.

### 2. Get your KPI

`sql/02_kpi_prep.sql` extracts weekly revenue from GA4 ecommerce events. Transactions, average order value, conversion rate — the basics. If your KPI is something else (subscriptions, leads, trial starts), swap out the metric.

### 3. Add control variables

`sql/03_control_vars.sql` generates a table of week-level flags: Portuguese holidays, Black Friday week, summer period, month numbers for seasonality. Without these, the model might attribute December's organic spike to whatever ads happened to run in December.

### 4. Export and fit

Run a JOIN query to merge all three tables, export as CSV, then:

```python
import pandas as pd
from models.simple_mmm import SimpleMMM

data = pd.read_csv("mmm_data.csv")
channels = ['tv', 'digital', 'search', 'social', 'tiktok', 'ooh']

spend = data.pivot(index='week_start', columns='channel', values='spend')[channels].values
revenue = data.groupby('week_start')['revenue'].sum().values

mmm = SimpleMMM().fit(spend, revenue, channels)
mmm.summary(spend, channels)
```

### 5. Understanding the numbers

- ROI above 1.5: the channel is probably making money. Consider spending more there.
- ROI near 1.0: it's paying for itself but not much else. Might be worth keeping for brand awareness.
- ROI below 0.8: losing money. Either the creative is bad, the targeting is off, or the channel doesn't work for your product.
- R²: how much of revenue's ups and downs the model captures. 0.7+ is decent for marketing data. Below 0.5 means there's a lot going on that your channels alone don't explain — seasonality, PR, competitor moves.

## What this model doesn't do

It does not prove causation. If you always launch search ads and TV ads together, the model can't cleanly separate them. It sees correlation and splits the credit proportionally.

It doesn't model cross-channel effects. A TV ad might make someone Google you, which shows up as a search conversion. This model assigns that to search, not TV. No easy fix for that without experiments.

It needs at least a year of weekly data to capture seasonality properly. Less than that, and the control variables won't help much.

For most small to mid-size businesses, this is enough to make better budget decisions than "we spent the same as last quarter." If you need more precision, use Google Meridian directly — it handles all the uncertainty properly with Bayesian methods.

## Files

```
sql/01_media_spend.sql       — Weekly spend: Facebook, Google, TikTok, TV, Radio, OOH
sql/02_kpi_prep.sql          — Weekly revenue from GA4 ecommerce
sql/03_control_vars.sql      — Holidays, seasonality, Black Friday
models/simple_mmm.py         — Adstock + saturation + regression model
requirements.txt             — numpy, pandas, scipy, scikit-learn, matplotlib
```

## Other projects

- [GA4 Attribution Models](https://github.com/GlitchG/ga4-attribution-models) — SQL attribution models
- [Landing Page AB Testing](https://github.com/GlitchG/landing-page-ab-testing) — statistical AB test analysis
- [Cohort Log-Predict](https://github.com/GlitchG/cohort-log-predict) — retention forecasting from 2 points

---

MIT
