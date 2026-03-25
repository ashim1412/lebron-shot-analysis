{{
	config(
		materialized='table',
		tags=['mart', 'clutch']
	)
}}

/*
Mart: The Clutch Gene
Question: How does LeBron perform under pressure vs. normal situations?

Clutch definitions:
- Clutch time:        Last 5 minutes of 4th quarter or overtime (period >= 4, <= 300s remaining)
- Critical time:      Last 2 minutes (period >= 4, <= 120s remaining)
- Final possession:   Last 24 seconds (one possession) — game-winning scenarios

Compares shot volume, efficiency, selection, and scoring in clutch vs non-clutch,
broken down by tenure and era for historical context.
*/

with enriched as (

	select * from {{ ref('int_shots_enriched') }}

),

-- Overall clutch vs non-clutch comparison
clutch_vs_regular as (

	select
		case when is_clutch_time then 'Clutch' else 'Regular' end as situation,
		is_clutch_time,

		count(*) as total_shots,
		sum(is_shot_made::int) as total_made,
		round(avg(is_shot_made::int) * 100, 1) as fg_pct,
		sum(points_scored) as total_points,
		round(sum(points_scored)::decimal / count(*), 3) as points_per_shot,

		-- Shot type split
		count(*) filter (where shot_type = '2PT Field Goal') as shots_2pt,
		count(*) filter (where shot_type = '3PT Field Goal') as shots_3pt,
		round(count(*) filter (where shot_type = '3PT Field Goal')::decimal / count(*) * 100, 1) as three_pt_rate,
		round(avg(is_shot_made::int) filter (where shot_type = '2PT Field Goal') * 100, 1) as fg2_pct,
		round(avg(is_shot_made::int) filter (where shot_type = '3PT Field Goal') * 100, 1) as fg3_pct,

		-- Distance profile
		count(*) filter (where shot_distance_category = 'At Rim') as shots_at_rim,
		count(*) filter (where shot_distance_category = 'Mid-range') as shots_midrange,
		count(*) filter (where shot_distance_category = 'Three-point') as shots_threepoint,
		round(avg(shot_distance), 1) as avg_shot_distance,

		-- Zone FG%
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'At Rim') * 100, 1) as fg_pct_at_rim,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Mid-range') * 100, 1) as fg_pct_midrange,
		round(avg(is_shot_made::int) filter (where shot_distance_category = 'Three-point') * 100, 1) as fg_pct_threepoint,

		-- Critical / final possession
		count(*) filter (where is_critical_time) as critical_time_shots,
		round(avg(is_shot_made::int) filter (where is_critical_time) * 100, 1) as critical_fg_pct,
		count(*) filter (where is_final_possession) as final_possession_shots,
		round(avg(is_shot_made::int) filter (where is_final_possession) * 100, 1) as final_possession_fg_pct

	from enriched
	group by is_clutch_time

),

-- Clutch performance broken down by tenure
clutch_by_tenure as (

	select
		tenure,
		tenure_order,
		case when is_clutch_time then 'Clutch' else 'Regular' end as situation,
		is_clutch_time,

		count(*) as shots,
		round(avg(is_shot_made::int) * 100, 1) as fg_pct,
		sum(points_scored) as points,
		round(sum(points_scored)::decimal / count(*), 3) as points_per_shot,
		round(count(*) filter (where shot_type = '3PT Field Goal')::decimal / count(*) * 100, 1) as three_pt_rate,
		count(*) filter (where is_final_possession) as game_winning_attempts,
		sum(is_shot_made::int) filter (where is_final_possession) as game_winning_made

	from enriched
	where tenure != 'Unknown'
	group by tenure, tenure_order, is_clutch_time

),

-- Clutch performance by period (4th quarter sub-segments)
clutch_by_time_segment as (

	select
		case
			when is_final_possession then 'Final Possession (<24s)'
			when is_critical_time then 'Critical (<2 min)'
			when is_clutch_time then 'Clutch (<5 min)'
			else 'Regular'
		end as time_segment,
		case
			when is_final_possession then 1
			when is_critical_time then 2
			when is_clutch_time then 3
			else 4
		end as segment_order,

		count(*) as shots,
		round(avg(is_shot_made::int) * 100, 1) as fg_pct,
		sum(points_scored) as points,
		round(sum(points_scored)::decimal / count(*), 3) as points_per_shot,
		round(count(*) filter (where shot_type = '3PT Field Goal')::decimal / count(*) * 100, 1) as three_pt_rate

	from enriched
	group by
		is_final_possession,
		is_critical_time,
		is_clutch_time

),

-- Overtime performance
overtime_stats as (

	select
		case when is_overtime then 'Overtime' else 'Regulation' end as game_segment,
		count(*) as shots,
		round(avg(is_shot_made::int) * 100, 1) as fg_pct,
		sum(points_scored) as points

	from enriched
	group by is_overtime

)

-- Final combined output
select
	cvr.situation,
	cvr.is_clutch_time,
	cvr.total_shots,
	cvr.total_made,
	cvr.fg_pct,
	cvr.total_points,
	cvr.points_per_shot,
	cvr.shots_2pt,
	cvr.shots_3pt,
	cvr.three_pt_rate,
	cvr.fg2_pct,
	cvr.fg3_pct,
	cvr.shots_at_rim,
	cvr.shots_midrange,
	cvr.shots_threepoint,
	cvr.avg_shot_distance,
	cvr.fg_pct_at_rim,
	cvr.fg_pct_midrange,
	cvr.fg_pct_threepoint,
	cvr.critical_time_shots,
	cvr.critical_fg_pct,
	cvr.final_possession_shots,
	cvr.final_possession_fg_pct,

	-- Tenure breakdown (pivoted as separate cols for easy reporting)
	max(cbt.shots) filter (where cbt.tenure = 'Cavs I'  and cbt.is_clutch_time = cvr.is_clutch_time) as cavs1_shots,
	max(cbt.fg_pct) filter (where cbt.tenure = 'Cavs I' and cbt.is_clutch_time = cvr.is_clutch_time) as cavs1_fg_pct,
	max(cbt.shots) filter (where cbt.tenure = 'Heat'    and cbt.is_clutch_time = cvr.is_clutch_time) as heat_shots,
	max(cbt.fg_pct) filter (where cbt.tenure = 'Heat'   and cbt.is_clutch_time = cvr.is_clutch_time) as heat_fg_pct,
	max(cbt.shots) filter (where cbt.tenure = 'Cavs II' and cbt.is_clutch_time = cvr.is_clutch_time) as cavs2_shots,
	max(cbt.fg_pct) filter (where cbt.tenure = 'Cavs II'and cbt.is_clutch_time = cvr.is_clutch_time) as cavs2_fg_pct,
	max(cbt.shots) filter (where cbt.tenure = 'Lakers'  and cbt.is_clutch_time = cvr.is_clutch_time) as lakers_shots,
	max(cbt.fg_pct) filter (where cbt.tenure = 'Lakers' and cbt.is_clutch_time = cvr.is_clutch_time) as lakers_fg_pct,
	max(cbt.game_winning_attempts) filter (where cbt.tenure = 'Cavs I'  and cbt.is_clutch_time = cvr.is_clutch_time) as cavs1_gw_attempts,
	max(cbt.game_winning_attempts) filter (where cbt.tenure = 'Heat'    and cbt.is_clutch_time = cvr.is_clutch_time) as heat_gw_attempts,
	max(cbt.game_winning_attempts) filter (where cbt.tenure = 'Cavs II' and cbt.is_clutch_time = cvr.is_clutch_time) as cavs2_gw_attempts,
	max(cbt.game_winning_attempts) filter (where cbt.tenure = 'Lakers'  and cbt.is_clutch_time = cvr.is_clutch_time) as lakers_gw_attempts

from clutch_vs_regular cvr
cross join clutch_by_tenure cbt
group by
	cvr.situation,
	cvr.is_clutch_time,
	cvr.total_shots,
	cvr.total_made,
	cvr.fg_pct,
	cvr.total_points,
	cvr.points_per_shot,
	cvr.shots_2pt,
	cvr.shots_3pt,
	cvr.three_pt_rate,
	cvr.fg2_pct,
	cvr.fg3_pct,
	cvr.shots_at_rim,
	cvr.shots_midrange,
	cvr.shots_threepoint,
	cvr.avg_shot_distance,
	cvr.fg_pct_at_rim,
	cvr.fg_pct_midrange,
	cvr.fg_pct_threepoint,
	cvr.critical_time_shots,
	cvr.critical_fg_pct,
	cvr.final_possession_shots,
	cvr.final_possession_fg_pct

order by cvr.is_clutch_time desc
