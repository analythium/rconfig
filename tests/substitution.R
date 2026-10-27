local({
    env_names <- c(
        "RCONFIG_TEST_SUB_PRESENT",
        "RCONFIG_TEST_SUB_EMPTY",
        "RCONFIG_TEST_SUB_UNSET"
    )
    old_env <- Sys.getenv(env_names, unset = NA_character_)
    on.exit({
        for (name in env_names) {
            value <- old_env[[name]]
            if (is.na(value))
                Sys.unsetenv(name)
            else
                do.call(Sys.setenv, setNames(list(value), name))
        }
    })

    Sys.setenv(RCONFIG_TEST_SUB_PRESENT = "present",
               RCONFIG_TEST_SUB_EMPTY = "")
    Sys.unsetenv("RCONFIG_TEST_SUB_UNSET")
    empty_is_set <- identical(
        Sys.getenv("RCONFIG_TEST_SUB_EMPTY", unset = NA_character_),
        ""
    )

    values <- rconfig:::substitute_list(list(
        present_default = "${RCONFIG_TEST_SUB_PRESENT:-fallback}",
        present_plain = "${RCONFIG_TEST_SUB_PRESENT-fallback}",
        empty_default = "${RCONFIG_TEST_SUB_EMPTY:-fallback}",
        empty_plain = "${RCONFIG_TEST_SUB_EMPTY-fallback}",
        unset_default = "${RCONFIG_TEST_SUB_UNSET:-fallback}",
        unset_plain = "${RCONFIG_TEST_SUB_UNSET-fallback}",
        source = "${RCONFIG_TEST_SUB_PRESENT}",
        reference = "#{source}"
    ))

    empty_question <- tryCatch(
        rconfig:::substitute_list(list(
            value = "${RCONFIG_TEST_SUB_EMPTY?required}",
            other = "x"
        )),
        error = identity
    )
    missing_error <- tryCatch(
        rconfig:::substitute_list(list(
            value = "${RCONFIG_TEST_SUB_UNSET?missing value}",
            other = "x"
        )),
        error = identity
    )
    empty_error <- tryCatch(
        rconfig:::substitute_list(list(
            value = "${RCONFIG_TEST_SUB_EMPTY:?empty value}",
            other = "x"
        )),
        error = identity
    )

    stopifnot(
        identical(values$present_default, "present"),
        identical(values$present_plain, "present"),
        identical(values$empty_default, "fallback"),
        identical(values$empty_plain, if (empty_is_set) "" else "fallback"),
        identical(values$unset_default, "fallback"),
        identical(values$unset_plain, "fallback"),
        identical(values$reference, "present"),
        inherits(missing_error, "error"),
        identical(conditionMessage(missing_error), "missing value"),
        inherits(empty_error, "error"),
        identical(conditionMessage(empty_error), "empty value")
    )
    if (empty_is_set) {
        stopifnot(identical(empty_question$value, ""))
    } else {
        stopifnot(
            inherits(empty_question, "error"),
            identical(conditionMessage(empty_question), "required")
        )
    }
})
