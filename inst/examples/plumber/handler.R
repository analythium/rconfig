#* Echo back the input
#* @param msg The message to echo
#* @post /echo
function(msg="") {
    list(msg = paste0(
        value(CONFIG$title, "The message is"),
        ": '", msg, "'"))
}

#* Return tets or prod mode
#* @get /test
function() {
    list(mode = if (TEST) "test" else "prod")
}
