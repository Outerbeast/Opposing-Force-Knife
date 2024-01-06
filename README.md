Original Opposing Force Knife custom weapon script
==================================================

This script adds the original Opposing Force knife as a standalone weapon rather than a simple reskin of the crowbar, with its own hud slot and icon.
It also features a secondary attack based on an unused animation of the model, that does twice the damage but the attack rate is slower.
Included is a testing map knife_testmap.bsp to try it out against some npcs.

The code is almost entirely based on weapon_hlcrowbar and weapon_csknife for the secondary attack from KernCore's Counter Strike Weapons Pack https://forums.svencoop.com/showthread.php/43757-Custom-Weapons-All-Counter-Strike-Weapons

Note: anything with "my-" is a placeholder name- you are free to change this.

## Installation instructions for mappers: ##

1) [Download]( https://github.com/Outerbeast/Opposing-Force-Knife/releases/download/v1.3/weapon_knife_v1.3.zip ) and extract into svencoop_addon
2) In your main map script add the code `"#include "opfor/weapon_knife"` at the top of the file, then `RegisterKnife();` Inside `void MapInit()`
It should look like this:
```
#include "opfor/weapon_knife"

void MapInit()
{
	RegisterKnife();
}
```
-you should already have the map script set in the cfg "map_script mymap"

You should now be able to use the weapon like with any other weapon: placed in maps, equipped via cfg or give in console.

If you wish to replace all the crowbars in your maps with the knife, use `RegisterKnife( true );`.

## Installation for Server owners: ##

Unfortunately a plugin for this is not possible- while the weapon can be registered it is not possible to swap the crowbar with the knife automatically in a plugin because of API limitations.

If you wish to add this to maps like Opposing Force or Polar Rescue, follow these instructions carefully:

1) (See Step 1 for Mappers)

2) You need to use the enable_knife.as script that is already included with the pack and being used for the testmap, in scripts/maps/.
To enable this script, you must add the line "map_script opfor" to every map cfg file you wish to have the knife enabled, for instance in polar_rescue.cfg.
For Opposing Force, you have to repeat this step for every of*a*.cfg file- I'm sorry but thats what it takes :/

This will register it as a weapon, and also swap out the crowbar for it automatically- since maps like Polar Rescue and Opposing force use crowbar (just reskinned with knife) by default this is necessary.

-What if the map uses a different knife model?

For this you can simply create a global model replacement file (mymap.gmr), and then swap the models out in through that. There is no need to modify the script itself- in fact avoid doing so!

1) In the gmr file, add these lines:
"models/opfor/p_knife.mdl" "models/mymap/p_myknife.mdl"
"models/opfor/w_knife.mdl" "models/mymap/w_myknife.mdl"
"models/opfor/v_knife.mdl" "models/mymap/v_myknife.mdl"
first line is the original dir and model (do not change this) and the second is what you do change to your own path and filename of your own model.

2) Save the file and place in the maps dir with your map.

3) Then in your your map cfg, add the line
globalmodellist "../../maps/mymap.gmr". Save the file.

The model needs to have the same animations (in the correct order) for it to work properly.
The models also need to be res'd so that players download and view the models at all.

## Credits ##
My big thanks to KernCore for guidance and generously allowing some of his code to be used, and for also helping me with the hud icon
