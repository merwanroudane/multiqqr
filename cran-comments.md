## Test environments

* local Windows 11, R 4.5.2
* win-builder (devel and release) — pending
* R-hub (Linux, macOS, Windows) — pending

## R CMD check results

0 errors | 0 warnings | 0 notes

## Submission notes

This is the first CRAN release of `mqqr`.

Maintainer: Dr Merwan Roudane <merwanroudane920@gmail.com>
Source repository: https://github.com/merwanroudane/multiqqr

The package extends my existing CRAN package `QuantileOnQuantile`
(Sim and Zhou 2015 bivariate QQR) to the multivariate setting of
Sinha et al. (2023, *Energy Economics*) with moderators and `x * Z`
interaction terms.

The dependency on `quantreg` is used for weighted quantile regression via
`quantreg::rq.wfit`; the dependency on `plotly` is used for the interactive
3D surfaces, heatmaps and contour plots, which default to the MATLAB
Parula colour scale reproduced from its 64 RGB stops.

Slow examples (those requiring bootstrap standard errors on the default
quantile grid) are wrapped in `\donttest{}` so that the on-CRAN example
timing budget is respected. Tests cover the lightweight code paths.
