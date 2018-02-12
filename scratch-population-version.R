
# Unfortunately no data from PR
pops <- readr::read_csv("data/population_minus_line2.csv", col_types = "ccc________n")

counties_longlat <- st_read("./data/cb_2016_us_county_20m/cb_2016_us_county_20m.shp") %>%
  filter(STATEFP != 72) # drop Puerto Rico
counties <- st_transform(counties_longlat, "+init=epsg:26978")
counties$GEOID <- as.character(counties$GEOID)

counties_outline <- st_union(counties)
not_border_zone <- st_buffer(counties_outline, dist = -meters) # negative to go inland
border_zone <- st_difference(counties_outline, not_border_zone)

# add county's area and merge in population counts
counties <- counties %>%
  mutate(original_area = st_area(counties)) %>%
  inner_join(pops, by = c(GEOID = "GEO.id2"))

# compute overlaps and estimate border population
overlaps <- st_intersection(counties, border_zone) # about 14s
overlaps$border_area <- st_area(overlaps) # doesn't work in mutate
overlaps <- mutate(overlaps,
                   STATEFP = as.character(STATEFP), # for joining later
                   prop_overlap = as.numeric(border_area) / as.numeric(original_area),
                   border_population = respop72016 * prop_overlap)
border_population_us <- sum(overlaps$respop72016) / sum(counties$respop72016)

fips <- read_csv("data/fips-state-codes.csv") # to decode name from numeric

# fold in state names
cont <- counties %>%
  group_by(STATEFP) %>%
  summarise(population = sum(respop72016)) %>%
  mutate(STATEFP = as.character(STATEFP)) %>%
  left_join(fips, by = c(STATEFP = "numeric"))

overlap_by_state <- overlaps %>%
  group_by(STATEFP) %>%
  summarise(border = sum(border_population)) %>%
  left_join(fips, by = c(STATEFP = "numeric")) %>%
  st_set_geometry(NULL)

bystate <- left_join(cont, overlap_by_state, by = "STATEFP") %>%
  mutate(prop = ifelse(is.na(border), 0, border / population),
         NAME = factor(name.x, levels = name.x[order(prop)])) %>%
  arrange(desc(prop))

ggplot(bystate, aes(x = NAME, y = 100 * prop)) +
  geom_point() +
  coord_flip() +
  labs(y = "Percent",
       x = "State",
       title = "Estimated Percentage of Population in each State in 'Border' Zone",
       subtitle = sprintf("Estimated Percentage of Total Population: %.2f", border_population_us)) +
  theme_minimal()
# ggsave("pics/border-zone-pop-proportions-by-state.png", dpi = 300, width = 7, height = 7)

diffss <- left_join(covered, bystate, by = c(NAME = "name.x")) %>%
  filter(prop.x != 0.0 & prop.x != 1.0, prop.y != 0.0 & prop.y != 1.0)

ggplot(diffss, aes(x = prop.x, y = prop.y, label = name.y)) +
  geom_point() +
  geom_text(nudge_y = -0.02) +
  geom_abline(alpha = 0.3) +
  ylim(0,1) +
  xlim(0,1) +
  xlab("Percent of State in 'Border'") +
  ylab("Estimated 'Border' Population Percentage of State") +
  theme_minimal()
# ggsave("pics/border-zone-pop-proportions-by-state.png", dpi = 300, width = 7, height = 7)

