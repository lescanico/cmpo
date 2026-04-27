At period $t$, prior re-entrant latent demand $D^L_{r,t-1}$ is activated at rate $p_{act}$ into re-entrant active demand $D^A_{r,t}$. A share $p_{surf}$ of that active re-entrant demand surfaces into visible active demand $D^A_{v,t}$, and the remaining share $1 - p_{surf}$ enters hidden active demand $D^A_{h,t}$.

In parallel, intake demand $D^L_{i,t}$ is admitted through the intake gate into $D^A_{i,t}$; operationally, $p_{in}$ determines the intake-facing share of formal capacity $C^F_t$ that is made available for that admission flow. The total visible active stream is therefore the combination of admitted intake demand and surfaced re-entrant demand, while the hidden active stream carries the remaining unsurfaced re-entrant burden. At that point, total active demand in the period is represented by the active burden entering the capacity container $C$.

Inside $C$, the formal-capacity template $C^F_t$ is partitioned into scheduled formal capacity $C^F_{s,t}$ and unscheduled formal capacity:

$$
C^F_t - C^F_{s,t}
$$

The utilization parameter $p_{uti}$ then acts on scheduled formal capacity $C^F_{s,t}$, yielding utilized scheduled formal capacity:

$$
C^F_{s,u,t} = p_{uti} C^F_{s,t}
$$

and not-utilized scheduled capacity:

$$
C^F_{s,t} - C^F_{s,u,t} = (1 - p_{uti}) C^F_{s,t}
$$

The utilized scheduled layer clears visible workload $W_{v,t}$. The not-utilized scheduled layer clears hidden workload through channel $W^1_{h,t}$. The unscheduled formal layer $C^F_t - C^F_{s,t}$ clears additional hidden workload through $W^2_{h,t}$. Beyond the formal template, the broader capacity buffer $C^B_t$ absorbs additional burden, and the specifically human-buffer portion of that buffered clearance is represented by $W^3_{h,t}$.

Thus the period’s total cleared workload is:

$$
W_t = W_{v,t} + W^1_{h,t} + W^2_{h,t} + W^3_{h,t}
$$

Completed workload $W_t$ then regenerates future obligation through $p_{gen}$. In the MVP, this is held at $p_{gen} = 1$, so cleared recurring work replenishes its full latent obligation mass.

At the same time, unresolved active burden overflows according to:

$$
D^A_t - W_t
$$

and that overflow enters the period-end latent stock $D^L_t$. The period-end latent stock therefore contains latent demand remaining after activation, regenerated future obligation from cleared work, and overflow beyond same-period clearance.

Finally, $p_{out}$ acts on $D^L_t$, moving a share out of the system and carrying the remaining share forward into the next period:

$$
(1 - p_{out})D^L_t
$$

The dashboard layer then reads only the formal-capacity slice of this process:

Future ATP:

$$
\frac{C^F_{t+n} - C^F_{s,t+n}}{C^F_{t+n}}
$$

Apparent slack:

$$
\frac{C^F - C^F_{s,u}}{C^F}
$$

Utilization:

$$
\frac{C^F_{s,u}}{C^F}
$$

## Key algebra

The key algebra in this figure is therefore:

- $p_{act}$ acts on $D^L_{r,t-1}$
- $p_{surf}$ acts on $D^A_{r,t}$
- $p_{in}$ allocates intake access through $C^F_t$
- $p_{uti}$ partitions $C^F_{s,t}$ into $C^F_{s,u,t}$ and $C^F_{s,t} - C^F_{s,u,t}$
- $p_{gen}$ acts on $W_t$
- $p_{out}$ acts on $D^L_t$