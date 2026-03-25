{{
	config(
		materialized='table',
		tags=['mart', 'best_seasons']
	)
}}

-- one row per season; ranked separately by volume, scoring, and effectiveness

with enriched as (
	select * from {{ ref('int_shots_enriched') }}
),

season_stats as (
	select
		season,
		season_start_year,
		era,
		tenure,

		-- volume
		count(*) as total_shots,
		count(distinct game_id) as games_played,
		round(count(*)::decimal / count(distinct game_id), 1) as shots_per_game,

		-- shooting splits
		count(*) filter (where shot_type = '2PT Field Goal') as shots_2pt,
		count(*) filter (where shot_type = '3PT Field Goal') as shots_3pt,
		sum(is_shot_made::int) filter (where shot_type = '2PT Field Goal') as made_2pt,
		sum(is_shot_made::int) filter (where shot_type = '3PT Field Goal') as made_3pt,
		sum(is_shot_made::int) as total_made,

		-- scoring
		sum(points_scored) as total_points,
		round(sum(points_scored)::decimal / count(distinct game_id), 1) as points_per_game,

		-- effectiveness
		round(avg(is_shot_made::int) * 100, 1) as fg_pct,
		round(avg(is_shot_made::int) filter (where shot_type = '2PT Field Goal') * 100, 1) as fg2_pct,
		round(avg(is_shot_made::int) filter (where shot_type = '3PT Field Goal') * 100, 1) as fg3_pct,
		round(sum(points_scored)::decimal / count(*), 3) as points_per_shot,

		-- shot profile
		round(count(*) filter (where shot_type = '3PT Field Goal')::decimal / count(*) * 100, 1) as three_pt_rate,
		round(avg(shot_distance), 1) as avg_shot_distance,

		-- zone efficiency
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'At Rim') * 100, 1) as fg_pct_at_rim,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Mid-range') * 100, 1) as fg_pct_midrange,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Three-point') * 100, 1) as fg_pct_threepoint,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Long Mid-range') * 100, 1) as fg_pct_long_midrange,

		-- home / away split
		round(avg(is_shot_made::int) filter (where is_home_game = 1) * 100, 1) as home_fg_pct,
		round(avg(is_shot_made::int) filter (where is_home_game = 0) * 100, 1) as away_fg_pct,

		-- clutch within season
		count(*) filter (where is_clutch_time) as clutch_shots,
		round(avg(is_shot_made::int) filter (where is_clutch_time) * 100, 1) as clutch_fg_pct

	from enriched
	where tenure != 'Unknown'
	group by season, season_start_year, era, tenure
)

select
	*,
	-- volume rank: 1 = most shots in a season
	rank() over (order by total_shots desc) as rank_by_shots,
	-- scoring rank: 1 = most field-goal points in a season
	rank() over (order by total_points desc) as rank_by_points,
	-- effectiveness rank: 1 = highest FG% (min ~500 shots = partial seasons included, rankings naturally show full seasons at top)
	rank() over (order by fg_pct desc) as rank_by_fg_pct,
	-- scoring efficiency rank: 1 = highest points per shot
	rank() over (order by points_per_shot desc) as rank_by_pps

from season_stats
order by season_start_year
