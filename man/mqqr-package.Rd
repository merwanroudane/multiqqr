\name{mqqr-package}
\alias{mqqr-package}
\alias{mqqr}
\docType{package}
\title{mqqr: Multivariate Quantile-on-Quantile Regression}
\description{Implements the multivariate Quantile-on-Quantile regression
of Sinha et al. (2023) extending the bivariate QQR of Sim and Zhou (2015)
with exogenous moderators and optional interaction terms.}
\section{Main functions}{
\itemize{
  \item \code{\link{mqq_regression}} -- the multivariate QQR estimator.
  \item \code{\link{plot_mqq_3d}}, \code{\link{plot_mqq_heatmap}},
        \code{\link{plot_mqq_contour}}, \code{\link{plot_mqq_interaction}}
        -- visualisations.
  \item \code{\link{mqq_to_matrix}}, \code{\link{mqq_export}},
        \code{\link{mqq_statistics}} -- helpers.
  \item \code{\link{parula_colors}}, \code{\link{mqqr_colorscales}}
        -- colour palettes.
}
}
\author{Dr Merwan Roudane \email{merwanroudane920@gmail.com}\cr
  GitHub: \url{https://github.com/merwanroudane/multiqqr}}
\keyword{package}
