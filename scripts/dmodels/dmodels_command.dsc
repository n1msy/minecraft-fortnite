###########################
# This file is part of dModels / Denizen Models.
# Refer to the header of "dmodels_main.dsc" for more information.
##############

dmodels_cmd_data:
    type: data
    debug: false
    # Note: must not include the '.' symbol
    # (both for security reasons, and because that's the flag submapping key symbol)
    valid_chars: abcdefghijklmnopqrstuvwxyz0123456789_-/

dmodels_command:
    type: command
    debug: false
    name: dmodels
    usage: /dmodels [load/loadall/spawn/remove/animate/stopanimate/npcmodel/unload/unloadall/rotate/scale/color/viewrange]
    description: Manages Denizen Models.
    permission: dmodels.help
    tab completions:
        1: <proc[dmodels_tab_1]>
        2: <context.args.proc[dmodels_tab_2]>
    data:
        load_example: <&[error]>'path' should be a valid file name, for example if you have <&[emphasis]>data/dmodels/example.bbmodel<&[error]>, you should do: <&[warning]>/dmodels load example
    script:
    - define arg1 <context.args.first||help>
    - if !<[arg1].matches_character_set[<script[dmodels_cmd_data].data_key[valid_chars]>]>:
        - define arg1 help
    - if !<player.has_permission[dmodels.<[arg1]>]||<context.server>>:
        - narrate "<&[error]>You do not have permission for that."
        - stop
    - choose <[arg1]>:
        - case load:
            - if !<context.args.get[2].exists>:
                - narrate "<&[warning]>/dmodels load [path] <&[error]>- loads a model from file based on filename"
                - narrate <script.parsed_key[data.load_example]>
                - stop
            - define path <context.args.get[2]>
            - if !<[path].to_lowercase.matches_character_set[<script[dmodels_cmd_data].data_key[valid_chars]>]>:
                - narrate "<&[error]>Given file path has an invalid format. Double-check that you entered the exact name, without root path, and without the '.bbmodel' suffix."
                - narrate <script.parsed_key[data.load_example]>
                - stop
            - if !<util.has_file[data/dmodels/<[path]>.bbmodel]>:
                - narrate "<&[error]>No file exists at the given path. Double-check that you entered the exact name, without root path, and without the '.bbmodel' suffix."
                - narrate <script.parsed_key[data.load_example]>
                - stop
            - if <server.has_flag[dmodels_data.model_<[path]>]>:
                - narrate "<&[base]>That model is already loaded and will be reloaded..."
            - else:
                - narrate "<&[base]>Loading that model..."
            - debug log "[DModels] <&[emphasis]><player.name||server> <&[base]>is loading a model file: <[path].custom_color[emphasis]>"
            - ~run dmodels_load_bbmodel def.model_name:<[path]>
            - if <server.has_flag[dmodels_data.model_<[path]>]>:
                - narrate "<&[base]>Model <[path].custom_color[emphasis]> loaded."
            - else:
                - narrate "<&[error]>Unable to load that model."
        - case loadall:
            - ~run dmodels_gather_folder def.folder:data/dmodels save:list
            - define files <entry[list].created_queue.determination.first>
            - narrate "<&[base]>Loading <[files].size.custom_color[emphasis]> files..."
            - debug log "[DModels] <&[emphasis]><player.name||server> <&[base]>is loading <[files].size.custom_color[emphasis]> model files: <[files].formatted.custom_color[emphasis]>"
            - ~run dmodels_multi_load def.list:<[files]>
            - narrate <&[base]>Done!
        - case unload:
            - if !<context.args.get[2].exists>:
                - narrate "<&[warning]>/dmodels unload [model] <&[error]>- unloads a model's data from memory."
                - stop
            - define model <context.args.get[2]>
            - if !<[model].to_lowercase.matches_character_set[<script[dmodels_cmd_data].data_key[valid_chars]>]>:
                - narrate "<&[error]>Given model name has an invalid format."
                - stop
            - if !<server.has_flag[dmodels_data.model_<[model]>]>:
                - narrate "<&[error]>No such model exists, or that model has never been loaded."
                - stop
            - flag server dmodels_data.model_<[model]>:!
            - flag server dmodels_data.animations_<[model]>:!
            - narrate "<&[base]>Removed model <[model].custom_color[emphasis]> from memory."
        - case unloadall:
            - flag server dmodels_data:!
            - flag server dmodels_temp_item_file:!
            - flag server dmodels_temp_atlas_file:!
            - flag server dmodels_last_pack_version:!
            - narrate "<&[base]>Removed all DModels data from memory."
        - case spawn:
            - if !<context.args.get[2].exists>:
                - narrate "<&[warning]>/dmodels spawn [model] <&[error]>- spawns a model at your position (must be loaded)"
                - stop
            - define model <context.args.get[2]>
            - if !<[model].to_lowercase.matches_character_set[<script[dmodels_cmd_data].data_key[valid_chars]>]>:
                - narrate "<&[error]>Given model name has an invalid format."
                - stop
            - if !<server.has_flag[dmodels_data.model_<[model]>]>:
                - narrate "<&[error]>No such model exists, or that model has never been loaded."
                - stop
            - run dmodels_spawn_model def.model_name:<[model]> def.location:<player.location> save:result
            - define spawned <entry[result].created_queue.determination.first||null>
            - if !<[spawned].is_truthy>:
                - narrate "<&[error]>Spawning failed?"
                - stop
            - flag player spawned_dmodel_<[model]>:<[spawned]>
            - narrate "<&[base]>Spawned model <[model].custom_color[emphasis]> with root entity <[spawned].uuid.custom_color[emphasis]>, stored to player flag '<&[emphasis]>spawned_dmodel_<[model]><&[base]>'"
        - case remove:
            - inject dmodels_get_target
            - define model <[target].flag[dmodel_model_id]>
            - run dmodels_delete def.root_entity:<[target]>
            - narrate "<&[base]>Removed a spawned copy of model <[model].custom_color[emphasis]>."
        - case animate:
            - if !<context.args.get[2].exists>:
                - narrate "<&[warning]>/dmodels animate [animation] <&[error]>- causes the closest real-spawned model to start playing the given animation"
                - stop
            - define animation <context.args.get[2]>
            - if !<[animation].to_lowercase.matches_character_set[<script[dmodels_cmd_data].data_key[valid_chars]>]>:
                - narrate "<&[error]>Given animation name contains an invalid format."
                - stop
            - inject dmodels_get_target
            - if !<server.has_flag[dmodels_data.animations_<[target].flag[dmodel_model_id]>.<[animation]>]||null>:
                - narrate "<&[error]>Unknown animation name given. Available animations: <&[emphasis]><server.flag[dmodels_data.animations_<[target].flag[dmodel_model_id]>].keys.formatted||None>"
            - run dmodels_animate def.root_entity:<[target]> def.animation:<[animation]>
            - narrate "<&[base]>Model <[target].flag[dmodel_model_id].custom_color[emphasis]> is now playing animation <[animation].custom_color[emphasis]>"
        - case stopanimate:
            - inject dmodels_get_target
            - if !<[target].has_flag[dmodels_animation_id]>:
                - narrate "<&[base]>Your nearest model is not animating currently."
                - stop
            - run dmodels_end_animation def.root_entity:<[target]>
            - narrate "<&[base]>Animation stopped."
        - case npcmodel:
            - if !<player.selected_npc.exists>:
                - narrate "<&[error]>You do not have any NPC selected."
                - stop
            - adjust <queue> linked_npc:<player.selected_npc>
            - if !<context.args.get[2].exists>:
                - narrate "<&[warning]>/dmodels npcmodel [model] <&[error]>- sets an NPC to render as a given model (must be loaded). Use 'none' to remove the model."
                - stop
            - define model <context.args.get[2]>
            - if !<[model].to_lowercase.matches_character_set[<script[dmodels_cmd_data].data_key[valid_chars]>]>:
                - narrate "<&[error]>Given model name has an invalid format."
                - stop
            - if <[model]> == none:
                - flag <npc> dmodels_model:!
                - if <npc.scripts.parse[name].contains[dmodels_npc_assignment]||false>:
                    - run dmodels_npc_despawn
                    - assignment remove script:dmodels_npc_assignment
                - narrate "<&[base]>NPC <npc.id.custom_color[emphasis]> (<npc.name><&[base]>) will now render as a normal NPC."
                - stop
            - if !<server.has_flag[dmodels_data.model_<[model]>]>:
                - narrate "<&[error]>No such model exists, or that model has never been loaded."
                - stop
            - flag <npc> dmodels_model:<[model]>
            - if !<npc.scripts.parse[name].contains[dmodels_npc_assignment]||false>:
                - assignment add script:dmodels_npc_assignment
            - else:
                - run dmodels_npc_despawn
                - run dmodels_npc_spawn
            - narrate "<&[base]>NPC <npc.id.custom_color[emphasis]> (<npc.name><&[base]>) will now render as model <[model].custom_color[emphasis]>"
        - case rotate:
            - if !<context.args.get[2].exists>:
                - narrate "<&[warning]>/dmodels rotate [rotation] <&[error]>- sets the rotation of the nearest real-spawned model to the given euler angles. Use '0,0,0' for default."
                - stop
            - define rotation <location[<context.args.get[2].split[,].parse[to_radians].comma_separated>]||null>
            - if <[rotation]> == null:
                - narrate "<&[error]>Given rotation is invalid must be in the form xrot,yrot,zrot, eg '90,0,0'."
                - stop
            - inject dmodels_get_target
            - run dmodels_set_rotation def.root_entity:<[target]> def.quaternion:<proc[dmodels_quaternion_from_euler].context[<[rotation].xyz.split[,]>]>
            - narrate "<&[base]>Model <[target].flag[dmodel_model_id].custom_color[emphasis]> rotation is now <[rotation].xyz.split[,].parse[to_degrees].parse[round_up_to_precision[0.01]].comma_separated>"
        - case scale:
            - if !<context.args.get[2].exists>:
                - narrate "<&[warning]>/dmodels scale [scale] <&[error]>- sets the scale-multiplier of the nearest real-spawned model set to the given value. Use '1,1,1' for default."
                - stop
            - define scale <location[<context.args.get[2]>]||null>
            - if <[scale]> == null:
                - narrate "<&[error]>Given scale is invalid must be in the form 1,1,1."
                - stop
            - inject dmodels_get_target
            - run dmodels_set_scale def.root_entity:<[target]> def.scale:<[scale]>
        - case color:
            - if !<context.args.get[2].exists>:
                - narrate "<&[warning]>/dmodels color [color] <&[error]>- sets the color of the nearest real-spawned model to the given color. Use 'white' for default."
                - stop
            - define color <color[<context.args.get[2]>]||null>
            - if <[color]> == null:
                - narrate "<&[error]>Given color is invalid must be in the form red/255,0,0."
            - inject dmodels_get_target
            - run dmodels_set_color def.root_entity:<[target]> def.color:<[color]>
            - narrate "<&[base]>Model <[target].flag[dmodel_model_id].custom_color[emphasis]> color is now <[color].hex>"
        - case viewrange:
            - if !<context.args.get[2].exists>:
                - narrate "<&[warning]>/dmodels viewrange [range] <&[error]>- sets the view-range of the nearest real-spawned model to the given range (in blocks)."
                - stop
            - inject dmodels_get_target
            - define view_range <context.args.get[2]>
            - run dmodels_set_view_range def.root_entity:<[target]> def.view_range:<[view_range]>
            - narrate "<&[base]>Model <[target].flag[dmodel_model_id].custom_color[emphasis]> view range is now <[view_range]>"
        # help
        - default:
            - if <player.has_permission[dmodels.load]||true>:
                - narrate "<&[warning]>/dmodels load [path] <&[error]>- loads a model from file based on filename"
            - if <player.has_permission[dmodels.loadall]||true>:
                - narrate "<&[warning]>/dmodels loadall <&[error]>- loads all models in the source folder"
            - if <player.has_permission[dmodels.unload]||true>:
                - narrate "<&[warning]>/dmodels unload [model] <&[error]>- unloads a specific model from memory"
            - if <player.has_permission[dmodels.unloadall]||true>:
                - narrate "<&[warning]>/dmodels unloadall <&[error]>- unloads all DModels data from memory"
            - if <player.has_permission[dmodels.spawn]||true>:
                - narrate "<&[warning]>/dmodels spawn [model] <&[error]>- spawns a model at your position (must be loaded)"
            - if <player.has_permission[dmodels.remove]||true>:
                - narrate "<&[warning]>/dmodels remove <&[error]>- removes the closest real-spawned model to your location"
            - if <player.has_permission[dmodels.animate]||true>:
                - narrate "<&[warning]>/dmodels animate [animation] <&[error]>- causes the closest real-spawned model to start playing the given animation"
            - if <player.has_permission[dmodels.stopanimate]||true>:
                - narrate "<&[warning]>/dmodels stopanimate <&[error]>- causes the closest real-spawned model to stop animating"
            - if <player.has_permission[dmodels.npcmodel]||true>:
                - narrate "<&[warning]>/dmodels npcmodel [model] <&[error]>- sets an NPC to render as a given model (must be loaded). Use 'none' to remove the model."
            - if <player.has_permission[dmodels.rotate]||true>:
                - narrate "<&[warning]>/dmodels rotate [rotation] <&[error]>- sets the rotation of the nearest real-spawned model to the given euler angles. Use '0,0,0' for default."
            - if <player.has_permission[dmodels.scale]||true>:
                - narrate "<&[warning]>/dmodels scale [scale] <&[error]>- sets the scale-multiplier of the nearest real-spawned model set to the given value. Use '1,1,1' for default."
            - if <player.has_permission[dmodels.color]||true>:
                - narrate "<&[warning]>/dmodels color [color] <&[error]>- sets the color of the nearest real-spawned model to the given color. Use 'white' for default."
            - if <player.has_permission[dmodels.viewrange]||true>:
                - narrate "<&[warning]>/dmodels viewrange [range] <&[error]>- sets the view-range of the nearest real-spawned model to the given range (in blocks)."
            - narrate "<&[warning]>/dmodels help <&[error]>- this help output"

dmodels_get_target:
    type: task
    debug: false
    script:
    - define target <player.location.find_entities[dmodel_part_display].within[10].filter[has_flag[dmodel_model_id]].first||null>
    - if !<[target].is_truthy>:
        - narrate "<&[error]>No spawned model is close enough. Are you near a model? If so, are you sure it's an independent real-spawned model (as opposed to fake-spawned, or separately attached)?"
        - stop

dmodels_tab_1:
    type: procedure
    debug: false
    script:
    - define list <list>
    - foreach load|loadall|spawn|remove|animate|stopanimate|npcmodel|help|unload|unloadall|rotate|scale|color|viewrange as:key:
        - if <player.has_permission[dmodels.<[key]>]||true>:
            - define list:->:<[key]>
    - determine <[list]>

dmodels_tab_2:
    type: procedure
    debug: false
    definitions: args
    script:
    - if !<[args].first.matches_character_set[<script[dmodels_cmd_data].data_key[valid_chars]>]> || !<player.has_permission[dmodels.<[args].first>]||true>:
        - determine <list>
    - if <[args].first> == load:
        - define path <[args].get[2]||>
        - if !<[path].to_lowercase.matches_character_set[<script[dmodels_cmd_data].data_key[valid_chars]>]>:
            - determine <list>
        - if <[path].contains[/]>:
            - define path <[path].before_last[/]>
        - else:
            - define path <empty>
        - determine <util.list_files[data/dmodels/<[path]>].parse[before_last[.bbmodel]]||<list>>
    - if !<server.has_flag[dmodels_data]>:
        - determine <list>
    - if <[args].first> in spawn|unload:
        - determine <server.flag[dmodels_data].keys.filter[starts_with[model_]].parse[after[model_]]>
    - else if <[args].first> == npcmodel:
        - determine <server.flag[dmodels_data].keys.filter[starts_with[model_]].parse[after[model_]].include[none]>
    - else if <[args].first> == animate:
        - define target <player.location.find_entities[dmodel_part_display].within[10].filter[has_flag[dmodel_model_id]].first||null>
        - if !<[target].is_truthy>:
            - determine <list>
        - determine <server.flag[dmodels_data.animations_<[target].flag[dmodel_model_id]>].keys||<list>>
    - else if <[args].first> == color:
        - determine <util.color_names>
    - determine <list>

dmodels_gather_folder:
    type: task
    debug: false
    definitions: folder
    script:
    - define output <list>
    - foreach <util.list_files[<[folder]>]||<list>> as:file:
        - define full_file <[folder]>/<[file]>
        - if <[file].ends_with[.bbmodel]>:
            - define clean_name <[full_file].after[data/dmodels/].before_last[.bbmodel]>
            - if !<[clean_name].to_lowercase.matches_character_set[<script[dmodels_cmd_data].data_key[valid_chars]>]>:
                - narrate "<&[error]>Skipping file <[file].custom_color[emphasis]> due to invalid file name format"
            - else:
                - define output:->:<[clean_name]>
        - else if !<[file].contains[.]>:
            - run dmodels_gather_folder def.folder:<[full_file]> save:subdata
            - define output:|:<entry[subdata].created_queue.determination.first>
    - determine <[output]>
