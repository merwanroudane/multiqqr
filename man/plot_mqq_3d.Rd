\name{plot_mqq_3d}
\alias{plot_mqq_3d}
\alias{plot_mqq_heatmap}
\alias{plot_mqq_contour}
\alias{plot_mqq_interaction}
\title{Visualisations for m-QQR Results}
\usage{
plot_mqq_3d(mqq_result, value = "beta1", moderator = NULL,
            colorscale = "Parula", show_contour = TRUE,
            x_label = "X Quantile (tau)",
            y_label = "Y Quantile (theta)",
            title = NULL)

plot_mqq_heatmap(mqq_result, value = "beta1", moderator = NULL,
                 colorscale = "Parula",
                 x_label = "X Quantile (tau)",
                 y_label = "Y Quantile (theta)",
                 title = NULL, show_stars = FALSE)

plot_mqq_contour(mqq_result, value = "beta1", moderator = NULL,
                 colorscale = "Parula",
                 x_label = "X Quantile (tau)",
                 y_label = "Y Quantile (theta)",
                 title = NULL)

plot_mqq_interaction(mqq_result, moderator,
                     value = c("gamma", "alpha"),
                     colorscale = "Parula",
                     kind = c("3d", "heatmap", "contour"), ...)
}
\arguments{
\item{mqq_result}{An \code{mqq_regression} object.}
\item{value}{Quantity to plot.}
\item{moderator}{Moderator name (for gamma / alpha).}
\item{colorscale}{Default \code{"Parula"}.}
\item{show_contour, show_stars, x_label, y_label, title, kind, ...}{See details.}
}
\value{A plotly object.}
\description{3D surface, heatmap, contour and moderator-interaction plots
for results of \code{\link{mqq_regression}}, defaulting to MATLAB Parula.}
\examples{
## Small toy example -- auto-tested. Plot objects are constructed but
## not rendered when run non-interactively.
set.seed(1); n <- 60
x <- rnorm(n); z <- rnorm(n)
y <- 0.4 * x + 0.2 * z + rnorm(n, sd = 0.4)
fit <- mqq_regression(y, x, list(Z = z),
                      y_quantiles = c(0.25, 0.5, 0.75),
                      x_quantiles = c(0.25, 0.5, 0.75),
                      n_boot = 5, verbose = FALSE)
p1 <- plot_mqq_3d(fit, colorscale = "Parula")
p2 <- plot_mqq_heatmap(fit, value = "beta1", show_stars = TRUE)
p3 <- plot_mqq_contour(fit, value = "beta1")
p4 <- plot_mqq_interaction(fit, "Z", value = "gamma", kind = "heatmap")
}
