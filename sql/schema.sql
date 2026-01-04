-- =====================================================
-- SCHEMA: LeBron James Shot Analysis Data Warehouse
-- Database: PostgreSQL
-- Purpose: Store detailed shot-by-shot data for analysis
-- =====================================================

-- ======================
-- Drop tables if needed
-- ======================
DROP TABLE IF EXISTS shots CASCADE;
DROP TABLE IF EXISTS games CASCADE;
DROP TABLE IF EXISTS teams CASCADE;

-- ======================
-- Teams Dimension Table
-- ======================
CREATE TABLE teams (
    team_id SERIAL PRIMARY KEY,
    nba_team_id INT UNIQUE NOT NULL,
    team_abbreviation VARCHAR(3) UNIQUE NOT NULL,
    team_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================
-- Games Fact Table
-- ======================
CREATE TABLE games (
    game_id BIGINT PRIMARY KEY,
    game_date DATE NOT NULL,
    season INT NOT NULL,
    is_postseason BOOLEAN DEFAULT FALSE,
    postseason_round VARCHAR(20),
    lebron_team_id INT NOT NULL,
    opponent_team_id INT NOT NULL,
    is_home BOOLEAN NOT NULL,
    lebron_points INT,
    lebron_rebounds INT,
    lebron_assists INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_games_lebron_team
        FOREIGN KEY (lebron_team_id) REFERENCES teams(team_id),
    CONSTRAINT fk_games_opponent_team
        FOREIGN KEY (opponent_team_id) REFERENCES teams(team_id)
);

-- ======================
-- Shots Fact Table
-- ======================
CREATE TABLE shots (
    shot_id SERIAL PRIMARY KEY,
    game_id BIGINT NOT NULL,
    shot_number INT NOT NULL,
    shot_type VARCHAR(50) NOT NULL,      -- '2PT Field Goal', '3PT Field Goal', 'Free Throw'
    shot_made BOOLEAN NOT NULL,
    shot_x FLOAT,
    shot_y FLOAT,
    shot_distance FLOAT,                 -- Distance in feet
    quarter INT NOT NULL,
    time_remaining_quarter VARCHAR(10),  -- MM:SS
    seconds_remaining_game INT,
    season INT NOT NULL,
    is_postseason BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_shots_game
        FOREIGN KEY (game_id) REFERENCES games(game_id)
);

-- ======================
-- Indexes for Performance
-- ======================

-- Shots table indexes
CREATE INDEX idx_shots_game_id
    ON shots(game_id);

CREATE INDEX idx_shots_season
    ON shots(season);

CREATE INDEX idx_shots_shot_made
    ON shots(shot_made);

CREATE INDEX idx_shots_season_shot_type
    ON shots(season, shot_type);

CREATE INDEX idx_shots_postseason
    ON shots(is_postseason, season);

-- Games table indexes
CREATE INDEX idx_games_season_date
    ON games(season, game_date);


ALTER TABLE shots
ADD COLUMN shot_zone_basic VARCHAR(50),
ADD COLUMN shot_zone_area VARCHAR(50),
ADD COLUMN action_type VARCHAR(100),
ADD COLUMN distance_class VARCHAR(20),
ADD COLUMN minutes_remaining INT,
ADD COLUMN seconds_remaining INT;

ALTER TABLE games
ALTER COLUMN season TYPE VARCHAR(7);

ALTER TABLE shots
ALTER COLUMN season TYPE VARCHAR(7);

