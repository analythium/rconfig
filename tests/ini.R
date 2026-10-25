local({
    file <- tempfile(fileext = ".ini")
    on.exit(unlink(file))

    old_eval <- Sys.getenv("R_RCONFIG_EVAL", unset = NA_character_)
    old_option <- options("rconfig.eval" = TRUE)
    Sys.unsetenv("R_RCONFIG_EVAL")
    on.exit({
        options(old_option)
        if (is.na(old_eval))
            Sys.unsetenv("R_RCONFIG_EVAL")
        else
            Sys.setenv(R_RCONFIG_EVAL = old_eval)
    }, add = TRUE)

    writeLines(c(
        "[app]",
        "token = a=b:c",
        "url: https://example.test/query?a=b:c",
        "count = 12",
        "expr = !expr 2 + 3"
    ), file)

    config <- rconfig::read_ini(file)
    merged_config <- rconfig::rconfig(file = file, sub = FALSE)
    stopifnot(
        identical(config$app$token, "a=b:c"),
        identical(config$app$url, "https://example.test/query?a=b:c"),
        identical(config$app$count, "12"),
        identical(config$app$expr, 5),
        identical(merged_config$app$count, 12L),
        identical(merged_config$app$expr, 5)
    )
})
