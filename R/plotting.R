#' @title 3D Surface Plot for m-QQR Results
#'
#' @description
#' Builds an interactive 3D surface from the (theta, tau) grid of m-QQR
#' coefficients. The default colour scale is MATLAB Parula.
#'
#' @param mqq_result An \code{mqq_regression} object.
#' @param value Character. \code{"beta1"} (default), \code{"r_squared"},
#'   \code{"p_value"}, or \code{"gamma"} / \code{"alpha"} for moderator
#'   slopes.
#' @param moderator Character. Moderator name when \code{value} is
#'   \code{"gamma"} or \code{"alpha"}.
#' @param colorscale Character. Color-scale name (default \code{"Parula"}).
#'   See \code{\link{mqqr_colorscales}}.
#' @param show_contour Logical. Show gridlines on the surface.
#' @param x_label,y_label Axis labels.
#' @param title Plot title (auto if NULL).
#' @return A plotly object.
#' @examples
#' \donttest{
#' set.seed(1); n <- 200; x <- rnorm(n); z <- rnorm(n)
#' y <- 0.4 * x + 0.2 * z + rnorm(n, sd = 0.4)
#' fit <- mqq_regression(y, x, list(Z = z), n_boot = 30, verbose = FALSE)
#' plot_mqq_3d(fit, colorscale = "Parula")
#' }
#' @export
#' @importFrom plotly plot_ly layout "%>%"
plot_mqq_3d <- function(mqq_result, value = "beta1", moderator = NULL,
                        colorscale = "Parula", show_contour = TRUE,
                        x_label = "X Quantile (tau)",
                        y_label = "Y Quantile (theta)",
                        title = NULL) {
  M <- mqq_to_matrix(mqq_result, value = value, moderator = moderator)
  xs <- as.numeric(colnames(M)); ys <- as.numeric(rownames(M))

  zlab <- switch(value, beta1 = "beta1",
                 r_squared = "R-squared",
                 p_value = "p-value",
                 gamma = paste0("gamma(", moderator, ")"),
                 alpha = paste0("alpha(", moderator, ")"),
                 value)
  if (is.null(title))
    title <- paste("m-QQR 3D Surface -", zlab)

  cs <- resolve_colorscale(colorscale)
  step_x <- if (length(xs) > 1) diff(xs)[1] else 0.05
  step_y <- if (length(ys) > 1) diff(ys)[1] else 0.05

  p <- plotly::plot_ly(
    x = xs, y = ys, z = M,
    type = "surface",
    colorscale = cs,
    showscale = TRUE,
    colorbar = list(title = zlab, tickformat = ".3f"),
    contours = list(
      x = list(show = show_contour, color = "black",
               start = min(xs), end = max(xs), size = step_x),
      y = list(show = show_contour, color = "black",
               start = min(ys), end = max(ys), size = step_y),
      z = list(show = FALSE)),
    lighting = list(ambient = 0.55, diffuse = 0.8,
                    specular = 0.15, roughness = 0.9),
    lightposition = list(x = 60, y = 120, z = 80),
    hovertemplate = paste0("tau: %{x:.2f}<br>theta: %{y:.2f}<br>",
                           zlab, ": %{z:.4f}<extra></extra>")
  )
  p %>% plotly::layout(
    title = title, paper_bgcolor = "white", plot_bgcolor = "white",
    scene = list(
      xaxis = list(title = x_label, tickformat = ".2f",
                   showgrid = TRUE, gridcolor = "#E6E6E6"),
      yaxis = list(title = y_label, tickformat = ".2f",
                   showgrid = TRUE, gridcolor = "#E6E6E6"),
      zaxis = list(title = zlab, showgrid = TRUE, gridcolor = "#F0F0F0"),
      aspectratio = list(x = 1, y = 1, z = 0.7),
      camera = list(eye = list(x = 1.4, y = 1.7, z = 1.2))
    )
  )
}


#' @title Heatmap for m-QQR Results
#'
#' @param mqq_result An \code{mqq_regression} object.
#' @param value,moderator,colorscale,x_label,y_label,title Same as
#'   \code{\link{plot_mqq_3d}}.
#' @param show_stars Logical. Overlay significance stars (***, **, *).
#' @return A plotly object.
#' @export
#' @importFrom plotly plot_ly layout "%>%"
plot_mqq_heatmap <- function(mqq_result, value = "beta1", moderator = NULL,
                             colorscale = "Parula",
                             x_label = "X Quantile (tau)",
                             y_label = "Y Quantile (theta)",
                             title = NULL, show_stars = FALSE) {
  M <- mqq_to_matrix(mqq_result, value = value, moderator = moderator)
  xs <- as.numeric(colnames(M)); ys <- as.numeric(rownames(M))
  zlab <- switch(value, beta1 = "beta1",
                 r_squared = "R-squared",
                 p_value = "p-value",
                 gamma = paste0("gamma(", moderator, ")"),
                 alpha = paste0("alpha(", moderator, ")"),
                 value)
  if (is.null(title))
    title <- paste("m-QQR Heatmap -", zlab)
  cs <- resolve_colorscale(colorscale)

  p <- plotly::plot_ly(
    x = xs, y = ys, z = M,
    type = "heatmap", colorscale = cs, showscale = TRUE,
    hovertemplate = paste0("tau: %{x:.2f}<br>theta: %{y:.2f}<br>",
                           zlab, ": %{z:.4f}<extra></extra>")
  ) %>%
    plotly::layout(title = title,
                   xaxis = list(title = x_label),
                   yaxis = list(title = y_label))

  if (show_stars && value == "beta1") {
    pmat <- mqq_to_matrix(mqq_result, value = "p_value")
    stars <- matrix("", nrow = nrow(pmat), ncol = ncol(pmat))
    stars[pmat < 0.10] <- "*"
    stars[pmat < 0.05] <- "**"
    stars[pmat < 0.01] <- "***"
    anns <- list()
    for (i in seq_len(nrow(M))) for (j in seq_len(ncol(M))) {
      if (nzchar(stars[i, j])) {
        anns[[length(anns) + 1]] <- list(
          x = xs[j], y = ys[i], text = stars[i, j],
          xref = "x", yref = "y", showarrow = FALSE,
          font = list(size = 10, color = "white"))
      }
    }
    p <- p %>% plotly::layout(annotations = anns)
  }
  p
}


#' @title Contour Plot for m-QQR Results
#' @param mqq_result,value,moderator,colorscale,x_label,y_label,title Same as
#'   \code{\link{plot_mqq_3d}}.
#' @return A plotly object.
#' @export
#' @importFrom plotly plot_ly layout "%>%"
plot_mqq_contour <- function(mqq_result, value = "beta1", moderator = NULL,
                             colorscale = "Parula",
                             x_label = "X Quantile (tau)",
                             y_label = "Y Quantile (theta)",
                             title = NULL) {
  M <- mqq_to_matrix(mqq_result, value = value, moderator = moderator)
  xs <- as.numeric(colnames(M)); ys <- as.numeric(rownames(M))
  zlab <- switch(value, beta1 = "beta1",
                 r_squared = "R-squared",
                 p_value = "p-value",
                 gamma = paste0("gamma(", moderator, ")"),
                 alpha = paste0("alpha(", moderator, ")"),
                 value)
  if (is.null(title))
    title <- paste("m-QQR Contour -", zlab)
  cs <- resolve_colorscale(colorscale)
  plotly::plot_ly(
    x = xs, y = ys, z = M,
    type = "contour", colorscale = cs, showscale = TRUE,
    contours = list(showlabels = TRUE)
  ) %>%
    plotly::layout(title = title,
                   xaxis = list(title = x_label),
                   yaxis = list(title = y_label))
}


#' @title Plot the (theta, tau) surface for a moderator interaction
#' @param mqq_result An mqq_regression object.
#' @param moderator Character. Moderator name.
#' @param value Character. \code{"gamma"} (interaction) or \code{"alpha"}
#'   (direct effect).
#' @param colorscale Character. Default "Parula".
#' @param kind Character. \code{"3d"}, \code{"heatmap"}, or \code{"contour"}.
#' @param ... Passed to the underlying plot function.
#' @return A plotly object.
#' @export
plot_mqq_interaction <- function(mqq_result, moderator,
                                 value = c("gamma", "alpha"),
                                 colorscale = "Parula",
                                 kind = c("3d", "heatmap", "contour"), ...) {
  value <- match.arg(value); kind <- match.arg(kind)
  fn <- switch(kind,
               "3d"      = plot_mqq_3d,
               heatmap   = plot_mqq_heatmap,
               contour   = plot_mqq_contour)
  fn(mqq_result, value = value, moderator = moderator,
     colorscale = colorscale, ...)
}


#' @title S3 plot method for mqq_regression
#' @param x An mqq_regression object.
#' @param value,colorscale,kind,... See \code{\link{plot_mqq_interaction}}.
#' @return A plotly object.
#' @export
plot.mqq_regression <- function(x, value = "beta1", colorscale = "Parula",
                                kind = c("3d", "heatmap", "contour"), ...) {
  kind <- match.arg(kind)
  fn <- switch(kind,
               "3d"      = plot_mqq_3d,
               heatmap   = plot_mqq_heatmap,
               contour   = plot_mqq_contour)
  fn(x, value = value, colorscale = colorscale, ...)
}
