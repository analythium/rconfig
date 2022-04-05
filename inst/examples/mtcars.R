#!/usr/bin/env Rscript
CONFIG <- rconfig::rconfig()
verbose <- rconfig::value(CONFIG$verbose, FALSE)
if (verbose)
    message(Sys.time(), " - Started")
vars <- rconfig::value(
    CONFIG$vars,
    colnames(mtcars)[-1L])
if (any(!(vars %in% colnames(mtcars)[-1L])))
    stop("Not valid variable")
coef(lm(mpg ~ ., mtcars[,c("mpg", vars)]))
if (verbose)
    message(Sys.time(), " - Done")
