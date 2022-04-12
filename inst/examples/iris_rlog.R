#!/usr/bin/env Rscript

#' Usage:
#'
#' Rscript iris_rlog.R --species virginica > iris.log 2>&1
#' Rscript iris_rlog.R > iris.log 2>&1
#' Rscript iris_rlog.R --species maxima > iris.log 2>&1
#'
#' Rscript iris_rlog.R --species virginica > iris.log 2> iris.err
#' Rscript iris_rlog.R > iris.log 2> iris.err
#' Rscript iris_rlog.R --species maxima > iris.log 2> iris.err
#'
#' Note: this script requires the rlog package

info <- function(...) {
    rlog::log_info(paste(...))
}
error <- function(...) {
    rlog::log_error(paste(...))
    if (!interactive())
        q(status = 1)
}
abort <- function(...) {
    error(geterrmessage())
}
options(digits.secs = 3, error = abort)
CONFIG <- rconfig::rconfig()

info("Started")

species <- rconfig::value(
    CONFIG$species,
    error("Species not provided")) # anticipated error

## Make invalid species names a non-anticipated error
# if (!(species %in% iris$Species))
#     error("Provide a valid species")

info("Getting summaries for species", species)
summary(iris[iris$Species %in% species, 1:4])

info("Done")

q(status = 0)
