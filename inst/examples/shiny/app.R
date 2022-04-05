#!/usr/bin/env Rscript

library(shiny)
library(rconfig)
CONFIG <- rconfig()
TEST <- value(CONFIG$test, FALSE)
message("Mode: ", if (TEST) "Test" else "Prod")

ui <- fluidPage(
    mainPanel(
        h1(value(CONFIG$title, "Hello Shiny!")),
        sliderInput("obs",
            "Number of observations",
            min = 1,
            max = 5000,
            value = value(CONFIG$value, 100)),
        plotOutput("distPlot")
    )
)
server <- function(input, output) {
    output$distPlot <- renderPlot({
        dist <- rnorm(input$obs)
        hist(dist,
            col=value(CONFIG$color, "purple"),
            xlab="Random values")
    })
}
shinyApp(
    ui = ui,
    server = server,
    options = list(
        port = value(CONFIG$port, 8080)
    )
)
