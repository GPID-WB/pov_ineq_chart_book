library(pins)
dfc <- readr::read_rds("data/dfc.rds")
dfr <- readr::read_rds("data/dfr.rds")

#--------- GITHUB ---------

# board_register_github(repo = "PovcalNet-Team/pov_ineq_chart_book")
# pin(dfc, description = "Deciles of countries by year", board = "github")
# pin(dfr, description = "Deciles of regions by year", board = "github")
#

#--------- RS COnnect ---------
my_key <- Sys.getenv("connect_key_ext")


# my_server  <- "https://datanalytics.worldbank.org/"
# my_server  <- "http://w0lxopshyprd1b.worldbank.org/"
# my_server  <- "http://w0lxpjekins05.worldbank.org:3939/"
# my_server  <- "http://localhost:3939"

my_server  <- "http://w0lxopshyprd1b.worldbank.org:3939/"
my_server  <- "http://localhost:3939/"

board_register_rsconnect(server = my_server,
                         key    = my_key)

pin(dfc,
    name        = "deciles_by_country",
    description = "Deciles of countries by year",
    board       = "rsconnect")


pin(dfr,
    name        = "deciles_by_region",
    description = "Deciles of regions by year",
    board       = "rsconnect")

