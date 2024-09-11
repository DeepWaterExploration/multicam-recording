from dataclasses import dataclass
from typing import List
import subprocess
from multiprocessing import Process
import time
import shlex
import threading
import event_emitter as events
from .list_devices import DeviceInfo
from datetime import datetime

import logging

class StreamRunner:

    def __init__(self, device_info: DeviceInfo, width: int, framerate: int) -> None:
        super().__init__()
        self.device_info = device_info
        self.device_path = device_info.device_paths[0] # MJPEG
        self.pipeline = None
        self.loop = None
        self.started = False
        self.width = width
        self.framerate = framerate

    def start(self, directory: str):
        if self.started:
            self.stop()
        self.started = True
        self._run_pipeline(directory)

    def stop(self):
        if not self.started:
            return
        self.started = False
        self._process.kill()
        self._process.wait()
        del self._process

    def _run_pipeline(self, directory: str):
        pipeline_str = self._construct_pipeline(self.device_path, f'{directory}/{self.device_info.bus_info}.avi', self.width, self.framerate)
        logging.info(pipeline_str)
        self._process = subprocess.Popen(
            f'gst-launch-1.0 {pipeline_str}'.split(' '), stdout=subprocess.DEVNULL, text=True)

    def _construct_pipeline(self, device_index: str, output_file_path: str, resolution_width: int = 1920, framerate: int = 30):
        return f"v4l2src device={device_index} ! image/jpeg, width={resolution_width},framerate={framerate}/1 ! queue ! avimux ! filesink location={output_file_path}"

