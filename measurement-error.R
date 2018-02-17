## Measurement error
#
# border-states.R estimated population by interpolating from county
# populations.  This will get the right counties that are either completely in
# or completely outside the border zone.  Errors happen when counties overlap
# the border and the crude interpolation process makes assumptions about
# populations that are not nearly true.
#
# To be more concrete, let's look at the states where measurement error
# might make the most difference. Somewhere with a large population and also
# large counties and clumpy populations clustered around the coast e.g. California
#
# Note: This script assumes you've run border-states.R and made those objects

cal_overlaps <- overlaps %>%
  filter(state_name  == "California", prop_overlap < 1.0)
cal <- counties %>%
  filter(state_name  == "California")

cal_overlap_counties <- cal %>%
  filter(name %in% cal_overlaps$name)

# Where are the overlapping border counties in which measurement error would
# be potentially problematic?

# png("pics/border-zone-california.png",
#    width = 8, height = 6.5, units = "in", res = 300)
plot(st_geometry(cal), main = "California Counties Overlapping the 'Border' Zone")
plot(st_geometry(cal_overlap_counties), col = rgb(.8, .8, .8), add = TRUE)
plot(st_geometry(cal_overlaps), col = rgb(.5,.5,.5), add = TRUE)
overlaps %>%
  filter(state_name  == "California", prop_overlap == 1.0) %>%
  st_geometry %>%
  plot(col = rgb(.2, .2, .2), add = TRUE)
# dev.off()

# How many people in these border overlapping counties?
sum(cal_overlap_counties$pop2016)
# >6M people we can get wrong

# Grab a census block level data set from the Census Bureau
# Unfortunately it's for 2010, so we'll need to assume that populations
# have grown but not substantially moved since then.

# Uncomment the next lines to download and unpack the data
# download.file("https://www2.census.gov/geo/tiger/TIGER2010BLKPOPHU/abblock2010_06_pophu.zip",
#               "data/abblock2010_06_pophu.zip")
# unzip("data/abblock2010_06_pophu.zip", exdir = "data")
cal_block <- st_read("./data/tabblock2010_06_pophu.shp")
cal_block_proj <- st_transform(cal_block, "+init=epsg:26978")

# Because it's [ahem] quite big, Let's look at the second largest county,
# San Bernardino, and see how our crude estimate and a better estimate
# based on smaller population units compare
#
san_bernadino <- cal_block_proj %>%
  filter(COUNTYFP == "071")
# 48176 census blocks

# We are just as impatient as we were in border-states.R so we'll use
# random sampling to get the population of San Bernardino in the border zone:
# We draw 2000 census blocks compute the number of people in blocks in the zone
# versus the number of people in all the 2000 blocks
set.seed(123)
nn <- sample(nrow(san_bernadino), 2000)
sb_border <- st_intersection(san_bernadino[nn,], border_zone)
sb_estimated_people_affected <- sum(sb_border$POP10) / sum(san_bernadino$POP10[nn])
# 0.964

# This is not super surprising because the west end of SB is basically
# Los Angeles.
#
# Compare this to the previous cruder method, which we'll re-do
# the steps for quickly now
cal %>%
  filter(NAME == "San Bernardino") %>%
  summarise(population = pop2016)
# SB has 2,140,096 people

# The area of the whole county
sb_landmass <- sum(st_area(san_bernadino))
set_units(sb_landmass, miles^2)
# 20161.21 miles^2

# the area of the border zone part of the county
sb_landmass_in_border <- counties %>%
  filter(NAME = "San Bernardino") %>%
  st_intersection(border_zone) %>%
  st_area
set_units(sb_landmass_in_border, miles^2)
# 5169.603 miles^2

# So the border proportion is
sb_landmass_prop <- as.numeric(sb_landmass_in_border / sb_landmass)
# 0.256
#
# which is nowhere near 96%

# How much difference should we expct this to make to the state figures?
#
# San Bernardino holds about 5.5% of California population
cal %>%
  filter(NAME == "San Bernardino") %>%
  summarise(population = pop2016,
            population_cal = sum(cal$pop2016),
            prop_of_state_pop = population / population_cal) %>%
  st_set_geometry(NULL)
# 0.055
#
# and we have misclassified about 0.96 - 0.26 = 0.7 of them.  So that's about
# 1.5M people to add to the 'affected by the border' count for California.
# SB won't make much of dent in the overall country proportions, but it's
# still a fair number of people to miss.  And that's just one county.
#
# In general we should probably expect errors of this kind to lead to
# undercounts, as they do here.  If that's true, we can think of the
# figures in border-states.R as underestimates of affected people.

