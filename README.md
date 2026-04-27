# CMPO: Capacity Management under Partial Observability

*The road to hell is paved with partial observability.*

------------------------------------------------------------------------

## The problem

In longitudinal care systems, what is measured is often not what
determines whether the system is actually sustainable.

A clinic can appear stable on visible metrics such as: - schedule
utilization
- appointment availability
- visit throughput

while true internal burden is rising through: - follow-up obligations
- asynchronous work (messages, coordination, documentation)
- deferred or latent demand

This creates a structural failure mode:

> **The system looks fine while it is getting worse.**

------------------------------------------------------------------------

## The core idea

This repository provides a minimal, auditable demonstration of a simple
claim:

> **Partial observability alone is sufficient to produce divergence
> between visible workload and total burden.**

Even under deliberately simplified assumptions: - demand is fungible
- capacity is stable
- no strategic behavior is modeled

the system can still: - maintain stable visible utilization
- accumulate latent demand
- increase total workload over time

------------------------------------------------------------------------

## What this repo shows

A single minimal simulation tracks:

-   **Visible workload** --- what dashboards typically capture
-   **Total workload** --- visible + hidden work
-   **Latent demand** --- future obligations not yet visible

### Key result

Under common operating conditions:

-   visible metrics remain stable
-   apparent slack invites additional intake
-   latent burden accumulates
-   total workload rises

This produces a gap between: - what the system *appears* to be handling
- what it is *actually* carrying

------------------------------------------------------------------------

## Example output

See: figures/divergence_plot.png

Interpretation:

-   visible workload suggests stability
-   total workload reveals accumulation
-   the gap represents hidden work and deferred obligations

------------------------------------------------------------------------

## Run the model

``` r
Rscript mvp_kernel.R
```

No external dependencies required.

------------------------------------------------------------------------

## Scope

This is a **minimal conceptual model**, not a production system.

It is intended to: - illustrate a structural failure mode
- provide a clear, reproducible demonstration
- serve as a starting point for further work

It does **not**: - provide clinical decision support
- use real patient data
- model full operational complexity

------------------------------------------------------------------------

## Why this matters

If decisions are made using only visible metrics:

-   apparent slack may be misinterpreted as available capacity
-   intake may be expanded at the wrong time
-   hidden workload may be displaced onto clinicians
-   long-term system stability may degrade

This is not primarily a problem of effort or intent.

It is a problem of **what the system can see**.

------------------------------------------------------------------------

## Framing

This repository is a **lower-bound demonstration**.

If divergence appears even in this minimal setting, then:

-   real-world complexity will likely amplify the effect
-   hidden burden is not an edge case, but a structural feature
-   observability becomes a core design problem

------------------------------------------------------------------------

## Intellectual property notice

This repository contains a minimal conceptual implementation intended for
research and demonstration purposes. It does not represent a production system
or complete operational framework.
