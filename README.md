# rconfig

> Manage R Configuration at the Command Line

[![](https://github.com/analythium/rconfig/actions/workflows/check.yml/badge.svg)](https://github.com/analythium/rconfig/actions)

Manage R configuration using files (JSON, YAML, separated text) JSON
strings and command line arguments. Command line arguments can be used
to override configuration. Period-separated command line flags are
parsed as hierarchical lists.

## Install

``` r
remotes::install_packages("analythium/rconfig")
```

## Another config package?

There are other R packages to manage configs:

-   [config](https://rstudio.github.io/config/) has nice inheritance
    rules, and it even scans parent directories for YAML config files
-   [configr](https://CRAN.R-project.org/package=configr) has nice
    substitution/interpolation features and supports YAML, JSON, TOML,
    and INI file formats

These package are fantastic if you are managing deployments at different
stages of the life cycle, i.e. testing/staging/production.

However, when you use Rscript from the command line, you often do not
want to manage too many configuration files, but want a quick way to
override some of the default settings.

The rconfig package provides various ways to override defaults, and
instead of changing active configuration (as in the config package), you
can merge lists in order to arrive at a final configuration. These are
very similar concepts, but not quite the same.

The rconfig package has the following features:

-   uses default configuration file
-   file based override with the `-f` or `--file` flags (accepts JSON,
    YAML, and plain text files)
-   JSON string based override with the `-j` or `--json` flags
-   other command line arguments are merged too, e.g. `--cores 4`
-   heuristic rules are used to coerce command line values to the right
    type
-   R expressions starting with `!expr` are evaluated by default, this
    behavior can be turned off (same feature can be found in the yaml
    and config packages, but here it works with plain text and JSON too)
-   period-separated command line arguments are parsed as hierarchical
    lists, e.g. `--user.name Joe` will be added as `user$name` to the
    config list
-   nested configurations can also be flattened
-   command line flags without a value will evaluate to `TRUE`,
    e.g. `--verbose`

If you are not yet convinced, here is a quick teaser. This is the
content of the default configuration file, `rconfig.yml`:

    # trials: 5
    # dataset: "demo-data.csv"
    # cores: !expr getOption("mc.cores", 1L)
    # user:
    #   name: "demo"

Let’s use a simple R script to print out the configs:

    # #!/usr/bin/env Rscript
    # options("rconfig.debug"=TRUE)
    # str(rconfig::rconfig())

Now you can override the default configuration using another file, a
JSON string, and some other flags. Notice the variable substitution for
user name!

``` bash
export USER=Jane

Rscript --vanilla test.R \
  -f rconfig-prod.yml \
  -j '{"trials":30,"dataset":"full-data.csv"}' \
  --user.name $USER \
  --verbose
# List of 5
#  $ trials : int 30
#  $ dataset: chr "full-data.csv"
#  $ cores  : int 1
#  $ user   :List of 1
#   ..$ name: chr "Jane"
#  $ verbose: logi TRUE
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "merged"
#   ..$ value:List of 4
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/dev/rconfig/inst/examples/rconfig.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/dev/rconfig/inst/examples/rconfig-prod.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "json"
#   .. .. ..$ value: chr "{\"trials\":30,\"dataset\":\"full-data.csv\"}"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "args"
#   .. .. ..$ value: chr "--user.name Jane --verbose"
#  - attr(*, "class")= chr "rconfig"
```

The package was inspired by the config package,
docker-compose/kubectl/caddy and other CLI tools, and was motivated by
some real world need when managing background processing on cloud
instances.

## Usage

### R command line usage

Open the project in RStudio or set the work directory to the folder root
after cloning/downloading the repo.

``` r
str(rconfig::rconfig())
# List of 4
#  $ trials : int 5
#  $ dataset: chr "demo-data.csv"
#  $ cores  : int 1
#  $ user   :List of 1
#   ..$ name: chr "demo"
#  - attr(*, "class")= chr "rconfig"

str(rconfig::rconfig(
    file = "rconfig-prod.yml"))
# List of 4
#  $ trials : int 30
#  $ dataset: chr "full-data.csv"
#  $ cores  : int 1
#  $ user   :List of 1
#   ..$ name: chr "real_We4$#z*="
#  - attr(*, "class")= chr "rconfig"

str(rconfig::rconfig(
    file = c("rconfig.json",
             "rconfig-prod.txt"),
    list = list(user = list(name = "Jack"))))
# List of 4
#  $ trials : int 30
#  $ dataset: chr "full-data.csv"
#  $ cores  : int 1
#  $ user   :List of 1
#   ..$ name: chr "Jack"
#  - attr(*, "class")= chr "rconfig"

str(rconfig::rconfig(
    file = c("rconfig.json",
             "rconfig-prod.txt"),
    list = list(user = list(name = "Jack")),
    flatten = TRUE))
# List of 4
#  $ trials   : int 30
#  $ dataset  : chr "full-data.csv"
#  $ cores    : int 1
#  $ user.name: chr "Jack"
#  - attr(*, "class")= chr "rconfig"
```

Using alongside of the config package:

``` r
conf <- config::get(
    config = "production",
    file = "config.yml",
    use_parent = FALSE)

str(rconfig::rconfig(
    file = "rconfig.yml",
    list = conf))
# List of 4
#  $ trials : int 30
#  $ dataset: chr "data.csv"
#  $ cores  : int 1
#  $ user   :List of 1
#   ..$ name: chr "demo"
#  - attr(*, "class")= chr "rconfig"
```

### Using with Rscript

Set the work directory to the `inst/examples` folder cloning/downloading
the repo.

Default config if found (the script has debug mode on):

``` bash
Rscript test.R
# List of 4
#  $ trials : int 5
#  $ dataset: chr "demo-data.csv"
#  $ cores  : int 1
#  $ user   :List of 1
#   ..$ name: chr "demo"
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "file"
#   ..$ value: chr "/Users/Peter/dev/rconfig/inst/examples/rconfig.yml"
#  - attr(*, "class")= chr "rconfig"
```

Default with debug mode off:

``` bash
R_RCONFIG_DEBUG="FALSE" Rscript test.R
# List of 4
#  $ trials : int 5
#  $ dataset: chr "demo-data.csv"
#  $ cores  : int 1
#  $ user   :List of 1
#   ..$ name: chr "demo"
#  - attr(*, "class")= chr "rconfig"
```

Change default config file:

``` bash
R_RCONFIG_FILE="rconfig-prod.yml" Rscript test.R
# List of 3
#  $ trials : int 30
#  $ dataset: chr "full-data.csv"
#  $ user   :List of 1
#   ..$ name: chr "real_We4$#z*="
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "file"
#   ..$ value: chr "/Users/Peter/dev/rconfig/inst/examples/rconfig-prod.yml"
#  - attr(*, "class")= chr "rconfig"
```

Change default config file and debug on:

``` bash
R_RCONFIG_FILE="rconfig-prod.yml" R_RCONFIG_DEBUG="FALSE" Rscript test.R
# List of 3
#  $ trials : int 30
#  $ dataset: chr "full-data.csv"
#  $ user   :List of 1
#   ..$ name: chr "real_We4$#z*="
#  - attr(*, "class")= chr "rconfig"
```

Use file and other props to override default:

``` bash
Rscript test.R -f rconfig-prod.yml --user.name "unreal_Zh5z*$#="
# List of 4
#  $ trials : int 30
#  $ dataset: chr "full-data.csv"
#  $ cores  : int 1
#  $ user   :List of 1
#   ..$ name: chr "unreal_Zh5z*0="
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "merged"
#   ..$ value:List of 3
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/dev/rconfig/inst/examples/rconfig.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/dev/rconfig/inst/examples/rconfig-prod.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "args"
#   .. .. ..$ value: chr "--user.name unreal_Zh5z*0="
#  - attr(*, "class")= chr "rconfig"
```

Use JSON string and other props to override default:

``` bash
Rscript test.R \
  -j '{"trials":30,"dataset":"full-data.csv","user":{"name": "real_We4$#z*="}}' \
  --user.name "unreal_Zh5z*$#="
# List of 4
#  $ trials : int 30
#  $ dataset: chr "full-data.csv"
#  $ cores  : int 1
#  $ user   :List of 1
#   ..$ name: chr "unreal_Zh5z*0="
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "merged"
#   ..$ value:List of 3
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/dev/rconfig/inst/examples/rconfig.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "json"
#   .. .. ..$ value: chr "{\"trials\":30,\"dataset\":\"full-data.csv\",\"user\":{\"name\": \"real_We4$#z*=\"}}"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "args"
#   .. .. ..$ value: chr "--user.name unreal_Zh5z*0="
#  - attr(*, "class")= chr "rconfig"
```

## License

[MIT License](./LICENSE) © 2022 Peter Solymos and Analythium Solutions
Inc.
