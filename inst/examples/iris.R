#!/usr/bin/env Rscript
CONFIG <- rconfig::rconfig()
verbose <- rconfig::value(CONFIG$verbose, FALSE)
if (verbose)
    message(Sys.time(), " - Started")
species <- rconfig::value(
    CONFIG$species,
    stop("Species not provided", call. = FALSE))
if (!(species %in% iris$Species))
    stop("Provide a valid species")
if (verbose)
    message("Getting summaries for species ", species)
summary(iris[iris$Species == species, 1:4])
if (verbose)
    message(Sys.time(), " - Done")
