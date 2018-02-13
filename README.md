# cbp-border-zone

A short exploration of that 100 mile 'border' zone that the US Customs and Border
Patrol get to ask you for your papers in.  

Where is the 100 mile 'border' zone anyway?

![](pics/border-zone-contiguous-us.png)

![](pics/border-zone-alaska.png)

Hawaii and Puerto Rico, you're definitely all in it, so I'm not going to plot
you. Sorry.

More generally, how much of each US state or territory is 'in the zone'?

![](pics/border-zone-area-proportions-by-state.png)

But that's just space.  So here are the same proportions for 
with state populations (crudely estimated from county level data).

![](pics/border-zone-pop-proportions-by-state.png)

It's a bit hard to compare these, so here's another way to look at these
two sets of proportions together  

![](pics/border-zone-pop-area-diffs-by-state.png)

Over the diagonal states have more
people than space covered by the zone. Under the diagonal, it's the opposite.

If you want to check my figures or ask more interesting 
questions than I did, the R that generated the maps is 
in [border-maps.R](border-maps.R), and the R that generated the proportions
is in [border-states.R](border-states.R).  So have at it - the license just says
you shouldn't forget where you found the code. 

Will Lowe. February 12, 2018

