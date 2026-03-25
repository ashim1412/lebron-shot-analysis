{{config(
	materialized = 'view',
	tags=['staging','shots']
)}}

-- lowercase columns, parse YYYYMMDD date, derive opponent, calc seconds remaining

with source_data as (
	select * from {{ source('raw', 'lebron_shots') }}
),

team_mapping as (
	select * from main_seeds.team_abbreviations
),

renamed_and_transformed as (
	select
		season,
		strptime("GAME_DATE", '%Y%m%d')::date as game_date,
		"GAME_ID" as game_id,
		"TEAM_ID" as team_id,
		"TEAM_NAME" as lebron_team_name,
		"HTM" as home_team_abbr,
		"VTM" as visitor_team_abbr,
		"SHOT_MADE_FLAG"::boolean as is_shot_made,
		"ACTION_TYPE" as action_type,
		"SHOT_TYPE" as shot_type,
		"SHOT_ZONE_BASIC" as shot_zone_basic,
		"SHOT_ZONE_AREA" as shot_zone_area,
		"SHOT_ZONE_RANGE" as shot_zone_range,
		"SHOT_DISTANCE" as shot_distance,
		"LOC_X" as loc_x,
		"LOC_Y" as loc_y,
		"PERIOD" as period,
		"MINUTES_REMAINING" as minutes_remaining,
		"SECONDS_REMAINING" as seconds_remaining,
		source_file
	from source_data
),

with_opponent as (
	select
		rt.*,
		tm.team_abbr as lebron_team_abbr,
		-- home team = LeBron's team → opponent is visitor, and vice versa
		case
			when tm.team_abbr = rt.home_team_abbr then rt.visitor_team_abbr
			when tm.team_abbr = rt.visitor_team_abbr then rt.home_team_abbr
			else null
		end as opponent_abbr,
		case
			when tm.team_abbr = rt.home_team_abbr then 1
			else 0
		end as is_home_game
	from renamed_and_transformed rt
	left join team_mapping tm on rt.lebron_team_name = tm.team_name
),

final as (
	select
		season,
		game_id,
		game_date,
		lebron_team_name,
		lebron_team_abbr,
		opponent_abbr,
		is_home_game,
		is_shot_made,
		action_type,
		shot_type,
		shot_zone_basic,
		shot_zone_area,
		shot_zone_range,
		shot_distance,
		loc_x,
		loc_y,
		period,
		minutes_remaining,
		seconds_remaining,
		-- regulation: Q4 ends at 0; OT periods are 5 min, count negative from Q4 end
		case
			when period <= 4 then
				((4 - period) * 12 * 60) + (minutes_remaining * 60) + seconds_remaining
			else
				((period - 5) * -5 * 60) + (minutes_remaining * 60) + seconds_remaining
		end as seconds_remaining_in_game,
		source_file
	from with_opponent
)

select * from final
