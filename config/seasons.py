"""
NBA Seasons configuration
Purpose: Define which seasons to extract
"""

# LeBron's NBA seasons: 2003-04 to 2024-25
# NBA-API uses numeric format: 2024 = 2023-24 season
# LeBron's first season: 2003-04 (API code: 2003)
# Current season: 2024-25 (API code: 2024)

LEBRON_SEASONS = list(range(2003, 2026))  # [2003, 2004, 2005, ..., 2025]

print(f"Seasons to extract: {len(LEBRON_SEASONS)}")
print(f"Range: {LEBRON_SEASONS[0]}-{LEBRON_SEASONS[-1]}")
