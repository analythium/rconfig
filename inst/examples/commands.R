#!/usr/bin/env Rscript
CONFIG <- rconfig::rconfig()

SILENT <- rconfig::value(CONFIG$silent, FALSE)

model <- function() {
    if (!SILENT)
        message("Model ...")
    # your logic comes here
}

pred <- function() {
    if (!SILENT)
        message("Predict ...")
    # your logic comes here
}

main <- function() {
    cmd <- rconfig::command(CONFIG)
    if (length(cmd) == 0L)
        stop("Specify a command.", call. = FALSE)
    if (cmd[1L] == "model") {
        model()
    } else if (cmd[1L] == "predict") {
        pred()
    } else {
        stop("Command ", cmd, " not found.", call. = FALSE)
    }
}

main()
