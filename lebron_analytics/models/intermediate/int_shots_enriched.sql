{{
	config(
		materialized='table',
		tags=['intermediate', 'enriched']
	)
}}

-- join era + tenure + clutch flags onto base shots; multi-col join avoids row fan-out

with base_shots as (
	select * from {{ ref('stg_lebron_shots') }}
),
with_era as (
	select * from {{ ref('int_shots_with_era') }}
),
with_tenure as (
	select * from {{ ref('int_shots_with_tenure') }}
),
with_clutch as (
	select * from {{ ref('int_shots_with_clutch') }}
),

combined as (
	select
		base.*,
		era.era,
		era.season_start_year,
		era.is_deadball_era,
		era.is_threepoint_era,
		tenure.tenure,
		tenure.tenure_order,
		tenure.years_experience,
		tenure.career_stage,
		clutch.is_clutch_time,
		clutch.is_critical_time,
		clutch.is_final_possession,
		clutch.quarter_label,
		clutch.is_overtime,
		clutch.game_period,
		clutch.quarter_timing,
		clutch.shot_distance_category,
		clutch.points_scored
	from base_shots as base
	inner join with_era as era
		on  base.game_id           = era.game_id
		and base.season            = era.season
		and base.shot_distance     = era.shot_distance
		and base.period            = era.period
		and base.minutes_remaining = era.minutes_remaining
		and base.seconds_remaining = era.seconds_remaining
	inner join with_tenure as tenure
		on  base.game_id           = tenure.game_id
		and base.season            = tenure.season
		and base.shot_distance     = tenure.shot_distance
		and base.period            = tenure.period
		and base.minutes_remaining = tenure.minutes_remaining
		and base.seconds_remaining = tenure.seconds_remaining
	inner join with_clutch as clutch
		on  base.game_id           = clutch.game_id
		and base.season            = clutch.season
		and base.shot_distance     = clutch.shot_distance
		and base.period            = clutch.period
		and base.minutes_remaining = clutch.minutes_remaining
		and base.seconds_remaining = clutch.seconds_remaining
)

select * from combined