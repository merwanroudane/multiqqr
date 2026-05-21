#' @keywords internal
"_PACKAGE"

#' mqqr: Multivariate Quantile-on-Quantile Regression
#'
#' Implements the multivariate Quantile-on-Quantile regression of
#' Sinha et al. (2023) extending the bivariate QQR of Sim and Zhou (2015)
#' with exogenous moderators and optional interaction terms. The default
#' colour scale for all 3D surface, heatmap and contour plots is MATLAB
#' Parula.
#'
#' @section Main functions:
#' \itemize{
#'   \item \code{\link{mqq_regression}} -- the multivariate QQR estimator.
#'   \item \code{\link{plot_mqq_3d}}, \code{\link{plot_mqq_heatmap}},
#'         \code{\link{plot_mqq_contour}}, \code{\link{plot_mqq_interaction}}
#'         -- visualisations.
#'   \item \code{\link{mqq_to_matrix}}, \code{\link{mqq_export}},
#'         \code{\link{mqq_statistics}} -- helpers.
#'   \item \code{\link{parula_colors}}, \code{\link{mqqr_colorscales}}
#'         -- colour palettes.
#' }
#'
#' @docType package
#' @name mqqr-package
#' @aliases mqqr
NULL
