# A closer look at two states
#
# This code assumes you have run border-states.R and created 'counties' and
# 'border_zone'.

library(tmap)

plot_border_zone <- function(state, n = 9){
  pl_state <- counties %>%
    filter(state_name == state) %>%
    mutate(Population = pop2016 / 1000000)
  inter <- st_union(st_intersection(pl_state, border_zone))
  if (st_is_empty(inter))
    stop(paste("There is no 'border' zone in", state))
  tm_shape(pl_state) +
    tm_borders(alpha = 0.3) +
    tm_fill(col = 'Population', title = "Population (millions)",
            palette = "Blues", n = n) +
    tm_shape(inter) +
    tm_fill(alpha = 0.3, col = "grey") +
    tm_layout(paste("The 'Border' Zone in", state))
}

png("pics/border-county-plot-pa.png",
    width = 8, height = 8, units = "in", res = 300)
plot_border_zone("Pennsylvania", n = 5)
dev.off()

png("pics/border-county-plot-oh.png",
    width = 8, height = 8, units = "in", res = 300)
plot_border_zone("Ohio", n = 5)
dev.off()

