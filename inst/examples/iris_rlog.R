#!/usr/bin/env Rscript

#' Usage:
#'
#' Rscript iris_rlog.R --species virginica > iris.log 2>&1
#' Rscript iris_rlog.R --species maxima > iris.log 2>&1
#'
#' Rscript iris_rlog.R --species virginica > iris.log 2> iris.err
#' Rscript iris_rlog.R --species maxima > iris.log 2> iris.err
#'
#' Note: this script requires the rlog package

options(digits.secs = 3)
abort <- function(...) {
    rlog::log_error(paste(...))
    if (!interactive())
        q(status = 1)
}
info <- function(...) {
    rlog::log_info(paste(...))
}
CONFIG <- rconfig::rconfig()

info("Started")
species <- rconfig::value(
    CONFIG$species,
    abort("Species not provided"))
if (!(species %in% iris$Species))
    abort("Provide a valid species")
info("Getting summaries for species", species)
summary(iris[iris$Species == species, 1:4])
info("Done")

q(status = 0)
