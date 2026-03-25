{{
	config(
		materialized='view',
		tags=['intermediate', 'tenure']
	)
}}

-- Cavs I: 2003-10 | Heat: 2010-14 | Cavs II: 2014-18 | Lakers: 2018+

with shots_with_tenure as (

	select
		*,
		case
			when season between '2003-04' and '2009-10' and lebron_team_abbr = 'CLE' then 'Cavs I'
			when season between '2010-11' and '2013-14' and lebron_team_abbr = 'MIA' then 'Heat'
			when season between '2014-15' and '2017-18' and lebron_team_abbr = 'CLE' then 'Cavs II'
			when season >= '2018-19'                    and lebron_team_abbr = 'LAL' then 'Lakers'
			else 'Unknown'
		end as tenure,
		case
			when season between '2003-04' and '2009-10' and lebron_team_abbr = 'CLE' then 1
			when season between '2010-11' and '2013-14' and lebron_team_abbr = 'MIA' then 2
			when season between '2014-15' and '2017-18' and lebron_team_abbr = 'CLE' then 3
			when season >= '2018-19'                    and lebron_team_abbr = 'LAL' then 4
			else 0
		end as tenure_order,
		cast(split_part(season, '-', 1) as integer) - 2003 as years_experience,
		case
			when cast(split_part(season, '-', 1) as integer) - 2003 <= 3 then 'Early Career'
			when cast(split_part(season, '-', 1) as integer) - 2003 <= 10 then 'Prime I'
			when cast(split_part(season, '-', 1) as integer) - 2003 <= 17 then 'Prime II'
			else 'Late Career'
		end as career_stage

	from {{ ref('stg_lebron_shots') }}

)

select * from shots_with_tenure
