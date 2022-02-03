## config

## Parse cli arguments for:
## Precedence:
## 1. R_RCONFIG_FILE value or config.yml
## 2. json and file args are parsed and applied in order
## 3. the remaining other cli args are added last
## 4. config file
## 5. config list
rconfig <- function(file = NULL, list = NULL) {
    args <- commandArgs(trailingOnly=TRUE)
    l1 <- parse_default()
    l2 <- parse_args_file_and_json(args)
    l3 <- parse_args_other(args)
    lists <- list(l1)
    for (i in seq_along(l2))
        lists[length(lists)+1L] <- l2[i]
    lists[[length(lists)+1L]] <- l3
    if (!is.null(file)) {
        l4 <- parse_file(file)
        lists[[length(lists)+1L]] <- l4
    }
    if (!is.null(list)) {
        lists[[length(lists)+1L]] <- list
    }
    out <- list()
    for (i in lists)
        out <- utils::modifyList(out, i)
    out
}

