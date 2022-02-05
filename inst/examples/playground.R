devtools::check()
devtools::install()
source("R/parsers.R")
source("R/types.R")
source("R/config.R")

str(rconfig::rconfig())

str(rconfig::rconfig(list = list(a = 1)))

cfile <- function(file) {
    system.file("examples", file, package = "rconfig")
}

str(rconfig::rconfig(file = cfile("rconfig.yml")))

str(rconfig::rconfig(file = cfile("rconfig.yml")))
str(rconfig::rconfig(file = cfile("rconfig-prod.yml")))

str(rconfig::rconfig(file = c(
    cfile("rconfig.yml"),
    cfile("rconfig-prod.yml"))))

str(rconfig::rconfig(file = c(
    cfile("rconfig.yml"),
    cfile("rconfig-prod.yml")),
    list = list(user = list(name = "Jack"))))

str(rconfig::rconfig(file = "https://raw.githubusercontent.com/analythium/docker-compose-shiny-example/main/docker-compose.yml"))

## json file
str(rconfig::rconfig(file = cfile("rconfig.json")))
str(rconfig::rconfig(file = cfile("rconfig-prod.json")))
str(rconfig::rconfig(file = c(
    cfile("rconfig.json"),
    cfile("rconfig-prod.json"))))

## text file
str(rconfig::rconfig(file = cfile("rconfig.txt")))
str(rconfig::rconfig(file = cfile("rconfig-prod.txt")))
str(rconfig::rconfig(file = c(
    cfile("rconfig.txt"),
    cfile("rconfig-prod.txt"))))

## cmd line: default config via R_RCONFIG_FILE

## cmd line --file

## cmd line --json

## cmd line default + args

## cmd line multiple files & args override

## check evaluating expressions
options("rconfig.eval"=FALSE)
str(rconfig::rconfig(file = cfile("rconfig.yml")))
str(rconfig::rconfig(file = cfile("rconfig.json")))
options("rconfig.eval"=NULL)
str(rconfig::rconfig(file = cfile("rconfig.yml")))
str(rconfig::rconfig(file = cfile("rconfig.json")))

## write some tips

## how to make sure type conversion is not mixed up
## detail what counts for parsing
## dot in names
## quotes in expressions for text parser: avoid double quotes
## when sep appears in value ("ab=4df")

## --- etc

yaml::yaml.load_file(x,
            eval.expr = FALSE,
            handlers = list(expr = function(x) paste0("!expr ", x))
            )

# note: prop is dropped where value is NULL, e.g. getOption("mc.cores")
options("rconfig.eval"=NULL)
rconfig:::parse_yml(cfile("rconfig.yml")) |>
    jsonlite::toJSON(auto_unbox = TRUE, pretty = TRUE)


#Rscript inst/examples/test.R

#cd inst/examples
#Rscript test.R

#R_RCONFIG_DEBUG="FALSE" Rscript test.R

#R_RCONFIG_FILE="rconfig-prod.yml" Rscript test.R

#R_RCONFIG_FILE="rconfig-prod.yml" R_RCONFIG_DEBUG="FALSE" Rscript test.R

#Rscript test.R -f rconfig-prod.yml --user.name "unreal_Zh5z*$#="

#Rscript test.R -j '{"trials":30,"dataset":"full-data.csv","user":{"name": "real_We4$#z*="}}' --user.name "unreal_Zh5z*$#="

#export USER=Jane
#Rscript test.R --user.name $USER

## Using alongside config

options("rconfig.debug"=TRUE)
conf <- config::get(
    config = "production",
    file = cfile("config.yml"),
    use_parent = FALSE)

str(rconfig::rconfig(
    file = cfile("rconfig.yml"),
    list = conf))


## assume here that the root of x1 and x2 are the same
## and we want that part (reversing unique naming side effects)
findroot <- function(x1, x2) {
    n1 <- nchar(x1)
    n2 <- nchar(x2)
    out <- character(0)
    for (i in seq_len(min(n1, n2))) {
        if (identical(substr(x1, i, i), substr(x2, i, i))) {
            out <- paste0(out, substr(x1, i, i))
        } else break
    }
    out
}
x1 <- "a.b.c9"
x2 <- "a.b.c10"
findroot(x1, x2)

x <- list(
    user=list(name="Joe"),
    cores=2,
    a=list(b=list(c=c(22,44)), d="q"))

flatten_list(x)

str(rconfig::rconfig(file = cfile("rconfig.yml")))
str(rconfig::rconfig(file = cfile("rconfig.yml"),
    list = x))

str(rconfig::rconfig(file = cfile("rconfig.yml"), flatten=TRUE))
str(rconfig::rconfig(file = cfile("rconfig.yml"),
    list = x, flatten=TRUE))


x <- list(
    user=list(name="Joe"),
    cores=2,
    a=list(b=list(c=c(22,44, 66)), d="q"))

str(x)
str(as.list(unlist(x), as.list))

str(x)
str(flatten_list(x))
identical(x, nest(flatten_list(x)))

x <- list(
    user=list(name="Joe"),
    cores=2,
    a=list(b.x=list(c=c(22,44, 66)), d.x="q"))
str(x)
str(as.list(unlist(x), as.list))
str(flatten_list(x))
str(x)
str(flatten_list(x, check=FALSE))

x <- list(
    user=list(name="Joe"),
    cores=2,
    a=list(b.c=list(d="b.c$d"), b=list(c.d="b$c.d")))


## make random lists

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
    make_list(parts, values)
}

for (i in 1:1000) {
    x <- make_new_list(n=10, maxdepth=10, m=5)

    xi <- rconfig:::flatten_list(x, check=FALSE)
    ix <- rconfig:::nest(xi)
    if (!identical(x, ix))
        stop("Flatten/nest failed:\n\n", x)
}

str(x)
str(xi)
str(ix)



rconfig::rconfig(
    file = c(cfile("rconfig.json"),
             cfile("rconfig-prod.txt")),
    list = list(user = list(name = "Jack")),
    flatten = TRUE)

## lists for testing
x <- list(
    k = 0.51,
    t = list(
        r = list(
            b = c(FALSE, TRUE, TRUE))),
    l1 = -1,
    l = c(85L, 35L))

x <- list(
    x = c(0.27, -1.21),
    v = list(d = c(-0.49, -0.22)),
    p = list(w = 0.86))

x <- list(f = FALSE, i = FALSE, z = -0.78)

x <- list(
    s = list(x = list(g = c("v", "o"))),
    l = list(e = list(g = c("z", "l"))))

x <- list(
    h = list(s = list(k = "o"), f = c(TRUE, TRUE)),
    u = list(n = list(s = c("q", "a", "z"))))

x <- list(n = list(q = FALSE, z = list(u = FALSE)),
    f = list(z = list(t = 0.13)))
