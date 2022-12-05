# Summary: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02
#
#              a is set & not null             a set but null                  a is unset           implement
# ${a:-b}      substitute a                    substitute b                    substitute b         Yes
# ${a-b}       substitute a                    substitute null                 substitute b         Yes
# ${a:?b}      substitute a                    error, exit                     error, exit          Yes
# ${a?b}       substitute a                    substitute null                 error, exit          Yes

#' Process a `${par/sep/alt}` pattern
#' 
#' @param x A length 1 string.
#' @return A character vector of length 3 (par, sep, alt).
#' @noRd 
split_param <- function(x) {
    # r <- gregexpr("(:\\=|:\\+|:\\-|:\\?|\\=|\\+|\\-|\\?)", x)[[1L]]
    r <- gregexpr("(:\\-|:\\?|\\-|\\?)", x)[[1L]]
    i1 <- as.integer(r)
    i2 <- i1 + attr(r, "match.length") -1L
    sep <- substr(x, i1, i2)
    if (sep == "") {
        o <- c(x, "", "")
    } else {
        w <- strsplit(x, sep, fixed = TRUE)[[1L]]
        if (length(w) < 2L) {
            w <- c(w, "")
        }
        o <- c(w[1L], sep, w[2L])
    }
    o
}

#' Find patterns to substitute
#' 
#' @param x A length 1 string.
#' @return A matrix with character values, rows are values to substitute, columns are: type, par, sep, alt, val.
#' @noRd 
inspect_char <- function(x) {
    if (length(x) != 1L)
        stop("Length must be 1")
    s <- strsplit(gsub("(\\$|\\#|\\@)\\{([^}]+)\\}", "___SPLIT___", x), "___SPLIT___", fixed = TRUE)[[1L]]
    if (!length(s) || identical(x, s))
        return(NULL)
    r <- gregexpr("(\\$|\\#|\\@)\\{([^}]+)\\}", x)[[1L]]
    i1 <- as.integer(r)
    i2 <- i1 + attr(r, "match.length") -1L
    v <- sapply(seq_along(i1), function(i) substr(x, i1[i] + 2L, i2[i] - 1L))
    q <- sapply(seq_along(i1), function(i) substr(x, i1[i], i1[i]))
    w <- t(sapply(v, split_param))
    colnames(w) <- c("par", "sep", "alt")
    m <- cbind(type = q, w, val = "")
    attr(m, "input") <- x
    attr(m, "split") <- s
    m
}

#' Get configuration value
#' 
#' @param name Name of the parameter.
#' @param x Config list.
#' @param flat Logical, flatten `x` or not.
#' @return The value or `NULL` (unset).
#' @noRd 
get_value_conf <- function(name, x, flat = FALSE) {
    if (flat)
        flatten_list(x)[[name]] else x[[name]]
}

#' Get environment value
#' 
#' @param name Name of the environment variable.
#' @return The value (set and not null), empty string (`""`; set but null) or `NULL` (unset).
#' @noRd 
get_value_env <- function(name) {
    o <- Sys.getenv(x = name, unset = NA)
    if (is.na(o))
        NULL else o
}

#' Get value of an R object
#' 
#' @param name Name of the environment variable.
#' @return The value coerced to character or `NULL` (unset).
#' @noRd 
get_value_renv <- function(name) {
    o <- try(get(name, envir = .GlobalEnv), silent = TRUE)
    if (inherits(o, "try-error"))
        NULL else as.character(o)
}

#' Evaluate parameter
#' 
#' Parameter is a matrix object returned by `inspect_char()`.
#' 
#' @param d Matrix with parsed parameter information.
#' @param fx A flattened config list
#' @return The matrix with the val column filled in after evaluation, this is the value to substitute.
#' @noRd 
eval_param <- function(d, fx) {
    if (is.null(d))
        return(d)
    n <- nrow(d)
    for (j in seq_len(n)) {
        pj <- switch(d[j,"type"],
            "$" = get_value_env(d[j,"par"]),
            "#" = get_value_conf(d[j,"par"], fx, flat = FALSE),
            "@" = get_value_renv(d[j,"par"]))
        # par set but null (i.e. "")
        if (!is.null(pj) && identical(pj, "")) {
            if (grepl(":", d[j,"sep"])) {
                if (d[j, "sep"] == ":-") {
                    pj <- d[j, "alt"]
                } else {
                    stop(d[j, "alt"], call. = FALSE)
                }
            }
        }
        # par is unset (i.e. NULL)
        if (is.null(pj)) {
            if (d[j, "sep"] %in% c(":-", "-")) {
                pj <- d[j, "alt"]
            } else {
                stop(d[j, "alt"], call. = FALSE)
            }
        }
        # otherwise par is set and is not null (!= "")
        d[j, "val"] <- pj
    }
    d
}

#' Substitute values in a config list
#' 
#' Environment variables are already there (from outside and .Renviron),
#' `!expr` expressions and other R session level variables need to be present
#' at the time of config evaluation.
#' At last, the config level variables are evaluated, thus config level values can
#' refer to existing keys that are already substituted (i.e. not substituted from other
#' config values).
#' 
#' @param x Config list.
#' @return The config list with values substituted
#' @noRd
substitute_list <- function(x) {
    if (length(x) <= 1L)
        return(x)
    fx <- flatten_list(x)
    nam <- names(fx)[sapply(fx, is.character)]
    X <- list()
    for (i in nam) {
        X[[i]] <- lapply(fx[[i]], inspect_char)
        for (k in seq_along(X[[i]])) {
            pk <- eval_param(X[[i]][[k]], fx)
            if (any(pk[,"type"] == "#")) {
                if (!all(pk[,"type"] == "#"))
                    stop("Mixed variable substitution for config keys not allowed.")
            } else {
                if (!is.null(pk)) {
                    v1 <- attr(pk, "split")
                    v2 <- pk[,"val"]
                    if (length(v2) < length(v1))
                        v2 <- c(v2, "")
                    attr(pk, "subst") <- paste0(v1, v2, collapse="")
                    X[[i]][[k]] <- pk
                    fx[[i]][k] <- attr(pk, "subst")
                }
            }
        }
    }
    for (i in nam) {
        for (k in seq_along(X[[i]])) {
            pk <- eval_param(X[[i]][[k]], fx)
            if (any(pk[,"type"] == "#")) {
                if (!is.null(pk)) {
                    v1 <- attr(pk, "split")
                    v2 <- pk[,"val"]
                    if (length(v2) < length(v1))
                        v2 <- c(v2, "")
                    attr(pk, "subst") <- paste0(v1, v2, collapse="")
                    X[[i]][[k]] <- pk
                    fx[[i]][k] <- attr(pk, "subst")
                }
            }
        }
    }
    o <- nest(fx)
    attributes(o) <- attributes(x)
    o
}

## TODO
## - order of precedence for env/renv/conf settings: conf to come at the end (env->renv|expr->conf)
## - OK how should !expr be handled for precedence? Probably env->renv\expr->conf
## - DONTFIX allow .env to be listed as part of --file or --env-file
## - DONTFIX function to set env vars based on .env file
