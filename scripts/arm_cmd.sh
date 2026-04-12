#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/noetic/setup.bash
source /home/ay/team2/devel/setup.bash

exec rosrun sagittarius_openclaw_bridge openclaw_cmd.py "$@"
