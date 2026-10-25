local({
    yml_file <- tempfile(fileext = ".yml")
    json_file <- tempfile(fileext = ".json")
    txt_file <- tempfile(fileext = ".txt")
    on.exit(unlink(c(yml_file, json_file, txt_file)))

    writeLines("expr: !expr 2 + 3", yml_file)
    writeLines('{"expr":"!expr 2 + 3"}', json_file)
    writeLines("expr=!expr 2 + 3", txt_file)

    stopifnot(
        identical(rconfig:::parse_yml(yml_file, eval = FALSE)$expr,
                  "!expr 2 + 3"),
        identical(rconfig:::parse_yml(yml_file, eval = TRUE)$expr, 5),
        identical(rconfig:::parse_json(json_file, eval = FALSE)$expr,
                  "!expr 2 + 3"),
        identical(rconfig:::parse_json(json_file, eval = TRUE)$expr, 5),
        identical(rconfig:::parse_txt(txt_file, eval = FALSE)$expr,
                  "!expr 2 + 3"),
        identical(rconfig:::parse_txt(txt_file, eval = TRUE)$expr, 5)
    )
})
