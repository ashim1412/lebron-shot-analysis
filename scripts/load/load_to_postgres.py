"""
Load LeBron James shot data into PostgreSQL
Purpose: Transform CSV into normalized database schema
Run: python scripts/load/load_to_postgres.py
"""

import os
import sys
import pandas as pd
import psycopg2
from psycopg2.extras import execute_batch
import json
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

from config.database import DatabaseConnection
from config.team_mapping import TEAM_MAPPING

PROCESSED_DATA_PATH = "data/processed/lebron_shots_processed.csv"
LOG_DIR = "logs"

os.makedirs(LOG_DIR, exist_ok=True)

class PostgreSQLLoader:
    def __init__(self):
        self.db = DatabaseConnection()
        self.df = None
        self.load_log = {
            'timestamp': datetime.now().isoformat(),
            'steps': [],
            'errors': [],
            'stats': {}
        }
    
    def load_processed_data(self):
        """Load processed CSV"""
        print("[STEP 1/5] Loading processed data...", end=" ")
        try:
            self.df = pd.read_csv(PROCESSED_DATA_PATH)
            print(f"✓ ({len(self.df):,} shots)")
            self.load_log['steps'].append({
                'step': 'load_csv',
                'rows': len(self.df)
            })
        except Exception as e:
            print(f"✗ Error: {e}")
            raise
    
    def load_teams(self):
        """Load unique teams into teams table"""
        print("[STEP 2/5] Loading teams...", end=" ")
        
        try:
            conn = self.db.connect()
            cursor = conn.cursor()
            
            teams_to_insert = []
            for nba_id, team_info in TEAM_MAPPING.items():
                teams_to_insert.append((
                    nba_id,
                    team_info['abbreviation'],
                    team_info['name']
                ))
            
            insert_query = """
            INSERT INTO teams (nba_team_id, team_abbreviation, team_name)
            VALUES (%s, %s, %s)
            ON CONFLICT (nba_team_id) DO NOTHING
            """
            
            execute_batch(cursor, insert_query, teams_to_insert, page_size=100)
            conn.commit()
            
            cursor.execute("SELECT COUNT(*) FROM teams")
            team_count = cursor.fetchone()[0]
            
            print(f"✓ ({team_count} teams)")
            self.load_log['steps'].append({
                'step': 'load_teams',
                'teams_loaded': team_count
            })
            self.load_log['stats']['teams'] = team_count
            
            cursor.close()
            conn.close()
            
        except Exception as e:
            print(f"✗ Error: {e}")
            self.load_log['errors'].append(f"load_teams: {str(e)}")
            raise
    
    def load_games(self):
        """Load unique games into games table"""
        print("[STEP 3/5] Loading games...", end=" ")
        
        try:
            games_df = self.df[[
                'GAME_ID', 'GAME_DATE', 'SEASON', 'IS_POSTSEASON',
                'TEAM_ID', 'OPPONENT_TEAM_ID', 'HOME_AWAY'
            ]].drop_duplicates(subset=['GAME_ID'])
            
            conn = self.db.connect()
            cursor = conn.cursor()

            # Map NBA ID -> team_id
            cursor.execute("SELECT team_id, nba_team_id FROM teams")
            team_id_map = {row[1]: row[0] for row in cursor.fetchall()}

            games_to_insert = []
            for _, game in games_df.iterrows():
                lebron_team_id = team_id_map.get(int(game['TEAM_ID']))
                opponent_team_id = team_id_map.get(int(game['OPPONENT_TEAM_ID']))

                if lebron_team_id is None or opponent_team_id is None:
                    self.load_log['errors'].append(
                        f"Missing team mapping for game {game['GAME_ID']}"
                    )
                    continue

                is_home = True if game.get('HOME_AWAY', 'AWAY') == 'HOME' else False

                games_to_insert.append((
                    int(game['GAME_ID']),
                    pd.to_datetime(game['GAME_DATE']).date(),
                    str(game['SEASON']),
                    bool(game['IS_POSTSEASON']),
                    None,  # postseason_round
                    lebron_team_id,
                    opponent_team_id,
                    is_home
                ))
            
            insert_query = """
            INSERT INTO games 
            (game_id, game_date, season, is_postseason, postseason_round, 
             lebron_team_id, opponent_team_id, is_home)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (game_id) DO NOTHING
            """
            
            execute_batch(cursor, insert_query, games_to_insert, page_size=100)
            conn.commit()

            cursor.execute("SELECT COUNT(*) FROM games")
            game_count = cursor.fetchone()[0]

            print(f"✓ ({game_count} games)")
            self.load_log['steps'].append({
                'step': 'load_games',
                'games_loaded': game_count
            })
            self.load_log['stats']['games'] = game_count

            cursor.close()
            conn.close()
            
        except Exception as e:
            print(f"✗ Error: {e}")
            self.load_log['errors'].append(f"load_games: {str(e)}")
            raise
    
    def load_shots(self):
        """Load all shots into shots table"""
        print("[STEP 4/5] Loading shots...", end=" ")
        
        try:
            conn = self.db.connect()
            cursor = conn.cursor()
            
            shots_to_insert = []
            for idx, shot in self.df.iterrows():
                shots_to_insert.append((
                    int(shot['GAME_ID']),
                    idx + 1,
                    shot['SHOT_TYPE_STD'],
                    bool(shot['SHOT_MADE']),
                    float(shot['LOC_X']) if pd.notna(shot['LOC_X']) else None,
                    float(shot['LOC_Y']) if pd.notna(shot['LOC_Y']) else None,
                    float(shot['SHOT_DISTANCE']) if pd.notna(shot['SHOT_DISTANCE']) else None,
                    int(shot['QUARTER']),
                    f"{int(shot['MINUTES_REMAINING']):02d}:{int(shot['SECONDS_REMAINING']):02d}" if pd.notna(shot['MINUTES_REMAINING']) and pd.notna(shot['SECONDS_REMAINING']) else None,
                    int(shot['MINUTES_REMAINING']) * 60 + int(shot['SECONDS_REMAINING']) if pd.notna(shot['MINUTES_REMAINING']) and pd.notna(shot['SECONDS_REMAINING']) else None,
                    str(shot['SEASON']),
                    bool(shot['IS_POSTSEASON']),
                    shot['SHOT_ZONE_BASIC'],
                    shot['SHOT_ZONE_AREA'],
                    shot['ACTION_TYPE'],
                    shot['DISTANCE_CLASS'],
                    int(shot['MINUTES_REMAINING']) if pd.notna(shot['MINUTES_REMAINING']) else None,
                    int(shot['SECONDS_REMAINING']) if pd.notna(shot['SECONDS_REMAINING']) else None
                ))
            
            insert_query = """
            INSERT INTO shots 
            (game_id, shot_number, shot_type, shot_made, shot_x, shot_y, 
             shot_distance, quarter, time_remaining_quarter, seconds_remaining_game,
             season, is_postseason, shot_zone_basic, shot_zone_area, action_type, distance_class,
             minutes_remaining, seconds_remaining)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            execute_batch(cursor, insert_query, shots_to_insert, page_size=500)
            conn.commit()

            cursor.execute("SELECT COUNT(*) FROM shots")
            shot_count = cursor.fetchone()[0]

            print(f"✓ ({shot_count:,} shots)")
            self.load_log['steps'].append({
                'step': 'load_shots',
                'shots_loaded': shot_count
            })
            self.load_log['stats']['shots'] = shot_count

            cursor.close()
            conn.close()
            
        except Exception as e:
            print(f"✗ Error: {e}")
            self.load_log['errors'].append(f"load_shots: {str(e)}")
            raise
    
    
    def save_load_log(self):
        log_filepath = os.path.join(LOG_DIR, 'load_log.json')
        with open(log_filepath, 'w') as f:
            json.dump(self.load_log, f, indent=2)
        print(f"✓ Saved load log to: {log_filepath}")
    
    def load(self):
        print("\n" + "=" * 70)
        print("LOADING DATA INTO POSTGRESQL")
        print("=" * 70 + "\n")
        
        self.load_processed_data()
        self.load_teams()
        self.load_games()
        self.load_shots()
        verify_results = self.verify_load()
        self.print_summary(verify_results)
        self.save_load_log()


def main():
    loader = PostgreSQLLoader()
    loader.load()


if __name__ == "__main__":
    main()
