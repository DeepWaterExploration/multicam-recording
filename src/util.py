from datetime import datetime
from dataclasses import dataclass
import shutil
import json
import os
import logging

@dataclass
class MulticamSettings:
    # Default settings
    recording_length_seconds: int = 30
    recording_interval_seconds: int = 60
    framerate: int = 30
    resolution_width: int = 1920

def load_multicam_config(file_path: str) -> MulticamSettings:
    """Loads settings from a JSON file and returns a MulticamSettings object."""
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)
            return MulticamSettings(**data)  # Unpacking dictionary
        
    except FileNotFoundError:
        logging.info(f"Error: File '{file_path}' not found.")
    except json.JSONDecodeError:
        logging.info(f"Error: File '{file_path}' is not a valid JSON.")
    except KeyError as e:
        logging.info(f"Error: Missing key in JSON: {e}")
    return None

def example():
    settings_file = 'config.json'  # Ensure this file is in the same directory
    multicam_settings = load_multicam_config(settings_file)

    if multicam_settings:
        logging.info(f"Resolution: {multicam_settings.resolution_width}")
        logging.info(f"Framerate: {multicam_settings.framerate}")
        logging.info(f"Recording length (seconds): {multicam_settings.recording_length_seconds}")
        logging.info(f"Recording interval (seconds): {multicam_settings.recording_interval_seconds}")
    else:
        logging.info("Failed to load settings.")

def get_current_timestamp():
    """Returns the current timestamp as a string in the format YYYY_MM_DD___HH_MM_SS."""
    current_time = datetime.now()
    return current_time.strftime('%Y_%m_%d___%H_%M_%S')
    
def get_free_space_in_mb(path='/') -> int:
    """Returns the free space in megabytes on the device for the given path."""
    total, used, free = shutil.disk_usage(path)
    return free // (1024 * 1024)  # Convert bytes to megabytes

def sys_less_than_x_mb_left(x: int) -> bool:
    return get_free_space_in_mb() < x

def createDirectory(directory: str):
    if not os.path.exists(directory):
        os.makedirs(directory)
        logging.info(f"Created video directory: {directory}")
    else:
        logging.info(f"Video directory already exists: {directory}")
