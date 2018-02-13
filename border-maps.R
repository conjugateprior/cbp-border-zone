library(sf)
library(dplyr)

# Grab some US state shapefiles from the census bureau
#
# dir.create("data")
# Uncomment the next lines to download and unpack the data
# download.file("http://www2.census.gov/geo/tiger/GENZ2016/shp/cb_2016_us_state_20m.zip",
#               "data/cb_2016_us_state_20m.zip")
# unzip("data/cb_2016_us_state_20m.zip", exdir = "data")

# Transform to a projection from long-lat form
us <- st_read("./data/cb_2016_us_state_20m.shp") %>%
  st_transform("+init=epsg:26978")

# 100 miles in meters
meters <- 160934.4

not_contiguous_us <- c("Puerto Rico", "Alaska", "Hawaii")

us_filt <- filter(us, !(NAME %in% not_contiguous_us))
us_outline <- st_union(us_filt) # contiguous outline
not_border_zone <- st_buffer(us_outline, dist = -meters) # mainland outline 100m in
border_zone <- st_difference(us_outline, not_border_zone)

# png("pics/border-zone-contiguous-us.png",
#      width = 8, height = 6.5, units = "in", res = 300)
plot(st_geometry(us_filt), lwd = 2,
     main = "'Border' Zone in Contiguous United States",
     graticule = TRUE, col = "white", col_graticule = "lightgrey")
plot(border_zone, lty = "blank", col = rgb(0.7, 0.7, 0.7, 0.4), add = TRUE)
# dev.off()

# And here's Alaska by itself, to scale for once.
us_filt <- filter(us, NAME == "Alaska")

us_outline <- st_union(us_filt) # Alaska outline
not_border_zone <- st_buffer(us_outline, dist = -meters) # Alaska outline 100m in
border_zone <- st_difference(us_outline, not_border_zone)

# png("pics/border-zone-alaska.png",
#     width = 8, height = 6.5, units = "in", res = 300)
plot(st_geometry(us_filt),  lwd = 2,
     graticule = TRUE, col = "white", col_graticule = "lightgrey")
plot(border_zone, lty = "blank", col = rgb(0.7, 0.7, 0.7, 0.4), add = TRUE)
# dev.off()
