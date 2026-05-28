\name{mqq_to_matrix}
\alias{mqq_to_matrix}
\alias{mqq_export}
\alias{mqq_statistics}
\title{Helpers for m-QQR results}
\usage{
mqq_to_matrix(mqq_result, value = "beta1", moderator = NULL)
mqq_export(mqq_result, prefix, digits = 4)
mqq_statistics(mqq_result, alpha = 0.05)
}
\arguments{
\item{mqq_result}{An \code{mqq_regression} object.}
\item{value}{Column to pivot: \code{"beta1"}, \code{"se"}, \code{"t_value"},
   \code{"p_value"}, \code{"r_squared"}, \code{"gamma"}, \code{"alpha"}.}
\item{moderator}{Moderator name when \code{value} is gamma or alpha.}
\item{prefix}{Output-file prefix (three CSVs written).}
\item{digits}{Rounding digits.}
\item{alpha}{Significance threshold.}
}
\value{Matrix, NULL, or data frame.}
\description{Pivot, export and summarise m-QQR results.}
\examples{
set.seed(1); n <- 60
x <- rnorm(n); z <- rnorm(n)
y <- 0.3 * x + 0.2 * z + rnorm(n, sd = 0.4)
fit <- mqq_regression(y, x, list(Z = z),
                      y_quantiles = c(0.25, 0.5, 0.75),
                      x_quantiles = c(0.25, 0.5, 0.75),
                      n_boot = 5, verbose = FALSE)
M <- mqq_to_matrix(fit, "beta1")
mqq_statistics(fit)
mqq_export(fit, file.path(tempdir(), "mqq"))
}
