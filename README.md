# sagittarius-arm-control

This directory contains the OpenClaw skill for controlling the Sagittarius robotic arm.

It is built around `sagittarius_openclaw_bridge` in `~/team2`, so OpenClaw can use high-level commands for search, detection, pick, place, and sorting without directly operating the lower-level ROS Action interface.

## Directory Layout

- `SKILL.md`
  The main instruction file used by OpenClaw. It defines when to use this skill, how to choose commands, and how to recover from failures.
- `scripts/arm_cmd.sh`
  The main command entrypoint. It automatically runs `source /opt/ros/noetic/setup.bash` and `source ~/team2/devel/setup.bash`, then calls `openclaw_cmd.py`.
- `scripts/arm_backend.sh`
  The backend launcher. It starts `openclaw_backend.launch` with the camera parameters that have been validated on this machine.

## Environment Assumptions

- ROS workspace: `~/team2`
- Bridge package: `sagittarius_openclaw_bridge`
- Do not switch to another workspace during recovery

## Common Usage

Check whether the backend is ready:

```bash
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh status
```

If the backend is not ready, start it:

```bash
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_backend.sh
```

Common commands:

```bash
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh search
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh detect-color --color blue
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh pick-any
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh pick-once --color blue
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh pick-and-place --color blue --x 0.16 --y 0.24 --z 0.20 --pitch 1.57 --use-rpy
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh classify-once-fixed
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh sort-all-fixed
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh classify-once-map
```

## Failure Recovery

If a command returns:

```text
ERROR: ROS master is not reachable at http://localhost:11311. Start 'roscore' or launch the backend before running this command.
```

or if a readiness/detection command waits for a long time without returning any `success:`, `result_code:`, or `message:` lines, treat this as a backend startup problem first. In practice, it usually means:

```bash
roslaunch sagittarius_openclaw_bridge openclaw_backend.launch
```

is not running.

The right response is to remind the user to start the backend instead of continuing to retry the same arm command.

If a command fails because the bridge service is missing, the backend is not ready, or `status` reports that the action server or camera is not ready, first try:

```bash
source /opt/ros/noetic/setup.bash
source ~/team2/devel/setup.bash
roslaunch sagittarius_openclaw_bridge openclaw_backend.launch
```

In most cases, it is better to use the bundled launcher:

```bash
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_backend.sh
```

## Notes

- `status`, `search`, and `detect-color` are good pre-check commands.
- `pick-any`, `pick-once`, and `pick-and-place` are the most useful high-level commands for an agent.
- `sort-all-fixed` and `classify-once-map` are better suited for full-task demos.
