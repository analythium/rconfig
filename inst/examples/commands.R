#!/usr/bin/env Rscript
CONFIG <- rconfig::rconfig()

model <- function(...) {
    message("Model ...")
    # your logic comes here
}

pred <- function(...) {
    message("Predict ...")
    # your logic comes here
}

if (rconfig::command(CONFIG)[1L] == "model") {
    model()
} else if (rconfig::command(CONFIG)[1L] == "predict") {
    pred()
} else {
    stop("Command ", rconfig::command(CONFIG)[1L], " not found.")
}
