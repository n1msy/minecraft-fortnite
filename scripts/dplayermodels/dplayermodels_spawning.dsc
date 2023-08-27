pmodels_skin_type:
    type: procedure
    description: Determines if the player has a classic skin or slim skin
    debug: false
    definitions: player[(PlayerTag) - The player or npc to collect the skin texture from]
    script:
    - if <[player].is_npc||false>:
      - determine <util.parse_yaml[<npc[<[player]>].skin_blob.before[;].base64_to_binary.utf8_decode>].deep_get[textures.skin.metadata.model]||classic>
    - else if <[player].is_player||false> && <[player].is_online||false>:
      - determine <util.parse_yaml[<[player].skin_blob.before[;].base64_to_binary.utf8_decode>].deep_get[textures.skin.metadata.model]||classic>
    - determine null

pmodel_part_display:
    type: entity
    debug: false
    entity_type: item_display

pmodels_spawn_model:
    type: task
    description: Spawns the player model at the location specified including if it should be only shown to a player
    debug: false
    definitions: location[LocationTag]|player[PlayerTag/NPCTag]|scale[LocationTag]|rotation[QuaternionTag]|fake_to[PlayerTag]
    script:
    - if !<[player].is_npc||false> && !<[player].is_player||false>:
        - debug error "[Denizen Player Models] Must specify a valid player or npc to spawn the player model."
        - stop
    - define skin_type <[player].flag[pmodels_player_skin_type]||<[player].proc[pmodels_skin_type]>>
    - choose <[skin_type]>:
      - case classic:
        - define model_name player_model_template_norm
      - case slim:
        - define model_name player_model_template_slim
      - default:
        - debug error "[Denizen Player Models] <red>Something went wrong in pmodels_spawn_model invalid skin type."
        - stop
    - if !<server.has_flag[pmodels_data.model_<[model_name]>]>:
        - debug error "[Denizen Player Models] <red>Cannot spawn model <[model_name]>, model not loaded"
        - stop
    - define center <[location].with_pitch[0].above[0.5]>
    - define global_rot <quaternion[<[rotation]||identity>]>
    - define global_scale <location[<[scale]||1,1,1>]>
    - define yaw_quaternion <location[0,1,0].to_axis_angle_quaternion[<[location].yaw.add[180].to_radians.mul[-1]>]>
    - define orientation <[yaw_quaternion].mul[<[global_rot]>]>
    - if <[fake_to].exists>:
      - fakespawn pmodel_part_display <[location]> d:infinite save:root
      - define root_entity <entry[root].faked_entity>
      - flag <[root_entity]> fake_to:<[fake_to]>
    - else:
      - spawn pmodel_part_display <[location]> save:root
      - define root_entity <entry[root].spawned_entity>
    - flag <[root_entity]> pmodel_model_id:<[model_name]>
    - flag <[root_entity]> pmodel_global_scale:<[scale]||<location[1,1,1]>>
    - flag <[root_entity]> pmodel_global_rotation:<[global_rot]>
    - flag <[root_entity]> pmodel_yaw:<[center].yaw>
    - flag <[root_entity]> pmodel_skin_type:<[skin_type]>
    - define skull_skin <[player].skull_skin>
    - foreach <server.flag[pmodels_data.model_<[model_name]>]> key:id as:part:
        - if !<[part.item].exists>:
            - foreach next
        # If the part is external skip it and store it as data to use later
        #- else if <[part.type]> == external:
        #    - define external_parts.<[id]> <[part]>
        #    - foreach next
        - define offset <[orientation].transform[<[part.origin]>]>
        - define pose <[part.rotation]>
        - adjust <item[<[part.item]>]> skull_skin:<[skull_skin]> save:item
        - define part_item <entry[item].result>
        #When going too far from the player model textures can get messed up setting the tracking range to 256 fixes the issue
        - define offset_translate <[offset].div[16].proc[pmodels_mul_vecs].context[<[global_scale]>]>
        - define spawn_display pmodel_part_display[item=<[part_item]>;display=THIRDPERSON_RIGHTHAND;tracking_range=256;translation=<[offset_translate]>;scale=<[global_scale]>;left_rotation=<[orientation].mul[<[pose]>]>]
        - if <[fake_to].exists>:
          - fakespawn <[spawn_display]> <[center]> players:<[fake_to]> d:infinite save:spawned
          - define spawned <entry[spawned].faked_entity>
        - else:
          - spawn <[spawn_display]> <[center]> persistent save:spawned
          - define spawned <entry[spawned].spawned_entity>
        - adjust <[spawned]> interpolation_duration:0t
        - adjust <[spawned]> interpolation_start:0t
        - flag <[spawned]> pmodel_def_part_id:<[id]>
        - flag <[spawned]> pmodel_def_pose:<[pose]>
        - flag <[spawned]> pmodel_def_name:<[part.name]>
        - flag <[spawned]> pmodel_def_uuid:<[id]>
        - flag <[spawned]> pmodel_def_pos:<location[0,0,0]>
        - flag <[spawned]> pmodel_def_item:<item[<[part.item]>]>
        - flag <[spawned]> pmodel_def_offset:<[offset]>
        - flag <[spawned]> pmodel_root:<[root_entity]>
        - flag <[spawned]> pmodel_def_type:default
        - flag <[root_entity]> pmodel_parts:->:<[spawned]>
        - flag <[root_entity]> pmodel_anim_part.<[id]>:->:<[spawned]>
    #- if <[external_parts].exists>:
    #  - flag <[root_entity]> external_parts:<[external_parts]>
    - determine <[root_entity]>

pmodels_reset_model_position:
    type: task
    description: Resets the player model to the default position
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model]
    script:
    - define model_data <server.flag[pmodels_data.model_<[root_entity].flag[pmodel_model_id]>]||null>
    - if <[model_data]> == null:
        - debug error "<&[Error]> Could not update model for root entity <[root_entity]> as it does not exist."
        - stop
    - define center <[root_entity].location.with_pitch[0].above[0.5]>
    - define global_scale <[root_entity].flag[pmodel_global_scale]>
    - define yaw_quaternion <location[0,1,0].to_axis_angle_quaternion[<[root_entity].flag[pmodel_yaw].add[180].to_radians.mul[-1]>]>
    - define orientation <[yaw_quaternion].mul[<[root_entity].flag[pmodel_global_rotation]>]>
    - define parentage <map>
    - define root_parts <[root_entity].flag[pmodel_parts]>
    - foreach <[model_data]> key:id as:part:
        - define pose <[part.rotation]>
        - define parent_id <[part.parent]>
        - define parent_pos <location[<[parentage.<[parent_id]>.position]||0,0,0>]>
        - define parent_rot <quaternion[<[parentage.<[parent_id]>.rotation]||identity>]>
        - define parent_raw_offset <location[<[model_data.<[parent_id]>.origin]||0,0,0>]>
        - define rel_offset <location[<[part.origin]>].sub[<[parent_raw_offset]>]>
        - define orientation_parent <[orientation].mul[<[parent_rot]>]>
        - define rot_offset <[orientation_parent].transform[<[rel_offset]>]>
        - define new_pos <[rot_offset].as[location].add[<[parent_pos]>]>
        - define new_rot <[parent_rot].mul[<[pose]>]>
        - define parentage.<[id]>.position <[new_pos]>
        - define parentage.<[id]>.rotation <[new_rot]>
        - foreach <[root_parts]> as:root_part:
          - if <[root_part].flag[pmodel_def_part_id]> == <[id]>:
            - teleport <[root_part]> <[center]>
            - adjust <[root_part]> translation:<[new_pos].div[16].proc[pmodels_mul_vecs].context[<[global_scale]>]>
            - adjust <[root_part]> left_rotation:<[orientation].mul[<[pose]>]>
            - adjust <[root_part]> scale:<[global_scale]>

    #-Third person viewer (removal)
    - if <[root_entity].has_flag[emote_host]> && <[root_entity].has_flag[camera]>:
        - define host  <[root_entity].flag[emote_host]>
        - define cam   <[root_entity].flag[camera]>
        - define stand <[root_entity].flag[stand]>

        - teleport <[host]> <[center]>
        - invisible <[host]> false if:<[host].is_online>

        - flag <[host]> fort.emote:!

        - remove <[cam]> if:<[cam].is_spawned>
        - remove <[stand]> if:<[stand].is_spawned>
        - run dmodels_delete def.root_entity:<[root_entity]>

pmodels_mul_vecs:
    type: procedure
    debug: false
    definitions: a|b
    description: Multiplies two vectors together
    script:
    - determine <location[<[a].x.mul[<[b].x>]>,<[a].y.mul[<[b].y>]>,<[a].z.mul[<[b].z>]>]>

pmodels_remove_model:
    type: task
    description: Removes the player model from the world
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model]
    script:
    - remove <[root_entity].flag[pmodel_parts]>
    - flag <[root_entity]> pmodel_external_parts:!
    - remove <[root_entity]>

pmodels_remove_external_parts:
    type: task
    description: Removes all external parts from the player model
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model]
    script:
    - if <[root_entity].has_flag[pmodel_external_parts]>:
      - remove <[root_entity].flag[pmodel_external_parts]>
      - flag <[root_entity]> pmodel_external_parts:!

pmodels_set_yaw:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'pmodels_spawn_model']|yaw[Number, 0 for default]|update[If not specified as 'false', will immediately update the model's position]
    description: Sets the yaw of the model.
    script:
    - flag <[root_entity]> pmodel_yaw:<[yaw]>
    - if <[update]||true>:
        - run dmodels_reset_model_position def.root_entity:<[root_entity]>

pmodels_change_skin:
    type: task
    description:
    - Changes the skin of the player model to the given player or npc's skin
    - Note that this can take some time to process due to skin lookup
    debug: false
    definitions: player[(PlayerTag or NPCTag) - The player or npc skin the player model will change to]|root_entity[(EntityTag) - The root entity of the player model]
    script:
    - if !<[player].is_npc||false> && !<[player].is_player||false>:
        - debug error "[Denizen Player Models] Must specify a valid player or npc to change the player model skin."
        - stop
    - define norm_models <server.flag[pmodels_data.template_data.norm.models]||null>
    - define slim_models <server.flag[pmodels_data.template_data.slim.models]||null>
    - if <[norm_models]> == null || <[slim_models]> == null:
      - debug error "[Denizen Player Models] Could not find templates for player models in the server data."
      - stop
    - define skull_skin <[player].skull_skin>
    - define skin_type <[player].flag[pmodels_player_skin_type]||<[player].proc[pmodels_skin_type]>>
    - define fake_to <[root_entity].flag[fake_to]||null>
    - define parts <[root_entity].flag[pmodel_parts]||<list>>
    - define tex_load_order player_root|head|hip|waist|chest|right_arm|right_forearm|left_arm|left_forearm|right_leg|right_foreleg|left_leg|left_foreleg
    - define global_scale <[root_entity].flag[pmodel_global_scale]>
    - define root_skin_type <[root_entity].flag[pmodel_skin_type]>
    - foreach <[tex_load_order]> as:tex_part:
      - foreach <[parts]> as:part:
        - if <[part].flag[pmodel_def_name]> == <[tex_part]>:
          - define hand_item <[part].item_in_hand>
          # If the root model skin type does not equal the new model skin type change it
          - if <[root_skin_type]> != <[skin_type]>:
            - choose <[skin_type]>:
              - case classic:
                - foreach <[norm_models]> as:model:
                  - if <[model.name]> == <[tex_part]>:
                    - define hand_item <item[<[model.item]>]>
                    - flag <[part]> pmodel_def_offset: <location[<[model.origin]>].div[16].proc[pmodels_mul_vecs].context[<[global_scale]>]>
              - case slim:
                - foreach <[slim_models]> as:model:
                  - if <[model.name]> == <[tex_part]>:
                    - define hand_item <item[<[model.item]>]>
                    - flag <[part]> pmodel_def_offset: <location[<[model.origin]>].div[16].proc[pmodels_mul_vecs].context[<[global_scale]>]>
          - adjust <[hand_item]> skull_skin:<[skull_skin]> save:item
          - define item <entry[item].result>
          - if <[fake_to]> != null:
            - adjust <[fake_to]> item:<[item]>
          - else:
            - adjust <[part]> item:<[item]>
    - if <[root_skin_type]> != <[skin_type]>:
      - flag <[root_entity]> pmodel_skin_type:<[skin_type]>
      - run pmodels_reset_model_position def.root_entity:<[root_entity]>
