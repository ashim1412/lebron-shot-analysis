{{
	config(
		materialized='view',
		tags=['intermediate', 'era']
	)
}}

-- Dead-ball Era: 2003-04 to 2013-14 | Three-point Era: 2014-15 onward

with shots_with_era as (

	select
		*,
		case
			when season <= '2013-14' then 'Dead-ball Era'
			when season >= '2014-15' then 'Three-point Era'
			else 'Unknown'
		end as era,
		cast(split_part(season, '-', 1) as integer) as season_start_year,
		season <= '2013-14' as is_deadball_era,
		season >= '2014-15' as is_threepoint_era

	from {{ ref('stg_lebron_shots') }}

)

select * from shots_with_era
