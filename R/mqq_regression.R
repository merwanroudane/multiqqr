#' @title Multivariate Quantile-on-Quantile Regression
#'
#' @description
#' Implements the multivariate Quantile-on-Quantile regression (m-QQR) of
#' Sinha et al. (2023) which extends the bivariate QQR of Sim and Zhou (2015)
#' to include exogenous moderators \eqn{Z = (Z_1, \ldots, Z_p)} and optional
#' interaction terms \eqn{x \cdot Z_j}.
#'
#' At the \eqn{\theta}-quantile of \eqn{y_t} the model is
#' \deqn{y_t = \beta_0(\theta,\tau) + \beta_1(\theta,\tau)(x_t - x^\tau)
#'        + \sum_j \gamma_j(\theta,\tau)\bigl[x_t Z_{j,t} - x^\tau Z_j^\tau\bigr]
#'        + \sum_j \alpha_j(\theta,\tau)(Z_{j,t} - Z_j^\tau) + v_t^\theta,}
#' fitted by weighted quantile regression with Gaussian kernel weights
#' \eqn{w_t = K((F_n(x_t) - \tau)/h)}.
#'
#' @param y Numeric vector. Dependent variable.
#' @param x Numeric vector. Principal regressor whose \eqn{\tau}-quantile
#'   drives the local kernel weights.
#' @param moderators Named list of numeric vectors. Exogenous moderators
#'   or controls \eqn{Z_1, \ldots, Z_p}. Use \code{list()} for the
#'   bivariate case.
#' @param y_quantiles Numeric vector of \eqn{\theta} quantiles in (0, 1).
#'   Default \code{seq(0.05, 0.95, by = 0.05)}.
#' @param x_quantiles Numeric vector of \eqn{\tau} quantiles in (0, 1).
#'   Default \code{seq(0.05, 0.95, by = 0.05)}.
#' @param bandwidth Numeric. Kernel bandwidth on the empirical-CDF scale.
#'   Default 0.05 (Sim and Zhou plug-in).
#' @param include_lag Logical. Include \eqn{y_{t-1}} as a control.
#' @param interactions Logical. Include \eqn{x \cdot Z_j} cross-terms.
#' @param se Character. One of \code{"bootstrap"} or \code{"none"}.
#' @param n_boot Integer. Bootstrap replicates. Default 200.
#' @param cdf_based_kernel Logical. Use CDF-distance kernel.
#' @param x_name,y_name Character. Variable names for printing.
#' @param verbose Logical. Print progress.
#' @param seed Integer or \code{NULL}. RNG seed for bootstrap.
#'
#' @return Object of class \code{"mqq_regression"} with elements:
#' \describe{
#'   \item{main_results}{Data frame of \eqn{\beta_1(\theta,\tau)},
#'         standard errors, t-statistics, p-values and pseudo R-squared.}
#'   \item{interactions}{Long-format data frame of \eqn{\gamma_j(\theta,\tau)}.}
#'   \item{moderator_direct}{Direct effects \eqn{\alpha_j(\theta,\tau)}.}
#'   \item{y_quantiles, x_quantiles, n_obs, bandwidth}{Settings.}
#'   \item{moderator_names, x_name, y_name}{Names.}
#'   \item{call, method}{Call and method label.}
#' }
#'
#' @references
#' Sinha, A., Ghosh, V., Hussain, N., Nguyen, D.K., Das, N. (2023).
#' Green financing of renewable energy generation: Capturing the role
#' of exogenous moderation for ensuring sustainable development.
#' \emph{Energy Economics}, 126, 107021.
#'
#' Sim, N., Zhou, H. (2015). Oil Prices, US Stock Return, and the
#' Dependence Between Their Quantiles. \emph{Journal of Banking and
#' Finance}, 55, 1-12.
#'
#' @examples
#' set.seed(42)
#' n <- 200
#' x <- rnorm(n)
#' z <- rnorm(n)
#' y <- 0.3 * x + 0.2 * z + 0.1 * x * z + rnorm(n, sd = 0.5)
#' fit <- mqq_regression(y, x, list(Z = z),
#'                       y_quantiles = seq(0.1, 0.9, by = 0.1),
#'                       x_quantiles = seq(0.1, 0.9, by = 0.1),
#'                       n_boot = 50, verbose = FALSE)
#' print(fit)
#'
#' @export
#' @importFrom stats complete.cases quantile pt
mqq_regression <- function(y, x,
                           moderators = list(),
                           y_quantiles = seq(0.05, 0.95, by = 0.05),
                           x_quantiles = seq(0.05, 0.95, by = 0.05),
                           bandwidth = 0.05,
                           include_lag = TRUE,
                           interactions = TRUE,
                           se = c("bootstrap", "none"),
                           n_boot = 200,
                           cdf_based_kernel = TRUE,
                           x_name = "X",
                           y_name = "Y",
                           verbose = TRUE,
                           seed = 42) {
  se <- match.arg(se)
  y <- as.numeric(y); x <- as.numeric(x)
  if (length(y) != length(x)) stop("'y' and 'x' must have equal length")
  if (!is.list(moderators)) stop("'moderators' must be a named list of vectors")
  if (length(moderators) > 0 && is.null(names(moderators)))
    stop("'moderators' must be named (e.g. list(EPU = z1, UNEMP = z2))")

  Z_names <- names(moderators)
  if (length(Z_names) > 0) {
    Z_arrs <- lapply(seq_along(moderators), function(j) {
      a <- as.numeric(moderators[[j]])
      if (length(a) != length(y))
        stop(sprintf("moderator '%s' length mismatch", Z_names[j]))
      a
    })
    Z <- do.call(cbind, Z_arrs)
  } else {
    Z <- matrix(numeric(0), nrow = length(y), ncol = 0)
  }

  ok <- is.finite(y) & is.finite(x)
  if (ncol(Z) > 0) ok <- ok & apply(Z, 1, function(r) all(is.finite(r)))
  y <- y[ok]; x <- x[ok]; Z <- Z[ok, , drop = FALSE]
  n <- length(y)
  if (n < 40) stop("need at least 40 observations after NA-removal")

  if (include_lag) {
    y_resp <- y[-1]; x_main <- x[-1]
    Z_t <- Z[-1, , drop = FALSE]
    y_lag <- y[-n]
  } else {
    y_resp <- y; x_main <- x; Z_t <- Z; y_lag <- NULL
  }
  n_eff <- length(y_resp); p <- ncol(Z_t)

  if (verbose) {
    message("Multivariate Quantile-on-Quantile Regression (m-QQR)")
    message("  n = ", n_eff, ", Y q-grid = ", length(y_quantiles),
            ", X q-grid = ", length(x_quantiles),
            ", h = ", bandwidth,
            ", moderators = ", if (length(Z_names)) paste(Z_names, collapse = ",") else "(none)",
            ", interactions = ", interactions)
  }

  main_records <- list()
  inter_records <- list()
  mod_records   <- list()

  total <- length(y_quantiles) * length(x_quantiles)
  done <- 0; pct_marker <- max(1, total %/% 10)

  for (tau in x_quantiles) {
    x_tau <- as.numeric(stats::quantile(x_main, tau, na.rm = TRUE))
    z_x <- x_main - x_tau
    w <- qq_weights(x_main, tau, h = bandwidth, cdf_based = cdf_based_kernel)

    Z_tau <- if (p > 0) {
      vapply(seq_len(p),
             function(j) as.numeric(stats::quantile(Z_t[, j], tau, na.rm = TRUE)),
             numeric(1))
    } else numeric(0)
    z_Z <- if (p > 0) sweep(Z_t, 2, Z_tau, "-") else matrix(numeric(0), n_eff, 0)

    if (interactions && p > 0) {
      inter <- x_main * Z_t - matrix(rep(x_tau * Z_tau, each = n_eff),
                                     nrow = n_eff)
    } else {
      inter <- matrix(numeric(0), n_eff, 0)
    }

    blocks <- list(rep(1, n_eff), z_x)
    if (!is.null(y_lag)) blocks[[length(blocks) + 1]] <- y_lag
    if (p > 0)           blocks[[length(blocks) + 1]] <- z_Z
    if (ncol(inter) > 0) blocks[[length(blocks) + 1]] <- inter
    X_mat <- do.call(cbind, blocks)

    idx <- list(intercept = 1L, beta1 = 2L)
    col <- 3L
    if (!is.null(y_lag)) { idx$lag <- col; col <- col + 1L }
    if (p > 0) {
      for (j in seq_along(Z_names)) idx[[paste0("alpha_", Z_names[j])]] <- col + j - 1L
      col <- col + p
    }
    if (ncol(inter) > 0) {
      for (j in seq_along(Z_names)) idx[[paste0("gamma_", Z_names[j])]] <- col + j - 1L
      col <- col + p
    }

    for (theta in y_quantiles) {
      done <- done + 1L
      base <- list(y_quantile = round(theta, 4), x_quantile = round(tau, 4))
      main <- c(base, list(beta0 = NA_real_, beta1 = NA_real_, se = NA_real_,
                           t_value = NA_real_, p_value = NA_real_,
                           r_squared = NA_real_,
                           n_eff = sum(w > 1e-8)))
      fit <- weighted_qr(y_resp, X_mat, theta, w)
      if (fit$success) {
        coef <- fit$coef
        main$beta0 <- coef[idx$intercept]
        main$beta1 <- coef[idx$beta1]
        main$r_squared <- pseudo_r2(y_resp, fit$fitted, theta, w)

        if (se == "bootstrap") {
          bs <- boot_wqr_se(y_resp, X_mat, theta, w,
                            n_boot = n_boot,
                            seed = if (!is.null(seed)) seed + done else NULL)
          sb1 <- bs$se[idx$beta1]
          if (is.finite(sb1) && sb1 > 0) {
            main$se <- sb1
            main$t_value <- coef[idx$beta1] / sb1
            df_r <- max(1, n_eff - ncol(X_mat))
            main$p_value <- 2 * stats::pt(-abs(main$t_value), df = df_r)
          }
          if (interactions && p > 0) {
            for (j in seq_along(Z_names)) {
              k <- idx[[paste0("gamma_", Z_names[j])]]
              g <- coef[k]; sg <- bs$se[k]
              rec <- c(base, list(moderator = Z_names[j], gamma = g,
                                  se = if (is.finite(sg) && sg > 0) sg else NA_real_,
                                  t_value = if (is.finite(sg) && sg > 0) g / sg else NA_real_,
                                  p_value = if (is.finite(sg) && sg > 0)
                                    2 * stats::pt(-abs(g / sg), df = max(1, n_eff - ncol(X_mat)))
                                    else NA_real_))
              inter_records[[length(inter_records) + 1]] <- rec
            }
          }
          if (p > 0) {
            for (j in seq_along(Z_names)) {
              k <- idx[[paste0("alpha_", Z_names[j])]]
              a <- coef[k]; sa <- bs$se[k]
              rec <- c(base, list(moderator = Z_names[j], alpha = a,
                                  se = if (is.finite(sa) && sa > 0) sa else NA_real_,
                                  t_value = if (is.finite(sa) && sa > 0) a / sa else NA_real_,
                                  p_value = if (is.finite(sa) && sa > 0)
                                    2 * stats::pt(-abs(a / sa), df = max(1, n_eff - ncol(X_mat)))
                                    else NA_real_))
              mod_records[[length(mod_records) + 1]] <- rec
            }
          }
        }
      }
      main_records[[length(main_records) + 1]] <- main

      if (verbose && done %% pct_marker == 0)
        message("  Progress: ", round(100 * done / total), "%")
    }
  }
  if (verbose) message("  done.")

  main_df <- do.call(rbind, lapply(main_records, as.data.frame, stringsAsFactors = FALSE))
  inter_df <- if (length(inter_records))
    do.call(rbind, lapply(inter_records, as.data.frame, stringsAsFactors = FALSE))
    else data.frame(y_quantile = numeric(0), x_quantile = numeric(0),
                    moderator = character(0), gamma = numeric(0),
                    se = numeric(0), t_value = numeric(0), p_value = numeric(0))
  mod_df <- if (length(mod_records))
    do.call(rbind, lapply(mod_records, as.data.frame, stringsAsFactors = FALSE))
    else data.frame(y_quantile = numeric(0), x_quantile = numeric(0),
                    moderator = character(0), alpha = numeric(0),
                    se = numeric(0), t_value = numeric(0), p_value = numeric(0))
  main_df <- main_df[order(main_df$y_quantile, main_df$x_quantile), ]
  rownames(main_df) <- NULL

  res <- list(
    main_results = main_df,
    interactions = inter_df,
    moderator_direct = mod_df,
    y_quantiles = y_quantiles,
    x_quantiles = x_quantiles,
    n_obs = n_eff,
    bandwidth = bandwidth,
    x_name = x_name,
    y_name = y_name,
    moderator_names = Z_names,
    call = match.call(),
    method = "Multivariate Quantile-on-Quantile Regression (m-QQR)"
  )
  class(res) <- "mqq_regression"
  res
}


#' @title Print method for mqq_regression
#' @param x An mqq_regression object.
#' @param ... Ignored.
#' @return Invisibly returns \code{x}.
#' @export
print.mqq_regression <- function(x, ...) {
  cat("\nMultivariate Quantile-on-Quantile Regression (m-QQR)\n")
  cat(strrep("=", 54), "\n", sep = "")
  cat("  Y =", x$y_name, "   X =", x$x_name, "\n")
  cat("  Moderators :",
      if (length(x$moderator_names)) paste(x$moderator_names, collapse = ", ") else "(none)",
      "\n")
  cat("  N =", x$n_obs, "  bandwidth =", x$bandwidth, "\n")
  cat("  Y-quantiles :", length(x$y_quantiles),
      "   X-quantiles :", length(x$x_quantiles), "\n")
  r <- x$main_results
  rok <- r[is.finite(r$beta1), ]
  if (nrow(rok) > 0) {
    cat("\n  beta1(theta, tau)\n")
    cat(sprintf("    mean   = %+0.4f\n", mean(rok$beta1)))
    cat(sprintf("    median = %+0.4f\n", stats::median(rok$beta1)))
    cat(sprintf("    min    = %+0.4f\n", min(rok$beta1)))
    cat(sprintf("    max    = %+0.4f\n", max(rok$beta1)))
    if ("p_value" %in% names(rok)) {
      p <- rok$p_value
      cat(sprintf("    p<0.10 : %d / %d  (%0.1f%%)\n",
                  sum(p < 0.10, na.rm = TRUE), nrow(rok),
                  100 * sum(p < 0.10, na.rm = TRUE) / nrow(rok)))
      cat(sprintf("    p<0.05 : %d / %d  (%0.1f%%)\n",
                  sum(p < 0.05, na.rm = TRUE), nrow(rok),
                  100 * sum(p < 0.05, na.rm = TRUE) / nrow(rok)))
      cat(sprintf("    p<0.01 : %d / %d  (%0.1f%%)\n",
                  sum(p < 0.01, na.rm = TRUE), nrow(rok),
                  100 * sum(p < 0.01, na.rm = TRUE) / nrow(rok)))
    }
  }
  invisible(x)
}


#' @title Summary method for mqq_regression
#' @param object An mqq_regression object.
#' @param ... Ignored.
#' @return List of summary statistics (invisibly).
#' @export
summary.mqq_regression <- function(object, ...) {
  print(object)
  if (length(object$moderator_names)) {
    cat("\n  Moderator interactions gamma_j(theta, tau)\n")
    for (m in object$moderator_names) {
      sub <- object$interactions[object$interactions$moderator == m &
                                 is.finite(object$interactions$gamma), ]
      if (nrow(sub)) {
        sig <- sum(sub$p_value < 0.05, na.rm = TRUE)
        cat(sprintf("    %-12s mean gamma = %+0.4f   sig(5%%) = %d/%d\n",
                    m, mean(sub$gamma), sig, nrow(sub)))
      }
    }
  }
  invisible(object)
}


#' @title Convert m-QQR Results to Matrix
#'
#' @param mqq_result An object of class \code{"mqq_regression"}.
#' @param value Character. Column to pivot: \code{"beta1"}, \code{"se"},
#'   \code{"t_value"}, \code{"p_value"}, \code{"r_squared"} for the main
#'   table, or \code{"gamma"} / \code{"alpha"} for interactions.
#' @param moderator Character. When \code{value} is \code{"gamma"} or
#'   \code{"alpha"}, the moderator name.
#' @return Numeric matrix with y_quantiles as rows and x_quantiles as columns.
#' @examples
#' set.seed(1)
#' n <- 120; x <- rnorm(n); y <- 0.4 * x + rnorm(n, sd = 0.5)
#' fit <- mqq_regression(y, x, list(), n_boot = 30, verbose = FALSE)
#' M <- mqq_to_matrix(fit, "beta1")
#' dim(M)
#' @export
mqq_to_matrix <- function(mqq_result, value = "beta1", moderator = NULL) {
  if (!inherits(mqq_result, "mqq_regression"))
    stop("'mqq_result' must be an mqq_regression object")
  if (value %in% c("gamma", "alpha")) {
    if (is.null(moderator))
      stop("supply 'moderator' when value is 'gamma' or 'alpha'")
    df <- if (value == "gamma") mqq_result$interactions else mqq_result$moderator_direct
    df <- df[df$moderator == moderator, ]
  } else {
    df <- mqq_result$main_results
    if (!value %in% names(df))
      stop("value '", value, "' not in main_results")
  }
  ys <- sort(unique(df$y_quantile))
  xs <- sort(unique(df$x_quantile))
  M <- matrix(NA_real_, length(ys), length(xs),
              dimnames = list(as.character(ys), as.character(xs)))
  for (i in seq_along(ys)) for (j in seq_along(xs)) {
    k <- which(df$y_quantile == ys[i] & df$x_quantile == xs[j])
    if (length(k)) M[i, j] <- df[[value]][k[1]]
  }
  M
}


#' @title Export m-QQR results to CSV files
#' @param mqq_result An mqq_regression object.
#' @param prefix Character. File prefix; three files are written:
#'   \code{<prefix>_main.csv}, \code{_interactions.csv}, \code{_moderators.csv}.
#' @param digits Integer. Rounding digits. Default 4.
#' @return Invisibly NULL.
#' @export
#' @importFrom utils write.csv
mqq_export <- function(mqq_result, prefix, digits = 4) {
  if (!inherits(mqq_result, "mqq_regression"))
    stop("'mqq_result' must be an mqq_regression object")
  for (tbl in c("main_results", "interactions", "moderator_direct")) {
    df <- mqq_result[[tbl]]
    if (!is.null(df) && nrow(df) > 0) {
      num <- vapply(df, is.numeric, logical(1))
      df[num] <- lapply(df[num], round, digits)
      suffix <- switch(tbl, main_results = "main",
                       interactions = "interactions",
                       moderator_direct = "moderators")
      utils::write.csv(df, paste0(prefix, "_", suffix, ".csv"), row.names = FALSE)
    }
  }
  invisible(NULL)
}


#' @title Summary statistics across the (theta, tau) grid
#' @param mqq_result An mqq_regression object.
#' @param alpha Numeric. Significance threshold. Default 0.05.
#' @return Data frame with statistic / value columns.
#' @export
mqq_statistics <- function(mqq_result, alpha = 0.05) {
  if (!inherits(mqq_result, "mqq_regression"))
    stop("'mqq_result' must be an mqq_regression object")
  r <- mqq_result$main_results
  r <- r[is.finite(r$beta1), ]
  data.frame(
    Statistic = c("Mean beta1", "Median beta1", "Min beta1", "Max beta1",
                  "SD beta1", "Mean R-squared",
                  paste0("Significant (p<", alpha, ")"), "Total cells"),
    Value = c(round(mean(r$beta1), 4), round(stats::median(r$beta1), 4),
              round(min(r$beta1), 4), round(max(r$beta1), 4),
              round(stats::sd(r$beta1), 4),
              round(mean(r$r_squared, na.rm = TRUE), 4),
              sum(r$p_value < alpha, na.rm = TRUE),
              nrow(r))
  )
}
