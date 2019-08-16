## 'Border' States

library(sf)
library(dplyr)
library(ggplot2)
library(units)
library(readr)
library(rvest)

# Grab some US state shapefiles from the census bureau
dir.create("data")
# Uncomment the next lines to download and unpack the data
# download.file("http://www2.census.gov/geo/tiger/GENZ2016/shp/cb_2016_us_state_20m.zip",
#               "data/cb_2016_us_state_20m.zip")
# unzip("data/cb_2016_us_state_20m.zip", exdir = "data")

# Transform to a projection from long-lat form
us <- st_read("./data/cb_2016_us_state_20m.shp") %>%
  st_transform("+init=epsg:26978") %>%
  mutate(area = st_area(st_geometry(.)))

# 100 miles in meters
meters <- 160934.4

# An outline of the US (as a geometry set)
us_outline <- st_union(us)

# Buffer to get the US 100 miles inland from its borders
not_border_zone <- st_buffer(us_outline, dist = -meters) # negative => inside
border_zone <- st_difference(us_outline, not_border_zone)

# How much of the US is that anyway?
border_zone_area <- st_area(border_zone)
not_border_zone_area <- st_area(not_border_zone)

# Speak American please
set_units(border_zone_area, miles^2)
set_units(not_border_zone_area, miles^2)

# Apparently a lot of the US is 'border'
prop_us_covered <- as.numeric(border_zone_area /
                                (border_zone_area + not_border_zone_area))
prop_us_covered # yikes

# How much of each state is 'border' zone?
us_border <- st_intersection(us, border_zone)
us_border$area <- st_area(us_border) # correct area
st_geometry(us_border) <- NULL

border_areas_by_state <- left_join(us, us_border,
                                   by = "NAME", suffix = c("", "_border")) %>%
  mutate(prop = ifelse(is.na(area_border), 0, area_border / area),
         state_name = factor(NAME, levels = NAME[order(prop)])) %>%
  arrange(desc(prop))

# Plot the proportions
ggplot(border_areas_by_state, aes(x = state_name, y = 100 * prop)) +
  geom_point() +
  coord_flip() +
  labs(y = "Percent",
       x = "State / Territory",
       title = "Percentage of each State or Territory in 'Border' Zone",
       subtitle = sprintf("Percentage of Total Landmass: %.2f", prop_us_covered)) +
  theme_minimal()

# ggsave("pics/border-zone-proportions-by-state.png",
#        dpi = 300, width = 7, height = 7)

# How does this look with state populations rather than state areas?
#
# We can *approximate* the 'border' population using county-level population
# data: the number of the people in a 'border' zone in a state is the sum of the
# populations of all of its counties, weighted by the proportion of the
# county that is in the border zone. Clearly this will be a bad approximation
# when the county is big and the population is far from evenly distributed, and
# a better approximation when the county is small or the population is evenly
# distributed within it. A smaller population unit would help, but would make
# processing slower. County granularity is enough to get the idea.

# Here's some 2016 county level population data, also from the Census Bureau.
# Select the 'United States' link at
# https://www.census.gov/data/tables/2016/demo/popest/counties-total.html
# and download. When it lands it will be called PEP_2016_PEPANNRES.zip
# I shall assume you put it in the `data/` folder.

# unzip("data/PEP_2016_PEPANNRES.zip", exdir = "data")
state_pop <- read_csv("data/PEP_2016_PEPANNRES_with_ann.csv", skip = 2,
                      col_types = "_cc________n", col_names = FALSE)
names(state_pop) <- c("GEOID", "name", "pop2016")

# Unfortunately it doesn't have Puerto Rico counties in it. However, Puerto
# Rico is small enough to all be in the 'border' zone so we know where it's
# going to land

# Get shapefiles for counties from the Census Bureau
#
# download.file("http://www2.census.gov/geo/tiger/GENZ2016/shp/cb_2016_us_county_20m.zip",
#               "data/cb_2016_us_county_20m.zip")
# unzip("data/cb_2016_us_county_20m.zip", exdir = "data")

# These shapes have FIPS codes instead of state names, so we'll grab a translation from
# https://en.wikipedia.org/wiki/Federal_Information_Processing_Standard_state_code
# and tidy it up with rvest
#
fips <- "https://en.wikipedia.org/wiki/Federal_Information_Processing_Standard_state_code"
state_fips <- read_html(fips) %>%
  html_node("table") %>%
  html_table %>%
  setNames(c("state_name", "alpha", "STATEFP", "status")) %>%
  mutate(STATEFP = sprintf("%02d", STATEFP))

# Now to read in the shapes and fold in the state names and the population info
counties <- st_read("./data/cb_2016_us_county_20m.shp") %>%
  st_transform("+init=epsg:26978") %>%
  filter(STATEFP != 72) %>%               # Remove FIPS code 72 (Puerto Rico)
  mutate(GEOID = as.character(GEOID),
         STATEFP = as.character(STATEFP), # join keys as character
         area = st_area(st_geometry(.))) %>%
  inner_join(state_pop, by = "GEOID") %>% # fold in populations
  left_join(state_fips, by = "STATEFP")   # and state names

# The same overlap checking as before, but for smaller units
counties_outline <- st_union(counties)
not_border_zone <- st_buffer(counties_outline, dist = -meters)
border_zone <- st_difference(counties_outline, not_border_zone)

# compute overlaps and estimate border population
overlaps <- st_intersection(counties, border_zone) # slow - about 14s on my laptop
overlaps <- overlaps %>%
  mutate(STATEFP = as.character(STATEFP),       # for joining later
         border_area = st_area(st_geometry(.)),
         prop_overlap = as.numeric(border_area / area),
         pop2016 = pop2016 * prop_overlap)      # scale population down by overlap

border_population_us <- sum(overlaps$pop2016) / sum(counties$pop2016)

# aggregate county population up to state level
pops_by_state <- counties %>%  # cont
  group_by(state_name) %>%
  summarise(population = sum(pop2016))

# aggregate border county population up to state level
border_pops_by_state <- overlaps %>%
  group_by(state_name) %>%
  summarise(population = sum(pop2016))

border_pops_by_state <- left_join(pops_by_state,
                                  st_set_geometry(border_pops_by_state, NULL),
                                  by = "state_name", suffix = c("", "_border")) %>%
  mutate(prop = ifelse(is.na(population_border), 0, population_border / population),
         state_name = factor(state_name, levels = state_name[order(prop)])) %>%
  arrange(desc(prop))

ggplot(border_pops_by_state, aes(x = state_name, y = 100 * prop)) +
  geom_point() +
  coord_flip() +
  labs(y = "Percent",
       x = "State",
       title = "Estimated Percentage of Population in each State in 'Border' Zone",
       subtitle = sprintf("Estimated Percentage of Total Population: %.2f",
                          border_population_us)) +
  theme_minimal()

# ggsave("pics/border-zone-pop-proportions-by-state.png", dpi = 300, width = 7, height = 7)

# Here are the differences between the population and the state area proportions
differences <- left_join(border_areas_by_state,
                         st_set_geometry(border_pops_by_state, NULL),
                         by = "state_name", suffix = c("_area",  "_pop")) %>%
  filter(!(prop_area %in% c(0.0, 1.0)))

ggplot(differences, aes(x = prop_area, y = prop_pop, label = state_name)) +
  geom_point() +
  geom_text_repel() +
  geom_abline(alpha = 0.3) +
  ylim(0,1) +
  xlim(0,1) +
  xlab("Percentage of State in 'Border' Zone") +
  ylab("Estimated 'Border' Population Percentage of State") +
  theme_minimal()

# ggsave("pics/border-zone-pop-area-diffs-by-state.png", dpi = 300, width = 7, height = 7)


