% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/krige.head.R
\name{krige.head}
\alias{krige.head}
\title{Spatially interpolates sparse groundwater level observations, and if required, estimate mapping parameters.}
\usage{
krige.head(formula = as.formula("head ~ elev + MrVBF + MrRTF + smoothing"),
  grid = NULL, grid.landtype.colname = NULL, data = NULL,
  data.fixedHead = NULL, newdata = NULL, data.errvar.colname = NULL,
  model = NULL, mrvbf.pslope = if (any(match(all.vars(as.formula(formula)),
  "MrVBF", nomatch = F) | match(all.vars(as.formula(formula)), "MrRTF", nomatch
  = F))) {     seq(0.5, 1.5, length.out = 11) } else {     NULL },
  mrvbf.ppctl = if (any(match(all.vars(as.formula(formula)), "MrVBF", nomatch
  = F) | match(all.vars(as.formula(formula)), "MrRTF", nomatch = F))) {    
  seq(0.5, 1.5, length.out = 11) } else {     NULL }, smooth.std = seq(0.5,
  1.5, length.out = 11), nmax = if (is.character(data)) {     -999 } else {   
   ceiling(seq(0.1, 0.2, 0.01) * length(data)) }, nmax.fixedHead = if
  (!is.null(data.fixedHead)) {     seq(10, 110, length = 11) } else {     NULL
  }, maxdist = if (class(grid) == "SpatialPixelsDataFrame" || class(grid) ==
  "SpatialGridDataFrame") {     ceiling(0.5 * sqrt((extent(grid)[2] -
  extent(grid)[1])^2 + (extent(grid)[4] - extent(grid)[3])^2) * seq(0.1, 1,
  0.1)) } else {     -999 }, trendMaxDistFrac = seq(0.1, 1, 0.1),
  nmin = 0.2, omax = NULL, nsim = 0, fit.variogram.type = 1,
  objFunc.type = 1, use.cluster = TRUE, debug.level = 0, ...)
}
\arguments{
\item{\code{formula}}{defines the R formula (as a character or formula data type) to be used to interpolate the heads. The left hand side of the formula must be \code{head}.
The right hand side can contain any or all of the following terms: \code{elev} for the land surface elevation;
\code{MrVBF} for the Multiresolution Index of Valley Bottom Flatness as a measure of valley-ness at each DEM grd cell;
\code{MrRTF} for the Multiresolution Index of Ridge Top Flatness as a measure of ridge to plateaus at each DEM grd cell;
\code{smoothing} for a local smoothing factor derived from the DEM roughness. For any terms other than the prior, the data
for the variable must be listed within the inputs \code{grid} and \code{data}. The default is \code{as.formula("head ~ elev + MrVBF + MrRTF + smoothing")}.}

\item{\code{grid}}{is either a character string to a ASCII grid digital elevation model (DEM) or a \code{SpatialPixelsDataFrame} or \code{SpatialGridDataFrame} containing the land
surface elevation, which must be named \code{elev}, and each formula variable other than \code{MrVBF}, \code{MrRTF} and \code{smoothing}; which are each derived from the DEM.}

\item{\code{grid.landtype.colname}}{is a character of the column name within \code{grid} and \code{data} that define the land category. The land category data should be an integer and
be of a sufficiently small number of categories that multiple data points exists within each land category. If \code{NULL}, then land categories are not accounted for in the mapping. The default is \code{NULL}.}

\item{\code{data}}{is either a character string to a .csv file of point data or a \code{SpatialPointsDataFrame} containing the columns \code{Easting}, \code{Northing} and \code{head} or \code{depth}.
If the formula includes the term \code{elev}, then the bore elevation should be included in \code{data} so as to account for difference between the bore and DEM elevation.
Each formula right hand side variable other than \code{MrVBF}, \code{MrRTF} and \code{smoothing} should also be provided within \code{data}.}

\item{\code{data.fixedHead}}{is as for \code{data} but the points are treated as fixed head points within a cokriging approach. It can be used to guide the head estimates
toward zero along, say, the coastline. The fixed points will have a greater influence when no observation data is nearby. If \code{NULL}, then no fixed head points are used.
The default is \code{NULL}.}

\item{\code{newdata}}{is as for \code{data} but the points are used in a split-sample cross-validation scheme to estimate the interpolation error. Points listed within \code{newdata} should not be
listed within \code{data}. If \code{is.null(newdata)==TRUE}, then \code{grid} should be \code{NULL}.}

\item{\code{data.errvar.colname}}{is a character of the column name within \code{data} that define measurement error, as a variance. If \code{NULL}, then measurement error is not accounted for.
The default is \code{NULL}.}

\item{\code{model}}{is either a character for the name of the variogram model type or a \code{gstat} variogram model object of type \code{variogramModel}. The available options are as per \code{gstat}, but
it is suggested to be \code{Mat}.}

\item{\code{mrvbf.pslope}}{defines the MrVFB shape parameter for the slope (see Gallant et al. 2003), a vector of two values defines the optimisation range when the parameter is
treated as a real number. A vector of length >2 values defines the optimisation increments when the parameter is treated as not continuous but discrete. If a single number is input, then the parameter will
not be optimised. If the \code{formula} includes either of the terms \code{MrVBF} or \code{MrRTF}, then the default is \code{seq(0.5, 1.5, length.out = 11)}. Else, the default is \code{NULL}.}

\item{\code{mrvbf.ppctl}}{defines the MrVFB shape parameter for elevation percentile (see Gallant et al. 2003). It can be a scalar number, a vector of two values defining the optimisation range when the parameter is
treated as a real number or a vector of length >2 values defining the optimisation increments when the parameter is treated as not continuous but discrete. If a single number is input, then the parameter will
not be optimised.  If the \code{formula} includes either of the terms \code{MrVBF} or \code{MrRTF}, then the default is \code{seq(0.5, 1.5, length.out = 11)}. Else, the default is \code{NULL}.}

\item{\code{smooth.std}}{defines the strength of the Gaussian kernal smoothing applied to the 5x5 grid cells surrounding each DEM grid cell. It can be a scalar number, a vector of two values defining the optimisation range when the parameter is
treated as a real number or a vector of length >2 values defining the optimisation increments when the parameter is treated as not continuous but discrete. If a single number is input, then the parameter will
not be optimised.  The default is \code{seq(0.5, 1.5, length.out = 11)}.}

\item{\code{nmax}}{defines the maximum number of \code{data} observations to use when estimate each point using local kriging. It can be a scalar number, a vector of two values defining the optimisation range when the parameter is
treated as a real number or a vector of length >2 values defining the optimisation increments when the parameter is treated as not continuous but discrete. If a single number is input, then the parameter will
not be optimised.  The default is \code{ceiling(seq(0.1,0.20,0.01)*length(data))}.}

\item{\code{nmax.fixedHead}}{defines the maximum number of \code{data.fixedHead} observations to use when estimate each point using local kriging. It can be a scalar number, a vector of two values defining the optimisation range when the parameter is
treated as a real number or a vector of length >2 values defining the optimisation increments when the parameter is treated as not continuous but discrete. If a single number is input, then the parameter will
not be optimised.  The default is \code{seq(10,110,length=11)}.}

\item{\code{maxdist}}{defines the maximum search radius to use when estimate each point using local kriging. It can be a scalar number, a vector of two values defining the optimisation range when the parameter is
treated as a real number or a vector of length >2 values defining the optimisation increments when the parameter is treated as not continuous but discrete. If a single number is input, then the parameter will
not be optimised.  The default is from 10\% to 100\% of \code{grid} extend at increments of 10\%. If \code{grid} is \code{NULL}, then the user must input the search radius in one of the three accepted forms.}

\item{\code{trendMaxDistFrac}}{defines a threshold distance between an observation and estimation point (as a fraction of \code{maxdist}) at which minimal weight should be placed on the observation (see Rivoirard et al. 2011).
This can be used to reduce the numerical artefacts in the mapped head, which can appear as a linear sharp change in the head.
It can be a scalar number, a vector of two values defining the optimisation range when the parameter is
treated as a real number or a vector of length >2 values defining the optimisation increments when the parameter is treated as not continuous but discrete. If a single number is input, then the parameter will
not be optimised.  The default is \code{seq(0.1,1,0.1)}.}

\item{\code{nmin}}{defines the minimum number of \code{data} observations to use when estimating each point using local kriging. If the \code{nmin} observations cannot be located within the search radius \code{nmax}, then the search
radius is increased until \code{nmin} points are obtained. If \code{nmin} is between zero and one and \code{omax} is between zero and one, then \code{nmin} is treated as a fraction of \code{nmax}. Else, \code{nmax} is treated as an
integer number of data points and hence must be >0. This input cannot be optimised. The default value is 0.2.}

\item{\code{omax}}{defines the maximum number of \code{data} observations to select per quadrant when estimating each point using local kriging. It must be either \code{NULL} (to not use quadrant search) or between zero and one,
which is treated as a fraction of \code{nmax}. This input cannot be optimised.  The default value is \code{NULL}.}

\item{\code{nsim}}{defines the number of conditional simulations to undertake. If set to a non-zero value, conditional simulation is used instead of kriging interpolation. Importantly, this feature has not been tested.
The default value is 0.}

\item{\code{fit.variogram.type}}{defines the way the model variogram is to be derived/used.
For \code{fit.variogram.type==1} the input \code{model} must be the variogram type (as character string) and optimisation must be undertaken. The variogram will be assumed isotropic. For more control of the variogram calibrate using \code{\link{krige.head.calib}}.
For \code{fit.variogram.type==2} the input \code{model} must be a \code{gstat} variogram model object of type \code{variogramModel}. The variogram model parameters will be estimated by fitting the model variogram to an experimental variogram using multi-start local calibration.
For \code{fit.variogram.type==3} the input \code{model} must also be a variogram model object of type \code{variogramModel}. If calibration is being undertaken, then the variogram model parameters will not be optimised or fit to an experimental variogram.}

\item{\code{objFunc.type}}{defines the type of objective function to use in the optimisation. See \code{\link{krige.head.calib}} for details.}

\item{\code{use.cluster}}{sets if the calibration and interpolation should be parallelised. If \code{TRUE}, then local all local cores will be used. An integer >0 sets the number of local cores to use.
An object from \code{makeCluster} allows for a user specified cluster.}

\item{\code{debug.level}}{Control the user messages. A value >0 outputs \code{hydroMap} progress. See \code{gstat} for the influence of values >0 on the kriging.}
}
\value{
If \code{is.null(newdata)==TRUE}, then a Spatial object grid will be returned with "head" and "head.var" for the groundwater level and kriging variance respectively.

Else, a point Spatial object will be returned with the estmates at the prediction locations and error estimates.
}
\description{
\code{krige.head} creates a groundwater level elevation map from sparse point observations for one time point.
}
\details{
This function is the primary means for using the package. It interpolates sparse input groundwater elevation
observations for a single time point using a form of kriging with external drift that can account
for land surface elevation, topographic form (e.g. valleys and ridges), the smoothness of the groundwater
relative to the land surface and remote sensing gridded data. Also, a co-kriging features allows for
the inclusion of categorical land types and fixed head boundary conditions, such as the ocean. Each of
these features can be individually controlled by the user.

Importantly, if the mapping parameters are not specified by the user, then this function estimates the parameters using
a mixed data-type (i.e. real and integer parameters) split-sample maximum likelihood global optimisation. The optimisation by default
includes the variogram parameters (e.g. range, sill and nugget) and the search parameters for local kriging (e.g. radius, minimum and
maximum number of observations to use). Optimising these parameters is not common in kriging. It is done herein because trials for Victoria,
Australia, showed that calibrating these parameters produced significantly lower cross-validation errors (i.e. the error in predicting the observations
removed from the optimisation) compared to the standard approach of graphical estimation from an experimental variogram. The optimisation is
numerically challenging and the following factors should be considered before use:

\itemize{
 \item{Optimisation of the parameters \code{mrvbf.pslope}, \code{mrvbf.ppctl} and \code{smooth.std} often required the creating of raster grids for every parameter combination. To ease the computation burden, these parameters should be treated as discrete, not continuous, numbers.}
 \item{The optimisation package \code{rgeoud} is used herein. For control the optimisation process, consider directly using \code{\link{krige.head.calib}}.}
 \item{Trials have established default calibration parameters and settings that were effective for Victoria, Australia. There is no guarantee they will be effective for other regions.}
}

In using this function, the primary user decisions are:
\itemize{
 \item{The kriging with external drift formula defining the independent gridded variables deemed to predict the groundwater elevation. See the input \code{formula}.}
 \item{The mapping extent and resolution, defined by the input \code{grid}, and the point observations of groundwater elevation, defined by the input \code{data}.}
 \item{The type of variogram model, defined by the input \code{model}}
 }
}
\examples{
# Load packages in case they have not loaded.
library(sp)
library(grid)
library(gstat)
library(raster)
library(RSAGA)
library(parallel)
library(rgenoud)

# Set enironment path for hydroMap
set.env()

# Load water table observations from  April 2000 for Victoria, Australia and a 250m state-wide DEM.
data('victoria.groundwater')

# Load a model variogram and mapping parametyers found to be effective.
data('mapping.parameters')
# Define a simple kriging formula without MrVBF terms that does not require the package RSAGA.
f <- as.formula('head ~ elev + smoothing')

# Interpolate the head data.
heads <- krige.head(formula=f, grid=DEM, data=obs.data, data.errvar.colname='total_err_var',
model=model, smooth.std=smooth.std, maxdist=maxdist, nmax=nmax, fit.variogram.type=3, debug.level=1)

# Recalibrate the parameters and map using the default settings.
heads <- krige.head(formula=f, grid=DEM, data=obs.data, data.errvar.colname='total_err_var',
model = 'Mat',  fit.variogram.type=1, debug.level=1)

}
\references{
Gallant, J.C., Dowling, T.I. (2003): 'A multiresolution index of valley bottom flatness for mapping depositional areas', Water Resources Research, 39/12:1347-1359

Rivoirard, J. & Romary, T. Math Geosci (2011) Continuity for Kriging with Moving Neighborhood, Mathematical Geosciences, 43: 469. DOI: 10.1007/s11004-011-9330-0
}
\seealso{
\code{\link{krige.head.calib}} for undertaking only the optimisation.
}
