#' Manage R Configuration at the Command Line
#'
#' Manage R configuration using files (JSON, YAML, separated text)
#' JSON strings and command line arguments. Command line arguments
#' can be used to override configuration. Period-separated command line
#' flags are parsed as hierarchical lists.
#'
#' @details
#' Merges configuration after parsing files, JSON strings,
#' and command line arguments.
#' Configurations are merged in the following order
#' (key-values from last element override previous values for the same key):
#'
#' 1. `R_RCONFIG_FILE` value or `"config.yml"`
#' 2. JSON strings (following `-j` and `--json` flags)
#'    and files (following `-f` and `--file` flags)
#'    provided as command line arguments are parsed and applied
#'    in the order they appear (key-value pars are separated by space,
#'    only a atomic values considered, i.e. file name or string)
#' 3. the remaining other command line arguments, period-separated
#'    command line flags are parsed as hierarchical lists
#'    (key-value pars are separated by space, flags must begin
#'    with `--`, values are treated as vectors when contain spaces)
#' 4. configuration from the `file` argument (one or multiple files,
#'    parsed and applied in the order they appear)
#' 5. configuration from the `list` argument
#'
#' The following environment variables and options can be set to
#' modify the default behavior:
#'
#' * `R_RCONFIG_FILE`: location of the default configuration file,
#'   it is assumed to be `config.yml` in the current working directory.
#'   The file name can be an URL or it can can be missing.
#' * `R_RCONFIG_EVAL`: coerced to logical, indicating whether
#'   R expressions starting with `!expr` should be evaluated in the
#'   namespace environment for the base package
#'   (overrides the value of `getOption("rconfig.eval")`).
#'   When not set the value is `TRUE`.
#' * `R_RCONFIG_SEP`: separator for text file parser,
#'   (overrides the value of `getOption("rconfig.sep")`).
#'   When not set the value is `"="`.
#'
#' When the configuration is a file (file name can also be a URL),
#' it can be nested structure in JSON, YAML format.
#' Other text files are parsed using the
#' separator (`R_RCONFIG_SEP` or `getOption("rconfig.sep")`) and
#' period-separated keys are parsed as hierarchical lists
#' (i.e. `a.b.c=12` is treated as `a$b$c = 12`).
#'
#' When the configuration is a file or a JSON string,
#' values starting with `!expr` will be evaluated depending on the
#' settings `R_RCONFIG_EVAL` and `getOption("rconfig.eval")`.
#' E.g. `cores: !expr getOption("mc.cores")`, etc.
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
#'   as a single configuration (as opposed to `file`).
#' @param x A configuration object (named or empty list) of class rconfig.
#' @param ... Other arguments passed to methods.
#'
#' @return The configuration value (a named list, or an empty list).
#'   The `"trace"` attribute traces the merged configurations.
#'
#' @seealso [utils::modifyList()]
#'
#' @name rconfig
NULL

#' @export
#' @rdname rconfig
## Parse files, json strings, and cli arguments for config
##
## Precedence:
## 1. R_RCONFIG_FILE value or config.yml
## 2. json and file args are parsed and applied in order
## 3. the remaining other cli args are added last
## 4. config file
## 5. config list
##
## this merges the lists to create the final config
## rconfig attribute traces what was merged
rconfig <- function(file = NULL, list = NULL) {
    ## unmerged list
    lists <- config_list(file = file, list = list)
    ## merged list
    out <- list()
    for (i in lists)
        out <- utils::modifyList(out, i)
    ## trace
    if (length(lists)) {
        rc <- if (length(lists) > 1L) {
            list(
                kind = "merged",
                value = lapply(lists, attr, "trace"))
        } else attr(lists[[1L]], "trace")
        attr(out, "trace") <- rc
    }
    class(out) <- "rconfig"
    out
}

#' @export
#' @rdname rconfig
print.rconfig <- function(x, ...) {
    xx <- x
    attr(xx, "trace") <- NULL
    print(unclass(xx))
    invisible(x)
}
