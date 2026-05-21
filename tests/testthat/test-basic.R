test_that("parula palette returns 10 hex colours", {
  cols <- parula_colors(10)
  expect_length(cols, 10)
  expect_match(cols, "^#[0-9A-Fa-f]{6}$")
})

test_that("qq_weights have correct length and normalisation", {
  x <- rnorm(50)
  w <- qq_weights(x, 0.5)
  expect_length(w, 50)
  expect_equal(sum(w), 50, tolerance = 1e-6)
})

test_that("mqq_regression returns expected structure", {
  set.seed(1); n <- 80
  x <- rnorm(n); z <- rnorm(n)
  y <- 0.3 * x + 0.2 * z + rnorm(n, sd = 0.3)
  fit <- mqq_regression(y, x, list(Z = z),
                        y_quantiles = c(0.25, 0.5, 0.75),
                        x_quantiles = c(0.25, 0.5, 0.75),
                        n_boot = 10, verbose = FALSE)
  expect_s3_class(fit, "mqq_regression")
  expect_true(all(c("main_results", "interactions",
                    "moderator_direct") %in% names(fit)))
  expect_equal(nrow(fit$main_results), 9)
  M <- mqq_to_matrix(fit, "beta1")
  expect_equal(dim(M), c(3, 3))
})
