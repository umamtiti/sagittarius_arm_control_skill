#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/noetic/setup.bash
source /home/ay/team2/devel/setup.bash

exec roslaunch sagittarius_openclaw_bridge openclaw_backend.launch \
  video_dev:=/dev/video0 \
  pixel_format:=mjpeg \
  image_width:=640 \
  image_height:=480 \
  framerate:=25
