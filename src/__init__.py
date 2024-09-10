from .list_devices import list_devices, DeviceInfo
import logging
import time
from typing import List
from .stream import StreamRunner
from threading import Thread
from datetime import datetime
import os
import sys

from .util import createDirectory, get_current_timestamp, sys_less_than_x_mb_left, load_multicam_config

CURRENT_USER = os.getenv('USER')
VIDEO_DIRECTORY = f'/home/{CURRENT_USER}/Videos/DeepWaterVideos/'

def list_diff(listA, listB):
    # find the difference between lists
    diff = []
    for element in listA:
        if element not in listB:
            diff.append(element)
    return diff


'''
> Before starting recording:
    - check space on disk
        - If less than 1.5GB left, shutdown system permanently
    - check if it is a time after: 11:59pm (PST) - recording length
        - If so, reboot system
            - Question: what if reboot fails
    - create new folder for new session
        - naming scheme: "$YYYY_MM_DD___HH_MM_SS"

> Starting Recording:
    - Check available cameras
    - Isolate cameras based on configuation file
    - recording .avi files saved as: "cam#_bus_id.avi", under the aforementioned session folder

'''

streams: List[StreamRunner] = []

def reboot():
    logging.info('Stopping all streams')
    for stream in streams:
        stream.stop()
    logging.info('Rebooting')
    os.system('reboot')

def get_devices(old_devices: List[DeviceInfo], width: int, framerate: int):
    devices_info = list_devices()

    new_devices: List[DeviceInfo] = list_diff(devices_info, old_devices)
    removed_devices: List[DeviceInfo] = list_diff(old_devices, devices_info)

    for device_info in new_devices:
        logging.info(f'Device added: {device_info.bus_info}')

        stream = StreamRunner(device_info, width, framerate)
        streams.append(stream)

        old_devices.append(device_info)

    for device_info in removed_devices:
        logging.error(f'Device removed: {device_info.bus_info}. This should not happen!')
        for stream in streams:
            if stream.device_info.bus_info == device_info.bus_info:
                logging.info(f'Stop recording: {device_info.bus_info}')
                stream.stop()
                streams.remove(stream)
                del stream
                break
        old_devices.remove(device_info)

    return devices_info

def monitor():
    # list of running streams (recordings)
    # from now on we will call recordings streams
    logging.info('Loading config')
    config = load_multicam_config('./src/config.json')

    is_recording = True

    recording_start_time = time.time()
    recording_end_time = None
    current_time = time.time()

    record_period = config.recording_length_seconds
    record_interval_minutes = config.recording_interval_minutes / 2.0
    width = config.resolution_width
    framerate = config.framerate

    devices = get_devices([], width, framerate)

    logging.info(f'Recording period starting now, which will end in {record_period} seconds')
    start_streams()

    while True:
        if sys_less_than_x_mb_left(1000):
            logging.warn('Out of disk space. Goodbye!')
            stop_streams()
            exit()

        current_time = time.time()
        current_recording_length = current_time - recording_start_time
        
        # the recording period is over
        if is_recording and current_recording_length >= record_period:
            logging.info(f'Record period is over, starting next recording in {record_interval_minutes} minutes')
            stop_streams()
            recording_end_time = time.time()
            is_recording = False
        
        # the recording should start now
        if not is_recording and current_recording_length >= record_interval_minutes * 60:
            logging.info(f'Recording period starting now, which will end in {record_period} seconds')
            start_streams()
            recording_start_time = time.time()
            recording_end_time = None
            is_recording = True 

        devices = get_devices(devices, width, framerate)
        
        time.sleep(0.1) # do not overload bus

def start_streams():
    directory = VIDEO_DIRECTORY + get_current_timestamp()
    createDirectory(directory)
    for stream in streams:
        stream.start(directory)

def stop_streams():
    for stream in streams:
        stream.stop()

def main():
    createDirectory(VIDEO_DIRECTORY)

    logging.basicConfig(filename='log.txt', stream=sys.stdout, filemode='a')
    logging.getLogger().setLevel(logging.INFO)

    monitor()
