% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Functions.R
\name{daily2annual}
\alias{daily2annual}
\title{Convert daily data to annual (zoo)----}
\usage{
daily2annual(x, FUN, na.rm = TRUE, out.fmt = "\%Y-\%m-\%d")
}
\arguments{
\item{x}{Input zoo variable.}

\item{FUN}{function for aggregation}
}
\description{
Convert daily data to annual (zoo)----
}
\examples{
daily2annual( FUN=mean)

}
\keyword{aggregation}
