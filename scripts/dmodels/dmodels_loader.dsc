###########################
# This file is part of dModels / Denizen Models.
# Refer to the header of "dmodels_main.dsc" for more information.
###########################


dmodels_multi_load:
    type: task
    debug: false
    definitions: list[A ListTag of valid model names, equivalent to the ones that can be input to 'dmodels_load_bbmodel']
    description:
    - Loads multiple models simultaneously, and ends the ~wait only after all models are loaded. This is faster than doing individual 'load' calls in a loop and waiting for each.
    - This task should be ~waited for.
    script:
    - define key <util.random_uuid>
    - foreach <[list]> as:model:
        - run dmodels_multiwaitable_load def.key:<[key]> def.model:<[model]>
    # Ensure all loads are done before ending the task
    - waituntil rate:1t max:5m <server.flag[dmodels_data.temp_<[key]>.multiload].is_empty||true>
    # Cleanup
    - flag server dmodels_data.temp_<[key]>:!

dmodels_multiwaitable_load:
    type: task
    debug: false
    definitions: key|model
    script:
    - flag server dmodels_data.temp_<[key]>.multiload.<[model]>
    - ~run dmodels_load_bbmodel def.model_name:<[model]>
    - flag server dmodels_data.temp_<[key]>.multiload.<[model]>:!

dmodels_load_bbmodel:
    type: task
    debug: false
    definitions: model_name[The name of the model to load, must correspond to the relevant '.bbmodel' file.]
    description:
    - Loads a model from source '.bbmodel' file by name into server data (flags). Also builds the resource pack entries for it.
    - Should be called well in advance, when the model is added or changed. Does not need to be re-called until the model is changed again.
    - This task should be ~waited for.
    script:
    - debug log "[DModels] loading <[model_name].custom_color[emphasis]>"
    # =============== Prep ===============
    - define pack_root <script[dmodels_config].parsed_key[resource_pack_path]>
    - define models_root <[pack_root]>/assets/minecraft/models/item/dmodels/<[model_name]>
    - define textures_root <[pack_root]>/assets/minecraft/textures/dmodels/<[model_name]>
    - define item_validate <item[<script[dmodels_config].parsed_key[item]>]||null>
    - if <[item_validate]> == null:
      - debug error "[DModels] Item must be valid Example: potion"
      - stop
    - define override_item_filepath <[pack_root]>/assets/minecraft/models/item/<script[dmodels_config].parsed_key[item]>.json
    - define file data/dmodels/<[model_name]>.bbmodel
    - define scale_factor <element[0.25].div[4.0]>
    - define mc_texture_data <map>
    - flag server dmodels_data.temp_<[model_name]>:!
    # =============== BBModel loading and validation ===============
    - if !<util.has_file[<[file]>]>:
        - debug error "[DModels] Cannot load model '<[model_name]>' because file '<[file]>' does not exist."
        - stop
    - ~fileread path:<[file]> save:filedata
    - define data <util.parse_yaml[<entry[filedata].data.utf8_decode||>]||>
    - if !<[data].is_truthy>:
        - debug error "[DModels] Something went wrong trying to load BBModel data for model '<[model_name]>' - fileread invalid."
        - stop
    - define meta <[data.meta]||>
    - define resolution <[data.resolution]||>
    - if !<[meta].is_truthy> || !<[resolution].is_truthy>:
        - debug error "[DModels] Something went wrong trying to load BBModel data for model '<[model_name]>' - possibly not a valid BBModel file?"
        - stop
    - if !<[data.elements].exists>:
        - debug error "[DModels] Can't load bbmodel for '<[model_name]>' - file has no elements?"
        - stop
    # =============== Pack validation ===============
    - define packversion 13
    - if !<util.has_file[<[pack_root]>/pack.mcmeta]>:
        - run dmodels_multiwaitable_filewrite def.key:core def.path:<[pack_root]>/pack.mcmeta def.data:<map.with[pack].as[<map[pack_format=<[packversion]>;description=dModels_AutoPack_Default]>].to_json[native_types=true;indent=4].utf8_encode>
    - else if <server.flag[dmodels_last_pack_version]||0> != <[packversion]>:
        - ~fileread path:<[pack_root]>/pack.mcmeta save:mcmeta
        - define mcmeta_data <util.parse_yaml[<entry[mcmeta].data.utf8_decode>]>
        - define mcmeta_data.pack.pack_format <[packversion]>
        - run dmodels_multiwaitable_filewrite def.key:core def.path:<[pack_root]>/pack.mcmeta def.data:<[mcmeta_data].to_json[native_types=true;indent=4].utf8_encode>
    - flag server dmodels_last_pack_version:<[packversion]>
    # =============== Textures loading ===============
    - define tex_id 0
    - define texture_paths <list>
    - foreach <[data.textures]||<list>> as:texture:
        - define texname <[texture.name].to_lowercase>
        - if <[texname].ends_with[.png]>:
            - define texname <[texname].before[.png]>
        - define raw_source <[texture.source]||>
        - if !<[raw_source].starts_with[data:image/png;base64,]>:
            - debug error "[DModels] Can't load bbmodel for '<[model_name]>': invalid texture source data."
            - stop
        - define texture_output_path <[textures_root]>/<[texname]>.png
        - run dmodels_multiwaitable_filewrite def.key:<[model_name]> def.path:<[texture_output_path]> def.data:<[raw_source].after[,].base64_to_binary>
        - define proper_path dmodels/<[model_name]>/<[texname]>
        - define mc_texture_data.<[tex_id]> <[proper_path]>
        - define texture_paths:->:<[proper_path]>
        - if <[texture.particle]||false>:
            - define mc_texture_data.particle <[proper_path]>
        - define tex_id:++
    # =============== Elements loading ===============
    - foreach <[data.elements]> as:element:
        - if <[element.type]||cube> != cube:
            - foreach next
        - if !<[element.faces.north.texture].exists>:
            - foreach next
        - define element.name <[element.name].to_lowercase>
        - define element.origin <[element.origin].separated_by[,]||0,0,0>
        - define element.rotation <[element.rotation].separated_by[,]||0,0,0>
        - define flagname dmodels_data.model_<[model_name]>.namecounter_element.<[element.name]>
        - flag server <[flagname]>:++
        - if <server.flag[<[flagname]>]> > 1:
            - define element.name <[element.name]><server.flag[<[flagname]>]>
        - flag server dmodels_data.temp_<[model_name]>.raw_elements.<[element.uuid]>:<[element]>
    # =============== Outlines loading ===============
    - define root_outline null
    - foreach <[data.outliner]||<list>> as:outliner:
        - define outliner.name <[outliner.name].to_lowercase>
        - if <[outliner].matches_character_set[abcdef0123456789-]>:
            - if <[root_outline]> == null:
                - definemap root_outline name:__root__ origin:0,0,0 rotation:0,0,0 uuid:genroot_<util.random_uuid> parent:none
                - flag server dmodels_data.temp_<[model_name]>.raw_outlines.<[root_outline.uuid]>:<[root_outline]>
            - run dmodels_loader_addchild def.model_name:<[model_name]> def.parent:<[root_outline]> def.child:<[outliner]>
        - else:
            - define outliner.parent:none
            - run dmodels_loader_readoutline def.model_name:<[model_name]> def.outline:<[outliner]>
    # =============== Clear out pre-existing data ===============
    - flag server dmodels_data.model_<[model_name]>:!
    - flag server dmodels_data.animations_<[model_name]>:!
    # =============== Animations loading ===============
    - foreach <[data.animations]||<list>> as:animation:
        - define animation_list.<[animation.name]>.loop <[animation.loop]>
        - define animation_list.<[animation.name]>.override <[animation.override]>
        - define animation_list.<[animation.name]>.anim_time_update <[animation.anim_time_update]>
        - define animation_list.<[animation.name]>.blend_weight <[animation.blend_weight]>
        - define animation_list.<[animation.name]>.length <[animation.length]>
        - define animator_data <[animation.animators]||<map>>
        - foreach <server.flag[dmodels_data.temp_<[model_name]>.raw_outlines]> key:o_uuid as:outline_data:
            - define animator <[animator_data.<[o_uuid]>]||null>
            - if <[animator]> == null:
                - define animation_list.<[animation.name]>.animators.<[o_uuid]>.frames <list>
            - else:
                - foreach <[animator.keyframes]> as:keyframe:
                    - definemap anim_map channel:<[keyframe.channel]> time:<[keyframe.time]> interpolation:<[keyframe.interpolation]>
                    - if <[anim_map.interpolation]> not in catmullrom|linear|step:
                        - debug error "[DModels] Limitation while loading bbmodel for '<[model_name]>': unknown interpolation type '<[anim_map.interpolation]>', defaulting to 'linear'."
                        - define anim_map.interpolation linear
                    - define data_points <[keyframe.data_points].first>
                    - if <[keyframe.channel]> == rotation:
                        - define anim_map.data <proc[dmodels_quaternion_from_euler].context[<[data_points.x].trim.to_radians.mul[-1]>|<[data_points.y].trim.to_radians.mul[-1]>|<[data_points.z].trim.to_radians>]>
                    - else:
                        - define anim_map.data <[data_points.x].trim>,<[data_points.y].trim>,<[data_points.z].trim>
                    - define animation_list.<[animation.name]>.animators.<[o_uuid]>.frames:->:<[anim_map]>
                # Sort frames by time (why is this not done by default? BlockBench is weird)
                - define animation_list.<[animation.name]>.animators.<[o_uuid]>.frames <[animation_list.<[animation.name]>.animators.<[o_uuid]>.frames].sort_by_value[get[time]]>
    - if <[animation_list].any||false>:
        - flag server dmodels_data.animations_<[model_name]>:<[animation_list]>
    # =============== Atlas gen ===============
    - define atlas_file <[pack_root]>/assets/minecraft/atlases/blocks.json
    - waituntil rate:1t max:15s !<server.has_flag[dmodels_temp_atlas_handling]>
    - if <server.has_flag[dmodels_temp_atlas_file]>:
        - define atlas_data <util.parse_yaml[<server.flag[dmodels_temp_atlas_file].utf8_decode>]>
    - else if <util.has_file[<[atlas_file]>]>:
        - flag server dmodels_temp_atlas_handling expire:1h
        - ~fileread path:<[atlas_file]> save:atlas_file_data
        - flag server dmodels_temp_atlas_handling:!
        - define atlas_data <util.parse_yaml[<entry[atlas_file_data].data.utf8_decode>]>
    - else:
        - definemap atlas_data sources:<list>
    - define known_atlas_dirs <[atlas_data.sources].parse[get[source]].deduplicate>
    - define atlas_dirs_to_track <[texture_paths].parse[before_last[/]].deduplicate>
    - define atlas_dirs_to_add <[atlas_dirs_to_track].exclude[<[known_atlas_dirs]>]>
    - if <[atlas_dirs_to_add].any>:
        - foreach <[atlas_dirs_to_add]> as:new_dir:
            - definemap src:
                type: directory
                source: <[new_dir]>
                prefix: <[new_dir]>/
            - define atlas_data.sources:->:<[src]>
        - define new_atlas_json <[atlas_data].to_json[indent=4].utf8_encode>
        - flag server dmodels_temp_atlas_file:<[new_atlas_json]> expire:1h
        - waituntil rate:1t max:15s !<server.has_flag[dmodels_data.temp_core.filewrites.<[atlas_file].escaped>]>
        - run dmodels_multiwaitable_filewrite def.key:core def.path:<[atlas_file]> def.data:<[new_atlas_json]>
    # =============== Item model file generation ===============
    - waituntil rate:1t max:15s !<server.has_flag[dmodels_temp_item_reading]>
    - if <server.has_flag[dmodels_temp_item_file]>:
        - define override_item_data <util.parse_yaml[<server.flag[dmodels_temp_item_file].utf8_decode>]>
    - else if <util.has_file[<[override_item_filepath]>]>:
        - flag server dmodels_temp_item_reading expire:1h
        - ~fileread path:<[override_item_filepath]> save:override_item
        - flag server dmodels_temp_item_reading:!
        - define override_item_data <util.parse_yaml[<entry[override_item].data.utf8_decode>]>
    - else:
        - definemap override_item_data parent:minecraft:item/generated textures:<map[layer0=minecraft:item/<script[dmodels_config].parsed_key[item]>]>
    # NOTE: THE BELOW SECTION MUST NOT WAIT! For item override file interlock.
    - define overrides_changed false
    - foreach <server.flag[dmodels_data.temp_<[model_name]>.raw_outlines]> as:outline:
        - define outline_origin <location[<[outline.origin]>]>
        - define model_json.textures <[mc_texture_data]>
        - define model_json.elements <list>
        - define child_count 0
        #### Element building
        - foreach <server.flag[dmodels_data.temp_<[model_name]>.raw_elements]> as:element:
            - if <[outline.children].contains[<[element.uuid]>]||false>:
                - define child_count:++
                - define jsonelement.name <[element.name].to_lowercase>
                - define rot <location[<[element.rotation]>]>
                - define jsonelement.from <location[<[element.from].separated_by[,]>].sub[<[outline_origin]>].mul[<[scale_factor]>].xyz.split[,]>
                - define jsonelement.to <location[<[element.to].separated_by[,]>].sub[<[outline_origin]>].mul[<[scale_factor]>].xyz.split[,]>
                - define jsonelement.rotation.origin <location[<[element.origin]>].sub[<[outline_origin]>].mul[<[scale_factor]>].xyz.split[,]>
                - if <[rot].x> != 0:
                    - define jsonelement.rotation.axis x
                    - define jsonelement.rotation.angle <[rot].x>
                - else if <[rot].z> != 0:
                    - define jsonelement.rotation.axis z
                    - define jsonelement.rotation.angle <[rot].z>
                - else:
                    - define jsonelement.rotation.axis y
                    - define jsonelement.rotation.angle <[rot].y>
                - foreach <[element.faces]> key:faceid as:face:
                    - define jsonelement.faces.<[faceid]> <[face].proc[dmodels_facefix].context[<[resolution]>]>
                - define model_json.elements:->:<[jsonelement]>
        - define outline.children:!
        - if <[child_count]> > 0:
            #### Item override building
            - definemap json_group name:<[outline.name].to_lowercase> color:0 children:<util.list_numbers[from=0;to=<[child_count]>]> origin:<[outline_origin].mul[<[scale_factor]>].xyz.split[,]>
            - define model_json.groups <list[<[json_group]>]>
            - define model_json.display.head.translation <list[32|32|32]>
            - define model_json.display.head.scale <list[4|4|4]>
            - define modelpath item/dmodels/<[model_name]>/<[outline.name].to_lowercase>
            - run dmodels_multiwaitable_filewrite def.key:<[model_name]> def.path:<[models_root]>/<[outline.name].to_lowercase>.json def.data:<[model_json].to_json[native_types=true;indent=4].utf8_encode>
            - define cmd 0
            - define min_cmd 1000
            - foreach <[override_item_data.overrides]||<list>> as:override:
                - if <[override.model]> == <[modelpath]>:
                    - define cmd <[override.predicate.custom_model_data]>
                - define min_cmd <[min_cmd].max[<[override.predicate.custom_model_data].add[1]||1000>]>
            - if <[cmd]> == 0:
                - define cmd <[min_cmd]>
                - define override_item_data.overrides:->:<map[predicate=<map[custom_model_data=<[cmd]>]>].with[model].as[<[modelpath]>]>
                - define overrides_changed true
            - define outline.item <script[dmodels_config].parsed_key[item]>[custom_model_data=<[cmd]>;color=white]
        # This sets the actual live usage flag data
        - define rotation <[outline.rotation].split[,]>
        - define outline.rotation <proc[dmodels_quaternion_from_euler].context[<[rotation].parse[to_radians]>]>
        - flag server dmodels_data.model_<[model_name]>.<[outline.uuid]>:<[outline]>
    - if <[overrides_changed]>:
        - define override_file_json <[override_item_data].to_json[native_types=true;indent=4].utf8_encode>
        - flag server dmodels_temp_item_file:<[override_file_json]> expire:1h
        - waituntil rate:1t max:15s !<server.has_flag[dmodels_data.temp_core.filewrites.<[override_item_filepath].escaped>]>
        - run dmodels_multiwaitable_filewrite def.key:<[model_name]> def.path:<[override_item_filepath]> def.data:<[override_file_json]>
    # Ensure all filewrites are done before ending the task
    - waituntil rate:1t max:5m <server.flag[dmodels_data.temp_<[model_name]>.filewrites].is_empty||true> && <server.flag[dmodels_data.temp_core.filewrites].is_empty||true>
    # Final clear of temp data
    - flag server dmodels_data.temp_<[model_name]>:!

dmodels_multiwaitable_filewrite:
    type: task
    debug: false
    definitions: key|path|data
    script:
    - flag server dmodels_data.temp_<[key]>.filewrites.<[path].escaped>
    - ~filewrite path:<[path]> data:<[data]>
    - flag server dmodels_data.temp_<[key]>.filewrites.<[path].escaped>:!

dmodels_facefix:
    type: procedure
    debug: false
    definitions: facedata|resolution
    script:
    - define uv <[facedata.uv]>
    - define out.texture #<[facedata.texture]>
    - define mul_x <element[16].div[<[resolution.width]>]>
    - define mul_y <element[16].div[<[resolution.height]>]>
    - define out.uv <list[<[uv].get[1].mul[<[mul_x]>]>|<[uv].get[2].mul[<[mul_y]>]>|<[uv].get[3].mul[<[mul_x]>]>|<[uv].get[4].mul[<[mul_y]>]>]>
    - define out.tintindex 0
    - determine <[out]>

dmodels_loader_addchild:
    type: task
    debug: false
    definitions: model_name|parent|child
    script:
    - if <[child].matches_character_set[abcdef0123456789-]>:
        - define elementflag dmodels_data.temp_<[model_name]>.raw_elements.<[child]>
        - define element <server.flag[<[elementflag]>]||null>
        - if <[element]> == null:
            - stop
        - define valid_rots 0|22.5|45|-22.5|-45
        - define rot <location[<[element.rotation]>]>
        - define xz <[rot].x.equals[0].if_true[0].if_false[1]>
        - define yz <[rot].y.equals[0].if_true[0].if_false[1]>
        - define zz <[rot].z.equals[0].if_true[0].if_false[1]>
        - define count <[xz].add[<[yz]>].add[<[zz]>]>
        - if <[rot].x> in <[valid_rots]> && <[rot].y> in <[valid_rots]> && <[rot].z> in <[valid_rots]> && <[count]> < 2:
            - flag server dmodels_data.temp_<[model_name]>.raw_outlines.<[parent.uuid]>.children:->:<[child]>
        - else:
            - definemap new_outline name:<[parent.name]>_auto_<[element.name]> origin:<[element.origin]> rotation:<[element.rotation]> uuid:<util.random_uuid> parent:<[parent.uuid]> children:<list[<[child]>]>
            - flag server dmodels_data.temp_<[model_name]>.raw_outlines.<[new_outline.uuid]>:<[new_outline]>
            - flag server <[elementflag]>.rotation:0,0,0
            - flag server <[elementflag]>.origin:0,0,0
    - else:
        - define child.parent:<[parent.uuid]>
        - run dmodels_loader_readoutline def.model_name:<[model_name]> def.outline:<[child]>

dmodels_loader_readoutline:
    type: task
    debug: false
    definitions: model_name|outline
    script:
    - definemap new_outline name:<[outline.name]> uuid:<[outline.uuid]> origin:<[outline.origin].separated_by[,]||0,0,0> rotation:<[outline.rotation].separated_by[,]||0,0,0> parent:<[outline.parent]||none>
    - define flagname dmodels_data.model_<[model_name]>.namecounter_outline.<[outline.name]>
    - flag server <[flagname]>:++
    - if <server.flag[<[flagname]>]> > 1:
        - define new_outline.name <[new_outline.name]><server.flag[<[flagname]>]>
    - define raw_children <[outline.children]||<list>>
    - define outline.children:!
    - flag server dmodels_data.temp_<[model_name]>.raw_outlines.<[new_outline.uuid]>:<[new_outline]>
    - foreach <[raw_children]> as:child:
        - run dmodels_loader_addchild def.model_name:<[model_name]> def.parent:<[outline]> def.child:<[child]>

dmodels_quaternion_from_euler:
    type: procedure
    debug: false
    definitions: x|y|z
    description: Converts euler angles in radians to a quaternion.
    script:
    - define x_q <location[1,0,0].to_axis_angle_quaternion[<[x]>]>
    - define y_q <location[0,1,0].to_axis_angle_quaternion[<[y]>]>
    - define z_q <location[0,0,1].to_axis_angle_quaternion[<[z]>]>
    - determine <[x_q].mul[<[y_q]>].mul[<[z_q]>]>

