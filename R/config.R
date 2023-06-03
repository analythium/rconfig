#' Manage R Configuration at the Command Line
#'
#' Manage R configuration using files (YAML, JSON, INI, TXT)
#' JSON strings and command line arguments. Command line arguments
#' can be used to provide commands and to override configuration.
#' Period-separated command line flags are parsed as hierarchical
#' lists.
#'
#' @details
#' Merges configuration after parsing files, JSON strings,
#' and command line arguments. Note that rconfig only considers
#' trailing command line arguments from Rscript.
#' rconfig differentiates verb/noun syntax, where
#' verbs are sub-commands following the R script file name
#' and preceding the command line flags (starting with `-` or `--`).
#' Configurations are merged in the following order
#' (key-values from last element override previous values for the same key):
#'
#' 1. `R_RCONFIG_FILE` value or `"rconfig.yml"` from working directory
#' 2. JSON strings (following `-j` and `--json` flags)
#'    and files (following `-f` and `--file` flags)
#'    provided as command line arguments are parsed and applied
#'    in the order they appear (key-value pairs are separated by space,
#'    only atomic values considered, i.e. file name or string)
#'    for each flag, but multiple file/JSON flags are accepted in sequence
#' 3. the remaining other command line arguments, that can be
#'    sub-commands or command line flags
#'    (starting with `-` or `--`), period-separated
#'    command line flags are parsed as hierarchical lists
#'    (key-value pairs are separated by space, flags must begin
#'    with `--`, values are treated as vectors when contain spaces,
#'    i.e. `--key 1 2 3`)
#' 4. configuration from the `file` argument (one or multiple files,
#'    parsed and applied in the order they appear)
#' 5. configuration from the `list` argument
#'
#' The following environment variables and options can be set to
#' modify the default behavior:
#'
#' * `R_RCONFIG_FILE`: location of the default configuration file,
#'   it is assumed to be `rconfig.yml` in the current working directory.
#'   The file name can be an URL or it can can be missing.
#' * `R_RCONFIG_EVAL`: coerced to logical, indicating whether
#'   R expressions starting with `!expr` should be evaluated in the
#'   namespace environment for the base package
#'   (overrides the value of `getOption("rconfig.eval")`).
#'   When not set the value assumed is `TRUE`.
#' * `R_RCONFIG_SUB`: coerced to logical, indicating whether
#'   environment variables should be substituted
#'   (overrides the value of `getOption("rconfig.sub")`).
#'   When not set the value assumed is `TRUE`.
#' * `R_RCONFIG_FLATTEN`: coerced to logical, flatten nested lists,
#'   i.e. `a$b$c` becomes the key `a.b.c`
#'   (overrides the value of `getOption("rconfig.flatten")`).
#'   When not set the value assumed is `FALSE`.
#' * `R_RCONFIG_DEBUG`: coerced to logical, to turn on debug mode
#'   (overrides the value of `getOption("rconfig.debug")`).
#'   When not set the value assumed is `FALSE`.
#' * `R_RCONFIG_SEP`: separator for text file parser,
#'   (overrides the value of `getOption("rconfig.sep")`).
#'   When not set the value assumed is `"="`.
#'
#' When the configuration is a file (file name can also be a URL),
#' it can be nested structure in JSON or YAML format.
#' Other text files are parsed using the
#' separator (`R_RCONFIG_SEP` or `getOption("rconfig.sep")`) and
#' period-separated keys are parsed as hierarchical lists
#' (i.e. `a.b.c=12` is treated as `a$b$c = 12`) by default.
#'
#' When the configuration is a file or a JSON string,
#' values starting with `!expr` will be evaluated depending on the
#' settings `R_RCONFIG_EVAL` and `getOption("rconfig.eval")`.
#' E.g. `cores: !expr getOption("mc.cores")`, etc.
#'
#' The rconfig package interprets 3 kinds of substitution patterns:
#' 
#' * environment variables (`${VALUE}`): these variables are already present when the configurations is read from the calling environment or from `.Renviron` file in the project specific or home folder, set variables can be null or not-null
#' * R global variables (`@{VALUE}`): the rconfig package looks for variables in the global environment at the time of configuration evaluation, however, expressions are not evaluated (unlike the `!expr` option for values)
#' * configuration values (`#{VALUE}`): the configuration level variables are evaluated last, thus these values can refer to existing keys that are already substituted
#' 
#' For additional details see the package website at
#'  \href{https://github.com/analythium/rconfig}{https://github.com/analythium/rconfig}.
#'
#' @param file Configuration file name or URL (`NULL` to not use
#'   this configuration file to override the default behavior).
#'   Can be a vector, in which case each element will be treated
#'   as a configuration file, and these will be parsed and applied
#'   in the order they appear.
#' @param list A list to override other configs (`NULL` to not use
#'   this list to override the default behavior). This argument is treated
#'   as a single configuration (as opposed to `file`). List names need
#'   to be unique.
#' @param eval Logical, evaluate `!expr` R expressions.
#' @param flatten Logical, should config contain nested lists or should
#'   results be flat, i.e. `a$b$c` to flattened into the key `a.b.c`;
#'   like [unlist()] but returning a list and preserving the value types.
#' @param debug Logical, when debug mode is on the configuration
#'   source information are attached as the `"trace"` attribute.
#' @param sep Character, separator for text files.
#' @param sub Logical, substitute environment variables (see Details).
#' @param ... Other arguments passed to file parsers:
#'   [yaml::yaml.load_file()] for YAML,
#'   [jsonlite::fromJSON()] for JSON, and
#'   [utils::read.table()] for text files.
#' @param x A list, e.g. the `rconfig()` output.
#' @param default A default value to be used when a configuration
#'   entry is not set.
#' @param coerce Logical, should values of `x` coerced to the same 
#'   type as `storage.mode(default).`
#'
#' @return The configuration value (a named list, or an empty list).
#'   When debug mode is on, the `"trace"` attribute traces the
#'   merged configurations. The `value()` method returns the value
#'   of a given argument or the default value when it is not found
#'   (i.e. `NULL`). The `command()` method returns a character vector
#'   with command line sub-commands (can be of length 0).
#'
#' @examples
#' cfile <- function(file) {
#'     system.file("examples", file, package = "rconfig")
#' }
#'
#' rconfig::rconfig()
#'
#' rconfig::rconfig(
#'     file = cfile("rconfig.yml"))
#'
#' rconfig::rconfig(
#'     file = c(cfile("rconfig.json"),
#'              cfile("rconfig-prod.txt")),
#'     list = list(user = list(name = "Jack")))
#'
#' rconfig::rconfig(
#'     file = c(cfile("rconfig.json"),
#'              cfile("rconfig-prod.txt")),
#'     list = list(user = list(name = "Jack")),
#'     flatten = TRUE)
#'
#' CONFIG <- rconfig::rconfig(
#'     file = cfile("rconfig.yml"))
#' value(CONFIG$cores, 2L)   # set to 1L
#' value(CONFIG$test, FALSE) # unset
#'
#' @seealso [utils::modifyList()]
#' @name rconfig
NULL

#' @rdname rconfig
#' @export
## Parse files, json strings, and cli arguments for config
##
## Precedence:
## 1. R_RCONFIG_FILE value or rconfig.yml
## 2. json and file args are parsed and applied in order
## 3. the remaining other cli args are added last
## 4. config file
## 5. config list
##
## this merges the lists to create the final config
## rconfig attribute traces what was merged
rconfig <- function(file = NULL,
                    list = NULL,
                    eval = NULL,
                    flatten = NULL,
                    debug = NULL,
                    sep = NULL,
                    sub = NULL,
                    ...) {

    ## handle eval
    if (!is.null(eval)) {
        oeval <- Sys.getenv("R_RCONFIG_EVAL", unset = NA)
        Sys.setenv("R_RCONFIG_EVAL" = eval)
        on.exit({
            if (!is.na(oeval))
                Sys.setenv("R_RCONFIG_EVAL" = oeval)
            else
                Sys.unsetenv("R_RCONFIG_EVAL")
        }, add = TRUE)
    }

    ## handle sep
    if (!is.null(sep)) {
        osep <- Sys.getenv("R_RCONFIG_SEP", unset = NA)
        Sys.setenv("R_RCONFIG_SEP" = sep)
        on.exit({
            if (!is.na(osep))
                Sys.setenv("R_RCONFIG_SEP" = osep)
            else
                Sys.unsetenv("R_RCONFIG_SEP")
        }, add = TRUE)
    }

    ## handle debug
    if (!is.null(debug)) {
        odebug <- Sys.getenv("R_RCONFIG_DEBUG", unset = NA)
        Sys.setenv("R_RCONFIG_DEBUG" = debug)
        on.exit({
            if (!is.na(odebug))
                Sys.setenv("R_RCONFIG_DEBUG" = odebug)
            else
                Sys.unsetenv("R_RCONFIG_DEBUG")
        }, add = TRUE)
    }

    ## handle flatten
    if (!is.null(flatten)) {
        oflatten <- Sys.getenv("R_RCONFIG_FLATTEN", unset = NA)
        Sys.setenv("R_RCONFIG_FLATTEN" = flatten)
        on.exit({
            if (!is.na(oflatten))
                Sys.setenv("R_RCONFIG_FLATTEN" = oflatten)
            else
                Sys.unsetenv("R_RCONFIG_FLATTEN")
        }, add = TRUE)
    }

    ## handle sub
    if (!is.null(sub)) {
        osub <- Sys.getenv("R_RCONFIG_SUB", unset = NA)
        Sys.setenv("R_RCONFIG_SUB" = sub)
        on.exit({
            if (!is.na(osub))
                Sys.setenv("R_RCONFIG_SUB" = osub)
            else
                Sys.unsetenv("R_RCONFIG_SUB")
        }, add = TRUE)
    }

    ## unmerged list
    lists <- config_list(file = file, list = list, ...)
    verbs <- attr(lists, "command")

    ## merged list
    out <- list()
    for (i in lists)
        out <- utils::modifyList(out, i)
    
    ## substitute variables
    if (do_sub())
        out <- substitute_list(out)

    ## flatten if requested
    if (do_flatten())
        out <- flatten_list(out)

    ## trace
    if (length(lists) > 0L) {
        rc <- if (length(lists) > 1L) {
            list(
                kind = "merged",
                value = lapply(lists, attr, "trace"))
        } else attr(lists[[1L]], "trace")
        if (do_debug())
            attr(out, "trace") <- rc
    }
    attr(out, "command") <- verbs

    class(out) <- "rconfig"
    out
}

#' @rdname rconfig
#' @export
value <- function(x, ...) {
    UseMethod("value")
}

#' @rdname rconfig
#' @export
#' @method value default
value.default <- function(x, default = NULL, coerce = TRUE, ...) {
    x <- if (is.null(x))
        default else x
    if (!is.null(default) && coerce)
        storage.mode(x) <- storage.mode(default)
    x
}

#' @rdname rconfig
#' @export
command <- function(x, ...) {
    UseMethod("command")
}

#' @rdname rconfig
#' @export
#' @method command default
command.default <- function(x, ...) {
    attr(x, "command")
}

## trace is stored when debug mode is on
do_debug <- function() {
    default_val <- FALSE
    var <- as.logical(Sys.getenv("R_RCONFIG_DEBUG"))
    if (is.na(var)) {
        opt <- getOption("rconfig.debug")
        if (!is.null(opt))
            opt <- suppressWarnings(as.logical(opt))
        var <- if (!length(opt) || is.na(opt))
            default_val else opt
    }
    var
}

## check settings for flattening
do_flatten <- function() {
    default_val <- FALSE
    var <- as.logical(Sys.getenv("R_RCONFIG_FLATTEN"))
    if (is.na(var)) {
        opt <- getOption("rconfig.flatten")
        if (!is.null(opt))
            opt <- suppressWarnings(as.logical(opt))
        var <- if (!length(opt) || is.na(opt))
            default_val else opt
    }
    var
}

## check settings for env substitution
do_sub <- function() {
    default_val <- TRUE
    var <- as.logical(Sys.getenv("R_RCONFIG_SUB"))
    if (is.na(var)) {
        opt <- getOption("rconfig.sub")
        if (!is.null(opt))
            opt <- suppressWarnings(as.logical(opt))
        var <- if (!length(opt) || is.na(opt))
            default_val else opt
    }
    var
}

## assume here that the root of x1 and x2 are the same
## and we want that part (reversing unique naming side effects)
findroot <- function(x1, x2) {
    n1 <- nchar(x1)
    n2 <- nchar(x2)
    l <- min(n1, n2)
    if (is.na(l))
        return(NA_character_)
    out <- character(0)
    for (i in seq_len(l)) {
        if (identical(substr(x1, i, i), substr(x2, i, i))) {
            out <- paste0(out, substr(x1, i, i))
        } else break
    }
    out
}

## the reverse of flatten list
nest <- function(x) {
    make_list(strsplit(names(x), "\\."), x)
}

## check for depth-1 vectors
depth1 <- function(x) {
    nam <- names(unlist(x))
    out <- data.frame(unlist=nam)
    parts <- strsplit(nam, "\\.")
    part1 <- rep(names(x), sapply(x, function(z) length(unlist(z))))
    for (i in seq_along(parts)) {
        if (!identical(part1[i], parts[[i]][1L])) {
            nam[i] <- part1[i]
            parts[[i]][1L] <- part1[i]
        }
    }
    out$part1 <- part1
    out$nam <- nam
    out
}

## flatten nested list to get period-separated keys
flatten_list <- function(x, check=TRUE) {
    if (length(x) <= 1L)
        return(x)
    if (is.null(names(x)))
        stop("No names found")
    if (any(duplicated(names(x))))
        stop("List names not unique")
    nam <- names(unlist(x))
    parts <- strsplit(nam, "\\.")
    ## check for level 1 vectors
    part1 <- rep(names(x), sapply(x, function(z) length(unlist(z))))
    for (i in seq_along(parts)) {
        if (!identical(part1[i], parts[[i]][1L])) {
            nam[i] <- part1[i]
            parts[[i]][1L] <- part1[i]
        }
    }
    for (n in names(x)[!(names(x) %in% part1)]) {
        ii <- which(sapply(sapply(part1, findroot, n), function(z)
            length(z) && z %in% names(x)))
        tmp <- part1[ii]
        ii <- ii[!(tmp %in% tmp[duplicated(tmp)])]
        parts[ii] <- n
        nam[ii] <- n
    }
    out <- lapply(parts, function(i) {
        p <- NULL
        for (j in i) {
            if (any(duplicated(names(x[[j]]))))
                stop("List names not unique")
            if (check && any(grepl("\\.", names(x))))
                stop("Names should not contain dots")
            if (!is.null(x[[j]])) {
                x <- x[[j]]
                p <- c(p, j)
            } else {
                d <- depth1(x)
                k <- d$part1[d$unlist == j]
                if (!is.null(x[[k]])) {
                    x <- x[[k]]
                    p <- c(p, k)
                }
            }
        }
        attr(x, "parts") <- p
        x
    })
    for (i in seq_along(nam)) {
        if (is.list(out[[i]]))
            out[[i]] <- out[[i]][[1L]]
        if (i > 1L) {
            if (identical(out[[i-1L]], out[[i]]) &&
                identical(attr(out[[i-1L]], "parts"),
                          attr(out[[i]], "parts"))) {
                nam[i-1L] <- findroot(nam[i-1L], nam[i])
                nam[i] <- NA
            }
        }
    }
    for (i in seq_along(out)) {
        attr(out[[i]], "parts") <- NULL
    }
    out <- out[!is.na(nam)]
    names(out) <- nam[!is.na(nam)]
    # if (check && !identical(x, nest(out)))
    #     stop("Something went wrong. Please report to package maintainer")
    if (check) {
        nx <- nest(out)
        attributes(nx) <- attributes(x)
        if (!identical(x, nx))
            stop("Something went wrong. Please report to package maintainer")
    }
    out
}
