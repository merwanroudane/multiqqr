\name{parula_colors}
\alias{parula_colors}
\alias{matlab_jet_colors}
\alias{turbo_colors}
\alias{bluered_colors}
\alias{sinha_colors}
\alias{mqqr_palette}
\alias{resolve_colorscale}
\alias{mqqr_colorscales}
\title{MATLAB-style and Sinha-paper colour palettes}
\usage{
parula_colors(n = 256)
matlab_jet_colors(n = 256)
turbo_colors(n = 256)
bluered_colors(n = 256)
sinha_colors(n = 256)
mqqr_palette(cols, n_breaks = 32)
resolve_colorscale(name = "Parula", n_breaks = 32)
mqqr_colorscales(show_preview = TRUE)
}
\arguments{
\item{n}{Number of interpolated colours.}
\item{cols}{Character vector of hex colours.}
\item{n_breaks}{Stops used in the plotly list.}
\item{name}{Scale name (Parula, Jet, Turbo, BlueRed, Sinha, Viridis, ...).}
\item{show_preview}{Print the available scales.}
}
\value{Character vector or list, depending on the function.}
\description{Colour palettes used by mqqr plotting functions. The default
colour scale across all mqqr 3D and heatmap functions is MATLAB Parula
(R2014b default), reproduced exactly from MathWorks' RGB stops.}
\examples{
parula_colors(8)
matlab_jet_colors(8)
turbo_colors(8)
bluered_colors(8)
sinha_colors(8)
mqqr_colorscales(show_preview = FALSE)
}
