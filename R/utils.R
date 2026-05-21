#' @title Empirical CDF
#'
#' @description Empirical CDF values \eqn{F_n(x_i) \in (0, 1]} for each
#'   observation using the mid-rank convention.
#' @param x Numeric vector.
#' @return Numeric vector of empirical CDF values.
#' @keywords internal
empirical_cdf <- function(x) {
  x <- as.numeric(x)
  n <- length(x)
  ranks <- rank(x, ties.method = "average")
  ranks / (n + 1)
}


#' @title Standard Gaussian Kernel
#' @param u Numeric vector.
#' @return Numeric vector of kernel weights \eqn{K(u) = (2\pi)^{-1/2} \exp(-u^2/2)}.
#' @export
#' @importFrom stats dnorm
gaussian_kernel <- function(u) {
  stats::dnorm(u)
}


#' @title Quantile-on-Quantile Kernel Weights
#'
#' @description
#' Kernel weights for the Sim and Zhou (2015) QQ estimator. The default
#' uses the CDF-distance kernel \eqn{K((F_n(x_t) - \tau) / h)} so that
#' \code{h} is interpretable on the unit interval (0.05 is the Sim and
#' Zhou plug-in). Set \code{cdf_based = FALSE} for raw-distance weighting.
#'
#' @param x Numeric vector.
#' @param tau Numeric scalar in (0, 1). Target quantile.
#' @param h Numeric. Bandwidth. Default 0.05.
#' @param cdf_based Logical. If TRUE, kernel uses empirical CDF distance.
#' @return Numeric vector of weights summing to \code{length(x)}.
#' @examples
#' x <- rnorm(100)
#' w <- qq_weights(x, tau = 0.3, h = 0.05)
#' @export
#' @importFrom stats sd
qq_weights <- function(x, tau, h = 0.05, cdf_based = TRUE) {
  x <- as.numeric(x)
  if (cdf_based) {
    Fn <- empirical_cdf(x)
    u <- (Fn - tau) / h
  } else {
    x_tau <- stats::quantile(x, tau, names = FALSE, na.rm = TRUE)
    s <- stats::sd(x, na.rm = TRUE)
    u <- (x - x_tau) / (if (s > 0) h * s else h)
  }
  w <- gaussian_kernel(u)
  s <- sum(w)
  if (s > 0) w <- w * (length(x) / s)
  w
}


#' @title Check (rho) Function
#' @param u Numeric vector of residuals.
#' @param tau Numeric scalar in (0, 1).
#' @return Numeric vector \eqn{\rho_\tau(u) = u(\tau - I(u < 0))}.
#' @keywords internal
check_fun <- function(u, tau) {
  u * (tau - as.numeric(u < 0))
}


#' @title Koenker-Machado Pseudo R-squared
#' @param y Numeric vector of observed responses.
#' @param y_pred Numeric vector of fitted values.
#' @param tau Numeric scalar in (0, 1).
#' @param weights Optional numeric weights.
#' @return Numeric pseudo R-squared in [0, 1].
#' @keywords internal
pseudo_r2 <- function(y, y_pred, tau, weights = NULL) {
  if (is.null(weights)) weights <- rep(1, length(y))
  rho_model <- sum(weights * check_fun(y - y_pred, tau))
  q_y <- weighted_quantile(y, tau, weights)
  rho_null <- sum(weights * check_fun(y - q_y, tau))
  if (!is.finite(rho_null) || rho_null <= 0) return(0)
  max(0, 1 - rho_model / rho_null)
}


#' @title Weighted Quantile
#' @keywords internal
weighted_quantile <- function(x, tau, w) {
  ord <- order(x)
  xs <- x[ord]; ws <- w[ord]
  cw <- cumsum(ws) / sum(ws)
  xs[min(which(cw >= tau), length(xs))]
}


#' @title Weighted Quantile Regression
#'
#' @description
#' Solves \eqn{\min_\beta \sum_t w_t \rho_\tau(y_t - X_t \beta)} via
#' \code{quantreg::rq.wfit} (interior-point solver). Returns a list of
#' coefficients and residuals.
#'
#' @param y Numeric response vector.
#' @param X Numeric design matrix including the intercept column.
#' @param tau Numeric scalar in (0, 1).
#' @param weights Numeric vector of weights (length \code{nrow(X)}).
#' @return A list with elements \code{coef}, \code{residuals},
#'   \code{fitted}, \code{success}.
#' @examples
#' set.seed(1)
#' n <- 100
#' X <- cbind(1, rnorm(n))
#' y <- X %*% c(0, 0.5) + rnorm(n, sd = 0.3)
#' fit <- weighted_qr(y, X, tau = 0.5, weights = rep(1, n))
#' fit$coef
#' @export
#' @importFrom quantreg rq.wfit
weighted_qr <- function(y, X, tau, weights = NULL) {
  y <- as.numeric(y)
  X <- as.matrix(X)
  n <- nrow(X)
  if (is.null(weights)) weights <- rep(1, n)
  weights <- pmax(as.numeric(weights), 0)
  out <- tryCatch(
    quantreg::rq.wfit(X, y, tau = tau, weights = weights, method = "br"),
    error = function(e) NULL
  )
  if (is.null(out) || any(!is.finite(out$coefficients))) {
    return(list(coef = rep(NA_real_, ncol(X)),
                residuals = rep(NA_real_, n),
                fitted = rep(NA_real_, n),
                success = FALSE))
  }
  fitted <- as.numeric(X %*% out$coefficients)
  list(coef = unname(out$coefficients),
       residuals = as.numeric(y - fitted),
       fitted = fitted,
       success = TRUE)
}


#' @title Bootstrap Standard Errors for Weighted QR
#'
#' @description Paired bootstrap of \code{weighted_qr}. Resamples rows of
#'   \code{(y, X, weights)} with replacement \code{n_boot} times.
#'
#' @param y Numeric response.
#' @param X Numeric design matrix.
#' @param tau Numeric quantile.
#' @param weights Numeric weights.
#' @param n_boot Integer. Number of bootstrap replicates. Default 200.
#' @param seed Integer or \code{NULL}. RNG seed.
#' @return A list with \code{se} (per-coefficient SE) and \code{boot}
#'   (matrix of bootstrap coefficients).
#' @keywords internal
boot_wqr_se <- function(y, X, tau, weights, n_boot = 200, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  n <- length(y); k <- ncol(X)
  coefs <- matrix(NA_real_, nrow = n_boot, ncol = k)
  for (b in seq_len(n_boot)) {
    idx <- sample.int(n, n, replace = TRUE)
    fit <- weighted_qr(y[idx], X[idx, , drop = FALSE], tau, weights[idx])
    if (fit$success) coefs[b, ] <- fit$coef
  }
  se <- apply(coefs, 2, function(z) {
    z <- z[is.finite(z)]
    if (length(z) > 1) stats::sd(z) else NA_real_
  })
  list(se = se, boot = coefs)
}


#' @title Standard Quantile Grid
#' @param by Numeric step. Default 0.05.
#' @return Numeric vector 0.05, 0.10, ..., 0.95.
#' @keywords internal
standard_quantile_grid <- function(by = 0.05) {
  round(seq(by, 1 - by, by = by), 4)
}
