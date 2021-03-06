krige.head.crossval <- function(newdata=NULL,  formula=NULL, model=NULL,model.landtype=NULL, model.landtype.head=NULL,model.fixedHead=NULL,
                                model.fixedHead.head=NULL,nmin=NULL,nmax=NULL,nmax.fixedHead=NULL,nmin.fixedHead=NULL,
                                omax.fixedHead=NULL,maxdist=NULL,omax=NULL,do.depth.est=T, use.MrVBF=F,use.MrRTF=F, use.DEMsmoothing=F,
                                use.LandCatagory=F, use.FixedHeads=F,data=NULL,data.fixedHead=NULL,data.weights=NULL,
                                smooth.std=NULL,trendMaxDistFrac=NULL,grid.elev=NULL,grid.MrVBF=NULL,grid.MrRTF=NULL,grid.LandType=NULL,
                                grid.params=NULL,debug.level=0) {
  if (is.null(newdata) || length(newdata)==0)
    stop('Kriging of point requires the input of "newdata" as a Spatial Point data Frame with >0 points.')

  #message(paste('DEBUGGING: length(newdata)=',length(newdata)))

  # Initialise data.
  nObs=length(newdata);
  est = matrix(nrow=0,ncol=7)
  newdata_orig = newdata;

  if (length(newdata)==0) {
    # Get list of variables and clear all except est
    vars = ls(all=FALSE)
    vars = vars[vars!='est']
    vars = vars[vars!='pkg.env']
    remove(list=vars)

    return(est)
  }


  # Check if terms other than start options are listed in the formula
  use.extraTerms = FALSE;
  var.names = all.vars(formula);
  ind = match(var.names, c('head','depth','elev','smoothing','MrVBF','MrRTF'))
  if (any(is.na(ind))) {
    use.extraTerms = T;
    use.extraTerms.names = var.names[is.na(ind)]
  }


  # Define matrix for adjacent cells to each obs point
  if (!use.DEMsmoothing && !is.null(smooth.std) && smooth.std>0) {
    cellDirs = matrix(1,5,5);
    cellDirs[3,3] = 0;
  }

  # Get coordinates of points to estimate
  easting  = coordinates(newdata)[,1]
  northing = coordinates(newdata)[,2]

  # Replace surveyed elevaton at point with DEM.
  newdata$elev = newdata$DEM;

  # If smoothing the predicted head, then extract grid data from grid cells adjacent to prodiction points.
  if (!use.DEMsmoothing && !is.null(smooth.std)  && smooth.std>0) {

    # Find grid cell number for obs point
    cellInd = extract(grid.elev, data.frame(Easting=easting,Northing=northing), cellnumbers=TRUE)[,1]

    # Find cells adjacent to tartget cell
    cellIndAdj = adjacent(grid.elev, cells=cellInd, directions=cellDirs,pairs=TRUE);

    # Get easting and northing of adjacent cells
    pointData_Easting = xFromCell(grid.elev, cellIndAdj[,2])
    pointData_Northing = yFromCell(grid.elev, cellIndAdj[,2])

    # Get MrVBF and MrRTF at adjacent cells
    if (use.MrVBF)
      pointData_MrVBF = extract(grid.MrVBF, cellIndAdj[,2]);
    if (use.MrRTF)
      pointData_MrRTF = extract(grid.MrRTF, cellIndAdj[,2]);
    if (use.LandCatagory)
      pointData_LandType = extract(grid.LandType, cellIndAdj[,2]);

    # Get DEM elevation at adjacent cells
    pointData_DEM = extract(grid.elev, cellIndAdj[,2]);

    # Get number of adjacent cells
    nAdjCells = length(cellIndAdj[,2])

    # Append newdata grid values to those extract
    if (use.MrVBF )
      pointData_MrVBF = c(pointData_MrVBF, newdata$MrVBF);
    if (use.MrRTF )
      pointData_MrRTF = c(pointData_MrRTF, newdata$MrRTF);
    if (use.DEMsmoothing)
      pointData_smoothing = c(pointData_smoothing, newdata$smoothing);
    if (use.LandCatagory)
      pointData_LandType = c(pointData_LandType, newdata$LandType);

    # Add coordinates of obs point
    pointData_Easting = c(pointData_Easting, easting);
    pointData_Northing = c(pointData_Northing, northing);

    # Make spatial object for adjacent cells
    newdata = data.frame(Easting = pointData_Easting, Northing= pointData_Northing,elev = pointData_DEM)
    if (use.MrVBF )
      newdata[['MrVBF']] = pointData_MrVBF;
    if (use.MrRTF )
      newdata[['MrRTF']] = pointData_MrRTF;
    if (use.DEMsmoothing)
      newdata[['smoothing']] = pointData_smoothing;
    if (use.LandCatagory)
      newdata[['LandType']] = pointData_LandType;
    coordinates(newdata) = ~Easting + Northing;

  } else {
    pointData_Easting = easting;
    pointData_Northing = northing;
  }

  # Build gstat object to allow efficient cross-validObject
  g = gstat(NULL, id='heads.cv',formula=formula, data=data, model=model, nmin=nmin, nmax=nmax, maxdist = maxdist, omax=omax, force=TRUE, weights = data.weights, set=list(trnd_threshdist=maxdist*trendMaxDistFrac));
  if (use.LandCatagory) {
    g = gstat(g,"land.type", formula = LandType ~ 1, data=data['LandType'], model = model.landtype, nmin=1, nmax=1, merge=c("heads.cv","land.type"))
    g = gstat(g, c("heads.cv","land.type"), model = model.landtype.head)
  }
  if (use.FixedHeads) {
    #g = gstat(g,"fixed.head", formula = formula, data=data.fixedHead, model = model.fixedHead, nmin=nmin.fixedHead, nmax=nmax.fixedHead, maxdist = maxdist, omax=omax.fixedHead, force=T, merge=c("heads.cv","fixed.head"))
    #g = gstat(g, c("heads.cv","fixed.head"), model = model.fixedHead.head)

    nVars = length(all.vars(formula,unique=T))-1
    mergeVarIDs = c("heads", 2, "fixed.head", 2)
    for (i in 2:nVars) {
      mergeVarIDs = c(mergeVarIDs, "heads.cv", i+1, "fixed.head", i+1)
    }

    g = gstat(g,"fixed.head", formula = formula, data=data.fixedHead, model = model.fixedHead, nmin=nmin.fixedHead, nmax=nmax.fixedHead, maxdist = maxdist, omax=omax.fixedHead, force=T,merge=c("heads.cv","fixed.head"))
    g = gstat(g, c("heads.cv","fixed.head"), model = model.fixedHead.head, merge=list(mergeVarIDs))

  }

  if (debug.level>0) {
    message(paste('... No. & mean newdata obs head finite values = ',sum(is.finite(newdata$head)),', ',mean(newdata$head,na.rm =T) ))
    message(paste('... No. & mean data obs head finite values = ',sum(is.finite(data$head)),', ',mean(data$head,na.rm =T) ))
    message(paste('... No. & mean newdata DEM finite values = ',sum(is.finite(newdata$DEM)),', ',mean(newdata$DEM,na.rm =T) ))
    message(paste('... No. & mean data obs DEM finite values = ',sum(is.finite(data$DEM)),', ',mean(data$DEM,na.rm =T) ))

    if (use.MrVBF) {
      message(paste('... No. & mean newdata MrVBF finite values = ',sum(is.finite(newdata$MrVBF)),', ',mean(newdata$MrVBF,na.rm =T) ))
      message(paste('... No. & mean data obs MrVBF finite values = ',sum(is.finite(data$MrVBF)),', ',mean(data$MrVBF,na.rm =T) ))
    }

    if (use.MrRTF) {
      message(paste('... No. & mean newdata MrRTF finite values = ',sum(is.finite(newdata$MrRTF)),', ',mean(newdata$MrRTF,na.rm =T) ))
      message(paste('... No. & mean data obs MrRTF finite values = ',sum(is.finite(data$MrRTF)),', ',mean(data$MrRTF,na.rm =T) ))
    }

    if (use.DEMsmoothing) {
      message(paste('... No. & mean newdata DEM-smoothing finite values = ',sum(is.finite(newdata$smoothing)),', ',mean(newdata$smoothing,na.rm =T) ))
      message(paste('... No. & mean data obs DEM-smoothing finite values = ',sum(is.finite(data$smoothing)),', ',mean(data$smoothing,na.rm =T) ))
    }

    if (use.LandCatagory) {
      message(paste('... No. & mean newdata LandType finite values = ',sum(is.finite(newdata$LandType)),', ',mean(newdata$LandType,na.rm =T) ))
      message(paste('... No. & mean data obsLandType finite values = ',sum(is.finite(data$LandType)),', ',mean(data$LandType,na.rm =T) ))
    }

    colnames = names(newdata);
    for (i in 1:length(colnames)) {
       if (use.extraTerms && any(!is.na(match(use.extraTerms.names,colnames[i]))))
         message(paste('... No. & mean newdata ',colnames[i],' finite values = ',sum(is.finite(newdata[[colnames[i]]])),', ',mean(newdata[[colnames[i]]],na.rm =T) ))
    }

    colnames = names(data);
    for (i in 1:length(colnames)) {
       if (use.extraTerms && all(!is.na(match(use.extraTerms.names,colnames[i]))))
         message(paste('... No. & mean data ',colnames[i],' finite values = ',sum(is.finite(data[[colnames[i]]])),', ',mean(newdata$head,na.rm =T) ))
    }

    if (use.FixedHeads) {
      message(paste('... No. & mean data.fixedHead obs head finite values = ',sum(is.finite(data.fixedHead$head)),', ',mean(data.fixedHead$head,na.rm =T) ))
      message(paste('... No. & mean data.fixedHead DEM finite values = ',sum(is.finite(data.fixedHead$DEM)),', ',mean(data.fixedHead$DEM,na.rm =T) ))

      if (use.MrVBF)
        message(paste('... No. & mean data obs MrVBF finite values = ',sum(is.finite(data.fixedHead$MrVBF)),', ',mean(data.fixedHead$MrVBF,na.rm =T) ))

      if (use.MrRTF)
        message(paste('... No. & mean data obs MrRTF finite values = ',sum(is.finite(data.fixedHead$MrRTF)),', ',mean(data.fixedHead$MrRTF,na.rm =T) ))

      if (use.DEMsmoothing)
        message(paste('... No. & mean data obs DEM-smoothing finite values = ',sum(is.finite(data.fixedHead$smoothing)),', ',mean(data.fixedHead$smoothing,na.rm =T) ))

      if (use.LandCatagory)
        message(paste('... No. & mean data obsLandType finite values = ',sum(is.finite(data.fixedHead$LandType)),', ',mean(data.fixedHead$LandType,na.rm =T) ))

      colnames = names(data.fixedHead);
      for (i in 1:length(colnames)) {
         if (use.extraTerms && all(!is.na(match(use.extraTerms.names,colnames[i]))))
           message(paste('... No. & mean data.fixedHead ',colnames[i],' finite values = ',sum(is.finite(data.fixedHead[[colnames[i]]])),', ',mean(data.fixedHead[[colnames[i]]],na.rm =T) ))
    }


    }

  }


  # Krige all newdata points
  est_tmp = predict(g, newdata=newdata, debug.level=debug.level);
  if (debug.level>0) {
    message(paste('... Total kriged points =',length(est_tmp)))
  }

  # Est RWL at nAdjCells+1 points
  if (do.depth.est) {
    head = pointData_DEM - est_tmp$heads.cv.pred;
  } else
    head = est_tmp$heads.cv.pred;

  # Build filter to non NAN values
  filt = !(is.na(pointData_Easting) | is.na(pointData_Northing) | is.na(head)) & !(is.nan(pointData_Easting) | is.nan(pointData_Northing) | is.nan(head));

  if (debug.level>0) {
    message(paste('... No. newdata NA head estimates =',sum(is.na(head)) ))
    message(paste('... No. newdata NAN head estimates =',sum(is.nan(head)) ))
  }


  # Apply Gussian blur
  if (!use.DEMsmoothing && !is.null(smooth.std) && smooth.std>0) {
    j=0;
    head=c();
    head.obs=c();
    krige.var=c();
    keep.est = logical(nObs);
    for (i in 1:nObs) {
      # Check prediction point i could be estimated
      if (!filt[nAdjCells+i])
        next

      keep.est[i] = TRUE;

      # Find indexes to adjacent to prediction point
      neighbour.ind  = which(cellIndAdj[,1]==i);

      # Add prediction point to indexes
      neighbour.ind = c(nAdjCells+i, neighbour.ind);

      # Remove any values assessed as erroneous
      filt.neighbour = filt[neighbour.ind]
      neighbour.ind = neighbour.ind[filt.neighbour];

      # Extract position of cells at and around prediction point
      pointData_Easting_aroundObs = pointData_Easting[neighbour.ind]
      pointData_Northing_aroundObs = pointData_Northing[neighbour.ind]
      pointData_Head_aroundObs = head[neighbour.ind]
      pointData_Var_aroundObs = st_tmp$heads.cv.var[neighbour.ind]

      # Apply weights
      sigmaWeights = 1/(2*pi*smooth.std^2) * exp(-( ((pointData_Easting_aroundObs - easting[i])/grid.params$cellsize[1])^2 + ((pointData_Northing_aroundObs - northing[i])/grid.params$cellsize[2])^2)/(2*smooth.std^2) )
      sigmaWeights = sigmaWeights/sum(sigmaWeights);
      head[i]  = sum(pointData_Head_aroundObs  * sigmaWeights);
      krige.var[i]  = sum(pointData_Var_aroundObs * sigmaWeights);
      head.obs[i] = newdata_orig$head[i];
    }

    easting = easting[keep.est];
    northing = northing[keep.est];
    head = head[keep.est];
    krige.var = krige.var[keep.est];
    head.obs = head.obs[keep.est];
    pointData_DEM = newdata$DEM[keep.est];
  } else {
    easting = easting[filt];
    northing = northing[filt];
    head  = head[filt];
    krige.var  = est_tmp$heads.cv.var[filt];
    head.obs = newdata_orig$head[filt];
    pointData_DEM = newdata$DEM[filt];
  }

  est = matrix(nrow=length(easting),ncol=7)
  est[,1] = easting
  est[,2] = northing
  est[,3] = head.obs
  est[,4] = head;			            # Head est.
  est[,5] = krige.var;			      # Kriging variance
  est[,6] = head.obs - head	;     # Residual
  est[,7] = pointData_DEM;     # DEM elevation

  return(est);
}
