## Internal functions for reading/parsing config files

## File extension of x
file_ext <- function(x) {
    #rev((x |> basename() |> strsplit("\\."))[[1L]])[1L]
    ## make it functional on old R versions w/o native pipe
    rev(strsplit(basename(x), "\\.")[[1L]])[1L]
}

## Guess file extension
guess_ext <- function(x) {
    switch(tolower(file_ext(x)),
        "yml" = "yml",
        "yaml" = "yml",
        "json" = "json",
        "txt")
}

## Make a nested list out of period-separated keys
## a.b.c is parsed as parts (e.g. c("a", "b", "c"))
## parts turned into named lists (e.g. a$b$c)
## values is a list of values to assign to the tips (e.g. a$b$c <- v)
## note: values used as is (no coercion/evaluation)
make_list <- function(parts, values) {
    to_merge <- list()
    for (i in seq_along(parts)) {
        v <- rev(parts[[i]])
        l <- list()
        for (u in seq_along(v)) {
            j <- v[u]
            if (u == 1L) {
                l[[j]] <- values[[i]]
            } else {
                l[[j]] <- l
                if (j != v[u - 1L])
                    l <- l[2L]
            }
        }
        to_merge <- utils::modifyList(to_merge, l)
    }
    to_merge
}

## find the separator for the text parser
## env var R_RCONFIG_SEP overrides the rconfig.sep option
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

## Parse text files (second separator as part of value must be quoted
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
## !expr evaluation is governed by do_eval()
parse_yml <- function(x, ...) {
    if (do_eval()) {
    yaml::yaml.load_file(x,
        eval.expr = FALSE,
        handlers = list(expr = function(x)
            eval(parse(text = x), envir = baseenv())), ...)
    } else {
        yaml::yaml.load_file(x,
            eval.expr = FALSE,
            handlers = list(expr = function(x)
                paste0("!expr ", x)), ...)
    }
}

## Parse JSON string (when --json is supplied as cli argument)
## convert to YAML when !expr evaluation needed
## need to work around ! being special char in YAML
## !expr evaluation is governed by do_eval()
parse_json_string <- function(x, ...) {
    if (do_eval()) {
        z <- gsub("!expr ", "__excl__expr ", x)
        l <- jsonlite::fromJSON(z, ...)
        y <- yaml::as.yaml(l)
        y <- gsub("__excl__expr ", "!expr ", y)
        out <- yaml::yaml.load(y,
            eval.expr = FALSE,
            handlers = list(expr = function(x)
                eval(parse(text = x), envir = baseenv())))
    } else {
        out <- jsonlite::fromJSON(x, ...)
    }
    attr(out, "trace") <- list(
        kind = "json",
        value = x)
    out
}

## Parse JSON file
## convert to YAML when !expr evaluation needed
## need to work around ! being special char in YAML
## !expr evaluation is governed by do_eval()
parse_json <- function(x, ...) {
    z <- readLines(x)
    if (do_eval()) {
        z <- gsub("!expr ", "__excl__expr ", z)
        l <- jsonlite::fromJSON(z, ...)
        y <- yaml::as.yaml(l)
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
## note: YAML, JSON, txt accept URLs or file names
parse_file <- function(x, ...) {
    x <- normalizePath(x, mustWork = FALSE)
    out <- switch(guess_ext(x),
        "yml" = parse_yml(x, ...),
        "json" = parse_json(x, ...),
        "txt" = parse_txt(x, ...))
    attr(out, "trace") <- list(
        kind = "file",
        value = x)
    out
}

## Parse default config file
## defined by R_RCONFIG_FILE
parse_default <- function(...) {
    f <- Sys.getenv("R_RCONFIG_FILE", "rconfig.yml")
    f <- normalizePath(f, mustWork = FALSE)
    if (!file.exists(f))
        return(NULL)
    l <- parse_file(f, ...)
    attr(l, "trace") <- list(
        kind = "file",
        value = f)
    l
}

## Parse cli verb arguments
## verb args are arguments not starting with '-' or '--'
## following the script file name and preceding
## any noun arguments (starting with '-' or '--')
## eg: args <- c("deploy", "ps", "--test", "--some.value", "!expr pi", "--another.value", "abc", "def", "--another.stuff", "99.2")
parse_args_verbs <- function(args) {
    noun1 <- which(startsWith(args, "-"))
    if (length(noun1) > 0L) {
        verbs <- args[seq_len(noun1[1L]-1)]
    } else {
        verbs <- args
    }
    verbs
}

## Parse cli noun arguments
## except for:
## -f --file and -j --json
## eg: args <- c("--test", "--some.value", "!expr pi", "--another.value", "abc", "def", "--another.stuff", "99.2")
## note: period-separated command line
## arguments are parsed as hierarchical lists
## values are coerced/evaluated using convert_type(value)
parse_args_other <- function(args) {
    foj <- args %in% c("-f", "--file", "-j", "--json")
    foj[which(foj)+1L] <- TRUE
    args <- args[!foj]
    if (!length(args) || identical(args, ""))
        return(NULL)
    idx <- which(startsWith(args, "--"))
    flags <- substr(args[idx], 3, nchar(args[idx]))
    if (any(flags == ""))
        stop("Empty keys not allowed.")
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
    l <- make_list(parts, values)
    attr(l, "trace") <- list(
        kind = "args",
        value = paste0(args, collapse = " "))
    l
}

## Parse cli arguments for:
## -f --file and -j --json
## eg: args <- c("--test", "--some.value", "!expr pi", "--another.value", "abc", "def", "-j", "{\"a\":1, \"b\":\"c\"}", "--another.stuff", "99.2", "-f", "inst/config/rconfig.yml")
parse_args_file_and_json <- function(args, ...) {
    idx <- which(args %in% c("-f", "--file", "-j", "--json"))
    if (!length(idx))
        return(NULL)
    ll <- list()
    for (i in seq_along(idx)) {
        is_file <- args[idx[i]] %in% c("-f", "--file")
        if (is_file) {
            l <- parse_file(args[idx[i]+1L], ...)
        } else {
            l <- parse_json_string(args[idx[i]+1L])
        }
        ll[[i]] <- l
    }
    ll
}

## Parse files, json strings, and cli arguments for config
## this returns all the lists in order of precedence before merging
## while separating cli verbs and cli nouns
##
## Precedence:
## 1. R_RCONFIG_FILE value or rconfig.yml
## 2. json and file args are parsed and applied in order
## 3. the remaining other cli args are added last
## 4. config file
## 5. config list
##
## last element overrides previous
## preserves all the rconfig attributes
config_list <- function(file = NULL, list = NULL, ...) {
    args <- commandArgs(trailingOnly=TRUE)
    l1 <- parse_default()
    l2 <- parse_args_file_and_json(args, ...)
    l3 <- parse_args_other(args)
    verbs <- parse_args_verbs(args)
    lists <- list()
    if (!is.null(l1))
        lists[[1L]] <- l1
    for (i in seq_along(l2))
        lists[length(lists)+1L] <- l2[i]
    if (!is.null(l3))
        lists[[length(lists)+1L]] <- l3
    for (i in file) {
        lists[[length(lists)+1L]] <- parse_file(i, ...)
    }
    if (!is.null(list)) {
        ## this will error in non unique names
        flist <- flatten_list(list, check=FALSE)
        attr(list, "trace") <- list(
            kind = "list",
            value = deparse(list))
        lists[[length(lists)+1L]] <- list
    }
    attr(lists, "command") <- verbs
    lists
}
