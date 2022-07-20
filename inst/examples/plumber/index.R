#!/usr/bin/env Rscript

library(plumber)
library(rconfig)
CONFIG <- rconfig()
TEST <- value(CONFIG$test, FALSE)
message("Mode: ", if (TEST) "Test" else "Prod")

pr("handler.R") |>
    pr_run(
        port = value(CONFIG$port, 8080)
    )
