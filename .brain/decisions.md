# Architecture Decisions — bigquery-meridian-mmm

> Every decision with rationale and trade-offs.

## Decision Log

| Date | Decision | Rationale | Trade-offs |
|------|----------|-----------|------------|
| 2026-04 | Frequentist over Bayesian | Meridian (Google's official MMM) uses Bayesian inference. This repo uses OLS regression. Rationale: simpler to explain, faster to run, no MCMC convergence diagnostics needed. Portfolio target is analysts who know regression, not Bayes. | Loses full posterior distributions. Can't express uncertainty in ROI estimates as naturally. |
| 2026-04 | No PyMC dependency | Meridian requires PyMC, which needs a C compiler and can be heavy. This repo uses only numpy + scikit-learn — pip install in seconds. | Less statistically rigorous. No hierarchical priors for pooling across geos. |
| 2026-04 | Geometric adstock only | Single-parameter decay (λ). Weibull, delayed adstock, and other functional forms are excluded. | Less flexible for channels with long lag times (TV, radio). Adequate for digital channels with 1-4 week carryover. |
| 2026-04 | SQL for data prep | Three separate .sql files for spend, KPI, and controls. Each is independently runnable and reviewable. Analysts can inspect the SQL before trusting the Python model output. | Requires BigQuery access. Demo mode uses synthetic data to bypass this. |
| 2026-04 | Synthetic data demo mode | `simple_mmm.py` generates fake data if no BigQuery connection is provided. The model logic is testable without production data. | Demo data is too clean — real data has more noise and missing weeks. README warns about this honestly. |
| 2026-04 | This is a light MMM, not a full one | README is explicit: this is a simpler version of Meridian. It keeps the core ideas (adstock, saturation) but skips the Bayesian engine. Honest about limitations. | Some hiring managers may expect a full MMM. README positioning ("lighter version") sets expectations correctly. |
| 2026-04-30 | .brain/ folder added | AI agent context. | Extra files. |
