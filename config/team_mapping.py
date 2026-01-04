"""
NBA Team ID and Name Mapping
Source: NBA-API standard team IDs
"""

# Comprehensive NBA team mapping
# Format: nba_team_id: {'abbreviation': 'XXX', 'name': 'Team Name'}

TEAM_MAPPING = {
    1610612737: {'abbreviation': 'ATL', 'name': 'Atlanta Hawks'},
    1610612738: {'abbreviation': 'BOS', 'name': 'Boston Celtics'},
    1610612739: {'abbreviation': 'CLE', 'name': 'Cleveland Cavaliers'},
    1610612740: {'abbreviation': 'NOP', 'name': 'New Orleans Pelicans'},        # current Pelicans
    1610612741: {'abbreviation': 'CHI', 'name': 'Chicago Bulls'},
    1610612742: {'abbreviation': 'DAL', 'name': 'Dallas Mavericks'},
    1610612743: {'abbreviation': 'DEN', 'name': 'Denver Nuggets'},
    1610612744: {'abbreviation': 'GSW', 'name': 'Golden State Warriors'},
    1610612745: {'abbreviation': 'HOU', 'name': 'Houston Rockets'},
    1610612746: {'abbreviation': 'LAC', 'name': 'LA Clippers'},
    1610612747: {'abbreviation': 'LAL', 'name': 'Los Angeles Lakers'},
    1610612748: {'abbreviation': 'MIA', 'name': 'Miami Heat'},
    1610612749: {'abbreviation': 'MIL', 'name': 'Milwaukee Bucks'},
    1610612750: {'abbreviation': 'NJN', 'name': 'New Jersey Nets'},            # historical
    1610612751: {'abbreviation': 'MIN', 'name': 'Minnesota Timberwolves'},
    1610612752: {'abbreviation': 'BKN', 'name': 'Brooklyn Nets'},             # current
    1610612753: {'abbreviation': 'NYK', 'name': 'New York Knicks'},
    1610612754: {'abbreviation': 'ORL', 'name': 'Orlando Magic'},
    1610612755: {'abbreviation': 'PHI', 'name': 'Philadelphia 76ers'},
    1610612756: {'abbreviation': 'PHX', 'name': 'Phoenix Suns'},
    1610612757: {'abbreviation': 'POR', 'name': 'Portland Trail Blazers'},
    1610612758: {'abbreviation': 'SAC', 'name': 'Sacramento Kings'},
    1610612759: {'abbreviation': 'SAS', 'name': 'San Antonio Spurs'},
    1610612760: {'abbreviation': 'SEA', 'name': 'Seattle SuperSonics'},       # historical
    1610612761: {'abbreviation': 'TOR', 'name': 'Toronto Raptors'},
    1610612762: {'abbreviation': 'UTA', 'name': 'Utah Jazz'},
    1610612763: {'abbreviation': 'MEM', 'name': 'Memphis Grizzlies'},         # current
    1610612764: {'abbreviation': 'WAS', 'name': 'Washington Wizards'},
    1610612765: {'abbreviation': 'DET', 'name': 'Detroit Pistons'},
    1610612766: {'abbreviation': 'CHA', 'name': 'Charlotte Hornets'},        # historical
    1610612767: {'abbreviation': 'OKC', 'name': 'Oklahoma City Thunder'},
    1610617041: {'abbreviation': 'IND', 'name': 'Indiana Pacers'},
    1610610025: {'abbreviation': 'NOH', 'name': 'New Orleans Hornets'},      # historical
    1610610039: {'abbreviation': 'NOK', 'name': 'New Orleans/Oklahoma City Hornets'}  # temporary relocation
}

def get_team_name(team_id):
    """Get team name by ID"""
    return TEAM_MAPPING.get(team_id, {}).get('name', 'Unknown Team')

def get_team_abbr(team_id):
    """Get team abbreviation by ID"""
    return TEAM_MAPPING.get(team_id, {}).get('abbreviation', 'UNK')
