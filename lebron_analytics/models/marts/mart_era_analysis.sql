{{
	config(
		materialized='table',
		tags=['mart', 'era']
	)
}}

/*
Mart: Era Analysis
Question: How has LeBron's shot selection evolved from Dead-ball Era to Three-point Era?

Aggregates shot data by era and season to show:
- Volume and efficiency by shot type (2PT vs 3PT)
- Shot distance distribution changes
- FG%, 3P%, 2P% trends
- Points per shot (scoring efficiency)
*/

with enriched as (

	select * from {{ ref('int_shots_enriched') }}

),

-- Era-level summary (rolled up)
era_summary as (

	select
		era,
		is_deadball_era,
		is_threepoint_era,

		-- Volume
		count(*) as total_shots,
		count(distinct game_id) as total_games,
		count(distinct season) as total_seasons,

		-- Overall efficiency
		round(avg(is_shot_made::int) * 100, 1) as overall_fg_pct,
		round(sum(points_scored)::decimal / count(*), 3) as points_per_shot,
		sum(points_scored) as total_points,

		-- 2PT breakdown
		count(*) filter (where shot_type = '2PT Field Goal') as shots_2pt,
		count(*) filter (where shot_type = '2PT Field Goal'
						and is_shot_made) as made_2pt,
		round(
			count(*) filter (where shot_type = '2PT Field Goal')
			::decimal / count(*) * 100, 1
		) as pct_shots_that_are_2pt,
		round(
			avg(is_shot_made::int)
			filter (where shot_type = '2PT Field Goal') * 100, 1
		) as fg2_pct,

		-- 3PT breakdown
		count(*) filter (where shot_type = '3PT Field Goal') as shots_3pt,
		count(*) filter (where shot_type = '3PT Field Goal'
						and is_shot_made) as made_3pt,
		round(
			count(*) filter (where shot_type = '3PT Field Goal')
			::decimal / count(*) * 100, 1
		) as pct_shots_that_are_3pt,
		round(
			avg(is_shot_made::int)
			filter (where shot_type = '3PT Field Goal') * 100, 1
		) as fg3_pct,

		-- Shot distance distribution
		count(*) filter (where shot_distance_category = 'At Rim') as shots_at_rim,
		count(*) filter (where shot_distance_category = 'Close Range') as shots_close_range,
		count(*) filter (where shot_distance_category = 'Short Mid-range') as shots_short_midrange,
		count(*) filter (where shot_distance_category = 'Mid-range') as shots_midrange,
		count(*) filter (where shot_distance_category = 'Long Mid-range') as shots_long_midrange,
		count(*) filter (where shot_distance_category = 'Three-point') as shots_threepoint,

		-- Efficiency by zone
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'At Rim') * 100, 1) as fg_pct_at_rim,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Mid-range') * 100, 1) as fg_pct_midrange,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Three-point') * 100, 1) as fg_pct_threepoint,

		-- Average shot distance
		round(avg(shot_distance), 1) as avg_shot_distance

	from enriched
	group by era, is_deadball_era, is_threepoint_era

),

-- Season-level breakdown within each era (for trend analysis)
season_within_era as (

	select
		era,
		season,
		season_start_year,

		count(*) as shots,
		round(avg(is_shot_made::int) * 100, 1) as fg_pct,
		round(avg(is_shot_made::int) filter (where shot_type = '3PT Field Goal') * 100, 1) as fg3_pct,
		round(
			count(*) filter (where shot_type = '3PT Field Goal')
			::decimal / count(*) * 100, 1
		) as three_pt_rate,
		round(avg(shot_distance), 1) as avg_shot_distance,
		round(sum(points_scored)::decimal / count(*), 3) as points_per_shot

	from enriched
	group by era, season, season_start_year

)

-- Final output: era summary joined with season detail
select
	es.era,
	es.is_deadball_era,
	es.is_threepoint_era,
	es.total_shots,
	es.total_games,
	es.total_seasons,
	es.overall_fg_pct,
	es.points_per_shot,
	es.total_points,
	es.shots_2pt,
	es.made_2pt,
	es.pct_shots_that_are_2pt,
	es.fg2_pct,
	es.shots_3pt,
	es.made_3pt,
	es.pct_shots_that_are_3pt,
	es.fg3_pct,
	es.shots_at_rim,
	es.shots_close_range,
	es.shots_short_midrange,
	es.shots_midrange,
	es.shots_long_midrange,
	es.shots_threepoint,
	es.fg_pct_at_rim,
	es.fg_pct_midrange,
	es.fg_pct_threepoint,
	es.avg_shot_distance,
	sw.season,
	sw.season_start_year,
	sw.shots as season_shots,
	sw.fg_pct as season_fg_pct,
	sw.fg3_pct as season_fg3_pct,
	sw.three_pt_rate as season_three_pt_rate,
	sw.avg_shot_distance as season_avg_shot_distance,
	sw.points_per_shot as season_points_per_shot

from era_summary es
inner join season_within_era sw
	on es.era = sw.era

order by sw.season_start_year
