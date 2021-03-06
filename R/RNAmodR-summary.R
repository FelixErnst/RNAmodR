#' @include RNAmodR.R
#' @include SequenceData-class.R
#' @include SequenceDataSet-class.R
#' @include SequenceDataList-class.R
#' @include Modifier-class.R
#' @include ModifierSet-class.R
NULL

.get_bamfiles_stats <- function(object){
  stats <- lapply(bamfiles(object),Rsamtools::idxstatsBam)
  stats <- data.frame(vapply(seq_along(stats),
                             function(i){
                               c(condition = names(stats[i]),
                                 mapped = sum(stats[[i]]$mapped),
                                 unmapped = sum(stats[[i]]$unmapped))
                             },
                             character(3)),
                      stringsAsFactors = FALSE)
  colnames(stats) <- basename(path(bamfiles(object)))
  rownames(stats) <- paste0("Bam.",rownames(stats))
  stats
}

.get_data_stats <- function(object){
  unlisted_object <- unlist(object, use.names = FALSE)
  stats <- lapply(seq_len(ncol(unlisted_object)),
                  function(i){
                    as.data.frame(as.list(summary(unlisted_object[,i])))
                  })
  stats <- Reduce(rbind,stats)
  stats <- as.data.frame(t(stats),
                         stringsAsFactors = FALSE)
  colnames(stats) <- colnames(unlisted_object)
  rownames(stats) <- paste0("Data.",rownames(stats))
  stats
}

.merge_summary_data <- function(bamfilesstats,datastats){
  bf_d_names <- c(rownames(bamfilesstats),rownames(datastats))
  stats <- data.frame(mapply(c,
                             as.list(bamfilesstats),
                             as.list(datastats)),
                      stringsAsFactors = FALSE)
  rownames(stats) <- bf_d_names
  colnames(stats) <- colnames(bamfilesstats)
  stats
}

.get_summary_SequenceData <- function(object){
  bamfilesstats <- .get_bamfiles_stats(object)
  datastats <- .get_data_stats(object)
  .merge_summary_data(bamfilesstats,datastats)
}

setMethod("summary",
          signature = "SequenceData",
          function(object){
            .get_summary_SequenceData(object)
          })

setMethod("summary",
          signature = "SequenceDataSet",
          function(object){
            stats <- lapply(object, summary)
            stats <- lapply(seq_along(stats),
                            function(i){
                              s <- stats[[i]]
                              if(i > 1L){
                                s <- s[!grepl("Bam",rownames(s)),,drop=FALSE]
                              }
                              rownames(s) <- gsub("Data",class(object[[i]]),
                                                  rownames(s))
                              rownames(s) <- gsub("SequenceData","",rownames(s))
                              s
                            })
            Reduce(rbind,stats)
          })

setMethod("summary",
          signature = "SequenceDataList",
          function(object){
            stats <- lapply(object, summary)
            stats <- lapply(seq_along(stats),
                            function(i){
                              s <- stats[[i]]
                              if(i > 1L){
                                s <- s[!grepl("Bam",rownames(s)),,drop=FALSE]
                              }
                              rownames(s) <- gsub("Data",class(object[[i]]),
                                                  rownames(s))
                              rownames(s) <- gsub("SequenceData","",rownames(s))
                              s
                            })
            Reduce(rbind,stats)
          })

setMethod("summary",
          signature = "Modifier",
          function(object){
            bamfilesstats <- .get_bamfiles_stats(object)
            datastats <- .get_data_stats(getAggregateData(object))
            return(list("bamfiles" = bamfilesstats,
                        "aggregated data" = datastats))
          })

setMethod("summary",
          signature = "ModifierSet",
          function(object){
            lapply(object, summary)
          })
