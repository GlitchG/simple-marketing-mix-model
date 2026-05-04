"""
Simple Marketing Mix Model — Predictive Analytics in BigQuery + Python.
No heavy Bayesian dependencies. Uses numpy/scipy only.
"""
import numpy as np
from sklearn.linear_model import LinearRegression
import matplotlib.pyplot as plt

def adstock(spend, decay, max_lag=12):
    """Geometric adstock: spend_t + spend_{t-1}*decay + spend_{t-2}*decay^2 + ..."""
    result = np.zeros_like(spend)
    for t in range(len(spend)):
        for lag in range(min(t+1, max_lag+1)):
            result[t] += spend[t-lag] * (decay ** lag)
    return result

def hill(x, alpha, gamma):
    """Hill saturation: x^a / (x^a + g^a)"""
    eps = 1e-8
    x = np.maximum(x, eps)
    return x**alpha / (x**alpha + gamma**alpha)

class SimpleMMM:
    """Lightweight MMM: adstock + saturation -> linear regression."""
    
    def __init__(self):
        self.params = {}
        self.model = None
        self.contributions = None
    
    def fit(self, spend, revenue, channels, decay_grid=np.linspace(0.1, 0.9, 20),
            alpha_grid=[1.5, 2.0, 2.5]):
        """Fit with grid search over decay and saturation parameters."""
        best_score = -np.inf
        best_result = None
        n = len(revenue)
        
        # Pre-compute gamma (median spend) per channel for Hill saturation
        gammas = [np.median(spend[:, i]) for i in range(len(channels))]
        
        for decay in decay_grid:
            for alpha in alpha_grid:
                X = np.zeros((n, len(channels) + 1))
                X[:, 0] = 1  # intercept column
                
                for i in range(len(channels)):
                    adstocked = adstock(spend[:, i], decay)
                    X[:, i+1] = hill(adstocked, alpha, gammas[i])
                
                # fit_intercept=False because we already added the intercept column
                model = LinearRegression(fit_intercept=False).fit(X, revenue)
                score = model.score(X, revenue)
                
                if score > best_score:
                    best_score = score
                    best_result = {
                        'decay': decay,
                        'alpha': alpha,
                        'gammas': gammas,
                        'coef': model.coef_,
                        'r2': score,
                        'X': X
                    }
        
        self.params = best_result
        self.model = LinearRegression(fit_intercept=False).fit(best_result['X'], revenue)
        self._calc_contributions(spend, channels)
        return self
    
    def _calc_contributions(self, spend, channels):
        coef = self.params['coef']
        self.contributions = {}
        # Baseline = intercept coefficient * number of observations
        self.contributions['Baseline'] = coef[0] * len(spend)
        for i, ch in enumerate(channels):
            # Contribution = coefficient * sum of transformed spend (Hill + adstock)
            self.contributions[ch] = coef[i+1] * self.params['X'][:, i+1].sum()
    
    def rois(self, spend, channels):
        """ROI per channel = revenue contribution / total spend."""
        rois = {}
        for i, ch in enumerate(channels):
            rev = self.contributions.get(ch, 0)
            rois[ch] = rev / spend[:, i].sum() if spend[:, i].sum() > 0 else 0
        return rois
    
    def summary(self, spend, channels):
        rois = self.rois(spend, channels)
        print("Simple MMM Results")
        print(f"  Adstock decay: {self.params['decay']:.3f}")
        print(f"  Hill alpha:    {self.params['alpha']:.2f}")
        print(f"  R-squared:     {self.params['r2']:.3f}")
        print(f"  Baseline:      {self.params['coef'][0]:.0f}")
        print("  Channel ROIs:")
        for ch in channels:
            print(f"    {ch:<12} ROI={rois[ch]:.2f}x  contrib={self.contributions.get(ch,0):.0f}")
    
    def plot_waterfall(self, save_path=None):
        fig, ax = plt.subplots(figsize=(10, 4))
        items = list(self.contributions.items())
        items.sort(key=lambda x: x[1])
        names = [x[0] for x in items]
        vals = [x[1] for x in items]
        colors = ['#2ecc71' if v > 0 else '#e74c3c' for v in vals]
        ax.barh(names, vals, color=colors)
        ax.set_xlabel('Revenue Contribution')
        ax.set_title('MMM - Channel Contribution')
        plt.tight_layout()
        if save_path:
            plt.savefig(save_path, dpi=150)

# ============================================================
if __name__ == "__main__":
    # Demo with synthetic data
    np.random.seed(42)
    n_weeks = 104
    channels = ['tv', 'digital', 'search', 'social']
    spend = np.random.gamma(2, 10, (n_weeks, len(channels)))
    base = 1000 + 200*np.sin(np.linspace(0, 4*np.pi, n_weeks))
    true_roi = [2.5, 1.8, 3.2, 0.9]
    rev = base
    for i in range(len(channels)):
        rev += adstock(spend[:, i], 0.5) * true_roi[i]
    rev += np.random.normal(0, 100, n_weeks)
    
    mmm = SimpleMMM().fit(spend, rev, channels)
    mmm.summary(spend, channels)
    mmm.plot_waterfall()
