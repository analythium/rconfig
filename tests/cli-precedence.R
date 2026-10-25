local({
    default_file <- tempfile(fileext = ".yml")
    override_file <- tempfile(fileext = ".yml")
    script <- tempfile(fileext = ".R")
    on.exit(unlink(c(default_file, override_file, script)))

    writeLines(c(
        "shared: default",
        "default_only: default",
        "json_level: default",
        "flag_level: default",
        "file_level: default",
        "list_level: default"
    ), default_file)
    writeLines(c(
        "shared: file",
        "file_level: file",
        "list_level: file",
        "file_only: file"
    ), override_file)

    old_default <- Sys.getenv("R_RCONFIG_FILE", unset = NA_character_)
    Sys.setenv(R_RCONFIG_FILE = default_file)
    on.exit({
        if (is.na(old_default))
            Sys.unsetenv("R_RCONFIG_FILE")
        else
            Sys.setenv(R_RCONFIG_FILE = old_default)
    }, add = TRUE)

    config_call <- paste0(
        "config <- rconfig::rconfig(file = ",
        paste(deparse(override_file), collapse = ""),
        ", list = list(shared = 'list', list_level = 'list', list_only = 'list'))"
    )
    writeLines(c(
        config_call,
        "stopifnot(",
        "  identical(config[['shared']], 'list'),",
        "  identical(config[['default_only']], 'default'),",
        "  identical(config[['json_level']], 'json'),",
        "  identical(config[['flag_level']], 'cli'),",
        "  identical(config[['file_level']], 'file'),",
        "  identical(config[['list_level']], 'list'),",
        "  identical(config[['json_only']], 'json'),",
        "  identical(config[['flag_only']], 'cli'),",
        "  identical(config[['file_only']], 'file'),",
        "  identical(config[['list_only']], 'list')",
        ")",
        "cat('CLI_PRECEDENCE_OK\\n')"
    ), script)

    rscript <- file.path(
        R.home("bin"),
        if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"
    )
    json <- '{"shared":"json","json_level":"json","flag_level":"json","file_level":"json","list_level":"json","json_only":"json"}'
    output <- system2(
        rscript,
        args = c(
            shQuote(script),
            "-j", shQuote(json),
            "--shared", "cli",
            "--flag_level", "cli",
            "--file_level", "cli",
            "--list_level", "cli",
            "--flag_only", "cli"
        ),
        stdout = TRUE,
        stderr = TRUE
    )
    if (!any(grepl("CLI_PRECEDENCE_OK", output, fixed = TRUE)))
        stop("CLI precedence test failed:\n", paste(output, collapse = "\n"))
})
