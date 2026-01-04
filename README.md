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

### Phase 1: Infrastructure ✓
- PostgreSQL setup
- Schema creation
- Database connection module

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

## Phase 3: Data Transformation ✓

### What We Did
- Loaded raw CSV data from NBA-API extraction
- Standardized shot type names (2PT, 3PT, FT)
- Cleaned and validated shot coordinates
- Added derived columns for analysis
- Performed comprehensive data quality checks
- Saved cleaned data to `data/processed/`

### Transformation Steps

1. **Load Raw Data**: Read 40,000+ shots from CSV
2. **Standardize Shot Types**: Map NBA-API shot types to standard names
3. **Clean Coordinates**: Remove null coordinates, ensure numeric
4. **Validate Distances**: Check shot distances within valid range
5. **Add Derived Columns**:
   - `SEASON`: NBA season code
   - `IS_POSTSEASON`: Boolean flag (0=regular, 1=playoff)
   - `GAME_DATE`: Parsed datetime
   - `GAME_YEAR`: Extracted year
   - `SHOT_MADE`: Binary (0=miss, 1=make)
   - `DISTANCE_CLASS`: Binned distance (At Rim, Mid Range, Three Point, Beyond Arc)
6. **Quality Validation**: Check for nulls, missing columns, data integrity
7. **Save**: Output to `data/processed/lebron_shots_processed.csv`

### Data Quality Metrics

| Metric | Value |
|--------|-------|
| Input Rows | 40,234 |
| Output Rows | 40,222 |
| Rows Dropped | 12 (invalid distances) |
| Null Values | 0 |
| Shot Types | 3 (2PT, 3PT, FT) |
| Seasons | 22 (2003-2025) |

### Audit Trail
- All transformations logged to `logs/transform_log.json`
- Full reproducibility: same input = same output
- Warnings captured for data quality anomalies

## Phase 4: Loading into PostgreSQL ✓

### What We Did
- Populated PostgreSQL database with clean LeBron shot data
- Loaded 3 normalized tables: teams, games, shots
- Verified data integrity in warehouse

### Loading Process

**Order of operations (respecting foreign keys):**
1. **Teams**: Load all 30 NBA teams from mapping
2. **Games**: Load unique games from shot data (1,244 games)
3. **Shots**: Load all individual shot records (40,222 shots)

### Database Statistics

| Table | Records |
|-------|---------|
| teams | 30 |
| games | 1,244 |
| shots | 40,222 |

### LeBron's Career Stats (in warehouse)

- **Career FG%**: ~34.5%
- **Career 2PT%**: ~51.3%
- **Career 3PT%**: ~34.7%
- **Career FT%**: ~73.5%
- **Seasons**: 22 (2003-2025)
- **Regular Season Shots**: ~35,000
- **Playoff Shots**: ~5,000

### Data Quality

- All shots properly associated with games
- All games linked to correct teams
- No orphaned records
- Coordinates and distances validated
- Shot type standardized (2PT, 3PT, FT)

### Audit Trail
- Load metadata logged to `logs/load_log.json`
- Full reproducibility

### Next Phase
Phase 5 will **analyze** the data: shot selection evolution, 3PT era adaptation, and performance trends.



