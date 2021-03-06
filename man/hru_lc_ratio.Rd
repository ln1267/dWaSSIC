% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Functions.R
\name{hru_lc_ratio}
\alias{hru_lc_ratio}
\title{Zonal vegetation coverage for each Hru in dWaSSI-C}
\usage{
hru_lc_ratio(classname, shp, field = NULL)
}
\arguments{
\item{classname}{a raster of each hru it can be vegetation type or soil type}

\item{shp}{the zonal boundary}

\item{field}{the field of the shp boundary that will used for zonal}

\item{varname}{The name of the zonaled variable}
}
\description{
FUNCTION_DESCRIPTION
}
\details{
This is a function for zonal hru data
}
\examples{
\dontrun{
ha<-hru_lc_ratio(classname = "inputs/Landcover/LUCC_Sun_IGBP.nc",
            shp = Basins,
            field="Station")
}
}
