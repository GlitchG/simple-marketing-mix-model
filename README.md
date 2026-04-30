# Meridian MMM — Marketing Mix Modeling in BigQuery

**Bayesian Marketing Mix Modeling using Google Meridian + BigQuery**

[![Python](https://img.shields.io/badge/Python-3.10+-blue?logo=python)](https://python.org)
[![BigQuery](https://img.shields.io/badge/BigQuery-Warehouse-4285F4?logo=googlecloud)](https://cloud.google.com/bigquery)
[![Meridian](https://img.shields.io/badge/Meridian-MMM-orange?logo=google)](https://developers.google.com/meridian)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A portfolio project demonstrating **predictive marketing analytics** using Google's [Meridian](https://developers.google.com/meridian) — an open-source Bayesian Marketing Mix Modeling framework — with BigQuery as the data warehouse.

**Why Meridian?** Unlike traditional MMM (which gives point estimates), Meridian uses Bayesian inference to provide **full posterior distributions** for every channel's ROI — so you know not just *what* works, but *how certain* you are.

---

## 📖 What You'll Learn

- ✅ **Media data modeling** — structure spend/impression data for MMM
- ✅ **Bayesian MMM** — build a Meridian model with priors, saturation curves, and carryover
- ✅ **Posterior analysis** — interpret ROI distributions, channel contributions
- ✅ **Budget optimization** — use the fitted model to optimize spend allocation
- ✅ **BigQuery → Python pipeline** — production-ready data flow

---

## 🏗 Architecture

```
bigquery-meridian-mmm/
├── sql/
│   ├── 01_media_spend.sql          # Extract media spend by channel/week
│   ├── 02_kpi_prep.sql             # Prepare KPI (revenue/conversions)
│   └── 03_control_vars.sql         # Seasonality, price, promotions
├── models/
│   ├── meridian_model.py           # Core Meridian model definition
│   ├── budget_optimizer.py         # Spend allocation optimization
│   └── diagnostics.py              # Model fit diagnostics
├── notebooks/
│   └── mmm_analysis.ipynb          # Full walkthrough notebook
├── docs/
│   └── methodology.md              # MMM theory + assumptions
├── .github/workflows/
│   └── test-model.yml              # CI/CD: validate model on sample data
├── requirements.txt
└── README.md
```

**Data flow:**
```
BigQuery (raw) → SQL prep → pandas DataFrame → Meridian Model → Posterior ROI distributions → Budget optimizer
```

---

## 🚀 Quick Start

```bash
pip install -r requirements.txt
```

```python
from models.meridian_model import MeridianMMM

# Load data from BigQuery
mmm = MeridianMMM(data_path="sample_data.csv")
mmm.fit()
mmm.summary()
mmm.plot_waterfall()
mmm.optimize_budget(budget=100000)
```

---

## 📊 Model Details

### Channels Modeled
- TV, Radio, Digital Display, Paid Search, Social, OOH
- Each with: spend, impressions, GRPs

### Bayesian Priors
- **β (beta)** — channel effectiveness (HalfNormal prior)
- **λ (lambda)** — adstock/carryover decay rate (Beta prior, 0.3–0.9)
- **α (alpha)** — saturation curve steepness (HalfNormal prior)

### Outputs
| Output | Description |
|--------|-------------|
| ROI posterior | Distribution of revenue per €1 spent |
| mROI | Marginal ROI — impact of next €1 |
| Contribution % | Share of total KPI by channel |
| Saturation curves | Diminishing returns visualization |
| Response curves | Lagged effect over weeks |

---

## 🧪 Sample Data

Includes synthetic 2-year weekly data:
- 6 media channels
- Revenue + seasonal control variables
- Realistic noise and adstock effects

---

## 📈 Budget Optimizer

Given a fitted model:
```python
optimizer = BudgetOptimizer(model=mmm)
result = optimizer.optimize(
    total_budget=100000,
    constraints={
        'tv': (10000, 40000),
        'digital': (5000, 30000)
    }
)
# → Optimal allocation per channel
```

---

## 🛠 Tech Stack

- **Meridian** — Bayesian MMM (PyMC backend)
- **BigQuery** — data warehouse
- **Python** — modeling + optimization
- **Pandas / NumPy** — data wrangling
- **ArviZ** — Bayesian diagnostics
- **Matplotlib / Seaborn** — visualization

---

## 📁 Related Projects
- [GA4 Attribution Models](https://github.com/GlitchG/ga4-attribution-models)
- [Marketing Analytics dbt](https://github.com/GlitchG/marketing_analytics_sample_reporting)
- [Cohort Log-Predict](https://github.com/GlitchG/cohort-log-predict)

---

## 📄 License
MIT © 2026 Gleb Baraniuk
