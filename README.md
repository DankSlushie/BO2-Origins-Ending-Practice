# Download
[EndingPracticeV2.gsc](https://github.com/DankSlushie/BO2-Origins-Ending-Practice/releases/download/V2/EndingPracticeV2.gsc)

# Usage
Put `EndingPracticeV2.gsc` in `C:\Users\%username%\AppData\Local\Plutonium\storage\t6\scripts\zm`

Type in game chat to configure your practice:
- "15" sets it to round 15
- "16" sets it to round 16
- "stg" toggles whether your stg is upgraded
- "gram" toggles whether the gramophone is placed in the wind tunnel
- "random" makes the robot foot random
- "left" makes the robot's left foot open
- "right" makes the robot's right foot open

# Compatibility Notes
This mod was developed on Plutonium r2905, but it should always work on the latest version of Plutonium.

This mod is incompatible with gsc files that replace any of the following functions (mainly other practice mods):
- maps\mp\zm_tomb_dig::waittill_dug()
- maps\mp\zm_tomb_giant_robot::robot_cycling()
- maps\mp\zm_tomb_giant_robot::giant_robot_start_walk()
- maps\mp\zm_tomb_main_quest::staff_biplane_drop_pieces()
- maps\mp\zm_tomb_capture_zones::recapture_round_tracker()
- maps\mp\zombies\_zm_ai_mechz::mechz_round_tracker()
- maps\mp\zombies\_zm_powerups::get_next_powerup()
