## Internal functions for guessing object types

## Should we evaluate !expr expressions?
## env var R_RCONFIG_EVAL overrides the rconfig.eval option
#' Determine whether `!expr` expressions should be evaluated.
#'
#' `R_RCONFIG_EVAL` takes precedence over the `rconfig.eval` option. If neither
#' is set, evaluation defaults to `TRUE`.
#'
#' @return A length-one logical value.
#' @noRd
do_eval <- function() {
    default_val <- TRUE
    var <- as.logical(Sys.getenv("R_RCONFIG_EVAL"))
    if (is.na(var)) {
        opt <- getOption("rconfig.eval")
        if (!is.null(opt))
            opt <- suppressWarnings(as.logical(opt))
        var <- if (!length(opt) || is.na(opt))
            default_val else opt
    }
    var
}

## Check type of x
#' Check whether a value is an `!expr` expression.
#'
#' @param x A character value to inspect.
#' @param eval Whether expression evaluation is enabled; defaults to
#'   `do_eval()`.
#' @return `TRUE` if `x` is a scalar `!expr` expression, otherwise `FALSE`.
#' @noRd
is_expression <- function(x, eval = do_eval()) {
    isTRUE(eval) && length(x) == 1L && startsWith(x, "!expr ")
}

#' Check whether values can be coerced to logical.
#'
#' @param x Values to test.
#' @return `TRUE` when coercion produces no missing values.
#' @noRd
is_logical <- function(x) {
    !any(is.na(suppressWarnings(as.logical(x))))
}

#' Check whether values can be coerced to numeric.
#'
#' @param x Values to test.
#' @return `TRUE` when coercion produces no missing values.
#' @noRd
is_numeric <- function(x) {
    !any(is.na(suppressWarnings(as.numeric(x))))
}

#' Check whether numeric values are integers.
#'
#' @param x Values to test.
#' @param tol Maximum accepted absolute difference from the nearest integer.
#' @return `TRUE` when all values are finite integer representations within
#'   `tol`.
#' @noRd
is_integer <- function(x, tol = 1e-6) {
    n <- suppressWarnings(as.numeric(x))
    i <- suppressWarnings(as.integer(n))
    !any(is.na(i)) && max(abs(n-i)) < tol
}

## Guess type of x
#' Guess the type represented by a character value.
#'
#' @param x Values to inspect.
#' @param eval Whether `!expr` values are treated as expressions; defaults to
#'   `do_eval()`.
#' @return One of `"int"`, `"num"`, `"logi"`, `"expr"`, or `"chr"`.
#' @noRd
guess_type <- function(x, eval = do_eval()) {
    if (is_integer(x))
        "int"
    else if (is_numeric(x))
        "num"
    else if (is_logical(x))
        "logi"
    else if (is_expression(x, eval = eval))
        "expr"
    else "chr"
}

## Evaluate/coerce character to guessed type
#' Evaluate or coerce a character value to its guessed type.
#'
#' @param x A character value or vector.
#' @param eval Whether to evaluate `!expr` values; defaults to `do_eval()`.
#' @return The evaluated or coerced value.
#' @noRd
convert_type <- function(x, eval = do_eval()) {
    tp <- guess_type(x, eval = eval)
    if (tp == "expr" && isTRUE(eval))
        return(base::eval(
            expr = parse(text = substr(x, 7L, nchar(x))),
            envir = baseenv()))
    switch(tp,
        "int"=as.integer(x),
        "num"=as.numeric(x),
        "logi"=as.logical(x),
        x)
}
