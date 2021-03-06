% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dWaSSI_functions.R
\name{f_cal_WaSSI}
\alias{f_cal_WaSSI}
\title{Calculate WaSSI for each pixel function}
\usage{
f_cal_WaSSI(lin, S_y, E_y, S_y_LAI, E_y_LAI, watershed = F, Q = NA,
  calibrate = NA, y_s = NA, y_e = NA)
}
\arguments{
\item{lin}{this is vector data, which includes all main variabels (P, T, E, Q etc.)}

\item{S_y, E_y}{The start and end year for input climate data}

\item{S_y_LAI, E_y_LAI}{The start and end year for LAI data}

\item{watershed}{whether calculate in watershed scale}

\item{Q}{A dataframe of Q data with c["YEAR","Month","Q"]}

\item{calibrate}{whether calibrate first}

\item{y_s, y_e}{the simulate start and end year}

\item{pars}{A names vector inlcudes "ALT","LAT","LONG",and "VEG" infomation}
}
\description{
Calculate WaSSI for each pixel function
}
\examples{
WaS<-f_cal_WaSSI(lin,S_y,E_y,S_y_LAI,E_y_LAI,watershed=F,Q=NA,calibrate=NA,y_s=NA,y_e=NA)

}
