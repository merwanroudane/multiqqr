\name{mqq_regression}
\alias{mqq_regression}
\title{Multivariate Quantile-on-Quantile Regression}
\usage{
mqq_regression(y, x, moderators = list(),
               y_quantiles = seq(0.05, 0.95, by = 0.05),
               x_quantiles = seq(0.05, 0.95, by = 0.05),
               bandwidth = 0.05, include_lag = TRUE,
               interactions = TRUE, se = c("bootstrap", "none"),
               n_boot = 200, cdf_based_kernel = TRUE,
               x_name = "X", y_name = "Y",
               verbose = TRUE, seed = 42)
}
\arguments{
\item{y}{Numeric vector. Dependent variable.}
\item{x}{Numeric vector. Principal regressor.}
\item{moderators}{Named list of numeric vectors.}
\item{y_quantiles}{Numeric vector of theta in (0, 1).}
\item{x_quantiles}{Numeric vector of tau in (0, 1).}
\item{bandwidth}{Kernel bandwidth on the empirical-CDF scale.}
\item{include_lag}{Include \eqn{y_{t-1}} as a control.}
\item{interactions}{Include x*Z cross-terms.}
\item{se}{Standard errors: \code{"bootstrap"} or \code{"none"}.}
\item{n_boot}{Bootstrap replicates.}
\item{cdf_based_kernel}{Use CDF-distance kernel.}
\item{x_name, y_name}{Variable names for printing.}
\item{verbose}{Print progress.}
\item{seed}{RNG seed for bootstrap.}
}
\value{An object of class \code{mqq_regression}.}
\description{Fits a multivariate Quantile-on-Quantile regression with
optional moderators and interaction terms.}
\references{
Sinha, A., Ghosh, V., Hussain, N., Nguyen, D.K., Das, N. (2023).
\emph{Energy Economics}, 126, 107021.

Sim, N., Zhou, H. (2015). \emph{Journal of Banking and Finance}, 55, 1-12.
}
\examples{
set.seed(1); n <- 200
x <- rnorm(n); z <- rnorm(n)
y <- 0.3*x + 0.2*z + 0.1*x*z + rnorm(n, sd=0.4)
fit <- mqq_regression(y, x, list(Z = z), n_boot = 30, verbose = FALSE)
print(fit)
}
