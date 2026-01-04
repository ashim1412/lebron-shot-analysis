-- =====================================================
-- Verification Queries for PostgreSQL Load
-- =====================================================

-- 1. Check table record counts
SELECT 
    'teams' as table_name,
    COUNT(*) as row_count
FROM teams
UNION ALL
SELECT 'games', COUNT(*) FROM games
UNION ALL
SELECT 'shots', COUNT(*) FROM shots;

-- 2. LeBron's career FG% by season
SELECT 
    season,
    COUNT(*) as total_shots,
    count(case when shot_made = true then shot_id end) as makes
FROM shots
GROUP BY season
ORDER BY season;

-- 3. 2PT vs 3PT evolution
SELECT 
    season,
    shot_type,
    COUNT(*) as attempts,
    count(case when shot_made = true then shot_id end) as makes
    ROUND(100.0 * count(case when shot_made = true then shot_id end)) / COUNT(*), 1) as pct
FROM shots
GROUP BY season, shot_type
ORDER BY season, shot_type;

-- 4. Regular season vs Postseason
SELECT 
    CASE WHEN is_postseason = 0 THEN 'Regular' ELSE 'Playoffs' END as season_type,
    COUNT(*) as total_shots,
    count(case when shot_made = true then shot_id end) as makes
    ROUND(100.0 * count(case when shot_made = true then shot_id end) / COUNT(*), 1) as fg_pct
FROM shots
GROUP BY is_postseason;

-- 5. Games per season
SELECT 
    season,
    COUNT(DISTINCT game_id) as games_played,
    COUNT(*) / COUNT(DISTINCT game_id) as avg_shots_per_game
FROM shots
GROUP BY season
ORDER BY season;
