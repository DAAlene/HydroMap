get.smoothedDEM <- function(data, grid, smooth.std = 1.0, smoothingKernal=NULL, maxStoredGrids=10, debug.level=0 ) {

  if (debug.level>0)
    message('Getting smoothed DEM elevation grid:');

  # Check enviro variables are setup
  if (!exists('pkg.env') || is.null(pkg.env))
    stop('    The environment variable are not setup. Call set.env() with paths to SAGA.');

  # Get point data.
  if (!is.null(data))
    data <- import.pointData(data);

  # Get DEM.
  grid = import.DEM(grid)


  # Build name of smoothed DEM grid
  var.name.smoothedDEM <- paste('smoothedDEM_std',smooth.std,sep='');

  # Get DEM grid attributes
  grid.DEM.params = gridparameters(grid)

  # Assess if need to smoothen DEM
  if (debug.level>0)
    message('... Assessing analysis requirements.')
  do.smoothedDEM = TRUE;
  if (!is.null(pkg.env$smoothDEM.grid)) {
    var.name.all = names(pkg.env$smoothDEM.grid)
    grid.smoothDEM.params = gridparameters(pkg.env$smoothDEM.grid)
    if (grid.DEM.params$cellcentre.offset[1] == grid.smoothDEM.params$cellcentre.offset[1] &&
        grid.DEM.params$cellcentre.offset[2] == grid.smoothDEM.params$cellcentre.offset[2] &&
        grid.DEM.params$cellsize[1] == grid.smoothDEM.params$cellsize[1] &&
        grid.DEM.params$cellsize[2] == grid.smoothDEM.params$cellsize[2] &&
        grid.DEM.params$cells.dim[1] == grid.smoothDEM.params$cells.dim[1] &&
        grid.DEM.params$cells.dim[2] == grid.smoothDEM.params$cells.dim[2] &&
        any(!is.na(match(var.name.all, var.name.smoothedDEM))))
      do.smoothedDEM <- FALSE;
  }

  # Do smoothening or get prior calc. grid.
  if (do.smoothedDEM) {

      if (is.null(smoothingKernal)) {
        if (debug.level>0)
      	  message('... Building smoothing kernal.')

      	# Build Gaussian blur kernal
      	smoothingKernal = matrix(1,5,5);
      	for (i in 1:5) {
      	  for(j in 1:5) {
      	    smoothingKernal[i,j] = (i-3)^2 + (j-3)^2
      	  }
      	}
      }
      if (debug.level>0)
        message('... Doing smoothing.')
      # Get central value if the parameter is a vector (ie if doing calibration)
      ind_smooth = max(1,round(length(smooth.std)/2))

      sigmaWeights = 1/(2*pi*smooth.std[ind_smooth]^2) * exp(-smoothingKernal/(2*smooth.std[ind_smooth]^2) )
      sigmaWeights = sigmaWeights/sum(sigmaWeights);

      # Infill NA DEM values of grid by taking the local average. This was essential to ensure
      # DEM values at fixed head points beyond the mappng area (eg coastal points
      # with a fixed head of zero just beyond the DEM extent)
      dem.asRaster = raster(grid,layer='DEM');
      kernal.maxdim = max(dim(smoothingKernal));
      for (i in 1:kernal.maxdim)
        dem.asRaster = focal(dem.asRaster, w=matrix(1,kernal.maxdim,kernal.maxdim), fun=mean, na.rm=TRUE, NAonly=TRUE)

      # Do smoothing of DEM
      smoothDEM.asRaster = focal(dem.asRaster, sigmaWeights);

      # Add smoothed DEM to grid
      smoothDEM.grid = as(smoothDEM.asRaster,'SpatialPixelsDataFrame')
      gridded(smoothDEM.grid) = TRUE;
      fullgrid(smoothDEM.grid) = TRUE;
      names(smoothDEM.grid)[1] = var.name.smoothedDEM
      grid$smoothDEM = NULL;
      grid$smoothDEM = smoothDEM.grid[[var.name.smoothedDEM]]

      if (debug.level>0)
        message('... Storing smoothed DEM grid into envir. variable.');
      if (is.null(pkg.env$smoothDEM.grid)) {
	      pkg.env$smoothDEM.grid = smoothDEM.grid;
      } else {

        # Assess if the maximum number of stored grids is exceeded. If so, then delete the first grid.
        if (maxStoredGrids>0) {
          if (is.null(pkg.env$smoothDEM.grid)) {
            var.name.all=NULL;
          } else {
            var.name.all = names(pkg.env$smoothDEM.grid)
          }
          if (!is.null(var.name.all) && length(var.name.all)>= maxStoredGrids) {
            if (debug.level>0)
              message('... Removing least recently created smoothed DEM grid from enviroment memory.');
            filt = seq(length(var.name.all),1,-1) < maxStoredGrids
            pkg.env$smoothDEM.grid = pkg.env$smoothDEM.grid[var.name.all[filt]];
          }

          # Store grid
          pkg.env$smoothDEM.grid[[var.name.smoothedDEM]] = smoothDEM.grid[[var.name.smoothedDEM]];

        }
      }
  } else {
    if (debug.level>0)
      message('... Retrieving previously est. smoothed DEM names:',var.name.smoothedDEM)
    grid$smoothDEM = pkg.env$smoothDEM.grid[[var.name.smoothedDEM]];
  }

  # Interpolate smoothed grid
  if (!is.null(data)) {
    if (debug.level>0)
      message('... Interpolating smoothed DEM grid to point locations.');
    grd.asRaster = raster(grid,layer='smoothDEM');
    data$smoothDEM = NULL;
    tmp = extract(grd.asRaster, data, method='bilinear');

    data$tmpName =  tmp;
    ncols = length(names(data))
    names(data)[ncols] = 'smoothDEM'

    # Append interpolated points to enviro variable
    if (is.null(pkg.env$smoothDEM.data) || length(data) != length(pkg.env$smoothDEM.data)) {
      if (debug.level>0)
        message('... Append interpolated points to pkg.env');
      Easting = coordinates(data)[1];
      Northing = coordinates(data)[2];
      tmp = data.frame(Easting, Northing, tmp);
      names(tmp) = c('Easting','Northing',var.name.smoothedDEM)
      coordinates(tmp) = ~Easting + Northing
      pkg.env$smoothDEM.data = tmp;

    } else {
      pkg.env$smoothDEM.data$tmp = tmp;
    }
    if (debug.level>0)
      message('... Editing column names in pkg.env');
    ncols = length(names(pkg.env$smoothDEM.data))
    names(pkg.env$smoothDEM.data)[ncols] = var.name.smoothedDEM;
    rm(tmp);

    if (debug.level>0)
      message('... Finished interpolating smoothed DEM grid to point locations.');
    return(data);

  } else {
    return(grid);
  }

}
