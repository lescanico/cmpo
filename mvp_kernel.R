#!/usr/bin/env Rscript

# CMPO MVP kernel
options(stringsAsFactors = FALSE)

minutes_per_hour <- 60

params <- list(
  n_weeks = 104L,
  formal_capacity_minutes = 40L * minutes_per_hour,
  buffer_capacity_minutes = 40L * minutes_per_hour,
  initial_latent_minutes = 80L * minutes_per_hour,
  p_in = 0.25,
  p_act = 0.25,
  p_surf = 0.50,
  p_uti = 0.90,
  p_out = 0.05,
  p_gen = 1.00,
  efficiency = 1.00,
  standard_of_care = 1.00,
  activation_wave = 0.10,
  activation_persistence = 0.82,
  activation_seed = 20260413L,
  tail_weeks = 12L
)

surfacing_sweep <- seq(0.10, 0.60, by = 0.05)

clamp <- function(x, lo, hi) {
  pmax(lo, pmin(hi, x))
}

hours <- function(minutes) {
  minutes / minutes_per_hour
}

resolve_minutes <- function(workload_minutes, demand_minutes, p) {
  if (p$standard_of_care <= 0) {
    stop("standard_of_care must be > 0.", call. = FALSE)
  }
  
  multiplier <- p$efficiency / p$standard_of_care
  pmin(demand_minutes, workload_minutes * multiplier)
}

activation_path <- function(p) {
  set.seed(as.integer(p$activation_seed))
  
  shocks <- rnorm(p$n_weeks)
  state <- numeric(p$n_weeks)
  state[1] <- shocks[1]
  
  if (p$n_weeks > 1L) {
    shock_scale <- sqrt(1 - p$activation_persistence^2)
    
    for (week in 2:p$n_weeks) {
      state[week] <- p$activation_persistence * state[week - 1] +
        shock_scale * shocks[week]
    }
  }
  
  centered <- state - mean(state)
  max_abs <- max(abs(centered))
  
  if (max_abs == 0) {
    normalized <- rep(0, p$n_weeks)
  } else {
    normalized <- centered / max_abs
  }
  
  clamp(
    1 + p$activation_wave * normalized,
    1 - p$activation_wave,
    1 + p$activation_wave
  )
}

kernel_step <- function(latent_start_minutes, p, activation_multiplier, week) {
  formal_capacity <- p$formal_capacity_minutes
  buffer_capacity <- p$buffer_capacity_minutes
  
  activation_rate <- clamp(p$p_act * activation_multiplier, 0.01, 0.99)
  
  active_reentrant <- latent_start_minutes * activation_rate
  latent_surviving <- latent_start_minutes - active_reentrant
  
  reserved_intake <- formal_capacity * p$p_in
  utilized_intake <- reserved_intake * p$p_uti
  intake_no_show <- reserved_intake - utilized_intake
  
  visible_room_for_reentry <- max(0, formal_capacity - reserved_intake)
  surfaced_reentrant <- min(active_reentrant * p$p_surf, visible_room_for_reentry)
  utilized_reentrant <- surfaced_reentrant * p$p_uti
  hidden_reentrant <- active_reentrant - surfaced_reentrant
  reentrant_no_show <- surfaced_reentrant - utilized_reentrant
  
  scheduled_formal <- reserved_intake + surfaced_reentrant
  utilized_scheduled <- utilized_intake + utilized_reentrant
  booked_unused <- intake_no_show + reentrant_no_show
  unbooked_formal <- max(0, formal_capacity - scheduled_formal)
  
  hidden_via_booked_unused <- min(hidden_reentrant, booked_unused)
  hidden_remaining <- hidden_reentrant - hidden_via_booked_unused
  
  hidden_via_unbooked <- min(hidden_remaining, unbooked_formal)
  hidden_remaining <- hidden_remaining - hidden_via_unbooked
  
  hidden_via_buffer <- min(hidden_remaining, buffer_capacity)
  hidden_remaining <- hidden_remaining - hidden_via_buffer
  
  visible_workload <- utilized_scheduled
  hidden_workload <- hidden_via_booked_unused + hidden_via_unbooked + hidden_via_buffer
  total_workload <- visible_workload + hidden_workload
  
  resolved_intake <- resolve_minutes(utilized_intake, reserved_intake, p)
  resolved_visible_reentrant <- resolve_minutes(utilized_reentrant, surfaced_reentrant, p)
  visible_reentrant_return <- surfaced_reentrant - resolved_visible_reentrant
  
  hidden_demand_left <- hidden_reentrant
  
  resolved_hidden_booked <- resolve_minutes(hidden_via_booked_unused, hidden_demand_left, p)
  hidden_demand_left <- hidden_demand_left - resolved_hidden_booked
  
  resolved_hidden_unbooked <- resolve_minutes(hidden_via_unbooked, hidden_demand_left, p)
  hidden_demand_left <- hidden_demand_left - resolved_hidden_unbooked
  
  resolved_hidden_buffer <- resolve_minutes(hidden_via_buffer, hidden_demand_left, p)
  hidden_demand_left <- hidden_demand_left - resolved_hidden_buffer
  
  resolved_total <- resolved_intake +
    resolved_visible_reentrant +
    resolved_hidden_booked +
    resolved_hidden_unbooked +
    resolved_hidden_buffer
  
  generated_obligation <- resolved_total * p$p_gen
  
  latent_pre_outflow <- latent_surviving +
    generated_obligation +
    visible_reentrant_return +
    hidden_demand_left
  
  latent_outflow <- latent_pre_outflow * p$p_out
  latent_end <- latent_pre_outflow - latent_outflow
  
  data.frame(
    week = week,
    p_in = p$p_in,
    p_surf = p$p_surf,
    latent_start_minutes = latent_start_minutes,
    active_reentrant_minutes = active_reentrant,
    visible_workload_minutes = visible_workload,
    hidden_workload_minutes = hidden_workload,
    overwork_minutes = hidden_via_buffer,
    total_workload_minutes = total_workload,
    apparent_slack_minutes = max(0, formal_capacity - utilized_scheduled),
    future_atp_proxy_minutes = max(0, formal_capacity - scheduled_formal),
    overflow_to_latent_minutes = hidden_demand_left,
    generated_obligation_minutes = generated_obligation,
    latent_outflow_minutes = latent_outflow,
    latent_end_minutes = latent_end
  )
}

simulate <- function(p) {
  activation <- activation_path(p)
  latent <- p$initial_latent_minutes
  rows <- vector("list", p$n_weeks)
  
  for (week in seq_len(p$n_weeks)) {
    row <- kernel_step(latent, p, activation[week], week)
    rows[[week]] <- row
    latent <- row$latent_end_minutes
  }
  
  do.call(rbind, rows)
}

simulate_policy <- function(base_p,
                            label,
                            p_surf,
                            reset_week = NA_integer_,
                            policy_start = NA_integer_,
                            policy_end = NA_integer_,
                            p_in_step = 0,
                            p_in_max = base_p$p_in,
                            slack_trigger = Inf) {
  activation <- activation_path(base_p)
  latent <- base_p$initial_latent_minutes
  p_in <- base_p$p_in
  rows <- vector("list", base_p$n_weeks)
  
  for (week in seq_len(base_p$n_weeks)) {
    if (!is.na(reset_week) && week == reset_week) {
      p_in <- base_p$p_in
    }
    
    p <- base_p
    p$p_in <- p_in
    p$p_surf <- p_surf
    
    row <- kernel_step(latent, p, activation[week], week)
    row$scenario <- label
    rows[[week]] <- row
    latent <- row$latent_end_minutes
    
    policy_active <- !is.na(policy_start) && week >= policy_start && week <= policy_end
    if (policy_active && row$apparent_slack_minutes > slack_trigger) {
      p_in <- min(p_in + p_in_step, p_in_max)
    }
  }
  
  do.call(rbind, rows)
}

summarize_tail <- function(history, tail_weeks) {
  tail_rows <- tail(history, tail_weeks)
  
  data.frame(
    tail_visible_h = round(hours(mean(tail_rows$visible_workload_minutes)), 1),
    peak_overwork_h = round(hours(max(history$overwork_minutes)), 1),
    tail_slack_h = round(hours(mean(tail_rows$apparent_slack_minutes)), 1),
    tail_latent_h = round(hours(mean(tail_rows$latent_end_minutes)), 1),
    tail_overflow_h = round(hours(mean(tail_rows$overflow_to_latent_minutes)), 1)
  )
}

run_observability_sweep <- function(p) {
  out <- lapply(surfacing_sweep, function(p_surf) {
    scenario_p <- p
    scenario_p$p_surf <- p_surf
    
    history <- simulate(scenario_p)
    summary <- summarize_tail(history, p$tail_weeks)
    summary$p_surf <- p_surf
    summary
  })
  
  out <- do.call(rbind, out)
  out[, c("p_surf", "tail_visible_h", "peak_overwork_h", "tail_slack_h", "tail_latent_h", "tail_overflow_h")]
}

run_policy_experiment <- function(p) {
  fixed <- simulate_policy(
    base_p = p,
    label = "fixed_intake",
    p_surf = 0.25
  )
  
  adaptive <- simulate_policy(
    base_p = p,
    label = "adaptive_then_reset",
    p_surf = 0.25,
    policy_start = 5L,
    policy_end = 68L,
    p_in_step = 0.01,
    p_in_max = 0.35,
    slack_trigger = 600,
    reset_week = 69L
  )
  
  histories <- rbind(fixed, adaptive)
  
  summaries <- do.call(rbind, lapply(split(histories, histories$scenario), function(df) {
    tail_rows <- tail(df, p$tail_weeks)
    
    data.frame(
      scenario = unique(df$scenario),
      tail_p_in = round(mean(tail_rows$p_in), 2),
      tail_latent_h = round(hours(mean(tail_rows$latent_end_minutes)), 1),
      tail_slack_h = round(hours(mean(tail_rows$apparent_slack_minutes)), 1),
      peak_overwork_h = round(hours(max(df$overwork_minutes)), 1)
    )
  }))
  
  list(histories = histories, summaries = summaries)
}

print_section <- function(title) {
  cat("\n", paste(rep("=", nchar(title)), collapse = ""), "\n", sep = "")
  cat(title, "\n")
  cat(paste(rep("=", nchar(title)), collapse = ""), "\n", sep = "")
}

main <- function() {
  print_section("CMPO MVP kernel")
  
  cat("Defaults\n")
  cat("  weeks:", params$n_weeks, "\n")
  cat("  formal_capacity_h:", hours(params$formal_capacity_minutes), "\n")
  cat("  buffer_capacity_h:", hours(params$buffer_capacity_minutes), "\n")
  cat("  initial_latent_h:", hours(params$initial_latent_minutes), "\n")
  cat("  p_in:", params$p_in, "\n")
  cat("  p_act:", params$p_act, "\n")
  cat("  p_surf:", params$p_surf, "\n")
  cat("  p_uti:", params$p_uti, "\n")
  cat("  p_out:", params$p_out, "\n")
  cat("  p_gen:", params$p_gen, "\n")
  
  print_section("Observability sweep")
  obs <- run_observability_sweep(params)
  print(obs, row.names = FALSE)
  
  print_section("Policy experiment")
  pol <- run_policy_experiment(params)
  print(pol$summaries, row.names = FALSE)
  
  print_section("Final-week snapshots")
  final_rows <- pol$histories[pol$histories$week == params$n_weeks, c(
    "scenario",
    "week",
    "p_in",
    "visible_workload_minutes",
    "hidden_workload_minutes",
    "overwork_minutes",
    "apparent_slack_minutes",
    "latent_end_minutes"
  )]
  
  final_rows$visible_workload_h <- round(hours(final_rows$visible_workload_minutes), 1)
  final_rows$hidden_workload_h <- round(hours(final_rows$hidden_workload_minutes), 1)
  final_rows$overwork_h <- round(hours(final_rows$overwork_minutes), 1)
  final_rows$apparent_slack_h <- round(hours(final_rows$apparent_slack_minutes), 1)
  final_rows$latent_end_h <- round(hours(final_rows$latent_end_minutes), 1)
  
  final_rows <- final_rows[, c(
    "scenario",
    "week",
    "p_in",
    "visible_workload_h",
    "hidden_workload_h",
    "overwork_h",
    "apparent_slack_h",
    "latent_end_h"
  )]
  
  print(final_rows, row.names = FALSE)
}

main()