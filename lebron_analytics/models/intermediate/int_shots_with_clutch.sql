{{
	config(
		materialized='view',
		tags=['intermediate', 'clutch']
	)
}}

-- clutch = last 5 min of Q4/OT | critical = last 2 min | final = last 24 sec

with shots_with_context as (

	select
		*,
		period >= 4 and seconds_remaining_in_game <= 300 as is_clutch_time,
		period >= 4 and seconds_remaining_in_game <= 120 as is_critical_time,
		period >= 4 and seconds_remaining_in_game <= 24 as is_final_possession,
		period >= 5 as is_overtime,
		case
			when period = 1 then '1st Quarter'
			when period = 2 then '2nd Quarter'
			when period = 3 then '3rd Quarter'
			when period = 4 then '4th Quarter'
			else 'Overtime'
		end as quarter_label,
		case
			when period <= 2 then 'First Half'
			when period = 3 then 'Third Quarter'
			when period = 4 then 'Fourth Quarter'
			else 'Overtime'
		end as game_period,
		case
			when minutes_remaining >= 9 then 'Early Quarter'
			when minutes_remaining >= 6 then 'Mid Quarter'
			when minutes_remaining >= 3 then 'Late Quarter'
			else 'End Quarter'
		end as quarter_timing,
		-- 0ft = at rim; 24+ft = beyond arc
		case
			when shot_distance = 0 then 'At Rim'
			when shot_distance <= 3 then 'Close Range'
			when shot_distance <= 10 then 'Short Mid-range'
			when shot_distance <= 16 then 'Mid-range'
			when shot_distance <= 23 then 'Long Mid-range'
			else 'Three-point'
		end as shot_distance_category,
		case
			when shot_type = '3PT Field Goal' and is_shot_made then 3
			when shot_type = '2PT Field Goal' and is_shot_made then 2
			else 0
		end as points_scored

	from {{ ref('stg_lebron_shots') }}

)

select * from shots_with_context
