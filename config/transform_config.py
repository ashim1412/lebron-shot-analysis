"""
Transformation configuration
Purpose: Define how to clean and transform the raw data
"""

# Shot type mapping (standardize NBA-API values)
SHOT_TYPE_MAPPING = {
    '2PT Field Goal': '2PT',
    '3PT Field Goal': '3PT',
    'Free Throw': 'FT'
}

# Quarter values (convert to integers)
VALID_QUARTERS = [1, 2, 3, 4, 5]  # 5 = overtime

# Season types
SEASON_TYPES = {
    'Regular Season': False,  # is_postseason
    'Playoffs': True
}

# Postseason round mapping
POSTSEASON_ROUNDS = {
    'Play-In Tournament': 'Play-In',
    'First Round': 'R1',
    'Conference Semifinals': 'R2',
    'Conference Finals': 'R3',
    'Finals': 'R4'
}

# Data quality thresholds
DATA_QUALITY = {
    'min_shot_distance': 0,
    'max_shot_distance': 80,  # Court is ~50ft, but shots recorded beyond
    'valid_shot_made_values': [0, 1, 0.0, 1.0],
    'required_columns': [
        'GAME_ID',
        'GAME_DATE',
        'PLAYER_ID',
        'SHOT_TYPE',
        'SHOT_MADE_FLAG',
        'LOC_X',
        'LOC_Y',
        'SHOT_DISTANCE',
        'QUARTER'
    ]
}
