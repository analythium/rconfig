set.seed(as.numeric(Sys.time()))

make_new_list <- function(n=10, maxdepth=3, m=10) {
    parts <- strsplit(unique(replicate(n, {
        paste0(sample(letters[seq_len(m)],
                      sample(maxdepth, 1), replace=TRUE), collapse=".")
    })), "\\.")
    values <- lapply(seq_along(parts), function(i) {
        ty <- sample(c("num", "int", "bool", "chr"), 1)
        v <- switch(ty,
            "bool"=c(TRUE, FALSE),
            "int"=1:100,
            "num"=rnorm(100),
            "chr"=letters)
        s <- sample(1:3, 1, prob = c(4, 2, 1))
        sample(v, s, replace=TRUE)
    })
    rconfig:::make_list(parts, values)
}

for (i in 1:100) {
    x <- make_new_list(n=10, maxdepth=10, m=3)
    xi <- rconfig:::flatten_list(x, check=FALSE)
    ix <- rconfig:::nest(xi)
    if (!identical(x, ix))
        stop("Flatten/nest failed:\n\n", x)
}

for (i in 1:100) {
    x <- make_new_list(n=10, maxdepth=3, m=5)
    xi <- rconfig:::flatten_list(x, check=FALSE)
    ix <- rconfig:::nest(xi)
    if (!identical(x, ix))
        stop("Flatten/nest failed:\n\n", x)
}
