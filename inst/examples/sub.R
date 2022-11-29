#              a is set & not null             a set but null                  a is unset           implement
# ${a:-b}      substitute a                    substitute b                    substitute b         Yes
# ${a-b}       substitute a                    substitute null                 substitute b         Yes
# ${a:?b}      substitute a                    error, exit                     error, exit          Yes
# ${a?b}       substitute a                    substitute null                 error, exit          Yes

## process a length 1 char value
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


get_value_conf <- function(name, x, flat = FALSE) {
    if (flat)
        rconfig:::flatten_list(x)[[name]] else x[[name]]
}
get_value_env <- function(name) {
    o <- Sys.getenv(x = name, unset = NA)
    if (is.na(o))
        NULL else o
}
get_value_renv <- function(name) {
    o <- try(get(name, envir = .GlobalEnv), silent = TRUE)
    if (inherits(o, "try-error"))
        NULL else o
}

eval_param <- function(d) {
    if (is.null(d))
        return(d)
    n <- nrow(d)
    for (j in seq_len(n)) {
        pj <- switch(d[j,"type"],
            "$" = get_value_env(d[j,"par"]),
            "#" = get_value_conf(d[j,"par"], x, flat = FALSE),
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

substitute_list <- function(x) {
    fx <- rconfig:::flatten_list(x)
    nam <- names(fx)[sapply(fx, is.character)]
    X <- list()
    for (i in nam) {
        X[[i]] <- lapply(fx[[i]], inspect_char)
        for (k in seq_along(X[[i]])) {
            pk <- eval_param(X[[i]][[k]])
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
    o <- rconfig:::nest(fx)
    attributes(o) <- attributes(x)
    o
}

# Variable substitution

#              a is set & not null             a set but null                  a is unset           implement
# ${a:-b}      substitute a                    substitute b                    substitute b         Yes
# ${a-b}       substitute a                    substitute null                 substitute b         Yes
#
# ${a:=b}      substitute a                    assign b                        assign b             No
# ${a=b}       substitute a                    substitute null                 assign b             No
#
# ${a:?b}      substitute a                    error, exit                     error, exit          Yes
# ${a?b}       substitute a                    substitute null                 error, exit          Yes
#
# ${a:+b}      substitute b                    substitute null                 substitute null      No
# ${a+b}       substitute b                    substitute b                    substitute null      No


# What we look for
# `${VARIABLE}`: use environment variables in your shell to populate values
# `$VARIABLE` is NOT supported
# Extended shell-style features, such as `${VARIABLE/foo/bar}`, are not supported
#
# Provide inline default values using typical shell syntax:
#    ${VARIABLE:-default} evaluates to default if VARIABLE is unset or empty in the environment.
#    ${VARIABLE-default} evaluates to default only if VARIABLE is unset in the environment.
#
# Specify mandatory variables:
#    ${VARIABLE:?err} exits with an error message containing err if VARIABLE is unset or empty in the environment.
#    ${VARIABLE?err} exits with an error message containing err if VARIABLE is unset in the environment.
#

# Best summary: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02

# ${parameter:-word}
#    If parameter is unset or null, the expansion of word is substituted. Otherwise, the value of parameter is substituted. 
# ${parameter:+word}
#    If parameter is null or unset, nothing is substituted, otherwise the expansion of word is substituted.
# ${parameter:=word}
#    If parameter is unset or null, the expansion of word is assigned to parameter. The value of parameter is then substituted. 
# ${parameter:?word}
#    If parameter is null or unset, the expansion of word (or a message to that effect if word is not present) is written to the standard error and the shell, if it is not interactive, exits. Otherwise, the value of parameter is substituted. 



# What we substitute


# how we traverse the whole CONFIG for substituting dotted variables, e.g. value.node based on the config itself

x <- "This is ${VAL} for sure. Plus #{FOO} and @{BAR} too."
inspect_char(x)
x <- c("a ${AAA} and ", "b #{bBb}", "c @{CcC}")
lapply(x, inspect_char)
x <- c("${a:-b}", "${a:=b}", "${a:+b}", "${a:?err}")
lapply(x, inspect_char)

x <- "This is ${VAL:-val} for sure, but not ${VAX-vax}. Plus #{FOO?err}, #{FEE:-}, and @{BAR} too."
inspect_char(x)


# next function can 
# - take known values from env,config,baseenv
# - evaluate based on output matrix
# - put it back together and assign to the config list or throw error




cf <- rconfig::rconfig(file = "inst/examples/rconfig-sub.yml")
cat(readLines("inst/examples/rconfig-prod.yml"), sep="\n")
fcf <- rconfig:::flatten_list(cf)
ncf <- rconfig:::nest(fcf)
attributes(ncf) <- attributes(cf)
identical(cf, ncf)

str(cf)
str(fcf)
str(ncf)

get_value_conf("unset", cf)
get_value_conf("this-is-null", cf)
get_value_conf("user.name", cf)

rm(a)
get_value_renv("a")
a=2
get_value_renv("a")
rm(a)
get_value_renv("a")

get_value_env("AAA")
Sys.setenv(AAA=12)
get_value_env("AAA")
Sys.setenv(AAA="")
get_value_env("AAA")
Sys.unsetenv("AAA")
get_value_env("AAA")


inspect_char("${A}")
inspect_char("${A} before")
inspect_char("after ${A}")
inspect_char("after ${A} before")

Sys.setenv(USER="Adele")
Sys.setenv(ACCESS="admin")
Type <- "simple"
Lang <- "HU"
x <- rconfig::rconfig(file = "inst/examples/rconfig-sub.yml")
str(x)
str(rconfig::substitute_list(x))


#              a is set & not null             a set but null                  a is unset           implement
# ${a:-b}      substitute a                    substitute b                    substitute b         Yes
# ${a-b}       substitute a                    substitute null                 substitute b         Yes
# ${a:?b}      substitute a                    error, exit                     error, exit          Yes
# ${a?b}       substitute a                    substitute null                 error, exit          Yes
