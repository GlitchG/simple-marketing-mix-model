# Marketing Mix Modeling in BigQuery

A modest attempt at answering a question every marketer asks: which channels actually drive revenue, and by how much?

## Why this exists

I kept running into the same problem with clients: everyone has Google Ads, Facebook Ads, maybe some TV or radio — but nobody knows which channel is pulling its weight. Attribution tools (last-click, data-driven) answer a different question. What you really want is: "if I move €1,000 from Facebook to Google, what happens to revenue?"

That's what Marketing Mix Modeling does. Google released an open-source library called Meridian for this. This project walks through the thinking — but using simple regression instead of Bayesian PyMC models so anyone can run it.

## How it works

The model has three ideas:

**1. Adstock (carryover)**
A TV ad doesn't stop working the moment it airs. People remember it. So spend in week N contributes to revenue in weeks N, N+1, N+2, etc — decaying over time. A geometric decay does the job.

**2. Saturation (diminishing returns)**
Doubling your Facebook budget doesn't double revenue. The 100th impression reaches someone who has already seen 99. A Hill function models this: revenue flattens as spend increases.

**3. Linear regression on transformed spend**
Once you adstock-transform and saturation-transform your spend columns, you fit an ordinary regression against revenue. The coefficients are your channel effectiveness estimates.

## Try it

```bash
git clone https://github.com/GlitchG/bigquery-meridian-mmm.git
cd bigquery-meridian-mmm
pip install -r requirements.txt
python models/simple_mmm.py
```

The demo generates synthetic 2-year weekly data with 4 channels, fits the model, and prints ROI per channel:

```
Simple MMM Results
  Adstock decay: 0.500
  R²: 0.972
  Channel ROIs:
    tv           ROI=2.47x
    digital      ROI=1.82x
    search       ROI=3.14x
    social       ROI=0.91x
```

Search is the best performer. Social barely breaks even. That's the kind of insight this model gives — and it took seconds to compute.

## Step-by-step guide

### Step 1: Get your data into BigQuery

Three SQL views prepare everything:

```
sql/01_media_spend.sql   → Weekly spend per channel (Facebook, Google, TikTok, TV, Radio, OOH)
sql/02_kpi_prep.sql      → Weekly revenue from GA4 ecommerce
sql/03_control_vars.sql  → Holidays, seasonality, Black Friday
```

Run these in your BigQuery console. They're built against GA4's public sample dataset, so you can test without setting up your own data.

### Step 2: Export to Python

```sql
-- Export weekly data with all columns
SELECT 
  m.week_start, m.channel, m.spend, m.impressions,
  k.revenue, k.sessions,
  c.is_holiday, c.black_friday_week
FROM `your_project.marketing_mmm.weekly_media_spend` m
JOIN `your_project.marketing_mmm.weekly_kpi` k USING (week_start)
JOIN `your_project.marketing_mmm.weekly_controls` c USING (week_start)
```

Save as CSV, or connect directly with the BigQuery Python client.

### Step 3: Fit the model

```python
import pandas as pd
from models.simple_mmm import SimpleMMM

data = pd.read_csv("mmm_data.csv")
channels = ['tv', 'digital', 'search', 'social', 'tiktok', 'ooh']

# Pivot spend into wide format
spend = data.pivot(index='week_start', columns='channel', values='spend')[channels].values
revenue = data.groupby('week_start')['revenue'].sum().values

mmm = SimpleMMM().fit(spend, revenue, channels)
mmm.summary(spend, channels)
mmm.plot_waterfall()
```

### Step 4: Interpret

- **ROI > 1.5**: Channel is profitable. Increase spend.
- **ROI ~ 1.0**: Break-even. Keep if it has branding value.
- **ROI < 0.8**: Losing money. Cut or redesign.
- **R²**: How much of revenue variance the model explains. Above 0.7 is decent.

## Limitations (be honest about these)

- **Correlation ≠ causation.** If you always run TV and search ads simultaneously, the model can't fully separate them.
- **No cross-channel effects.** A TV ad might make people Google you. This model doesn't capture that.
- **Assumes linear response after transformations.** Real marketing is messier.
- **Needs 1-2 years of weekly data.** Less than that, and the seasonality adjustment won't work well.

This model is a starting point — good for directional decisions, budget discussions, and showing the CFO that you're thinking quantitatively. If you need precision at scale, use Google Meridian's full Bayesian implementation.

## Files

```
sql/01_media_spend.sql         — Extract weekly spend by channel
sql/02_kpi_prep.sql            — Revenue from GA4
sql/03_control_vars.sql        — Seasonality & holidays
models/simple_mmm.py           — Adstock → saturation → regression
requirements.txt               — numpy, pandas, scipy, scikit-learn, matplotlib
```

## Related projects

- [Cohort Log-Predict](https://github.com/GlitchG/cohort-log-predict) — 2-point retention forecasting
- [GA4 Attribution Models](https://github.com/GlitchG/ga4-attribution-models) — SQL-based attribution
- [Marketing Analytics dbt](https://github.com/GlitchG/marketing_analytics_sample_reporting) — dbt pipeline

---

MIT License
