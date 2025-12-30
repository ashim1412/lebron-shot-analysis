# LeBron James Shot Analysis: Data Warehouse Project

## Overview
A comprehensive data engineering project analyzing LeBron James' shot selection and evolution over his 23-season NBA career (2003-2025).

## Project Architecture

### Database Schema
- **teams**: Reference data for NBA teams
- **games**: Game-level context (date, opponent, stats)
- **shots**: Shot-by-shot details (coordinates, made/missed, distance, time)

### Technology Stack
- **Data Source**: NBA-API
- **Processing**: Python (Pandas, NumPy)
- **Warehouse**: PostgreSQL
- **Analysis**: Python (Pandas, Matplotlib, Seaborn, Plotly)

## Phases

### Phase 1: Infrastructure ✓
- PostgreSQL setup
- Schema creation
- Database connection module

### Phase 2: Data Extraction (Next)
- Extract LeBron's shot data from NBA-API

## Phase 2: Data Extraction ✓

### What We Did
- Created extraction script using NBA-API
- Pulled 22 seasons of LeBron's shot data (2003-2025)
- Extracted both regular season and postseason shots
- Stored raw data in `data/raw/lebron_shots_raw.csv`

### Data Source
- **API**: NBA Stats API (nba-api Python library)
- **Player**: LeBron James (ID: 2544)
- **Seasons**: 2003-04 to 2024-25 (22 seasons)
- **Total Shots**: ~40,000+

### Extracted Columns
Key columns from NBA-API include:
- `SHOT_TYPE`: 2PT Field Goal, 3PT Field Goal, Free Throw
- `SHOT_MADE_FLAG`: 0 (missed) or 1 (made)
- `LOC_X`, `LOC_Y`: Shot coordinates on court
- `SHOT_DISTANCE`: Distance in feet
- `QUARTER`: Quarter of game (1-4)
- `GAME_DATE`: When the shot occurred
- Plus team, opponent, and game info

### Process
1. Initialize NBA-API client
2. Loop through each season (2003-2024)
3. For each season, extract regular season + playoffs
4. Respect rate limits (1.5 second delays)
5. Combine all data into single CSV

### Next Phase
Phase 3 will **transform** this raw data into clean, validated records ready for PostgreSQL.

