#' @include RNAmodR.R
#' @include ModifierSet-class.R
NULL

#' @name compareByCoord
#' @aliases compare compareByCoord plotCompare plotCompareByCoord 
#' 
#' @title Comparison of Samples
#' 
#' @description 
#' To compare data of different samples, a
#' \code{\link[=ModifierSet-class]{ModifierSet}} can be used. To select the data
#' alongside the transcripts and their positions a
#' \code{\link[GenomicRanges:GRanges-class]{GRanges}} or a
#' \code{\link[GenomicRanges:GRanges-class]{GRangesList}} needs to be provided.
#' In case of a \code{GRanges} object, the parent column must match the
#' transcript names as defined by the out put of \code{ranges(x)}, whereas in
#' case of a \code{GRangesList} the element names must match the transcript
#' names.
#' 
#' @param x a \code{Modifier} or \code{ModifierSet} object.
#' @param coord coordinates of position to subset to. Either a \code{GRanges} or
#'   a \code{GRangesList} object. For both types the 'Parent' column is expected
#'   to match the transcript name. The \code{GRangesList} object is
#'   unlisted and only non duplicated entries are retained.
#' @param name Only for \code{compare}: the transcript name
#' @param pos Only for \code{compare}: pos for comparison
#' @param normalize either a single logical or character value. If it is a 
#' character, it must match one of the names in the \code{ModifierSet}.
#' @param ... optional parameters:
#' \itemize{
#' \item{\code{alias}} {a data.frame with two columns, \code{tx_id} and 
#' \code{name}, to convert transcipt ids to another identifier}
#' \item{\code{name}} {Limit results to one specific gene or transcript}
#' \item{\code{sequenceData}} {TRUE or FALSE? Should the aggregate of 
#' sequenceData be used for the comparison instead of the aggregate data if each
#' \code{Modifier} element? (default: \code{sequenceData = FALSE})}
#' \item{\code{compareType}} {a valid score type to use for the comparison. If
#' \code{sequenceData = FALSE} this defaults to \code{mainScore(x)}, whereas
#' if \code{sequenceData = TRUE} all columns will be used by setting 
#' \code{allTypes = TRUE}.}
#' \item{\code{allTypes}} {TRUE or FALSE? Should all available score be 
#' compared? (default: \code{allTypes = sequenceData})}
#' \item{...} {passed on to \code{\link{subsetByCoord}}}
#' }
#' 
#' @return \code{compareByCoord} returns a
#'   \code{\link[S4Vectors:DataFrame-class]{DataFrame}} and
#'   \code{plotCompareByCoord} returns a \code{ggplot} object, which can be
#'   modified further. The \code{DataFrame} contains columns per sample as well
#'   as the columns \code{names}, \code{positions} and \code{mod} incorporated
#'   from the \code{coord} input. If \code{coord} contains a column
#'   \code{Activity} this is included in the results as well.
#' 
#' @examples
#' data(msi,package="RNAmodR")
#' # constructing a GRanges obejct to mark positive positions
#' mod <- modifications(msi)
#' coord <- unique(unlist(mod))
#' coord$score <- NULL
#' coord$sd <- NULL
#' # return a DataFrame
#' compareByCoord(msi,coord)
#' # plot the comparison as a heatmap
#' plotCompareByCoord(msi,coord)
NULL

.norm_alias <- function(input, x){
  alias <- NULL
  if(!is.null(input[["alias"]])){
    alias <- input[["alias"]]
    if(!is.data.frame(alias)){
      stop("'alias' has to be a data.frame with 'tx_id' and 'name' columns.",
           call. = FALSE)
    }
    colnames <- c("tx_id","name")
    if(!all(colnames %in% colnames(alias))){
      stop("'alias' has to be a data.frame with 'tx_id' and 'name' columns.",
           call. = FALSE)
    }
    alias <- alias[,colnames]
    if(any(duplicated(alias$tx_id))){
      stop("Values in 'tx_id' have to be unique.",
           call. = FALSE)
    }
    ranges_names <- names(ranges(x))
    if(!all(alias$tx_id %in% ranges_names)){
      stop("All values in 'tx_id' have to be valid transcript ids used as ",
           "names for the data.", call. = FALSE)
    }
  }
  list(alias = alias)
}

.compare_settings <- data.frame(
  variable = c("compareType",
               "allTypes",
               "perTranscript",
               "sequenceData"),
  testFUN = c(".is_non_empty_string",
              ".is_a_bool",
              ".is_a_bool",
              ".is_a_bool"),
  errorValue = c(FALSE,
                 FALSE,
                 FALSE,
                 FALSE),
  errorMessage = c("'compareType' must be a character and a valid colname in the aggregated data of 'x'.",
                   "'allTypes' must be a single logical value.",
                   "'perTranscript' must be a single logical value.",
                   "'sequenceData' must be a single logical value."),
  stringsAsFactors = FALSE)

.norm_compare_args <- function(input, data, x){
  if(is(x,"ModifierSet")){
    compareType <- mainScore(x)
  } else {
    compareType <- NA_character_
  }
  allTypes <- FALSE
  perTranscript <- FALSE
  sequenceData <- FALSE
  args <- .norm_settings(input, .compare_settings, compareType, allTypes,
                         perTranscript, sequenceData)
  if(args[["sequenceData"]] && is.null(input[["allTypes"]]) & 
     is.null(input[["compareType"]])){
    args[["allTypes"]] <- TRUE
  }
  colnames <- colnames(unlist(data[[1]]))
  if(args[["allTypes"]]){
    args[["compareType"]] <- colnames
  }
  if(!anyNA(args[["compareType"]]) && !(args[["compareType"]] %in% colnames)){
    stop("'compareType' must be a character and a valid colnames in the ",
         "aggregated data of 'x'.", call. = FALSE)
  }
  if(anyNA(args[["compareType"]]) & args[["sequenceData"]] & 
     !args[["allTypes"]]){
    stop("'compareType' must be set if 'sequenceData = TRUE' and ",
         "'allTypes = FALSE'", call. = FALSE)
  }
  args <- c(.norm_alias(input, x),
            args)
  args
}

.compare_ModifierSet_by_GRangesList <- function(x, coord, normalize, ...){
  coord <- unlist(coord)
  coord <- unname(coord[!duplicated(coord)])
  .compare_ModifierSet_by_GRanges(x, coord, normalize, ...)
}

.assemble_data_per_compare_type <- function(data, coord, sampleNames, alias, 
                                            modType){
  data <- do.call(cbind,data)
  colnames(data) <- sampleNames
  if(!is(data,"CompressedSplitDataFrameList")){
    data <- IRanges::SplitDataFrameList(data)
  }
  coord <- coord[match(names(data), names(coord))]
  # keep rownames/names and unlist data
  positions <- rownames(data)
  data_names <- as.character(S4Vectors::Rle(names(data), lengths(data)))
  partitioning_data <- IRanges::PartitioningByEnd(data)
  data <- unlist(data,use.names=FALSE)
  # add names and positions column as factors
  data$names <- factor(data_names)
  data$positions <- factor(as.integer(unlist(positions)))
  rownames(data) <- NULL
  # subset to specific modType, if set
  if(any(!is.na(modType)) && !is.null(unlist(coord)$mod)){
    coord <- coord[mcols(coord,level="within")[,"mod"] %in% modType,]
  }
  # add activity information if present
  unlisted_coord <- unlist(coord,use.names = FALSE)
  if(!is.null(unlisted_coord$Activity) || !is.null(unlisted_coord$mod)){
    f <- match(start(coord),relist(data$positions,partitioning_data))
    ff <- !is.na(f)
    f <- f[ff]
    f <- f + start(IRanges::PartitioningByEnd(partitioning_data)) - 1L
    f <- unlist(f)
    if(!is.null(unlisted_coord$Activity)){
      data$Activity <- ""
      data$Activity[f] <- vapply(unlisted_coord$Activity, paste, character(1),
                                 collapse = "/")[unlist(ff)]
    }
    if(!is.null(unlisted_coord$mod)){
      data$mod <- ""
      data$mod[f] <- unlisted_coord$mod[unlist(ff)]
    }
  }
  # convert ids to names for labeling if present
  if(!is.null(alias)){
    m <- match(data$names,as.character(alias$tx_id))
    data$names <- as.character(alias$name)[m[!is.na(m)]]
  }
  data
}

.compare_ModifierSet_by_GRanges <- function(x, coord, normalize, ...){
  coord <- .norm_coord(coord, modType(x))
  data <- subsetByCoord(x, coord, ...)
  args <- .norm_compare_args(list(...), data, x)
  # restructure to different compare types
  sampleNames <- names(data)
  compareTypes <- args[["compareType"]]
  if(args[["sequenceData"]]){
    modType <- NA
  } else {
    modType <- modType(x)
  }
  data <- lapply(compareTypes,
                 function(ct){
                   lapply(data,
                          function(d){
                            d[,ct,drop = FALSE]
                          })
                 })
  names(data) <- compareTypes
  # assamble data
  data <- lapply(data, .assemble_data_per_compare_type, coord, sampleNames,
                 args[["alias"]], modType)
  # normalize data
  data <- lapply(data, .normlize_data_against_one_sample, normalize)
  if(length(data) == 1L){
    return(data[[1L]])
  }
  data
}

#' @rdname compareByCoord
#' @export
setMethod("compare",
          signature = c("ModifierSet"),
          function(x, name, pos = 1L, normalize, ...){
            coord <- .construct_coord_from_name_from_to(x, name, pos)
            ans <- .compare_ModifierSet_by_GRanges(x, coord, normalize, ...)
            ans$mod <- NULL
            ans
          }
)

#' @rdname compareByCoord
#' @export
setMethod("compareByCoord",
          signature = c("ModifierSet","GRanges"),
          function(x, coord, normalize, ...){
            .compare_ModifierSet_by_GRanges(x, coord, normalize, ...)
          }
)

#' @rdname compareByCoord
#' @export
setMethod("compareByCoord",
          signature = c("ModifierSet","GRangesList"),
          function(x, coord, normalize, ...){
            .compare_ModifierSet_by_GRangesList(x, coord, normalize, ...)
          }
)

.normlize_data_against_one_sample <- function(data, normalize){
  if(!missing(normalize)){
    colnames <- colnames(data)
    colnames <- colnames[!(colnames %in% c("positions","names","mod","Activity"))]
    if(is.character(normalize)){
      if(!.is_non_empty_string(normalize)){
        stop("'normalize' must be single non empty character value.",
             call. = FALSE)
      }
      if(!(normalize %in% colnames)){
        stop("Data column '",normalize,"' not found in data. Available columns",
             " are '",paste(colnames, collapse = "','"),"'.",
             call. = FALSE)
      }
      data[,colnames] <- as.data.frame(data[,colnames,drop = FALSE]) - 
        data[,normalize]
    } else if(is.logical(normalize)){
      if(!.is_a_bool(normalize)){
        stop("'normalize' has to be TRUE or FALSE.",
             call. = FALSE)
      }
      if(normalize){
        data[,colnames] <- as.data.frame(data[,colnames,drop = FALSE]) - 
          apply(data[,colnames],1,max)
      }
    } else {
      stop("'normalize' must be a single character or a logical value.",
           call. = FALSE)
    }
  }
  data
}

.norm_compare_plot_args <- function(input){
  limits <- NA
  if(!is.null(input[["limits"]])){
    limits <- input[["limits"]]
    if(!is.numeric(limits) | length(limits) != 2L){
      stop("'limits' must be numeric vector with the length == 2.",
           call. = FALSE)
    }
  }
  args <- list(limits = limits)
  args
}

.create_position_labels <- function(positions, mod, activity){
  if(is.factor(positions)){
    positions <- as.numeric(as.character(positions))
  }
  tmp <- list(as.character(positions),
              mod,
              activity)
  spacer <- lapply(tmp,
                   function(el){
                     if(is.null(el)) return(NULL)
                     length <- nchar(el)
                     missingLength <- max(length) - length
                     unlist(lapply(missingLength,
                                   function(n){
                                     paste0(rep(" ",n),collapse = "")
                                   }))
                   })
  sep <- lapply(seq_along(tmp),
                   function(i){
                     if(i > 1L){
                       rep(" - ",length(tmp[[i]]))
                     } else {
                       rep("",length(tmp[[i]]))
                     }
                   })
  labels <- Map(paste0, spacer, tmp, sep)
  labels <- Reduce(paste0, rev(labels))
  f <- factor(labels, levels = unique(labels))
  stats::reorder(f,positions)
}

.create_sample_labels <- function(labels){
  labels <- as.character(labels)
  labels <- gsub("\\.", " ",labels)
  factor(labels, levels = unique(labels))
}

.plot_compare_ModifierSet_by_GRangesList <- function(x, coord, normalize, ...){
  coord <- unlist(coord)
  coord <- unname(coord[!duplicated(coord)])
  .plot_compare_ModifierSet_by_GRanges(x, coord, normalize, ...)
}

#' @importFrom ggplot2 ggplot geom_raster
#' @importFrom colorRamps matlab.like
#' @importFrom reshape2 melt
.plot_compare_ModifierSet_by_GRanges <- function(x, coord, normalize,  ...){
  data <- .compare_ModifierSet_by_GRanges(x, coord, normalize, ...)
  .plot_compare_ModifierSet(x, data, normalize, ...)
}

.plot_compare_ModifierSet <- function(x, data, normalize, ...){
  args <- .norm_compare_plot_args(list(...))
  data$labels <- .create_position_labels(data$positions, data$mod,
                                         data$Activity)
  # melt data an plot
  data$labels <- factor(data$labels, levels = rev(levels(data$labels)))
  data$positions <- NULL
  data$mod <- NULL
  data$Activity <- NULL
  data <- reshape2::melt(as.data.frame(data), id.vars = c("names","labels"))
  data$variable <- .create_sample_labels(data$variable)
  # adjust limits
  limits <- NA
  if(!missing(normalize) && normalize != FALSE){
    max <- max(max(data$value),abs(min(data$value)))
    max <- max(max,0.5)
    max <- round(max,1) + 0.1
    limits <- c(-max,max)
  } else {
    limits <- c(0,ceiling(max(data$value)))
  }
  if(all(!is.na(args[["limits"]]))){
    if(limits[1L] < args[["limits"]][1L] || limits[2L] > args[["limits"]][2L]){
      warning("Default limits for value data modified. This set some values ",
              "out of bounds.", call. = FALSE)
    }
    limits <- args[["limits"]]
  }
  # plot
  ggplot2::ggplot(data) + 
    ggplot2::geom_raster(mapping = ggplot2::aes_(x = ~variable,
                                                 y = ~labels,
                                                 fill = ~value)) +
    ggplot2::facet_grid(names ~ ., scales = "free", space = "free") +
    ggplot2::scale_fill_gradientn(name = "Score",
                                  colours = rev(colorRamps::matlab.like(100)),
                                  limits = limits) +
    ggplot2::scale_y_discrete(name = "Positions",
                              expand = c(0,0)) +
    ggplot2::scale_x_discrete(name = "Samples",
                              position = "top",
                              expand = c(0,0)) +
    ggplot2::theme_minimal() +
    ggplot2::theme(strip.text.y = ggplot2::element_text(angle = 0),
                   axis.text.x.top = ggplot2::element_text(angle = 30,hjust = 0))
}


#' @rdname compareByCoord
#' @export
setMethod("plotCompare",
          signature = c("ModifierSet"),
          function(x, name, pos = 1L, normalize, ...){
            data <- compare(x, name, pos, normalize, ...)
            .plot_compare_ModifierSet(x, data, normalize, ...)
          }
)

#' @rdname compareByCoord
#' @export
setMethod("plotCompareByCoord",
          signature = c("ModifierSet","GRanges"),
          function(x, coord, normalize, ...){
            .plot_compare_ModifierSet_by_GRanges(x, coord, normalize, ...)
          }
)

#' @rdname compareByCoord
#' @export
setMethod("plotCompareByCoord",
          signature = c("ModifierSet","GRangesList"),
          function(x, coord, normalize, ...){
            .plot_compare_ModifierSet_by_GRangesList(x, coord, normalize, ...)
          }
)
