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

## Another config package?

There are other R packages to manage configs:

- [config](https://rstudio.github.io/config/) has nice inheritance rules, and it even scans parent directories for YAML config files
- [configr](https://CRAN.R-project.org/package=configr) has nice substitution/interpolation features and supports YAML, JSON, TOML, and INI file formats

These package are fantastic if you are managing deployments at different stages of the life cycle, i.e. testing/staging/production.

However, when you use Rscript from the command line, you often do not want to manage too many configuration files, but want a quick way to override some of the default settings.

The rconfig package provides various ways to override defaults, and instead of changing active configuration (as in the config package), you can merge lists in order to arrive at a final configuration. These are very similar concepts, but not quite the same.

The rconfig package has the following features:

- uses default configuration file
- file based override with the `-f` or `--file` flags (accepts JSON, YAML, and plain text files)
- JSON string based override with the `-j` or `--json` flags
- other command line arguments are merged too, e.g. `--cores 4`
- heuristic rules are used to coerce command line values to the right type
- R expressions starting with `!expr` are evaluated by default, this behavior can be turned off (same feature can be found in the yaml and config packages, but here it works with plain text and JSON too)
- period-separated command line arguments are parsed as hierarchical lists, e.g. `--user.name Joe` will be added as `user$name` to the config list
- command line flags without a value will evaluate to `TRUE`, e.g. `--verbose`

If you are not yet convinced, here is a quick teaser.
This is the content of the default configuration file, `rconfig.yml`:

```yaml
trials: 5
dataset: "demo-data.csv"
cores: !expr getOption("mc.cores", 1L)
user:
  name: "demo"
```

Let's use a simple R script to print out the configs:

```R
#!/usr/bin/env Rscript
str(rconfig::rconfig())
```

Now you can override the default configuration using another file, a JSON string, and some other flags. Notice the variable substitution for user name!

```bash
export USER=Jane

Rscript --vanilla test.R \
  -f rconfig-prod.yml \
  -j '{"trials":30,"dataset":"full-data.csv"}' \
  --user.name $USER \
  --verbose

# List of 4
#  $ trials : int 30
#  $ dataset: chr "full-data.csv"
#  $ cores  : int 1
#  $ user   :List of 1
#   ..$ name: chr "Jane"
#  $ verbose: logi TRUE
```

The package was inspired by the config package, docker-compose/kubectl/caddy and other CLI tools, and was motivated by some real world need when managing background processing on cloud instances.

## Usage

### R command line usage

Open the project in RStudio or set the work directory to the folder root after cloning/downloading the repo.

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

Using alongside of the config package:

```R
conf <- config::get(
    config = "production",
    file = "inst/examples/config.yml",
    use_parent = FALSE)

str(rconfig::rconfig(
    file = "inst/examples/rconfig.yml",
    list = conf))
```

### Using with Rscript

Set the work directory to the `inst/examples` folder cloning/downloading the repo.

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
