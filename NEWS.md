# mqqr 1.0.0

* Initial CRAN release.
* `mqq_regression()` implements multivariate Quantile-on-Quantile regression
  (Sinha et al. 2023) extending the bivariate QQR of Sim and Zhou (2015) with
  exogenous moderators, optional `x * Z` interactions, paired-bootstrap
  standard errors and Koenker--Machado pseudo R-squared.
* 3D surface, heatmap and contour visualisations (`plot_mqq_3d`,
  `plot_mqq_heatmap`, `plot_mqq_contour`, `plot_mqq_interaction`).
* MATLAB Parula colour scale as the default, alongside Jet, Turbo,
  BlueRed and the Sinha red-yellow-black palette.
* Helpers `mqq_to_matrix()`, `mqq_export()`, `mqq_statistics()`.
