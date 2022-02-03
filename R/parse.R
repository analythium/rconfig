## Internal functions for reading/parsing config files

## File extension of x
file_ext <- function(x) {
    rev((x |> basename() |> strsplit("\\."))[[1L]])[1L]
}

## Guess file extension
guess_ext <- function(x) {
    switch(tolower(file_ext(x)),
        "yml" = "yml",
        "yaml" = "yml",
        "json" = "json",
        "txt")
}

## Make a nested list
## parts is a list of nexted names
## values is a list of values to assign
make_list <- function(parts, values) {
    to_merge <- list()
    for (i in seq_along(parts)) {
        v <- rev(parts[[i]])
        l <- list()
        for (j in v) {
            if (j == v[1L]) {
                l[[j]] <- values[[i]]
            } else {
                l[[j]] <- l
                l <- l[2L]
            }
        }
        to_merge <- utils::modifyList(to_merge, l)
    }
    to_merge
}

txt_sep <- function() {
    default_val <- "="
    var <- as.character(Sys.getenv("R_RCONFIG_SEP"))
    if (identical(var, "")) {
        opt <- as.character(getOption("rconfig.sep"))
        var <- if (!length(opt) || is.na(opt))
            default_val else opt
    }
    var
}

## Parse text files (second separator as part of valie must be quoted
## because parts beyond that are dropped)
## separator is '=' by default, governed by txt_sep()
parse_txt <- function(x, ...) {
    txt <- utils::read.table(x, sep = txt_sep(), ...)
    parts <- strsplit(txt[[1L]], "\\.")
    ## convert_type handles !expr when needed
    values <- lapply(txt[[2L]], convert_type)
    make_list(parts, values)
}

## Parse YAML files
parse_yml <- function(x, ...) {
    if (do_eval()) {
    yaml::yaml.load_file(x,
        eval.expr = FALSE,
        handlers = list(expr = function(x)
            eval(parse(text = x), envir = baseenv())), ...)
    } else {
        yaml::yaml.load_file(x,
            eval.expr = FALSE, ...)
    }
}

## parse JSON string (json can be supplied as argument)
## convert to YML when !expr evaluation needed
parse_json_string <- function(x, ...) {
    if (do_eval()) {
        z <- gsub("!expr ", "__excl__expr ", x)
        l <- jsonlite::fromJSON(z, ...)
        y <- yaml::as.yaml(l)
        y <- gsub("__excl__expr ", "!expr ", y)
        yaml::yaml.load(y,
            eval.expr = FALSE,
            handlers = list(expr = function(x)
                eval(parse(text = x), envir = baseenv())))
    } else {
        jsonlite::fromJSON(x, ...)
    }
}

## parse JSON file
## convert to YML when !expr evaluation needed
parse_json <- function(x, ...) {
    z <- readLines(x)
    if (do_eval()) {
        z <- gsub("!expr ", "__excl__expr ", z)
        l <- jsonlite::fromJSON(z, ...)
        y <- yaml::as.yaml(l)
        cat(y)
        y <- gsub("__excl__expr ", "!expr ", y)
        yaml::yaml.load(y,
            eval.expr = FALSE,
            handlers = list(expr = function(x)
                eval(parse(text = x), envir = baseenv())))
    } else {
        jsonlite::fromJSON(z, ...)
    }
}

## Parse the file depending on file type (yml, json, txt)
parse_file <- function(x, ...) {
    x <- normalizePath(x, mustWork = FALSE)
    switch(guess_ext(x),
        "yml" = parse_yml(x, ...),
        "json" = parse_json(x, ...),
        "txt" = parse_txt(x, ...))
}

## Parse default config file
## defined by R_RCONFIG_FILE
parse_default <- function() {
    f <- Sys.getenv("R_RCONFIG_FILE", "config.yml")
    f <- normalizePath(f, mustWork = FALSE)
    if (!file.exists(f))
        list() else parse_file(f)
}

## Parse cli arguments
## except for:
## -f --file and -j --json
## eg: args <- c("--test", "--some.value", "!expr pi", "--another.value", "abc", "def", "--another.stuff", "99.2")
parse_args_other <- function(args) {
    foj <- args %in% c("-f", "--file", "-j", "--json")
    foj[which(foj)+1L] <- TRUE
    args <- args[!foj]
    idx <- which(startsWith(args, "--"))
    flags <- substr(args[idx], 3, nchar(args[idx]))
    parts <- strsplit(flags, "\\.")
    if (any(duplicated(flags)))
        stop("Duplicated flags found.")
    ## convert_type handles !expr when needed
    values <- list()
    for (i in seq_along(idx)) {
        Start <- idx[i]
        End <- if (i == length(idx))
            length(args) else idx[i+1] - 1L
        values[[flags[i]]] <- args[Start:End][-1]
        if (!length(values[[flags[i]]])) {
            values[[flags[i]]] <- TRUE
        } else {
            values[[flags[i]]] <- convert_type(values[[flags[i]]])
        }
    }
    make_list(parts, values)
}

## Parse cli arguments for:
## -f --file and -j --json
## eg: args <- c("--test", "--some.value", "!expr pi", "--another.value", "abc", "def", "-j", "{\"a\":1, \"b\":\"c\"}", "--another.stuff", "99.2", "-f", "inst/config/config.yml")
parse_args_file_and_json <- function(args) {
    idx <- which(args %in% c("-f", "--file", "-j", "--json"))
    ll <- list()
    for (i in seq_along(idx)) {
        is_file <- args[idx[i]] %in% c("-f", "--file")
        if (is_file) {
            l <- parse_file(args[idx[i]+1L])
            attr(l, "file") <- args[idx[i]+1L]
        } else {
            l <- parse_json_string(args[idx[i]+1L])
            attr(l, "json") <- args[idx[i]+1L]
        }
        ll[[i]] <- l
    }
    ll
}
