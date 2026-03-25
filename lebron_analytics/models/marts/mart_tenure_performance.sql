{{
	config(
		materialized='table',
		tags=['mart', 'tenure']
	)
}}

/*
Mart: Tenure Performance
Question: How did LeBron's performance differ across his four team tenures?

Tenures:
- Cavs I   (2003-04 to 2009-10): Rookie through first championship run
- Heat      (2010-11 to 2013-14): The Decision, back-to-back championships
- Cavs II   (2014-15 to 2017-18): Return of the King, 2016 title
- Lakers    (2018-19 onwards):    West Coast chapter

Aggregates by tenure showing:
- Total volume (shots, games, seasons)
- Overall FG% and scoring efficiency
- 2PT vs 3PT split
- Shot distance profile
- Home vs away splits
- Career progression within each stage
*/

with enriched as (

	select * from {{ ref('int_shots_enriched') }}

),

-- Tenure-level summary
tenure_summary as (

	select
		tenure,
		tenure_order,
		career_stage,

		min(season) as first_season,
		max(season) as last_season,
		count(distinct season) as seasons_played,
		count(distinct game_id) as total_games,
		count(*) as total_shots,

		-- Overall efficiency
		sum(is_shot_made::int) as total_made,
		round(avg(is_shot_made::int) * 100, 1) as overall_fg_pct,
		sum(points_scored) as total_points,
		round(sum(points_scored)::decimal / count(*), 3) as points_per_shot,

		-- Shots per game
		round(count(*)::decimal / count(distinct game_id), 1) as shots_per_game,
		round(sum(points_scored)::decimal / count(distinct game_id), 1) as points_per_game,

		-- 2PT breakdown
		count(*) filter (where shot_type = '2PT Field Goal') as shots_2pt,
		sum(is_shot_made::int) filter (where shot_type = '2PT Field Goal') as made_2pt,
		round(avg(is_shot_made::int) filter (where shot_type = '2PT Field Goal') * 100, 1) as fg2_pct,

		-- 3PT breakdown
		count(*) filter (where shot_type = '3PT Field Goal') as shots_3pt,
		sum(is_shot_made::int) filter (where shot_type = '3PT Field Goal') as made_3pt,
		round(avg(is_shot_made::int) filter (where shot_type = '3PT Field Goal') * 100, 1) as fg3_pct,
		round(count(*) filter (where shot_type = '3PT Field Goal')::decimal / count(*) * 100, 1) as three_pt_rate,

		-- Shot distance profile
		count(*) filter (where shot_distance_category = 'At Rim') as shots_at_rim,
		count(*) filter (where shot_distance_category = 'Close Range') as shots_close_range,
		count(*) filter (where shot_distance_category = 'Short Mid-range') as shots_short_midrange,
		count(*) filter (where shot_distance_category = 'Mid-range') as shots_midrange,
		count(*) filter (where shot_distance_category = 'Long Mid-range') as shots_long_midrange,
		count(*) filter (where shot_distance_category = 'Three-point') as shots_threepoint,

		round(count(*) filter (where shot_distance_category = 'At Rim')::decimal / count(*) * 100, 1) as rim_rate,
		round(count(*) filter (where shot_distance_category = 'Mid-range')::decimal / count(*) * 100, 1) as midrange_rate,
		round(count(*) filter (where shot_distance_category = 'Three-point')::decimal / count(*) * 100, 1) as three_pt_zone_rate,

		-- Efficiency by zone
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'At Rim') * 100, 1) as fg_pct_at_rim,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Mid-range') * 100, 1) as fg_pct_midrange,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Three-point') * 100, 1) as fg_pct_threepoint,

		-- Home vs away
		count(*) filter (where is_home_game = 1) as home_shots,
		round(avg(is_shot_made::int) filter (where is_home_game = 1) * 100, 1) as home_fg_pct,
		count(*) filter (where is_home_game = 0) as away_shots,
		round(avg(is_shot_made::int) filter (where is_home_game = 0) * 100, 1) as away_fg_pct,

		-- Average shot distance
		round(avg(shot_distance), 1) as avg_shot_distance

	from enriched
	where tenure != 'Unknown'
	group by tenure, tenure_order, career_stage

),

-- Season-level breakdown within each tenure
season_within_tenure as (

	select
		tenure,
		tenure_order,
		season,
		season_start_year,
		years_experience,

		count(*) as shots,
		round(avg(is_shot_made::int) * 100, 1) as fg_pct,
		round(avg(is_shot_made::int) filter (where shot_type = '3PT Field Goal') * 100, 1) as fg3_pct,
		round(count(*) filter (where shot_type = '3PT Field Goal')::decimal / count(*) * 100, 1) as three_pt_rate,
		round(avg(shot_distance), 1) as avg_shot_distance,
		round(sum(points_scored)::decimal / count(*), 3) as points_per_shot

	from enriched
	where tenure != 'Unknown'
	group by tenure, tenure_order, season, season_start_year, years_experience

)

select
	ts.tenure,
	ts.tenure_order,
	ts.career_stage,
	ts.first_season,
	ts.last_season,
	ts.seasons_played,
	ts.total_games,
	ts.total_shots,
	ts.total_made,
	ts.overall_fg_pct,
	ts.total_points,
	ts.points_per_shot,
	ts.shots_per_game,
	ts.points_per_game,
	ts.shots_2pt,
	ts.made_2pt,
	ts.fg2_pct,
	ts.shots_3pt,
	ts.made_3pt,
	ts.fg3_pct,
	ts.three_pt_rate,
	ts.shots_at_rim,
	ts.shots_close_range,
	ts.shots_short_midrange,
	ts.shots_midrange,
	ts.shots_long_midrange,
	ts.shots_threepoint,
	ts.rim_rate,
	ts.midrange_rate,
	ts.three_pt_zone_rate,
	ts.fg_pct_at_rim,
	ts.fg_pct_midrange,
	ts.fg_pct_threepoint,
	ts.home_shots,
	ts.home_fg_pct,
	ts.away_shots,
	ts.away_fg_pct,
	ts.avg_shot_distance,
	sw.season,
	sw.season_start_year,
	sw.years_experience,
	sw.shots as season_shots,
	sw.fg_pct as season_fg_pct,
	sw.fg3_pct as season_fg3_pct,
	sw.three_pt_rate as season_three_pt_rate,
	sw.avg_shot_distance as season_avg_shot_distance,
	sw.points_per_shot as season_points_per_shot

from tenure_summary ts
inner join season_within_tenure sw
	on ts.tenure = sw.tenure

order by ts.tenure_order, sw.season_start_year
