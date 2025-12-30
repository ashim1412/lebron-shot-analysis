"""
LeBron James Shot Data Transformation
Purpose: Clean, validate, and enrich raw data
Run: python scripts/transform/transform_lebron_shots.py
"""

import os
import sys
import pandas as pd
import numpy as np
import json
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
from config.transform_config import (
    SHOT_TYPE_MAPPING, SEASON_TYPES, POSTSEASON_ROUNDS, DATA_QUALITY
)

RAW_DATA_PATH = "data/raw/lebron_shots_raw.csv"
PROCESSED_DATA_PATH = "data/processed/lebron_shots_processed.csv"
LOG_DIR = "logs"
PROCESSED_DIR = "data/processed"

os.makedirs(PROCESSED_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

class LeBronTransformer:
    def __init__(self):
        self.df = None
        self.transform_log = {
            'start_rows': 0,
            'end_rows': 0,
            'steps': [],
            'warnings': [],
            'errors': []
        }
    
    def load_data(self):
        """Load raw CSV data"""
        print("[STEP 1/6] Loading raw data...", end=" ")
        try:
            self.df = pd.read_csv(RAW_DATA_PATH)
            self.transform_log['start_rows'] = len(self.df)

            # Rename PERIOD -> QUARTER
            if 'PERIOD' in self.df.columns:
                self.df.rename(columns={'PERIOD': 'QUARTER'}, inplace=True)
                
            print(f"✓ ({len(self.df):,} rows)")
            self.transform_log['steps'].append({
                'step': 'load_data',
                'rows': len(self.df)
            })
        except Exception as e:
            print(f"✗ Error: {e}")
            raise
    
    def inspect_data(self):
        """Display data structure"""
        print("\n[DATA INSPECTION]")
        print(f"Shape: {self.df.shape}")
        print(f"\nColumns: {list(self.df.columns)}")
        print(f"\nMissing values:")
        missing = self.df.isnull().sum()
        for col, count in missing[missing > 0].items():
            pct = (count / len(self.df)) * 100
            print(f"  {col}: {count} ({pct:.1f}%)")
    
    def standardize_shot_types(self):
        """Standardize shot type names"""
        print("[STEP 2/6] Standardizing shot types...", end=" ")
        
        # Create standardized column
        self.df['SHOT_TYPE_STD'] = self.df['SHOT_TYPE'].map(SHOT_TYPE_MAPPING)
        
        # Check for unmapped values
        unmapped = self.df[self.df['SHOT_TYPE_STD'].isnull()]['SHOT_TYPE'].unique()
        if len(unmapped) > 0:
            msg = f"Unmapped shot types: {unmapped}"
            self.transform_log['warnings'].append(msg)
            print(f"⚠ {msg}")
        
        print(f"✓")
        self.transform_log['steps'].append({
            'step': 'standardize_shot_types',
            'unique_types': self.df['SHOT_TYPE_STD'].nunique()
        })
    
    def clean_coordinates(self):
        """Clean and validate shot coordinates"""
        print("[STEP 3/6] Cleaning shot coordinates...", end=" ")
        
        # Check for null coordinates
        null_coords = self.df[
            (self.df['LOC_X'].isnull()) | (self.df['LOC_Y'].isnull())
        ]
        
        if len(null_coords) > 0:
            msg = f"{len(null_coords)} shots with null coordinates"
            self.transform_log['warnings'].append(msg)
            print(f"⚠ {msg}")
            # Drop these rows
            self.df = self.df.dropna(subset=['LOC_X', 'LOC_Y'])
        
        # Ensure coordinates are numeric
        self.df['LOC_X'] = pd.to_numeric(self.df['LOC_X'], errors='coerce')
        self.df['LOC_Y'] = pd.to_numeric(self.df['LOC_Y'], errors='coerce')
        
        print(f"✓")
        self.transform_log['steps'].append({
            'step': 'clean_coordinates',
            'rows_remaining': len(self.df)
        })
    
    def validate_shot_distance(self):
        """Validate shot distance values"""
        print("[STEP 4/6] Validating shot distance...", end=" ")
        
        min_dist = DATA_QUALITY['min_shot_distance']
        max_dist = DATA_QUALITY['max_shot_distance']
        
        invalid = self.df[
            (self.df['SHOT_DISTANCE'] < min_dist) | 
            (self.df['SHOT_DISTANCE'] > max_dist)
        ]
        
        if len(invalid) > 0:
            msg = f"{len(invalid)} shots outside valid distance range"
            self.transform_log['warnings'].append(msg)
            print(f"⚠ {msg}")
        
        print(f"✓")
        self.transform_log['steps'].append({
            'step': 'validate_shot_distance',
            'avg_distance': self.df['SHOT_DISTANCE'].mean()
        })
    
    def add_derived_columns(self):
        """Create new columns for analysis"""
        print("[STEP 5/6] Adding derived columns...", end=" ")
        
        # Extract season from api_extraction_season
        self.df['SEASON'] = self.df['api_extraction_season']
        
        # Determine if postseason
        self.df['IS_POSTSEASON'] = (
            self.df['api_extraction_season_type'] == 'Playoffs'
        ).astype(int)
        
        # Parse game date
        self.df['GAME_DATE'] = pd.to_datetime(self.df['GAME_DATE'])
        
        # Extract game year (for analysis purposes)
        self.df['GAME_YEAR'] = self.df['GAME_DATE'].dt.year
        
        # Shot made as boolean
        self.df['SHOT_MADE'] = self.df['SHOT_MADE_FLAG'].astype(int)
        
        # Shot missed (inverse)
        self.df['SHOT_MISSED'] = 1 - self.df['SHOT_MADE']
        
        # Classify shot distance
        def classify_distance(distance):
            if distance <= 3:
                return 'At Rim'
            elif distance <= 10:
                return 'Mid Range'
            elif distance <= 23.75:
                return 'Three Point'
            else:
                return 'Beyond Arc'
        
        self.df['DISTANCE_CLASS'] = self.df['SHOT_DISTANCE'].apply(classify_distance)
        
        print(f"✓")
        self.transform_log['steps'].append({
            'step': 'add_derived_columns',
            'new_columns': [
                'SEASON', 'IS_POSTSEASON', 'GAME_DATE', 'GAME_YEAR', 
                'SHOT_MADE', 'SHOT_MISSED', 'DISTANCE_CLASS'
            ]
        })
    
    def validate_data_quality(self):
        """Final data quality check"""
        print("[STEP 6/6] Validating data quality...", end=" ")
        
        required_cols = DATA_QUALITY['required_columns']
        
        # Check for required columns
        missing_cols = [col for col in required_cols if col not in self.df.columns]
        if missing_cols:
            msg = f"Missing required columns: {missing_cols}"
            self.transform_log['errors'].append(msg)
            print(f"✗ {msg}")
            raise ValueError(msg)
        
        # Check for nulls in critical columns
        critical_nulls = self.df[required_cols].isnull().sum()
        if critical_nulls.sum() > 0:
            msg = f"Null values in critical columns:\n{critical_nulls[critical_nulls > 0]}"
            self.transform_log['warnings'].append(msg)
        
        print(f"✓")
        self.transform_log['steps'].append({
            'step': 'validate_data_quality',
            'final_rows': len(self.df),
            'null_count': self.df.isnull().sum().sum()
        })
    
    def select_final_columns(self):
        """Select only columns needed for analysis"""
        
        final_columns = [
            'GAME_ID',
            'GAME_DATE',
            'GAME_YEAR',
            'SEASON',
            'IS_POSTSEASON',
            'TEAM_ID',
            'OPPONENT_TEAM_ID',
            'SHOT_TYPE_STD',
            'SHOT_MADE',
            'SHOT_MISSED',
            'LOC_X',
            'LOC_Y',
            'SHOT_DISTANCE',
            'DISTANCE_CLASS',
            'QUARTER',
            'MINUTES_REMAINING',
            'SECONDS_REMAINING'
        ]
        
        # Only select columns that exist
        existing_cols = [col for col in final_columns if col in self.df.columns]
        self.df = self.df[existing_cols]
    
    def save_processed_data(self):
        """Save cleaned data to CSV"""
        print(f"\n[SAVING] Writing to {PROCESSED_DATA_PATH}...", end=" ")
        
        self.df.to_csv(PROCESSED_DATA_PATH, index=False)
        
        self.transform_log['end_rows'] = len(self.df)
        rows_dropped = self.transform_log['start_rows'] - self.transform_log['end_rows']
        
        print(f"✓")
        print(f"  → Rows processed: {self.transform_log['start_rows']:,}")
        print(f"  → Rows retained: {self.transform_log['end_rows']:,}")
        print(f"  → Rows dropped: {rows_dropped:,}")
    
    def save_transform_log(self):
        """Save transformation metadata"""
        log_filepath = os.path.join(LOG_DIR, 'transform_log.json')
        
        self.transform_log['timestamp'] = datetime.now().isoformat()
        
        # Convert numpy types to native Python types
        def convert(o):
            if isinstance(o, (np.integer, np.int64)):
                return int(o)
            if isinstance(o, (np.floating, np.float64)):
                return float(o)
            return str(o)  # fallback
    
        with open(log_filepath, 'w') as f:
            json.dump(self.transform_log, f, indent=2, default=convert)
        
        print(f"✓ Saved transform log to: {log_filepath}")
    
    def print_summary(self):
        """Print transformation summary"""
        print("\n" + "=" * 70)
        print("TRANSFORMATION SUMMARY")
        print("=" * 70)
        print(f"\nInput rows: {self.transform_log['start_rows']:,}")
        print(f"Output rows: {self.transform_log['end_rows']:,}")
        print(f"Rows removed: {self.transform_log['start_rows'] - self.transform_log['end_rows']:,}")
        
        if self.transform_log['warnings']:
            print(f"\nWarnings: {len(self.transform_log['warnings'])}")
            for warning in self.transform_log['warnings']:
                print(f"  ⚠ {warning}")
        
        if self.transform_log['errors']:
            print(f"\nErrors: {len(self.transform_log['errors'])}")
            for error in self.transform_log['errors']:
                print(f"  ✗ {error}")
        else:
            print(f"\n✓ No errors!")
        
        print(f"\nFinal data shape: {self.df.shape}")
        print(f"Final columns: {list(self.df.columns)}")
    
    def transform(self):
        """Execute full transformation pipeline"""
        print("\n" + "=" * 70)
        print("TRANSFORMING LEBRON JAMES SHOT DATA")
        print("=" * 70 + "\n")
        
        self.load_data()
        self.inspect_data()
        self.standardize_shot_types()
        self.clean_coordinates()
        self.validate_shot_distance()
        self.add_derived_columns()
        self.validate_data_quality()
        self.select_final_columns()
        self.save_processed_data()
        self.save_transform_log()
        self.print_summary()


def main():
    transformer = LeBronTransformer()
    transformer.transform()


if __name__ == "__main__":
    main()
