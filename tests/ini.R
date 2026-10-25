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
        "empty =",
        "no_value",
        "expr = !expr 2 + 3"
    ), file)

    config <- rconfig::read_ini(file)
    unevaluated_config <- rconfig::read_ini(file, eval = FALSE)
    evaluated_config <- rconfig::read_ini(file, eval = TRUE)
    options("rconfig.eval" = FALSE)
    option_disabled_config <- rconfig::read_ini(file)
    option_enabled_config <- rconfig::read_ini(file, eval = TRUE)
    options("rconfig.eval" = TRUE)
    eval_env <- Sys.getenv("R_RCONFIG_EVAL", unset = NA_character_)
    merged_config <- rconfig::rconfig(file = file, sub = FALSE)
    stopifnot(
        identical(config$app$token, "a=b:c"),
        identical(config$app$url, "https://example.test/query?a=b:c"),
        identical(config$app$count, "12"),
        identical(config$app$empty, ""),
        identical(config$app$no_value, ""),
        identical(config$app$expr, 5),
        identical(unevaluated_config$app$expr, "!expr 2 + 3"),
        identical(evaluated_config$app$expr, 5),
        identical(option_disabled_config$app$expr, "!expr 2 + 3"),
        identical(option_enabled_config$app$expr, 5),
        identical(eval_env, NA_character_),
        identical(merged_config$app$count, 12L),
        identical(merged_config$app$expr, 5)
    )
})
