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

The population estimates used here are crude estimates.  You should expect them
to be underestimates of the true numbers affected. To see why this is true,
consider the big populous counties in California overlapping the 'border' zone

![](pics/border-zone-california.png)

Take San Bernardino. 

![](pics/san-bernardino.png)

From the census block data it's clear that most of the
population is going to be in the south west - basically Los Angeles.

Sure enough, although 25% of the state is in the 'border' zone, more than
90% of the population are - about 1.5M more people than the simple 
interpolation would suggest.  So, while quick to compute, the original 
numbers are probably on average too small.

If you want to check my figures or ask more interesting 
questions than I did, the R that generated the first two maps is 
in [border-maps.R](border-maps.R).  The R that generated the proportions
is in [border-states.R](border-states.R).  And the code that did the California
comparisons is in [measurement-error.R](measurement-error.R) 

So have at it - the license just says you shouldn't forget where you found 
the code. 

Will Lowe. February 16, 2018

