###########################
# This loads animations for Denizen Player Models including any external bones utilized
# in the animations which are then put into a resource pack
###########################

pmodels_load_bbmodel:
    type: task
    description: Loads all animations for Denizen Player Models. If you use waitable ~ on this task you can get the animation count.
    debug: false
    script:
    # =============== Clear out pre-existing data ===============
    - flag server pmodels_data.model_player_model_template_norm:!
    - flag server pmodels_data.model_player_model_template_slim:!
    - flag server pmodels_data.animations_player_model_template_norm:!
    - flag server pmodels_data.animations_player_model_template_slim:!
    # ============== Startup ===============
    - define animation_files <util.list_files[data/pmodels/animations]||null>
    - define pack_root data/pmodels/denizen_player_models_pack
    - define item_validate <item[<script[pmodel_config].data_key[config].get[item]>]||null>
    - define override_item_filepath <[pack_root]>/assets/minecraft/models/item/<script[pmodel_config].data_key[config].get[item]>.json
    - define scale_factor <element[0.25].div[4.0]>
    - define template_data <script[pmodel_config].data_key[templates]||null>
    - define norm_data <[template_data.classic]||null>
    - define slim_data <[template_data.slim]||null>
    - if <[norm_data]> == null || <[slim_data]> == null || <[template_data]> == null:
      - debug error "Could not find templates for player models in config"
      - stop
    - define pmodels_data.template_data.norm:<[norm_data]>
    - define pmodels_data.template_data.slim:<[slim_data]>
    - define norm_models <[norm_data.models]>
    - define slim_models <[slim_data.models]>
    - define find_bone <script[pmodels_excluded_bones].data_key[bones]>
    - define tex_load_order <proc[pmodels_tex_load_order]>
    # =============== Pack validation ===============
    - if !<util.has_file[<[pack_root]>/pack.mcmeta]>:
        - define pack_version 13
        - ~filewrite path:<[pack_root]>/pack.mcmeta data:<map.with[pack].as[<map[pack_format=<[pack_version]>;description=denizen_player_models_pack]>].to_json[native_types=true;indent=4].utf8_encode>
        - ~filewrite path:<[pack_root]>/pack.png data:<proc[pmodels_denizen_logo_proc].base64_to_binary>
    - if <[item_validate]> == null:
        - debug error "[Denizen Player Models] Warning: The item specified in the config is an invalid item external bones will not generate"
        - stop
    - if <[animation_files]> == null:
        - debug error "[Denizen Player Models] Could not find animations folder in data/pmodels"
        - stop
    - else if <[animation_files].is_empty>:
        - debug error "[Denizen Player Models] Could not find player model animations in data/pmodels/animations"
        - stop
    # ============== Animation loading ===========
    - foreach <[animation_files]> as:anim_file_raw:
        - if <[anim_file_raw].ends_with[.bbmodel]>:
            - define animation_file <[anim_file_raw].replace[.bbmodel].with[<empty>]>
        - else:
            - foreach next
        # =============== Prep ===============
        - define models_root <[pack_root]>/assets/minecraft/models/item/pmodels/<[animation_file]>
        - define textures_root <[pack_root]>/assets/minecraft/textures/pmodels/<[animation_file]>
        - define file data/pmodels/animations/<[animation_file]>.bbmodel
        - define mc_texture_data <map>
        - flag server pmodels_data.temp_<[animation_file]>:!
        # =============== BBModel loading and validation ===============
        - if !<util.has_file[<[file]>]>:
            - debug error "[Denizen Player Models] Cannot load model '<[animation_file]>' because file '<[file]>' does not exist."
            - stop
        - ~fileread path:<[file]> save:filedata
        - define data <util.parse_yaml[<entry[filedata].data.utf8_decode||>]||>
        - if !<[data].is_truthy>:
            - debug error "[Denizen Player Models] Something went wrong trying to load BBModel data for model '<[animation_file]>' - fileread invalid."
            - stop
        - define meta <[data.meta]||>
        - define resolution <[data.resolution]||>
        - if !<[meta].is_truthy> || !<[resolution].is_truthy>:
            - debug error "[Denizen Player Models] Something went wrong trying to load BBModel data for model '<[animation_file]>' - possibly not a valid BBModel file?"
            - stop
        - if !<[data.elements].exists>:
            - debug error "[Denizen Player Models] Can't load bbmodel for '<[animation_file]>' - file has no elements?"
            - stop
        # =============== Elements loading ===============
        - define texture_exclude_id null
        # Reason for loading elements before is to skip the player model texture
        - foreach <[data.elements]> as:element:
            - if <[element.type]> != cube:
                - foreach next
            - define name <[element.name]>
            # Excluded player model texture id
            - choose <[name]>:
                - case skin:
                    - define texture_exclude_id <[element.faces.north.texture]>
                - case hat:
                    - define texture_exclude_id <[element.faces.north.texture]>
            - define element.origin <[element.origin].separated_by[,]||0,0,0>
            - define element.rotation <[element.rotation].separated_by[,]||0,0,0>
            - define flagname pmodels_data.model_<[animation_file]>.namecounter_element.<[element.name]>
            - flag server <[flagname]>:++
            - if <server.flag[<[flagname]>]> > 1:
                - define element.name <[element.name]><server.flag[<[flagname]>]>
            - flag server pmodels_data.temp_<[animation_file]>.raw_elements.<[element.uuid]>:<[element]>
        # =============== Textures loading ===============
        - define tex_id 0
        - define texture_paths <list>
        - foreach <[data.textures]||<list>> as:texture:
            - define texname <[texture.name]>
            - if <[texname].ends_with[.png]>:
                - define texname <[texname].before[.png]>
            - if <[texname]> == steve_template:
                - foreach next
            - define raw_source <[texture.source]||>
            - if !<[raw_source].starts_with[data:image/png;base64,]>:
                - debug error "Can't load bbmodel for '<[animation_file]>': invalid texture source data."
                - stop
            - define texture_output_path <[textures_root]>/<[texname]>.png
            - if <[item_validate]> != null:
              - ~filewrite path:<[texture_output_path]> data:<[raw_source].after[,].base64_to_binary>
            - define proper_path pmodels/<[animation_file]>/<[texname]>
            - define mc_texture_data.<[tex_id]> <[proper_path]>
            - define texture_paths:->:<[proper_path]>
            - if <[texture.particle]||false>:
                - define mc_texture_data.particle <[proper_path]>
            - define tex_id:++
        # =============== Outlines loading ===============
        - define root_outline null
        - foreach <[data.outliner]||<list>> as:outliner:
            - if <[outliner].matches_character_set[abcdef0123456789-]>:
                - if <[root_outline]> == null:
                    - definemap root_outline name:__root__ origin:0,0,0 rotation:0,0,0 uuid:<util.random_uuid>
                    - flag server pmodels_data.temp_<[animation_file]>.raw_outlines.<[root_outline.uuid]>:<[root_outline]>
                - run pmodels_loader_addchild def.animation_file:<[animation_file]> def.parent:<[root_outline]> def.child:<[outliner]>
            - else:
                - define outliner.parent:none
                - run pmodels_loader_readoutline def.animation_file:<[animation_file]> def.outline:<[outliner]>
        # =============== Animations loading ===============
        - foreach <[data.animations]||<list>> as:animation:
            - define anim_count:++
            - if !<server.has_flag[pmodels_data.temp_<[animation_file]>.raw_outlines]>:
              - foreach next
            - define animation_list.<[animation.name]>.loop <[animation.loop]>
            - define animation_list.<[animation.name]>.length <[animation.length]>
            - define animator_data <[animation.animators]||<map>>
            - foreach <server.flag[pmodels_data.temp_<[animation_file]>.raw_outlines]> key:o_uuid as:outline_data:
              - define animator <[animator_data.<[o_uuid]>]||null>
              - if <[animator]> == null:
                - define animation_list.<[animation.name]>.animators.<[o_uuid]>.frames <list>
              - else:
                - define keyframes <[animator.keyframes]>
                - foreach <[keyframes]> as:keyframe:
                    - define channel <[keyframe.channel]>
                    - definemap anim_map channel:<[channel]> time:<[keyframe.time]> interpolation:<[keyframe.interpolation]>
                    - define data_points <[keyframe.data_points].first>
                    - if <[channel]> == rotation:
                        - define anim_map.data <proc[pmodels_quaternion_from_euler].context[<[data_points.x].trim.to_radians.mul[-1]>|<[data_points.y].trim.to_radians.mul[-1]>|<[data_points.z].trim.to_radians>]>
                    - else:
                        - define anim_map.data <[data_points.x].trim>,<[data_points.y].trim>,<[data_points.z].trim>
                    - define animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.<[channel]>:->:<[anim_map]>
                # Time sort
                - foreach position|rotation|scale as:channel:
                  - if <[animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.<[channel]>].exists>:
                    - define animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.<[channel]> <[animation_list.<[animation.name]>.animators.<[o_uuid]>.frames.<[channel]>].sort_by_value[get[time]]>
        # =============== Atlas gen ===============
        - define atlas_file <[pack_root]>/assets/minecraft/atlases/blocks.json
        - waituntil rate:1t max:15s !<server.has_flag[pmodels_temp_atlas_handling]>
        - if <server.has_flag[pmodels_temp_atlas_file]>:
            - define atlas_data <util.parse_yaml[<server.flag[pmodels_temp_atlas_file].utf8_decode>]>
        - else if <util.has_file[<[atlas_file]>]>:
            - flag server pmodels_temp_atlas_handling expire:1h
            - ~fileread path:<[atlas_file]> save:atlas_file_data
            - flag server pmodels_temp_atlas_handling:!
            - define atlas_data <util.parse_yaml[<entry[atlas_file_data].data.utf8_decode>]>
        - else:
            - definemap atlas_data sources:<list>
        - define atlas_sources <[atlas_data.sources]>
        - define player_model_check <[atlas_sources].filter[get[source].equals[player_animator/template]]>
        - if <[player_model_check].is_empty>:
          - definemap src type:directory source:player_animator/template prefix:player_animator/template/
          - define atlas_data.sources:->:<[src]>
          - define new_sources true
        - define known_atlas_dirs <[atlas_sources].parse[get[source]].deduplicate>
        - define atlas_dirs_to_track <[texture_paths].parse[before_last[/]].deduplicate>
        - define atlas_dirs_to_add <[atlas_dirs_to_track].exclude[<[known_atlas_dirs]>]>
        - if <[new_sources]||false> || <[atlas_dirs_to_add].any>:
            - foreach <[atlas_dirs_to_add]> as:new_dir:
                - definemap src:
                    type: directory
                    source: <[new_dir]>
                    prefix: <[new_dir]>/
                - define atlas_data.sources:->:<[src]>
            - define new_atlas_json <[atlas_data].to_json[indent=4].utf8_encode>
            - flag server pmodels_temp_atlas_file:<[new_atlas_json]> expire:1h
            - ~filewrite path:<[atlas_file]> data:<[new_atlas_json]>
        # =============== Item model file generation ===============
        - if <util.has_file[<[override_item_filepath]>]>:
            - ~fileread path:<[override_item_filepath]> save:override_item
            - define override_item_data <util.parse_yaml[<entry[override_item].data.utf8_decode>]>
        - else:
            - definemap override_item_data:
                parent: minecraft:item/generated
                textures: <map[layer0=minecraft:item/<script[pmodel_config].data_key[config].get[item]||splash_potion>]>
        - define overrides_changed false
        - foreach <server.flag[pmodels_data.temp_<[animation_file]>.raw_outlines]> as:outline:
            - define outline_origin <location[<[outline.origin]>]>
            - define model_json.textures <[mc_texture_data]>
            - define model_json.elements <list>
            - define child_count 0
            #### Element building
            - foreach <server.flag[pmodels_data.temp_<[animation_file]>.raw_elements]> as:element:
                - if <[outline.children].contains[<[element.uuid]>]||false>:
                    - define child_count:++
                    - define jsonelement.name <[element.name]>
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
                        - define jsonelement.faces.<[faceid]> <[face].proc[pmodels_facefix].context[<[resolution]>]>
                    - define model_json.elements:->:<[jsonelement]>
            - define outline.children:!
            # Check for player model bones if they are there do not generate the item file
            - define find <[find_bone].find[<[outline.name]>]>
            - if <[child_count]> > 0 && <[find]> == -1:
                #### Item override building
                - definemap json_group:
                    name: <[outline.name]>
                    color: 0
                    children: <util.list_numbers[from=0;to=<[child_count]>]>
                    origin: <[outline_origin].mul[<[scale_factor]>].xyz.split[,]>
                - define model_json.groups <list[<[json_group]>]>
                - define model_json.display.head.translation <list[32|32|32]>
                - define model_json.display.head.scale <list[4|4|4]>
                - define modelpath item/pmodels/<[animation_file]>/<[outline.name]>
                - if <[item_validate]> != null:
                    - ~filewrite path:<[models_root]>/<[outline.name]>.json data:<[model_json].to_json[native_types=true;indent=4].utf8_encode>
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
                - define outline.item <script[pmodel_config].data_key[config].get[item]>[custom_model_data=<[cmd]>]
                # Identifier for external bone
                - define outline.type external
            ## Sets actual live usage data
            #- if <[find]> == -1:
            #    - define external_count:++
             #   - define rotation <[outline.rotation].split[,]>
             #   - define outline.rotation <proc[pmodels_quaternion_from_euler].context[<[rotation].parse[to_radians]>]>
              #  - define temp_default_data.classic.<[outline.uuid]>:<[outline]>
            #    - define temp_default_data.slim.<[outline.uuid]>:<[outline]>
            #    - foreach next
            #- foreach <[norm_models]> key:uuid as:model:
            #    - if <[outline.uuid]> == <[uuid]>:
            #        - define outline.type default
            #        - define outline.origin <[model.origin]>
             #       - define temp_default_data.classic.<[uuid]>:<[outline]>
            #- foreach <[slim_models]> key:uuid as:model:
            #    - if <[outline.uuid]> == <[uuid]>:
            #        - define outline.type default
            #        - define outline.origin <[model.origin]>
            #        - define temp_default_data.slim.<[uuid]>:<[outline]>
        - if <[item_validate]> != null && <[overrides_changed]>:
            - ~filewrite path:<[override_item_filepath]> data:<[override_item_data].to_json[native_types=true;indent=4].utf8_encode>
        # Final clear of temp data
        - flag server pmodels_data.temp_<[animation_file]>:!
        #- if !<[temp_default_data].exists>:
        #    - foreach next
        #- define external_bones_classic <[temp_default_data.classic].filter_tag[<[find_bone].find[<[filter_value.name]>].equals[-1]>]>
        #- define external_bones_slim <[temp_default_data.slim].filter_tag[<[find_bone].find[<[filter_value.name]>].equals[-1]>]>
        #- foreach <[external_bones_classic]> key:uuid as:model:
        #    - define pmodels_data.model_player_model_template_norm.<[animation_file]>.<[uuid]>:<[model]>
        #- foreach <[external_bones_slim]> key:uuid as:model:
        #    - define pmodels_data.model_player_model_template_slim.<[animation_file]>.<[uuid]>:<[model]>
    # Set the animations
    - if <[animation_list].any||false>:
        - define pmodels_data.animations_player_model_template_norm <[animation_list]>
        - define pmodels_data.animations_player_model_template_slim <[animation_list]>
    #= Default template loading
    - foreach <[tex_load_order]> as:tex_name:
        - foreach <[norm_models]> key:uuid as:model:
            - if <[tex_name]> == <[model.name]>:
                - define model.type default
                - define pmodels_data.model_player_model_template_norm.<[uuid]>:<[model]>
        - foreach <[slim_models]> key:uuid as:model:
            - if <[tex_name]> == <[model.name]>:
                - define model.type default
                - define pmodels_data.model_player_model_template_slim.<[uuid]>:<[model]>
    - if <[pmodels_data].any||false>:
        - flag server pmodels_data:<[pmodels_data]>
    - debug log "[Denizen Player Models] Loaded <[anim_count]||0> animations."
    #- if <[external_count].exists>:
    #  - debug log "[Denizen Player Models] <[external_count]> External bones have been loaded."
    - determine <[anim_count]||0>

pmodels_excluded_bones:
    type: data
    description: Bones to exclude from player model loading
    bones:
    - player_root
    - head
    - hip
    - waist
    - chest
    - right_arm
    - right_forearm
    - left_arm
    - left_forearm
    - right_leg
    - right_foreleg
    - left_leg
    - left_foreleg

pmodels_tex_load_order:
    type: procedure
    debug: false
    script:
    - determine <list[player_root|head|hip|waist|chest|right_arm|right_forearm|left_arm|left_forearm|right_leg|right_foreleg|left_leg|left_foreleg]>

pmodels_facefix:
    type: procedure
    description: Facefix to fix the UVs of any external bones in the player model loading
    debug: false
    definitions: facedata|resolution
    script:
    - define uv <[facedata.uv]>
    - define out.texture #<[facedata.texture]>
    - define mul_x <element[16].div[<[resolution.width]>]>
    - define mul_y <element[16].div[<[resolution.height]>]>
    - define out.uv <list[<[uv].get[1].mul[<[mul_x]>]>|<[uv].get[2].mul[<[mul_y]>]>|<[uv].get[3].mul[<[mul_x]>]>|<[uv].get[4].mul[<[mul_y]>]>]>
    - determine <[out]>

pmodels_loader_addchild:
    type: task
    description: Adds a child to a parent bone
    debug: false
    definitions: animation_file|parent|child
    script:
    - if <[child].matches_character_set[abcdef0123456789-]>:
        - define elementflag pmodels_data.temp_<[animation_file]>.raw_elements.<[child]>
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
            - flag server pmodels_data.temp_<[animation_file]>.raw_outlines.<[parent.uuid]>.children:->:<[child]>
        - else:
            - definemap new_outline name:<[parent.name]>_auto_<[element.name]> origin:<[element.origin]> rotation:<[element.rotation]> uuid:<util.random_uuid> parent:<[parent.uuid]> children:<list[<[child]>]>
            - flag server pmodels_data.temp_<[animation_file]>.raw_outlines.<[new_outline.uuid]>:<[new_outline]>
            - flag server <[elementflag]>.rotation:0,0,0
            - flag server <[elementflag]>.origin:0,0,0
    - else:
        - define child.parent:<[parent.uuid]>
        - run pmodels_loader_readoutline def.animation_file:<[animation_file]> def.outline:<[child]>

pmodels_loader_readoutline:
    type: task
    description: Reads an outline from a JSON file
    debug: false
    definitions: animation_file|outline
    script:
    - definemap new_outline name:<[outline.name]> uuid:<[outline.uuid]> origin:<[outline.origin].separated_by[,]||0,0,0> rotation:<[outline.rotation].separated_by[,]||0,0,0> parent:<[outline.parent]||none>
    - define flagname pmodels_data.model_<[animation_file]>.namecounter_outline.<[outline.name]>
    - define raw_children <[outline.children]||<list>>
    - define outline.children:!
    - flag server pmodels_data.temp_<[animation_file]>.raw_outlines.<[new_outline.uuid]>:<[new_outline]>
    - foreach <[raw_children]> as:child:
        - run pmodels_loader_addchild def.animation_file:<[animation_file]> def.parent:<[outline]> def.child:<[child]>

pmodels_quaternion_from_euler:
    type: procedure
    debug: false
    definitions: x|y|z
    description: Converts euler angles in radians to a quaternion.
    script:
    - define x_q <location[1,0,0].to_axis_angle_quaternion[<[x]>]>
    - define y_q <location[0,1,0].to_axis_angle_quaternion[<[y]>]>
    - define z_q <location[0,0,1].to_axis_angle_quaternion[<[z]>]>
    - determine <[x_q].mul[<[y_q]>].mul[<[z_q]>]>

pmodels_denizen_logo_proc:
    type: procedure
    description: Procedure that contains the Denizen logo
    debug: false
    script:
    - determine iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAACXBIWXMAAAsSAAALEgHS3X78AAADAFBMVEX///8BAQL87pX875n+///97pP68Jn87pYAAAD77pYAAAH77ZYCAwL6+vv87Zb/+p79/v377Jj764/77ZUBAQX87Zj//v/+7ZhdXV2lnYP58JX8/P377Zj+7Jj97Zj77Zf87ZX77pUAAAH47pv/7Zr97Zf87Zf67JT67pgpKSn775P/8pwFAQX+/vvp6en/+Jv///z77pEaGhiJhWH975f575sGBQj375z///778JH67pIDAgz97Z0FBgTl5+IBAQf+//8vKxP765T8/Pz58JD775T865f77ZT87ZptbXP675X5+/b78JT//qD87Z3f1X+Ki4r37pzs5Yz/8535+fn8/fgpJyEsJyHe1X8pJyL97Zb97ZP97pESERHLysz39/cKCQdEREg2Oz387pNwaljf2H//8KD/8J/+9JgNDA0kHxb/95/565H/96OSkpL97Jj67pv/8pT865+zs7Olnnvs5Y/37JD97pj///n4+vo/Oyr/9Kn46pS7vL02OzhVTC3+8JPo6ej+7ZVVVlj/+pP97o00MzT78Zf/+ZcYFxf8+/z/9pFLTVD+/////Jnk5uFSSjP36ZZWTzGWlpYlJSX57pj+7pf67prc3Nyurq6enZ/475ZjXTyYkFvl5eXQ0ND88Jz67YlUUTw1Lh/t6Kb77phbW1r9/P5ZVz7y8/JeXmG3tXr78Iumnnb86aJmZWv18/YNCxr464yYkWaMiGb/+aVUTza4soX//7HHx8fo35Lu45eknG2lnYLy7Y/T1NFCQ0Hp4Kjw8O7w5pttZ0y/wL8eHx/56Zz37ore1ZLy6pUVEgv+//20q3epqqv+9KF3dnXWzpD28KxGPS2Fglajpqj8//0/PR/m359YVEc7OT0+O0P16IsuLi716ZP/8osVEQjq6Jnx651ycnKLglozLxNFQ0GtpnFtbXXv54z885vIvX1KRjJ9foLa0p1/dlLW1NSVkG1jX0SIiJEZHCb6+p/18pD2+PPNyYj8+omgoWvCu3xpZVHJuph2cFbIxZqlkjgZAAAGcUlEQVRYw7WXB1wTVxzHX07LvcviQoYtDebuQyXINLVGJMYoiSGFD1ZtqBZlaByACIoWKWALdTI+otS6cO+9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
