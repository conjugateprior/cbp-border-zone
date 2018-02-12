## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, comment = "")

## ---- message=FALSE------------------------------------------------------
library(sf)
library(dplyr)
library(ggplot2)
library(units)
library(readr)

## ---- eval = FALSE-------------------------------------------------------
## dir.create("data") # a place to put the shapefiles
## download.file("http://www2.census.gov/geo/tiger/GENZ2016/shp/cb_2016_us_state_20m.zip",
##               "data/cb_2016_us_state_20m.zip")
## unzip("data/cb_2016_us_state_20m.zip", exdir = "data")

## ------------------------------------------------------------------------
us_longlat <- st_read("./data/cb_2016_us_state_20m/cb_2016_us_state_20m.shp")
us <- st_transform(us_longlat, "+init=epsg:26978")

## ------------------------------------------------------------------------
meters <- 160934.4

## ------------------------------------------------------------------------
us_outline <- st_union(us)

## ------------------------------------------------------------------------
not_border_zone <- st_buffer(us_outline, dist = -meters) # negative to go inland
border_zone <- st_difference(us_outline, not_border_zone)

## ------------------------------------------------------------------------
border_zone_area <- st_area(border_zone)
not_border_zone_area <- st_area(not_border_zone)

set_units(border_zone_area, miles^2) # Translate to American
set_units(not_border_zone_area, miles^2)

## ------------------------------------------------------------------------
prop_us_covered <- border_zone_area / (border_zone_area + not_border_zone_area)
prop_us_covered

## ------------------------------------------------------------------------
overlaps <- st_intersection(us, border_zone)

## ------------------------------------------------------------------------
ov_df <- data_frame(NAME = overlaps$NAME, AREA = st_area(overlaps))
us_df <- data_frame(NAME = us$NAME, AREA = st_area(us))
covered <- left_join(us_df, ov_df, by = "NAME") %>%
  mutate(prop = ifelse(is.na(AREA.y), 0, AREA.y / AREA.x),
         NAME = factor(NAME, levels = NAME[order(prop)])) %>%
  arrange(desc(prop))

## ---- fig.height=7, fig.height = 7---------------------------------------
ggplot(covered, aes(x = NAME, y = 100 * prop)) +
  geom_point() +
  coord_flip() +
  labs(y = "Percent",
       x = "State / Territory",
       title = "Percentage of each State or Territory in 'Border' Zone",
       subtitle = sprintf("Percentage of Total Landmass: %.2f", prop_us_covered)) +
  theme_minimal()

## ---- eval = FALSE, echo = FALSE-----------------------------------------
## # keep a copy
## ggsave("pics/border-zone-proportions-by-state.png", dpi = 300, width = 7, height = 7)

## ------------------------------------------------------------------------
not_contiguous_us <- c("Puerto Rico", "Alaska", "Hawaii")

us_filt <- filter(us, !(NAME %in% not_contiguous_us))
us_outline <- st_union(us_filt) # contiguous outline
not_border_zone <- st_buffer(us_outline, dist = -meters) # mainland outline 100m in
border_zone <- st_difference(us_outline, not_border_zone)

## ------------------------------------------------------------------------
plot(st_geometry(us_filt),  lwd = 2,
     main = "'Border' Zone in Contiguous United States",
     graticule = TRUE, col = "white", col_graticule = "lightgrey")
plot(border_zone, lty = "blank", col = rgb(0.7, 0.7, 0.7, 0.4), add = TRUE)

## ---- eval = FALSE, echo = FALSE-----------------------------------------
## png("pics/border-zone-contiguous-us.png", width = 8, height = 6.5, units = "in", res = 300)
## plot(st_geometry(us_filt),  lwd = 2,
##      graticule = TRUE, col = "white", col_graticule = "lightgrey")
## plot(border_zone, lty = "blank", col = rgb(0.7, 0.7, 0.7, 0.4), add = TRUE)
## dev.off()

## ------------------------------------------------------------------------
us_filt <- filter(us, NAME == "Alaska")

us_outline <- st_union(us_filt) # Alaska outline
not_border_zone <- st_buffer(us_outline, dist = -meters) # Alaska outline 100m in
border_zone <- st_difference(us_outline, not_border_zone)

plot(st_geometry(us_filt),  lwd = 2,
     graticule = TRUE, col = "white", col_graticule = "lightgrey")
plot(border_zone, lty = "blank", col = rgb(0.7, 0.7, 0.7, 0.4), add = TRUE)

## ----eval = FALSE, echo = FALSE------------------------------------------
## png("pics/border-zone-alaska.png", width = 8, height = 6.5, units = "in", res = 300)
## plot(st_geometry(us_filt),  lwd = 2,
##      main = "'Border' Zone in Alaska",
##      graticule = TRUE, col = "white", col_graticule = "lightgrey")
## plot(border_zone, lty = "blank", col = rgb(0.7, 0.7, 0.7, 0.4), add = TRUE)
## dev.off()

