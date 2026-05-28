\name{qq_weights}
\alias{qq_weights}
\alias{gaussian_kernel}
\alias{weighted_qr}
\title{Numerical building blocks for QQ regression}
\usage{
qq_weights(x, tau, h = 0.05, cdf_based = TRUE)
gaussian_kernel(u)
weighted_qr(y, X, tau, weights = NULL)
}
\arguments{
\item{x, y}{Numeric vectors.}
\item{X}{Numeric design matrix (intercept included).}
\item{tau}{Quantile in (0, 1).}
\item{h}{Bandwidth.}
\item{cdf_based}{Use empirical-CDF distance kernel.}
\item{weights}{Optional numeric weights.}
\item{u}{Numeric vector.}
}
\value{Numeric vector (qq_weights, gaussian_kernel) or list (weighted_qr).}
\description{Low-level utilities exposed for advanced users: Gaussian kernel
weights on the empirical-CDF scale, and weighted quantile regression via
\code{quantreg::rq.wfit}.}
\examples{
set.seed(1)
x <- rnorm(100)
w <- qq_weights(x, tau = 0.3)
sum(w)            # weights sum to length(x)
k <- gaussian_kernel(seq(-3, 3, by = 1))
X <- cbind(1, x)
y <- 0.5 * x + rnorm(100, sd = 0.3)
fit <- weighted_qr(y, X, tau = 0.5, weights = w)
fit$coef
}
