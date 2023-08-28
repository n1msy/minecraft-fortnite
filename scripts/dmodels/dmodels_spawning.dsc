###########################
# This file is part of dModels / Denizen Models.
# Refer to the header of "dmodels_main.dsc" for more information.
###########################

dmodel_part_display:
    type: entity
    debug: false
    entity_type: item_display

dmodels_spawn_model:
    type: task
    debug: false
    definitions: player[Optional argument that allows you to use that player's skin.] | model_name[The name of the model to spawn, must already have been loaded via 'dmodels_load_bbmodel'] | location[World location to spawn at] | scale[The scale to spawn the model with, as a LocationTag-vector] | rotation[The rotation to spawn the model with, as a quaternion.] | view_range[(OPTIONAL) can override the global view_range setting in the config below per-model if desired.] | fake_to[(OPTIONAL) list of players to fake-spawn the model to. If left off, will use a real (serverside) entity spawn.]
    description:
    - Spawns a single instance of a model using real item display entities at a location.
    - Supplies determination: EntityTag of the model root entity.
    script:
    - if !<server.has_flag[dmodels_data.model_<[model_name]>]>:
        - debug error "[DModels] cannot spawn model <[model_name]>, model not loaded"
        - stop

    - if <[player].exists>:
        - define skin_type <[player].flag[dmodels_player_skin_type]||<[player].proc[dmodels_skin_type]>>
        - choose <[skin_type]>:
            - case classic:
                - define skin_model player_model_template_norm
            - case slim:
                - define skin_model player_model_template_slim
            - default:
                - debug error "[DModels] <red>Something went wrong in dmodels_spawn_model invalid skin type."
                - stop

    - define center <[location].with_pitch[0].below[1]>
    - define scale <[scale].if_null[<location[1,1,1]>].mul[<script[dmodels_config].parsed_key[default_scale]>]>
    - define rotation <[rotation].if_null[<quaternion[identity]>]>
    - define yaw_quaternion <quaternion[0,1,0,0]>
    #<location[0,1,0].to_axis_angle_quaternion[<[location].yaw.add[180].to_radians.mul[-1]>]>
    - define orientation <[yaw_quaternion].mul[<[rotation]>]>
    - if <[fake_to].exists>:
        - fakespawn dmodel_part_display <[center]> players:<[fake_to]> save:root d:infinite
        - define root <entry[root].faked_entity>
    - else:
        - spawn dmodel_part_display <[center]> save:root
        - define root <entry[root].spawned_entity>
    - define view_range <[view_range].if_null[<script[dmodels_config].parsed_key[view_range]>]>
    - flag <[root]> dmodel_model_id:<[model_name]>
    - flag <[root]> dmodel_root:<[root]>
    - flag <[root]> dmodel_yaw:<[location].yaw>
    - flag <[root]> dmodel_global_scale:<[scale]>
    - flag <[root]> dmodel_global_rotation:<[rotation]>
    - flag <[root]> dmodel_view_range:<[view_range]>
    - flag <[root]> dmodel_color:<color[white]>
    - if <[player].exists>:
        - define center <[root].location.with_pitch[0].below[1]>
        - flag <[root]> dmodel_skin_type:<[skin_type]>
        - flag <[root]> dmodel_skin_model:<[skin_model]>
        - define skull_skin <[player].skull_skin>
    - define parentage <map>
    - define model_data <server.flag[dmodels_data.model_<[model_name]>]>
    - define model_data <server.flag[dmodels_data.model_<[skin_model]>]> if:<[skin_model].exists>
    - foreach <[model_data]> key:id as:part:
        - if !<[part.item].exists>:
            - foreach next
        - define rots <[part.rotation].split[,]>
        - define pose <quaternion[<[rots].get[1]>,<[rots].get[2]>,<[rots].get[3]>,<[rots].get[4]>]>
        - define part_item <[part.item]>
        - if <[skull_skin].exists>:
            - adjust <item[<[part.item]>]> skull_skin:<[skull_skin]> save:item
            - define part_item <entry[item].result>

            - define scale <location[1,1,1]>
            - define offset <[orientation].transform[<[part.origin]>]>
            - define offset_translate <[offset].div[16].proc[dmodels_mul_vecs].context[<[scale]>]>

        - define parent_id <[part.parent]>
        - define parent_pos <location[<[parentage.<[parent_id]>.position]||0,0,0>]>
        - define parent_rot <[parentage.<[parent_id]>.rotation]||<quaternion[identity]>>
        - define parent_raw_offset <[model_data.<[parent_id]>.origin]||0,0,0>
        - define rel_offset <location[<[part.origin]>].sub[<[parent_raw_offset]>]>
        - define orientation_parent <[orientation].mul[<[parent_rot]>]>
        - define rot_offset <[orientation_parent].transform[<[rel_offset]>]>
        - define new_pos <[rot_offset].as[location].add[<[parent_pos]>]>
        - define new_rot <[parent_rot].mul[<[pose]>]>
        - define parentage.<[id]>.position <[new_pos]>
        - define parentage.<[id]>.rotation <[new_rot]>
        - define translation <[new_pos].proc[dmodels_mul_vecs].context[<[scale]>].div[16].mul[0.25]>
        - if !<[player].exists>:
            - define to_spawn_ent dmodel_part_display[item=<[part_item]>;display=HEAD;translation=<[translation]>;left_rotation=<[orientation].mul[<[pose]>]>;scale=<[scale]>]
        - else:
            #tracking_range 256 fixes issue of going too far from player model textures
            - define to_spawn_ent dmodel_part_display[item=<[part_item]>;display=THIRDPERSON_RIGHTHAND;tracking_range=256;translation=<[offset_translate]>;left_rotation=<[orientation].mul[<[pose]>]>;scale=<[scale]>]

        - if <[fake_to].exists>:
            - fakespawn <[to_spawn_ent]> <[center]> players:<[fake_to]> save:spawned d:infinite
            - define spawned <entry[spawned].faked_entity>
        - else:
            - spawn <[to_spawn_ent]> <[center]> save:spawned
            - define spawned <entry[spawned].spawned_entity>
        - if <[view_range]> > 0:
            - adjust <[spawned]> view_range:<[view_range]>
        - flag <[spawned]> dmodel_def_part_id:<[id]>
        - flag <[spawned]> dmodel_def_pose:<[new_rot]>
        - flag <[spawned]> dmodel_def_offset:<[translation]>
        - flag <[spawned]> dmodel_root:<[root]>
        - flag <[root]> dmodel_parts:->:<[spawned]>
        - flag <[root]> dmodel_anim_part.<[id]>:->:<[spawned]>
    - run dmodels_reset_model_position def.root_entity:<[root]>
    - determine <[root]>

dmodels_reset_model_position:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'dmodels_spawn_model']
    description: Resets any animation data on a model, moving the model back to its default positioning.
    script:

    - define model_id <[root_entity].flag[dmodel_model_id]>
    - define model_data <server.flag[dmodels_data.model_<[model_id]>]||null>
    - if <[root_entity].has_flag[dmodel_skin_model]>:
        - define is_player True
        - define model_data <server.flag[dmodels_data.model_<[root_entity].flag[dmodel_skin_model]>]>
    - if <[model_data]> == null:
        - debug error "<&[Error]> Could not update model for root entity <[root_entity]> as it does not exist."
        - stop
    - define center <[root_entity].location.with_pitch[0].below[1]>
    - define global_scale <[root_entity].flag[dmodel_global_scale].mul[<script[dmodels_config].parsed_key[default_scale]>]>
    - define yaw_quaternion <quaternion[0,1,0,0]>
    #<location[0,1,0].to_axis_angle_quaternion[<[root_entity].flag[dmodel_yaw].add[180].to_radians.mul[-1]>]>
    - define orientation <[yaw_quaternion].mul[<[root_entity].flag[dmodel_global_rotation]>]>
    - define parentage <map>
    - define root_parts <[root_entity].flag[dmodel_parts]>
    - foreach <[model_data]> key:id as:part:
        - define pose <[part.rotation]>
        - define parent_id <[part.parent]>
        - define parent_pos <location[<[parentage.<[parent_id]>.position]||0,0,0>]>
        - define parent_rot <quaternion[<[parentage.<[parent_id]>.rotation]||identity>]>
        - define parent_raw_offset <[model_data.<[parent_id]>.origin]||0,0,0>
        - define rel_offset <location[<[part.origin]>].sub[<[parent_raw_offset]>]>
        - define orientation_parent <[orientation].mul[<[parent_rot]>]>
        - define rot_offset <[orientation_parent].transform[<[rel_offset]>]>
        - define new_pos <[rot_offset].as[location].add[<[parent_pos]>]>
        - define new_rot <[parent_rot].mul[<[pose]>]>
        - define parentage.<[id]>.position <[new_pos]>
        - define parentage.<[id]>.rotation <[new_rot]>
        - foreach <[root_parts]> as:root_part:
          - if <[root_part].flag[dmodel_def_part_id]> == <[id]>:
            - define left_rotation <[orientation].mul[<[pose]>]>
            - if <[is_player].exists>:
                - define offset      <[orientation].transform[<[part.origin]>]>
                - define scale       <location[1,1,1]>
                - define translation <[offset].div[16].proc[dmodels_mul_vecs].context[<[scale]>]>
            - else:
                - define translation   <[new_pos].proc[dmodels_mul_vecs].context[<[global_scale]>].div[16].mul[0.25]>
                - define scale         <[global_scale]>
            - teleport <[root_part]> <[center]>
            - adjust <[root_part]> translation:<[translation]>
            - adjust <[root_part]> left_rotation:<[left_rotation]>
            - adjust <[root_part]> scale:<[scale]>

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

dmodels_mul_vecs:
    type: procedure
    debug: false
    definitions: a|b
    description: Multiplies two vectors together.
    script:
    - determine <location[<[a].x.mul[<[b].x>]>,<[a].y.mul[<[b].y>]>,<[a].z.mul[<[b].z>]>]>

dmodels_delete:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'dmodels_spawn_model']
    description: Removes a model from the world.
    script:
    - if !<[root_entity].is_truthy> || !<[root_entity].has_flag[dmodel_model_id]||false>:
        - debug error "[DModels] invalid delete root_entity <[root_entity]>"
        - stop
    - flag server dmodels_anim_active.<[root_entity].uuid>:!
    - flag server dmodels_attached.<[root_entity].uuid>:!
    - remove <[root_entity].flag[dmodel_parts]>
    - remove <[root_entity]>

dmodels_set_yaw:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'dmodels_spawn_model'] | yaw[Number, 0 for default] | update[If not specified as 'false', will immediately update the model's position]
    description: Sets the yaw of the model.
    script:
    - flag <[root_entity]> dmodel_yaw:<[yaw]>
    - if <[update]||true>:
        - run dmodels_reset_model_position def.root_entity:<[root_entity]>

dmodels_set_rotation:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'dmodels_spawn_model'] | quaternion[QuaternionTag, 'identity' for default] | update[If not specified as 'false', will immediately update the model's position]
    description: Sets the global rotation of a model.
    script:
    - define quaternion <quaternion[<[quaternion]>]||null>
    - if <[quaternion]> == null:
        - debug error "<&[error]>Invalid input, the rotation must be a quaternion."
        - stop
    - flag <[root_entity]> dmodel_global_rotation:<[quaternion]>
    - if <[update]||true>:
        - run dmodels_reset_model_position def.root_entity:<[root_entity]>

dmodels_set_scale:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'dmodels_spawn_model'] | scale[LocationTag, '1,1,1' for default] | update[If not specified as 'false', will immediately update the model's position]
    description: Sets the global scale of the model.
    script:
    - define scale <location[<[scale]>]||null>
    - if <[scale]> == null:
        - debug error "<&[error]>Invalid input, the scale must be a location."
        - stop
    - flag <[root_entity]> dmodel_global_scale:<[scale]>
    - if <[update]||true>:
        - run dmodels_reset_model_position def.root_entity:<[root_entity]>

dmodels_set_color:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'dmodels_spawn_model'] | color[ColorTag of the new item-tint to apply, 'white' for default]
    description: Sets the item-color of the model.
    script:
    - define color <color[<[color]>]||null>
    - if <[color]> == null:
        - debug error "<&[error]>Invalid input, must be a color."
        - stop
    - flag <[root_entity]> dmodel_color:<[color]>
    - foreach <[root_entity].flag[dmodel_parts]> as:part:
        - define item <[part].item>
        - adjust <[item]> color:<[color]> save:item
        - define new_item <entry[item].result>
        - adjust <[part]> item:<[new_item]>

dmodels_set_view_range:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'dmodels_spawn_model'] | view_range[Number]
    description: Sets the view-range of the model.
    script:
    - flag <[root_entity]> dmodel_view_range:<[view_range]>
    - adjust <[root_entity].flag[dmodel_parts]> view_range:<[view_range]>

dmodels_skin_type:
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