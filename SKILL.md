---
name: sagittarius-arm-control
description: Use when the user wants OpenClaw to control the Sagittarius robotic arm in ~/team2 through the ROS bridge package sagittarius_openclaw_bridge. Maps natural-language requests like search, detect color, pick, place, sort, and readiness checks to the bridge commands and explains when to use high-level commands instead of raw coordinates.
---

# Sagittarius Arm Control

Use this skill whenever the user wants to operate the Sagittarius arm connected to the `~/team2` ROS workspace.

Prefer the bundled scripts in `scripts/` instead of retyping long ROS environment setup commands.

## Environment

- ROS workspace: `~/team2`
- Bridge package: `sagittarius_openclaw_bridge`
- Main command wrapper: `~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh`
- Backend launcher: `~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_backend.sh`

## First move

Before sending any motion command, check readiness:

```bash
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh status
```

Interpret the result:

- If `success: true`, the backend is ready.
- If `camera_ok=false`, the camera stream is not ready.
- If `action_server_ok=false`, the Sagittarius action server is not ready.
- If `vision_config_ok=false` or `calibration_ok=false`, color-based tasks will fail.

If the backend is not ready and the user wants you to bring it up, use:

```bash
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_backend.sh
```

This launches the bridge with the camera settings currently known to work on this machine.

If a command fails because the bridge service is missing or the backend is not ready, retry with the `~/team2` workspace only:

```bash
source /opt/ros/noetic/setup.bash
source ~/team2/devel/setup.bash
roslaunch sagittarius_openclaw_bridge openclaw_backend.launch
```

Do not switch workspaces while recovering. Stay on `~/team2`.

## Backend-not-running signals

If any arm command returns this exact error:

```text
ERROR: ROS master is not reachable at http://localhost:11311. Start 'roscore' or launch the backend before running this command.
```

or if a readiness/detection command produces no response for a long time before returning any `success:` / `result_code:` / `message:` lines, interpret it as the OpenClaw backend not running or not reachable.

In that situation:

- Do not keep retrying the same arm command.
- Do not report this as a vision, grasping, or motion-planning failure.
- Tell the user that `roslaunch sagittarius_openclaw_bridge openclaw_backend.launch` is probably not running.
- Ask the user to start the backend, or start it yourself only if the user has asked you to bring the robot backend up.

Recommended recovery command:

```bash
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_backend.sh
```

Equivalent manual command:

```bash
source /opt/ros/noetic/setup.bash
source ~/team2/devel/setup.bash
roslaunch sagittarius_openclaw_bridge openclaw_backend.launch
```

## Command selection

Prefer high-level commands first:

- Use `status` for health checks.
- Use `search` to move to the observation pose.
- Use `detect-color` when the task is to inspect or localize without grasping.
- Use `pick-any` when the user wants any visible block.
- Use `pick-once --color <color>` when the user wants a specific color grasped and held.
- Use `pick-and-place` when the user describes a full pick then place task.
- Use `classify-once-fixed` for one-shot fixed-bin sorting.
- Use `sort-all-fixed` for repeated fixed-bin sorting until nothing remains.
- Use `classify-once-map` when the map drop areas are visible and the task is map-based sorting.

Only use low-level `move`, `pick`, or `put` when the user gives explicit coordinates or asks for manual positioning.

## Natural-language mapping

- "Look around" or "go to observation pose" -> `search`
- "What color block do you see?" -> `detect-color`
- "Grab the blue block" -> `pick-once --color blue`
- "Grab any block" -> `pick-any`
- "Pick the blue block and place it at x/y/z" -> `pick-and-place --color blue --x ... --y ... --z ... --pitch 1.57 --use-rpy`
- "Sort the table" -> `sort-all-fixed`
- "Sort one object by the map layout" -> `classify-once-map`

## Command reference

Read the output and reuse it in the conversation. `detected_color` and `target_xyz` are often useful follow-up context.

```bash
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh status
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh search
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh detect-color --color blue
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh detect-color
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh pick-once --color blue
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh pick-any
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh pick-and-place --color blue --x 0.16 --y 0.24 --z 0.20 --pitch 1.57 --use-rpy
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh classify-once-fixed
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh sort-all-fixed
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh classify-once-map
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh move --x 0.20 --y 0.00 --z 0.15 --pitch 1.57 --use-rpy
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh pick --x 0.24 --y 0.00 --z 0.02 --pitch 1.57 --use-rpy
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh put --x 0.16 --y 0.24 --z 0.20
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh stay
~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_cmd.sh sleep
```

## Decision rules

- Start with `status` unless the user already confirmed the backend is running.
- For color tasks, prefer high-level commands over raw motion.
- For repeated sorting, use `sort-all-fixed` instead of manually chaining `pick-once` and `put`.
- Use `pick-and-place` instead of separate `pick-once` and `put` when the user describes one closed-loop task.
- If a command fails because no stable object was found, tell the user it is a vision issue rather than pretending motion failed.
- If a command fails because readiness is false, report which subsystem is failing and suggest `~/.openclaw/workspace/skills/sagittarius_arm_control_skill/scripts/arm_backend.sh` or the manual `~/team2` backend launch commands above.
- If the bridge service is missing, retry recovery with `~/team2` before doing anything else.
- If the output says `ROS master is not reachable` or the command appears to hang without any response, treat it as backend-not-running first and remind the user to start `roslaunch sagittarius_openclaw_bridge openclaw_backend.launch`.

## Safety

- This skill controls real hardware. Avoid improvising arbitrary coordinates unless the user explicitly asks for manual positioning.
- For ambiguous physical requests, prefer `search`, `status`, and `detect-color` before moving.
- If the user requests a risky or unclear motion near people or obstacles, pause and ask for confirmation.
