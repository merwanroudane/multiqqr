# mqqr — Multivariate Quantile-on-Quantile Regression

> **Author / maintainer:** Dr Merwan Roudane &nbsp;&middot;&nbsp;
> <merwanroudane920@gmail.com> &nbsp;&middot;&nbsp;
> Repo: <https://github.com/merwanroudane/multiqqr>

`mqqr` implements the Multivariate Quantile-on-Quantile Regression (m-QQR)
of Sinha et al. (2023), extending the bivariate QQR framework of Sim and
Zhou (2015) with exogenous moderators and optional interaction terms. For
each pair of quantile levels (theta, tau), the package fits a
locally-weighted quantile regression of `y` on the principal regressor
`x`, a lagged dependent variable, moderators `Z` and `x * Z`
interactions, with Gaussian kernel weights on the empirical-CDF distance.

The default colour scale for all 3D surfaces, heatmaps and contour plots
is MATLAB Parula.

## Installation

```r
# from CRAN (once accepted)
install.packages("mqqr")

# development version
# install.packages("remotes")
remotes::install_github("merwanroudane/multiqqr")

# from a local source tarball
install.packages("mqqr_1.0.0.tar.gz", repos = NULL, type = "source")
```

## Quick start

```r
library(mqqr)

set.seed(1)
n <- 200
x <- rnorm(n)
z <- rnorm(n)
y <- 0.3 * x + 0.2 * z + 0.1 * x * z + rnorm(n, sd = 0.4)

fit <- mqq_regression(y, x, moderators = list(Z = z),
                      n_boot = 100)
print(fit)
summary(fit)

# 3D surface of beta1(theta, tau) with MATLAB Parula
plot_mqq_3d(fit, value = "beta1", colorscale = "Parula")

# Heatmap with significance stars
plot_mqq_heatmap(fit, value = "beta1", show_stars = TRUE)

# Moderator interaction surface
plot_mqq_interaction(fit, "Z", value = "gamma", kind = "heatmap")
```

## Colour scales

The MATLAB Parula colormap is reproduced exactly from its 64 RGB stops.
Built-in palettes:

```r
mqqr_colorscales()
#> Parula  : MATLAB R2014b default (perceptually uniform)
#> Jet     : Classic MATLAB rainbow (blue -> red)
#> Turbo   : Google Turbo (Mikhailov 2019)
#> BlueRed : Diverging (blue = low, red = high)
#> Sinha   : Sinha cross-quantile heatmap (black -> red -> yellow)
#> Viridis, Plasma, Cividis, Inferno, Magma, RdBu (plotly built-ins)
```

## References

* Sinha, A., Ghosh, V., Hussain, N., Nguyen, D.K., Das, N. (2023).
  *Energy Economics*, 126, 107021.
* Sim, N., Zhou, H. (2015). *Journal of Banking and Finance*, 55, 1-12.

## License

GPL-3
