# Architecture — bigquery-meridian-mmm

## Stack
Python 3.10+, scikit-learn, numpy, pandas, BigQuery (data source), SQL (data prep)

## Data Flow
```
BigQuery raw tables (media spend, KPI revenue, control variables)
    → sql/01_media_spend.sql (extract weekly spend per channel)
    → sql/02_kpi_prep.sql (extract weekly revenue/target KPI)
    → sql/03_control_vars.sql (extract seasonality, price, promotions)
        → models/simple_mmm.py (adstock transform → saturation transform → OLS regression)
            → Console output: ROI per channel, R², baseline revenue
```

## File Map
- `models/simple_mmm.py` — core model: geometric adstock, Hill saturation, OLS regression, ROI calculation
- `sql/01_media_spend.sql` — BigQuery: weekly spend by channel
- `sql/02_kpi_prep.sql` — BigQuery: weekly KPI (revenue, conversions)
- `sql/03_control_vars.sql` — BigQuery: control variables (seasonality dummies, price index, promo flags)
- `requirements.txt` — numpy, pandas, scikit-learn

## Design Patterns
- **SQL for extraction, Python for modelling**: BigQuery does the heavy data prep; Python does the statistical modelling. Clean separation.
- **No PyMC dependency**: intentionally avoids Meridian's full Bayesian stack. Uses scikit-learn LinearRegression — lighter, faster, easier to explain to non-statisticians.
- **Synthetic data for demo**: simple_mmm.py generates fake 2-year data if no BigQuery connection — the model logic is testable without production access
- **Geometric adstock**: simple carryover decay (λ parameter) instead of more complex Weibull or delayed adstock — good enough for portfolio, honest about simplification
