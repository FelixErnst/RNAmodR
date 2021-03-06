#' @include RNAmodR.R
#' @include Modifier-class.R
#' @include ModifierSet-class.R
NULL

#' @name plotROC
#' 
#' @title ROCR functions for \code{Modifier} and \code{ModifierSet} objects
#' 
#' @description 
#' \code{plotROC} streamlines labeling, prediction, performance and plotting
#' functions to test the peformance of a \code{Modifier} object and the data 
#' analyzed via the functionallity from the \code{ROCR} package.
#' 
#' The data from \code{x} will be labeled as positive using the \code{coord}
#' arguments. The other arguments will be passed on to the specific \code{ROCR}
#' functions.
#' 
#' By default the \code{prediction.args} include three values:
#' \itemize{
#' \item{\code{measure = "tpr"}}
#' \item{\code{x.measure = "fpr"}}
#' \item{\code{score = mainScore(x)}}
#' }
#' The remaining arguments are not predefined.
#' 
#' @param x a \code{Modifier} or a \code{ModifierSet} object
#' @param coord coordinates of position to label as positive. Either a 
#' \code{GRanges} or a \code{GRangesList} object. For both types the Parent 
#' column is expected to match the gene or transcript name.
#' @param score the score identifier to subset to, if multiple scores are 
#' available.
#' @param prediction.args arguments which will be used for calling 
#' \code{\link[ROCR:prediction]{prediction}} form the \code{ROCR} package
#' @param performance.args arguments which will be used for calling 
#' \code{\link[ROCR:performance]{performance}} form the \code{ROCR} package
#' @param plot.args arguments which will be used for calling \code{plot} on the
#' performance object of the \code{ROCR} package. If multiple scores are plotted
#' (for example if the score argument is not explicitly set) \code{add = FALSE}
#' will be set.
#' @param ... additional arguments
#' 
#' @return a plot send to the active graphic device
#' 
#' @references 
#' Tobias Sing, Oliver Sander, Niko Beerenwinkel, Thomas Lengauer (2005): "ROCR:
#' visualizing classifier performance in R." Bioinformatics 21(20):3940-3941
#' DOI:
#' \href{https://doi.org/10.1093/bioinformatics/bti623}{10.1093/bioinformatics/bti623}
#' 
#' @examples 
#' data(msi,package="RNAmodR")
#' # constructing a GRanges obejct to mark positive positions
#' mod <- modifications(msi)
#' coord <- unique(unlist(mod))
#' coord$score <- NULL
#' coord$sd <- NULL
#' # plotting a TPR vs. FPR plot per ModInosine object
#' plotROC(msi[[1]],coord)
#' # plotting a TPR vs. FPR plot per ModSetInosine object
#' plotROC(msi,coord)
NULL

.norm_prediction_args <- function(input){
  if(!is.list(input)){
    stop("'prediction.args' must be a list.")
  }
  if(length(input) > 0L && 
     (any(is.null(names(input))) || any(names(input) == ""))){
    warning("Unnamed list for 'prediction.args'. All values will be dropped.")
    input <- list()
  }
  args <- input
  args
}

.rocr_exclusive_functions <- c("rch","auc","prbe","mxe","rmse","ecost")
.rocr_performance_settings <- data.frame(
  variable = c("measure",
               "x.measure",
               "score"),
  testFUN = c(".is_a_string",
              ".is_a_string",
              ".is_a_string"),
  errorValue = c(FALSE,
                 FALSE,
                 FALSE),
  errorMessage = c("'measure' must a single character compatible with ?ROCR::performance.",
                   "'x.measure' must a single character compatible with ?ROCR::performance.",
                   "'score' must a single character and a valid column name in getAggregateData()."),
  stringsAsFactors = FALSE)
.norm_performance_args <- function(input, x){
  if(!is.list(input)){
    stop("'performance.args' must be a list.")
  }
  if(length(input) > 0L && 
     (any(is.null(names(input))) || any(names(input) == ""))){
    warning("Unnamed list for 'performance.args'. All values will be dropped.")
    input <- list()
  }
  measure <- "tpr"
  x.measure <- "fpr"
  score <- mainScore(x)
  args <- .norm_settings(input, .rocr_performance_settings, measure, x.measure,
                         score)
  if(args[["measure"]] %in% .rocr_exclusive_functions){
    args[["x.measure"]] <- "cutoff"
  }
  if(is(x,"Modifier")){
    cn <- colnames(getAggregateData(x)[[1]])
  } else if(is(x,"ModifierSet")) {
    cn <- colnames(getAggregateData(x[[1]])[[1]])
  } else {
    stop("")
  }
  if(!(args[["score"]] %in% cn)){
    stop(.rocr_performance_settings[.rocr_performance_settings$variable == "score","errorMessage"],
         call. = FALSE)
  }
  args <- c(args, input[!(names(input) %in% names(args))])
  args
}

.rocr_plot_settings <- data.frame(
  variable = c("colorize",
               "lwd",
               "colorize.palette",
               "abline",
               "AUC"),
  testFUN = c(".is_a_bool",
              ".is_numeric_string",
              ".is_a_string",
              ".is_a_bool",
              ".is_a_bool"),
  errorValue = c(FALSE,
                 FALSE,
                 FALSE,
                 FALSE,
                 FALSE),
  errorMessage = c("'colorize' must a single logical value.",
                   "'lwd' must be a single numeric value.",
                   "'colorize.palette' must a single character compatible with ?ROCR::plot.performance.",
                   "'abline' must a single logical value.",
                   "'AUC' must a single logical value."),
  stringsAsFactors = FALSE)
.norm_plot_args <- function(input){
  if(!is.list(input)){
    stop("'plot.args' must be a list.")
  }
  if(length(input) > 0L && 
     (any(is.null(names(input))) || any(names(input) == ""))){
    warning("Unnamed list for 'plot.args'. All values will be dropped.")
    input <- list()
  }
  colorize <- TRUE
  lwd <- 3
  colorize.palette <- NULL
  abline <- FALSE
  AUC <- FALSE
  args <- .norm_settings(input, .rocr_plot_settings, colorize, lwd,
                         colorize.palette, abline, AUC)
  args <- c(args, input[!(names(input) %in% names(args))])
  args
}

#' @importFrom grDevices rainbow
.readjust_plot_args <- function(plot.args, performance.args){
  if(performance.args[["measure"]] %in% .rocr_exclusive_functions){
    plot.args[["colorize"]] <- NULL
  }
  if(is.null(plot.args[["avg"]])){
    plot.args[["avg"]] <- "none"
  }
  if(is.null(plot.args[["spread.estimate"]])){
    plot.args[["spread.estimate"]] <- "none"
  }
  if(is.null(plot.args[["spread.scale"]])){
    plot.args[["spread.scale"]] <- 1
  }
  if(is.null(plot.args[["show.spread.at"]])){
    plot.args[["show.spread.at"]] <- c()
  }
  if(is.null(plot.args[["colorize"]])){
    plot.args[["colorize"]] <- FALSE
  }
  if(is.null(plot.args[["colorize.palette"]])){
    plot.args[["colorize.palette"]] <- rev(grDevices::rainbow(256, start = 0,
                                                              end = 4/6))
  }
  if(is.null(plot.args[["colorkey"]])){
    plot.args[["colorkey"]] <- plot.args[["colorize"]] 
  }
  if(is.null(plot.args[["colorkey.relwidth"]])){
    plot.args[["colorkey.relwidth"]] <- 0.25
  }
  if(is.null(plot.args[["colorkey.pos"]])){
    plot.args[["colorkey.pos"]] <- "right"
  }
  if(is.null(plot.args[["print.cutoffs.at"]])){
    plot.args[["print.cutoffs.at"]] <- c()
  }
  if(is.null(plot.args[["cutoff.label.function"]])){
    plot.args[["cutoff.label.function"]] <- function(x) { round(x,2) }
  }
  if(is.null(plot.args[["downsampling"]])){
    plot.args[["downsampling"]] <- 0
  }
  if(is.null(plot.args[["add"]])){
    plot.args[["add"]] <- FALSE
  }
  return(plot.args)
}

.get_prediction_data_Modifier <- function(x, coord, score){
  data <- .label_Modifier_by_GRangesList(x, coord)
  unlisted_data <- unlist(data)
  # exempt character values
  f_non_character <- vapply(unlisted_data,
                            function(x) {
                              !is.character(x)
                            },logical(1))
  colnames <- colnames(unlisted_data)[f_non_character]
  if(!is.null(score)){
    if(!all(score %in% colnames)){
      stop("Score identifier '",
           paste(score[!(score %in% colnames)], collapse = "','"),
           "' not found in the data. Available ",
           "columns: '",paste(colnames[colnames != "labels"], collapse = "','"),
           "'.",
           call. = FALSE)
    }
  }
  colnames <- colnames[colnames != "labels"]
  data <- lapply(seq_along(colnames),
                 function(i){
                   cn <- colnames[i]
                   cn <- c("labels",cn)
                   d <- data[,cn]
                   colnames(d) <- c("labels","predictions")
                   d <- unlist(d)
                   rownames(d) <- NULL
                   d <- d[!is.na(d$predictions),]
                   d
                 })
  names(data) <- colnames
  data
}

.get_prediction_data_ModifierSet <- function(x, coord, score){
  data <- lapply(x, .get_prediction_data_Modifier, coord, score)
  data_names <- names(data[[1]])
  data <- lapply(data_names,
                 function(name){
                   lapply(data,"[[",name)
                 })
  data <- lapply(data,
                 function(d){
                   predictions <- as.data.frame(lapply(d,"[","predictions"))
                   labels <- as.data.frame(lapply(d,"[","labels"))
                   colnames(predictions) <- names(d)
                   colnames(labels) <- names(d)
                   list(predictions = predictions,
                        labels = labels)
                 })
  names(data) <- data_names
  data
}

#' @importFrom graphics par abline title legend plot.new
#' @importFrom ROCR prediction performance
.plot_ROCR <- function(data, prediction.args, performance.args, plot.args,
                       score){
  if(!is.null(score)){
    data <- data[names(data) %in% score]
  }
  plot.args <- .readjust_plot_args(plot.args, performance.args)
  # add argument logical vector
  n <- length(data)
  # save mfrow setting
  mfrow_bak <- graphics::par("mfrow")
  mfrow_col <- ceiling(sqrt(n))
  mfrow_row <- ceiling(n / mfrow_col)
  graphics::par(mfrow = c(mfrow_row,mfrow_col))
  n_remaining <- (mfrow_row * mfrow_col) - n
  #
  if(is.null(plot.args[["colorize.palette"]])){
    plot.args[["colorize.palette"]] <- NULL
  }
  if(n > 1L){
    plot.args[["add"]] <- FALSE
  }
  #
  Map(
    function(d, name, colour, prediction.args, performance.args, plot.args){
      pred <- do.call(ROCR::prediction, c(list(predictions = d$predictions, 
                                               labels = d$labels), 
                                          prediction.args))
      perf <- do.call(ROCR::performance, c(list(prediction.obj = pred),
                                           performance.args))
      tmp <- try(do.call(ROCR:::.plot.performance,
                         c(list(perf = perf), plot.args)),
                 silent = TRUE)
      if(is(tmp,"try-error")){
        stop("Error during plotting of performance object: ",tmp)
      }
      graphics::title(main = name)
      if(plot.args[["abline"]]){
        graphics::abline(a = 0, b = 1)
      }
      if(plot.args[["AUC"]]){
        auc <- unlist(slot(performance(pred,"auc"),"y.values"))
        auc <- paste(c("AUC = "), round(auc,2L), sep = "")
        graphics::legend(0.55, 0.25, auc, bty = "n", cex = 1)
      }
    },
    data,
    names(data),
    MoreArgs = list(prediction.args = prediction.args,
                    performance.args = performance.args,
                    plot.args = plot.args))
  for(i in seq_len(n_remaining)){
    graphics::plot.new()
  }
  graphics::par(mfrow = mfrow_bak)
  invisible(NULL)
}

#' @rdname plotROC
#' @export
setMethod(
  f = "plotROC", 
  signature = signature(x = "Modifier"),
  definition = function(x, coord, score = NULL, prediction.args = list(), 
                        performance.args = list(), plot.args = list()){
    coord <- .norm_coord(coord, modType(x))
    data <- .get_prediction_data_Modifier(x, coord, score)
    .plot_ROCR(data,
               .norm_prediction_args(prediction.args),
               .norm_performance_args(performance.args, x),
               .norm_plot_args(plot.args),
               score)
  }
)

#' @rdname plotROC
#' @export
setMethod(
  f = "plotROC", 
  signature = signature(x = "ModifierSet"),
  definition = function(x, coord, score = NULL, prediction.args = list(), 
                        performance.args = list(), plot.args = list()){
    coord <- .norm_coord(coord, modType(x))
    data <- .get_prediction_data_ModifierSet(x, coord, score)
    .plot_ROCR(data,
               .norm_prediction_args(prediction.args),
               .norm_performance_args(performance.args, x),
               .norm_plot_args(plot.args),
               score)
  }
)
