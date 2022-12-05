options("rconfig.debug"=TRUE)

cfile <- function(file) {
    system.file("examples", file, package = "rconfig")
}

str(rconfig::rconfig())
str(rconfig::rconfig(list = list(a = 1)))

## yaml file
str(rconfig::rconfig(file = cfile("rconfig.yml")))
str(rconfig::rconfig(file = cfile("rconfig-prod.yml")))
str(rconfig::rconfig(file = c(
    cfile("rconfig.yml"),
    cfile("rconfig-prod.yml"))))

str(rconfig::rconfig(file = c(
    cfile("rconfig.yml"),
    cfile("rconfig-prod.yml")),
    list = list(user = list(name = "Jack"))))

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

## check evaluating expressions
options("rconfig.eval"=FALSE)
str(rconfig::rconfig(file = cfile("rconfig.yml")))
str(rconfig::rconfig(file = cfile("rconfig.json")))
options("rconfig.eval"=NULL)
str(rconfig::rconfig(file = cfile("rconfig.yml")))
str(rconfig::rconfig(file = cfile("rconfig.json")))

## flatten
rconfig::rconfig(
    file = c(cfile("rconfig.json"),
             cfile("rconfig-prod.txt")),
    list = list(user = list(name = "Jack")),
    flatten = TRUE)

## substitution
Sys.setenv(USER="Adele")
Sys.setenv(ACCESS="admin")
Type <- "simple"
Lang <- "HU"
rconfig::rconfig(file = cfile("rconfig-sub.yml"))
