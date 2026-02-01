import os
import time
from datetime import datetime
from loguru import logger
from nba_api.stats.endpoints import shotchartdetail
from dotenv import load_dotenv

load_dotenv()
logger.add("logs/extraction_{time}.log", rotation="10 MB", level="INFO")

def get_current_season():

    """
    Dynamically calculates the NBA season string.
    """
    now = datetime.now()
    year = now.year if now.month >= 10 else now.year - 1 #NBA season typically start in october(Month 10)
    return f"{year}-{str(year+1)[-2:]}"

def fetch_and_save_season(player_id, season_id, is_current = False):
    file_path = f'data/raw/shots_{season_id}.parquet'

    if os.path.exists(file_path) and not is_current:
        logger.info(f"Skipping {season_id} - File already exists.")
        return True
    
    logger.info(f"Starting Extraction for Season: {season_id}")

    try:
        response = shotchartdetail.ShotChartDetail(
            team_id=0,
            player_id=player_id,
            context_measure_simple='FGA',
            season_nullable=season_id,
            #headers=HEADERS,
            timeout=60
        )

        df = response.get_data_frames()[0]
        if not df.empty:
            df.to_parquet(file_path, index = False)
            logger.success(f" Successfully saved {len(df)} shots for {season_id}")
            return True
        return False
    except Exception as e:
        logger.exception(f"failed to fetch {season_id}: {str(e)}")
        time.sleep(2)
        return False

logger.info("starting LeBron James Shot selection pipeline")


if __name__ == "__main__":
    os.makedirs('data/raw', exist_ok = True)
    os.makedirs('logs', exist_ok=True)

    PLAYER_ID = 2544
    START_YEAR = 2003
    CURRENT_SEASON = get_current_season()


    current_year_int = int(CURRENT_SEASON.split('-')[0])
    seasons = [f"{yr}-{str(yr+1)[-2:]}" for yr in range(START_YEAR, current_year_int+1)]
    
    for s in seasons:
        fetch_and_save_season(PLAYER_ID, s, is_current=(s == CURRENT_SEASON))
        
    logger.success("Pipeline Run Complete!")