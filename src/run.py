from list_devices import list_devices, DeviceInfo
import logging
import time
from typing import List
from stream import Stream

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
        - naming scheme: "YYYY_MM_DD___HH_MM_SS"

> Starting Recording:
    - Check available cameras
    - Isolate cameras based on configuation file
    - recording .avi files saved as: "cam#_bus_id.avi", under the aforementioned session folder

'''

if __name__ == '__main__':
    # logging.basicConfig(filename='log.txt', filemode='a')
    logging.getLogger().setLevel(logging.INFO)
    old_devices = []

    while True:
        devices_info = list_devices()

        new_devices: List[DeviceInfo] = list_diff(devices_info, old_devices)
        removed_devices: List[DeviceInfo] = list_diff(old_devices, devices_info)

        for device_info in new_devices:
            logging.info(f'Device added: {device_info.bus_info}')

            mjpeg_path = device_info.device_paths[0]
            stream = Stream()

            old_devices.append(device_info)

        for device_info in removed_devices:
            logging.error(f'Device removed: {device_info.bus_info}. This should not happen!')
            old_devices.remove(device_info)
        
        time.sleep(0.1) # do not overload bus
