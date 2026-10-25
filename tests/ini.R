local({
    file <- tempfile(fileext = ".ini")
    on.exit(unlink(file))

    writeLines(c(
        "[app]",
        "token = a=b:c",
        "url: https://example.test/query?a=b:c"
    ), file)

    config <- rconfig::read_ini(file)
    stopifnot(
        identical(config$app$token, "a=b:c"),
        identical(config$app$url, "https://example.test/query?a=b:c")
    )
})
