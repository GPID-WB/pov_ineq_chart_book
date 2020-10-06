library("here")
library("data.table")
library("ggplot2")
library("plotly")
library("shiny")
library("miniUI")
library("pins")

#----------------------------------------------------------
#   subfunctions
#----------------------------------------------------------
# source(here("R", "utils.R"))


qtile <- function(x, nq = 10) {
    N   <-  length(x)
    csw <-  1:N
    qp  <-   floor(csw/((N+1)/nq)) + 1
    return(qp)
}



#--------- Connect to data ---------

my_key    <- Sys.getenv("connect_key")
# my_server <- "http://w0lxopshyprd1b.worldbank.org:3939/"
my_server  <- "http://localhost:3939/"

board_register_rsconnect(server = my_server,
                         key    = my_key)

dfc <- pin_get(name = "country_deciles",
               board = "rsconnect")


#----------------------------------------------------------
#   Calculate Quantiles
#----------------------------------------------------------

# set data.table

DT <- as.data.table(dfc)
setnames(DT, "threshold", "pv")


DT <- DT[
    # remove old years
    year >= 1990
][
    # filter negative values (which we should not have)
    pv > 0 & !is.na(pv)
][,
  # multiply by 100
  goal := 100*goal

][
    ,
    headcount := NULL
]


yrs <- DT[, unique(year)]


ui <- miniPage(
    miniTitleBar("Growth Incidence Curve of Medians"),
    miniTabstripPanel(
        miniTabPanel("Parameters",
                     icon = icon("sliders"),
                     miniContentPanel(sliderInput("pc",
                                                  label = "Percentile",
                                                  min = 10, max = 100, value = 50, step = 10),

                                      numericInput("nq",
                                                   label = "Number of quantiles",
                                                   min = 5, max = 100, value = 10, step  = 5),

                                      selectInput("yr1",
                                                  label    = "Year 1",
                                                  choices  = yrs,
                                                  selected = 1993),

                                      selectInput("yr2",
                                                  label    = "Year 2",
                                                  choices  = yrs,
                                                  selected = 2017),

                                      selectInput("ms",
                                                  label = "Measure:",
                                                  choices = c("sum", "mean", "min", "max"),
                                                  selected = "max")
                     )
        ),
        miniTabPanel("Visualize", icon = icon("area-chart"),
                     miniContentPanel(plotlyOutput("GIC", height = "100%"))
        ),
        miniTabPanel("Data", icon = icon("table"),
                     miniContentPanel(DT::dataTableOutput("table"))
        )
    )
) # End of UI


server <- function(input, output, session) {

    DQ <- reactive({

        calc <- paste0(".(", input$ms, "  = ", input$ms, "(pv, na.rm = TRUE))")
        calc <- parse(text = calc)

        # Make sure the input are included correclty in data.table (not efficient but works)
        iyr1  <- as.numeric(input$yr1)
        iyr2  <- as.numeric(input$yr2)
        yrdif <- iyr2 - iyr1
        yrst  <- c(iyr1, iyr2)

        DQ <-
            DT[
                year  %in% yrst
                & goal == input$pc
            ]

        setorder(DQ, year, pv)
        DQ <-
            DQ[
                , # Create deciles in each percentile
                qp := qtile(pv, input$nq),
                by = .(year)
            ][
                , # Make requested calculation
                eval(calc),
                by = .(year, qp)
            ][
                ,
                yr := ifelse(year == iyr1, "yr1", "yr2")
            ]


        DQ <- dcast(DQ,
                    formula = qp ~ yr,
                    value.var = input$ms)

        DQ <-
            DQ[
                ,
                gic := ((yr2/yr1)^(1 / yrdif)) - 1
            ]
        return(DQ)

    })


    output$GIC <- renderPlotly({
        pn <- ggplot(DQ(),
                     aes(
                         x = qp,
                         y = gic
                     )
        ) +
            geom_point() +
            geom_line() +
            geom_hline(yintercept = 0,
                       color = "red") +
            theme_minimal() +
            scale_y_continuous(labels = scales::percent) +
            labs(
                title = "Growth Incidence curve of selected percentile",
                x     = "Quantiles",
                y     = "Annualized growth"
            )

        ggplotly(pn)
    })
    output$table <- DT::renderDataTable({
        DQ()
    })


} # End of server

shinyApp(ui, server)
# runGadget(ui, server, viewer = dialogViewer("GIC"))
# runGadget(shinyApp(ui, server), viewer = panelViewer())

