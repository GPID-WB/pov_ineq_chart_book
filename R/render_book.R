


bookdown::render_book("index.Rmd")
beepr::beep(4)
browseURL("docs/index.html")



file <- c("Gini.Rmd")
bookdown::render_book(file, preview = TRUE)
