{{
	config(
		materialized='table',
		tags=['mart', 'opponent']
	)
}}

/*
Mart: Opponent Analysis
Question: How does LeBron perform against different opponents?

Shows:
- Total shots and FG% against each opponent
- Best and worst opponents for LeBron (where he shoots most/least efficiently)
- Volume ranking (most-faced opponents)
- Clutch performance by opponent
- Trend of performance vs. rivals over time
*/

with enriched as (

	select * from {{ ref('int_shots_enriched') }}

),

-- Core opponent stats
opponent_summary as (

	select
		opponent_abbr,

		-- Volume
		count(*) as total_shots,
		sum(is_shot_made::int) as total_made,
		count(distinct game_id) as games_played,
		count(distinct season) as seasons_faced,

		-- Overall efficiency
		round(avg(is_shot_made::int) * 100, 1) as fg_pct,
		sum(points_scored) as total_points,
		round(sum(points_scored)::decimal / count(*), 3) as points_per_shot,
		round(count(*)::decimal / count(distinct game_id), 1) as shots_per_game,

		-- 2PT breakdown
		count(*) filter (where shot_type = '2PT Field Goal') as shots_2pt,
		round(avg(is_shot_made::int) filter (where shot_type = '2PT Field Goal') * 100, 1) as fg2_pct,

		-- 3PT breakdown
		count(*) filter (where shot_type = '3PT Field Goal') as shots_3pt,
		round(avg(is_shot_made::int) filter (where shot_type = '3PT Field Goal') * 100, 1) as fg3_pct,
		round(count(*) filter (where shot_type = '3PT Field Goal')::decimal / count(*) * 100, 1) as three_pt_rate,

		-- Shot distance profile
		count(*) filter (where shot_distance_category = 'At Rim') as shots_at_rim,
		count(*) filter (where shot_distance_category = 'Mid-range') as shots_midrange,
		count(*) filter (where shot_distance_category = 'Three-point') as shots_threepoint,
		round(avg(shot_distance), 1) as avg_shot_distance,

		-- Zone efficiency
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'At Rim') * 100, 1) as fg_pct_at_rim,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Mid-range') * 100, 1) as fg_pct_midrange,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Three-point') * 100, 1) as fg_pct_threepoint,

		-- Clutch performance
		count(*) filter (where is_clutch_time) as clutch_shots,
		round(avg(is_shot_made::int) filter (where is_clutch_time) * 100, 1) as clutch_fg_pct,
		count(*) filter (where is_final_possession) as game_winning_shots,
		sum(is_shot_made::int) filter (where is_final_possession) as game_winning_made,

		-- Home vs away
		round(avg(is_shot_made::int) filter (where is_home_game = 1) * 100, 1) as home_fg_pct,
		round(avg(is_shot_made::int) filter (where is_home_game = 0) * 100, 1) as away_fg_pct

	from enriched
	group by opponent_abbr

),

-- Add ranking columns
ranked as (

	select
		*,
		row_number() over (order by total_shots desc) as rank_by_shots,
		row_number() over (order by fg_pct desc) as rank_by_fg_pct,
		row_number() over (order by total_points desc) as rank_by_points

	from opponent_summary

),

-- Season-by-season breakdown vs. most-faced opponents (top 10 by shots)
top_opponents as (

	select opponent_abbr
	from opponent_summary
	order by total_shots desc
	limit 10

),

opponent_by_season as (

	select
		e.opponent_abbr,
		e.season,
		e.season_start_year,
		e.era,
		e.tenure,
		count(*) as shots,
		round(avg(e.is_shot_made::int) * 100, 1) as fg_pct,
		sum(e.points_scored) as points,
		round(avg(e.shot_distance), 1) as avg_shot_distance,
		round(count(*) filter (where e.shot_type = '3PT Field Goal')::decimal / count(*) * 100, 1) as three_pt_rate

	from enriched e
	inner join top_opponents t
		on e.opponent_abbr = t.opponent_abbr
	group by e.opponent_abbr, e.season, e.season_start_year, e.era, e.tenure

)

-- Final output: full opponent stats with rankings
select
	r.opponent_abbr,
	r.total_shots,
	r.total_made,
	r.games_played,
	r.seasons_faced,
	r.fg_pct,
	r.total_points,
	r.points_per_shot,
	r.shots_per_game,
	r.shots_2pt,
	r.fg2_pct,
	r.shots_3pt,
	r.fg3_pct,
	r.three_pt_rate,
	r.shots_at_rim,
	r.shots_midrange,
	r.shots_threepoint,
	r.avg_shot_distance,
	r.fg_pct_at_rim,
	r.fg_pct_midrange,
	r.fg_pct_threepoint,
	r.clutch_shots,
	r.clutch_fg_pct,
	r.game_winning_shots,
	r.game_winning_made,
	r.home_fg_pct,
	r.away_fg_pct,
	r.rank_by_shots,
	r.rank_by_fg_pct,
	r.rank_by_points,

	-- Season trend columns (for top 10 opponents only)
	obs.season,
	obs.season_start_year,
	obs.era,
	obs.tenure,
	obs.shots as season_shots,
	obs.fg_pct as season_fg_pct,
	obs.points as season_points,
	obs.avg_shot_distance as season_avg_distance,
	obs.three_pt_rate as season_three_pt_rate

from ranked r
left join opponent_by_season obs
	on r.opponent_abbr = obs.opponent_abbr

order by r.rank_by_shots, obs.season_start_year
