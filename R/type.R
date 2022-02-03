## Internal functions for guessing object types

## Should we evaluate !expr expressions?
## env var R_RCONFIG_EVAL overrides the rconfig.eval option
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
is_expression <- function(x) {
    do_eval() && length(x) == 1L && startsWith(x, "!expr ")
}
is_logical <- function(x) {
    !any(is.na(suppressWarnings(as.logical(x))))
}
is_numeric <- function(x) {
    !any(is.na(suppressWarnings(as.numeric(x))))
}
is_integer <- function(x, tol = 1e-6) {
    n <- suppressWarnings(as.numeric(x))
    i <- suppressWarnings(as.integer(n))
    !any(is.na(i)) && max(abs(n-i)) < tol
}

## Guess type of x
guess_type <- function(x) {
    if (is_integer(x))
        "int"
    else if (is_numeric(x))
        "num"
    else if (is_logical(x))
        "logi"
    else if (is_expression(x))
        "expr"
    else "chr"
}

## Evaluate/coerce character to guessed type
convert_type <- function(x) {
    tp <- guess_type(x)
    if (tp == "expr")
        return(eval(
            expr = parse(text = substr(x, 7L, nchar(x))),
            envir = baseenv()))
    switch(tp,
        "int"=as.integer(x),
        "num"=as.numeric(x),
        "logi"=as.logical(x),
        x)
}
