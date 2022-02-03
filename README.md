# rconfig

> Manage R Configuration at the Command Line

Manage R configuration using files (JSON, YAML, separated text)
JSON strings and command line arguments. Command line arguments
can be used to override configuration. Period-separated command line
flags are parsed as hierarchical lists.

## Install

```R
remotes::install_packages("analythium/rconfig")
```

## Usage

R command line usage:

```R
## no default found
str(rconfig::rconfig())

## use a list override
str(rconfig::rconfig(list = list(a = 1)))

## Try different YAML files
str(rconfig::rconfig(file = "inst/examples/rconfig.yml"))
str(rconfig::rconfig(file = "inst/examples/rconfig-prod.yml"))

## prod config overrides the default
str(rconfig::rconfig(file = c(
    "inst/examples/rconfig.yml",
    "inst/examples/rconfig-prod.yml")))

## a list overrides the prod that overrides the default
str(rconfig::rconfig(file = c(
    "inst/examples/rconfig.yml",
    "inst/examples/rconfig-prod.yml"),
    list = list(user = list(name = "Jack"))))

## Parse YAML from URL
str(rconfig::rconfig(file = "https://raw.githubusercontent.com/analythium/docker-compose-shiny-example/main/docker-compose.yml"))

## Use a JSON file
str(rconfig::rconfig(file = "inst/examples/rconfig.json"))
str(rconfig::rconfig(file = "inst/examples/rconfig-prod.json"))
str(rconfig::rconfig(file = c(
    "inst/examples/rconfig.json",
    "inst/examples/rconfig-prod.json")))

## Use a text file
str(rconfig::rconfig(file = "inst/examples/rconfig.txt"))
str(rconfig::rconfig(file = "inst/examples/rconfig-prod.txt"))
str(rconfig::rconfig(file = c(
    "inst/examples/rconfig.txt",
    "inst/examples/rconfig-prod.txt")))

## Evaluating R expressions (!expr)
options("rconfig.eval"=FALSE)
str(rconfig::rconfig(file = "inst/examples/rconfig.yml"))
str(rconfig::rconfig(file = "inst/examples/rconfig.json"))
options("rconfig.eval"=NULL)
str(rconfig::rconfig(file = "inst/examples/rconfig.yml"))
str(rconfig::rconfig(file = "inst/examples/rconfig.json"))
```

Using with Rscript:

```bash
## Default config if found
Rscript test.R

## Default with debug mode on
R_RCONFIG_DEBUG="FALSE" Rscript test.R

## Change defult config file
R_RCONFIG_FILE="rconfig-prod.yml" Rscript test.R

## Change defult config file and debug on
R_RCONFIG_FILE="rconfig-prod.yml" R_RCONFIG_DEBUG="FALSE" Rscript test.R

## Use file and other props to override default
Rscript test.R -f rconfig-prod.yml --user.name "unreal_Zh5z*$#="

## Use JSON string and other props to override default
Rscript test.R -j '{"trials":30,"dataset":"full-data.csv","user":{"name": "real_We4$#z*="}}' --user.name "unreal_Zh5z*$#="
```

## License

[MIT License](./LICENSE)
Copyright (c) 2022 Peter Solymos and Analythium Solutions Inc.
