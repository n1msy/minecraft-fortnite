# +---------------------------
# |
# | D e n i z en   M o d e l s
# | AKA DModels - dynamically animated models in minecraft
# |
# +---------------------------
#
# @author mcmonkey
# @contributors Max^
# @thanks Darwin, Max^, kalebbroo, sharklaserss - for helping with reference models, testing, ideas, etc
# @date 2022/06/01
# @updated 2023/05/12
# @denizen-build REL-1793
# @script-version 2.0
#
# This takes BlockBench "BBModel" files, converts them to a client-ready resource pack and Denizen internal data,
# then is able to display them in minecraft and even animate them, by spawning and moving invisible armor stands with resource pack items on their heads.
#
# Installation:
# 1: Edit your "plugins/Denizen/config.yml", find "File:", and "Allow read" and "Allow write" inside, and set them both to "true", then use "/ex reload config"
# 2: Copy the "scripts/dmodels" folder to your "plugins/Denizen/scripts" and "/ex reload"
# 2.5: NOTE: If you do not use the plugin Citizens, you can exclude the "dmodels_citizens" file.
# 3: Note that you must know the basics of operating resource packs - the pack content will be generated for you, but you must know how to install a pack on your client and/or distribute it to players as appropriate
# 4: Take a look at the config settings in the bottom of this file in case you want to change any of them.
#
# Usage:
# 1: Create a model using blockbench - https://www.blockbench.net/
# 1.1 Create as a 'Generic Model'
# 1.2 Make basically anything you want
# 1.3 Note that there is a scale limit, of roughly 73 blockbench units (about 4 minecraft block-widths),
#     meaning you cannot have a section of block more than 36 blockbench units from its pivot point.
#     If you need a larger object, add more Outliner groups with pivots moved over.
# 1.4 Make sure pivot points are as correct as possible to minimize glitchiness from animations
#     (for example, if you have a bone pivot point in the center of a block, but the block's own pivot point is left at default 0,0,0, this can lead to the armor stand having to move and rotate at the same time, and lose sync when doing so)
# 1.5 Animate freely, make sure the animation names are clear
# 2: Save the ".bbmodel" file into "plugins/Denizen/data/dmodels"
# 3: Load the model. For now, just do a command like "/ex run dmodels_load_bbmodel def:GOAT" but replace "GOAT" with the name of your model
#    This will output a resource pack to "plugins/Denizen/data/dmodels/res_pack/"
# 4: Load the resource pack on your client (or include it in your server's automatic resource pack)
# 5: Spawn your model and control it using the Denizen scripting API documented below
#
# #########
# Commands:
#   /[Command]                     - [Permission]           - [Description]
#   /dmodels                       - "dmodels.help"         - Root command entry.
#   /dmodels help                  - "dmodels.help"         - Shows help information about the dModels command.
#   /dmodels load [path]           - "dmodels.load"         - Loads a single model based on model file name input.
#   /dmodels loadall               - "dmodels.loadall"      - Loads all models in the models folder.
#   /dmodels unload [model]        - "dmodels.unload"       - Unloads a single model from memory based on model name input.
######                                                      - This will not properly remove any spawned instances of that model, which may now be glitched as a result.
######                                                      - This also does not remove any data from the resource pack currently.
#   /dmodels unloadall             - "dmodels.unloadall"    - Unloads any/all DModels data from memory.
#   /dmodels spawn [model]         - "dmodels.spawn"        - Spawns a static instance of a model at your location.
#   /dmodels remove                - "dmodels.remove"       - Removes whichever real-spawned model is closest to your location.
#   /dmodels animate [animation]   - "dmodels.animate"      - Causes your nearest real-spawned model to play the specified animation.
#   /dmodels stopanimate           - "dmodels.stopanimate"  - Causes your nearest real-spawned model to stop animating.
#   /dmodels npcmodel [model]      - "dmodels.npcmodel"     - sets an NPC to render as a given model (must be loaded). Use 'none' to remove the model.
#   /dmodels rotate [angles]       - "dmodels.rotate"       - Sets the rotation of the nearest real-spawned model to the given euler angles. Use '0,0,0' for default.
#   /dmodels scale [scale]         - "dmodels.scale"        - Sets the scale-multiplier of the nearest real-spawned model set to the given value. Use '1,1,1' for default.
#   /dmodels color [color]         - "dmodels.color"        - Sets the color of the nearest real-spawned model to the given color. Use 'white' for default.
#   /dmodels viewrange [range]     - "dmoddels.viewrange"   - Sets the view-range of the nearest real-spawned model to the given range (in blocks).
#
# #########
#
# API usage examples:
# # First load a model (in advance, not every time - you can use '/ex' to do this once after adding or modifying the .bbmodel file)
# - ~run dmodels_load_bbmodel def.model_name:goat
# # Then you can spawn it
# - run dmodels_spawn_model def.model_name:goat def.location:<player.location> save:spawned
# - define root <entry[spawned].created_queue.determination.first>
# # To move the whole model
# - teleport <[root]> <player.location>
# - run dmodels_reset_model_position def.root_entity:<[root]>
# # To start an automatic animation
# - run dmodels_animate def.root_entity:<[root]> def.animation:idle
# # To end an automatic animation
# - run dmodels_end_animation def.root_entity:<[root]>
# # To move the entity to a single frame of an animation (timespot is a decimal number of seconds from the start of the animation)
# - run dmodels_move_to_frame def.root_entity:<[root]> def.animation:idle def.timespot:0.5
# # To remove a model
# - run dmodels_delete def.root_entity:<[root]>
# # To rotate a model
# - run dmodels_set_rotation def.root_entity:<[root]> def.quaternion:identity
# # To scale a model
# - run dmodels_scale_model def.root_entity:<[root]> def.scale:1,1,1
# # To set the color of a model
# - run dmodels_set_color def.root_entity:<[root]> def.color:red
#
# #########
#
# API details:
#     Runnable Tasks: (Specific documentation on the tasks themselves, visible automatically in the Denizen extension for VS Code when you run them)
#         Loading: dmodels_load_bbmodel, dmodels_multi_load
#         Spawning: dmodels_spawn_model, dmodels_delete
#         Configuring: dmodels_reset_model_position, dmodels_set_yaw, dmodels_set_rotation, dmodels_set_scale, dmodels_set_color, dmodels_set_view_range
#         Animation related: dmodels_end_animation, dmodels_animate, dmodels_attach_to
#         Animation (internal): dmodels_move_to_frame
#     Flags:
#         Every entity spawned by DModels has the flag 'dmodel_root', that refers up to the root entity.
#         The root entity has the following flags:
#             'dmodel_model_id': the name of the model used.
#             'dmodel_parts': a list of all part entities spawned.
#             'dmodel_global_rotation' the rotation of the entire model - this also affects the rotation while the model is animating.
#             'dmodel_global_scale' the scale of the entire model.
#             'dmodel_view_range' the view range of the model.
#             'dmodel_color' the color of the model.
#             'dmodel_anim_part.<ID_HERE>': a mapping of outline IDs to the part entity spawned for them.
#             'dmodels_animation_id': only if the model is animating automatically, contains the animation ID.
#             'dmodels_anim_time': only if the model is animating automatically, contains the progress through the current animation as a number representing time.
#             'dmodels_attached_to': the entity this model is attached to, if any.
#             'dmodels_temp_alt_anim': if set to a truthy value, will tell the model to not play any auto-animations (so other scripts can indicate they need to override the default)
#        Additional flags are present on both the root and on parts, but are not considered API - use at your own risk.
#
# #########
#
# Core Animations:
# Some systems within DModels look for certain core animations to exist, and will use them when relevant.
# For example, the with the 'dmodels_attach_to' task, with the 'auto_animate' flag enabled (or the 'npcmodel' command which enables it by default), will apply animations to match the attached entity.
# List:
#     'idle': default/no activity idle animation.
#     'crouching_idle': default/no activity idle animation, while crouching (sneaking).
#     'running': the animation for moving at normal speed.
#     'sprinting': the animation for moving very fast.
#     'jump': the animation for jumping in place.
#
################################################

dmodels_config:
    type: data
    debug: false
    # You can optionally set a view range for all properly-spawned model entities.
    # If set to 0, will use the server default for display entities.
    # You can instead set to a value like 16 for only short range visibility, or 128 for super long range, or any other number.
    view_range: 0
    # You can choose which item is used to override for models.
    # Using a leather based item is recommended to allow for dynamically recoloring items.
    # Leather_Horse_Armor is ideal because other leather armors make noise when equipped.
    item: leather_horse_armor
    # You can set the resource pack path to a custom path if you want.
    # Note that the default Denizen config requires this path start under "data/"
    resource_pack_path: data/dmodels/res_pack
    # During the loading process the scale is shrunken down exactly 2.2 for items to allow bigger models in block bench so this brings it back up to default scale in-game (this is an estimate)
    default_scale: 2.2
