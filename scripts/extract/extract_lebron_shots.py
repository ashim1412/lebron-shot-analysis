"""
LeBron James Shot Data Extraction
"""

import os
import json
import time
import pandas as pd
from nba_api.stats.endpoints import shotchartdetail
from datetime import datetime
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
from config.seasons import LEBRON_SEASONS

# Configuration
LEBRON_PLAYER_ID = 2544
LEBRON_NAME = "LeBron James"
RAW_DATA_DIR = "data/raw"
LOG_DIR = "logs"

os.makedirs(RAW_DATA_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

class LeBronExtractor:
    def __init__(self):
        self.extraction_log = []
        self.errors = []
    
    def extract_shots(self, season, season_type='Regular Season'):
        """Extract shot data for a season"""
        season_str = f"{season}-{str(season+1)[2:]}"  # e.g., 2023 -> "2023-24"
        try:
            print(f"  Extracting {season_type} {season_str}...", end=" ")
            
            shot_chart = shotchartdetail.ShotChartDetail(
                team_id=0,
                player_id=LEBRON_PLAYER_ID,
                context_measure_simple='FGA',
                season_type_all_star=season_type,
                season_nullable=season_str  # Correct argument
            )
            
            shots_df = shot_chart.get_data_frames()[0]
            shots_df['api_extraction_season'] = season
            shots_df['api_extraction_season_type'] = season_type
            
            print(f"✓ ({len(shots_df)} shots)")
            self.extraction_log.append({
                'season': season,
                'season_type': season_type,
                'shots_extracted': len(shots_df),
                'timestamp': datetime.now().isoformat()
            })
            return shots_df
        except Exception as e:
            print(f"✗ Error: {str(e)[:50]}")
            self.errors.append({
                'season': season,
                'season_type': season_type,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            })
            return None
    
    def extract_all_seasons(self):
        """
        Extracting shot data for all seasons (regular + postseason)
        """
        all_shots = []
        print(f"\nExtracting {LEBRON_NAME} shot data...")
        for season in LEBRON_SEASONS:
            # Regular season
            regular_shots = self.extract_shots(season, 'Regular Season')
            if regular_shots is not None:
                all_shots.append(regular_shots)
            time.sleep(1.5)
            
            # Playoffs
            playoff_shots = self.extract_shots(season, 'Playoffs')
            if playoff_shots is not None:
                all_shots.append(playoff_shots)
            time.sleep(1.5)
        
        if all_shots:
            combined_df = pd.concat(all_shots, ignore_index=True)
            print(f"\nTotal shots extracted: {len(combined_df):,}")
            return combined_df
        return None
    
    def save_raw_data(self, df, filename='lebron_shots_raw.csv'):
        filepath = os.path.join(RAW_DATA_DIR, filename)
        df.to_csv(filepath, index=False)
        print(f"Saved raw data to: {filepath}")
        return filepath
    
    def save_extraction_log(self):
        log_data = {
            'extraction_timestamp': datetime.now().isoformat(),
            'total_seasons': len(LEBRON_SEASONS),
            'seasons_range': f"{LEBRON_SEASONS[0]}-{LEBRON_SEASONS[-1]}",
            'extraction_log': self.extraction_log,
            'errors': self.errors
        }
        log_filepath = os.path.join(LOG_DIR, 'extraction_log.json')
        with open(log_filepath, 'w') as f:
            json.dump(log_data, f, indent=2)
        print(f"Saved extraction log to: {log_filepath}")

def main():
    extractor = LeBronExtractor()
    shots_df = extractor.extract_all_seasons()
    if shots_df is not None:
        extractor.save_raw_data(shots_df)
        extractor.save_extraction_log()
        print("\nSample data:")
        print(shots_df.head(1).to_string())
    else:
        print("No data extracted!")

if __name__ == "__main__":
    main()
