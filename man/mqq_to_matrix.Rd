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
