#====================================== Animating ============================================

pmodels_animate:
    type: task
    description: Animates a player model including if the player model should lerp in to the animation
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model] | animation[(ElementTag) - The animation the player model will play] | lerp_in[(DurationTag) - How long it takes to lerp in to the animation's first position] | reset[(Boolean) - Whether or not the player model will reset to the default position]
    script:
    - if !<[root_entity].is_spawned||false>:
      - debug error "[Denizen Player Models] <red>Cannot animate model <[root_entity]>, model not spawned"
      - stop
    - if <[reset]||true>:
      - run pmodels_reset_model_position def.root_entity:<[root_entity]>
    - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]||null>
    - if <[animation_data]> == null:
        - debug error "[Denizen Player Models] <red>Cannot animate entity <[root_entity].uuid> due to model <[root_entity].flag[pmodel_model_id]> not having an animation named <[animation]>."
        - stop
    # Used for correct model data based on the animation
    - if <[root_entity].flag[pmodels_is_animating]||false>:
      - define is_animating true
    - else:
      - define is_animating false
      - flag <[root_entity]> pmodels_is_animating:true
    # Lerp in
    - if <duration[<[lerp_in]||0>].in_seconds> == 0:
      - flag <[root_entity]> pmodels_lerp:false
      - flag <[root_entity]> pmodels_animation_to_interpolate:!
    - else:
      - define lerp_animation <[animation_data.animators].proc[pmodels_animation_lerp_frames].context[<[lerp_in]>|<[is_animating]>]>
      - flag <[root_entity]> pmodels_lerp:<[lerp_in]>
      - if !<[is_animating]>:
        - flag <[root_entity]> pmodels_animation_to_interpolate:<[lerp_animation]>
      - else:
        # Gathers the data from the previous animation before starting the lerp in animation
        - flag <[root_entity]> pmodels_get_before_lerp
        - flag <[root_entity]> pmodels_animation_to_interpolate:<[lerp_animation]>
        - waituntil !<[root_entity].has_flag[pmodels_get_before_lerp]> max:1s
        - if <[root_entity].has_flag[pmodels_get_before_lerp]>:
          - stop
    - flag <[root_entity]> pmodels_animation_id:<[animation]>
    - flag <[root_entity]> pmodels_anim_time:0
    # Spawn external bones if they exist in the animation
    - if <[root_entity].has_flag[external_parts]> && !<[lerp_in].exists>:
      - define global_scale <[root_entity].flag[pmodel_global_scale]>
      - if <[root_entity].has_flag[fake_to]>:
        - define fake_to <[root_entity].flag[fake_to]>
      - define center <[root_entity].location.with_pitch[0].above[0.5]>
      - define yaw_quaternion <location[0,1,0].to_axis_angle_quaternion[<[center].yaw.add[180].to_radians.mul[-1]>]>
      - define orientation <[yaw_quaternion].mul[<[root_entity].flag[pmodel_global_rotation]>]>
      - foreach <[root_entity].flag[external_parts]> key:id as:part:
        # Look for external bones in the animation
        - if !<[animation_data.animators.<[id]>].exists> || !<[part.item].exists>:
          - foreach next
        - define offset <[orientation].transform[<[part.origin]>]>
        - define rots <[part.rotation].split[,]>
        - define pose <quaternion[<[rots].get[1]>,<[rots].get[2]>,<[rots].get[3]>,<[rots].get[4]>]>
        - define part_item <[part.item]>
        - define offset_translate <[offset].div[16].proc[pmodels_mul_vecs].context[<[global_scale]>]>
        - define spawn_display pmodel_part_display[item=<[part_item]>;display=HEAD;tracking_range=256;translation=<[offset_translate]>;scale=<[global_scale]>;left_rotation=<[orientation].mul[<[pose]>]>]
        - if <[fake_to].exists>:
          - fakespawn <[spawn_display]> <[center]> players:<[fake_to]> d:infinite save:spawned
          - define spawned <entry[spawned].faked_entity>
        - else:
          - spawn <[spawn_display]> <[center]> persistent save:spawned
          - define spawned <entry[spawned].spawned_entity>
        - flag <[spawned]> pmodel_def_part_id:<[id]>
        - flag <[spawned]> pmodel_def_pose:<[pose]>
        - flag <[spawned]> pmodel_def_name:<[part.name]>
        - flag <[spawned]> pmodel_def_uuid:<[id]>
        - flag <[spawned]> pmodel_def_pos:<location[0,0,0]>
        - flag <[spawned]> pmodel_def_item:<item[<[part.item]>]>
        - flag <[spawned]> pmodel_def_offset:<[offset]>
        - flag <[spawned]> pmodel_root:<[root_entity]>
        - flag <[spawned]> pmodel_def_type:external
        - flag <[root_entity]> pmodel_parts:->:<[spawned]>
        - flag <[root_entity]> pmodel_external_parts:->:<[spawned]>
        - flag <[root_entity]> pmodel_anim_part.<[id]>:->:<[spawned]>
    - if <server.flag[pmodels_anim_active].contains[<[root_entity]>]||false>:
      - flag server pmodels_anim_active:<-:<[root_entity]>

    #-Third person viewer (start)
    - if <[root_entity].has_flag[emote_host]>:
        - define host   <[root_entity].flag[emote_host]>
        - define center <[root_entity].location.with_pitch[0].below[1.1]>

        - flag <[host]> fort.emote:<[animation]>
        - invisible <[host]> true

        - spawn ARMOR_STAND[gravity=false;collidable=false;invulnerable=true;visible=false] <[center].backward_flat[3].with_pitch[20]> save:cam
        - define cam <entry[cam].spawned_entity>
        - spawn ARMOR_STAND[gravity=false;collidable=false;invulnerable=true;visible=false] <[center]> save:stand
        - define stand <entry[stand].spawned_entity>

        - flag <[root_entity]> camera:<[cam]>
        - flag <[root_entity]> stand:<[stand]>
        - mount <[host]>|<[cam]>

    - flag server pmodels_anim_active:->:<[root_entity]>

pmodels_animation_lerp_frames:
    type: procedure
    description: Creates the necessary lerp frames for the temporary animation used to interpolate to the new animation
    debug: false
    definitions: animators[(MapTag) - The animators of the animation] | lerp_in[(DurationTag or Seconds) - The length on how long it will take to get to the next animation] | is_animating[(Boolean) - Whether or not the player model is currently animating or in the default state]
    script:
    - define lerp_in <duration[<[lerp_in]>].in_seconds>
    - foreach <[animators]> key:part_id as:animator:
      - foreach position|rotation|scale as:channel:
        - define relevant_frames <[animator.frames.<[channel]>]||null>
        - define first_frame <[relevant_frames].first||null>
        - if <[first_frame]> == null || <[relevant_frames]> == null:
          - definemap first_frame channel:<[channel]> interpolation:linear time:<[lerp_in]> data:0,0,0
        - else:
          - define new_time <[lerp_in].add[<[first_frame.time]>]>
          - if <[new_time]> > <[lerp_in]>:
            - define new_time <[lerp_in]>
          - define first_frame.time <[new_time]>
        - define temp_animators.<[part_id]>.frames.<[channel]>:->:<[first_frame]>
        # If the player model is in the default position or not animating
        - if !<[is_animating]>:
          - definemap new_first_frame channel:<[channel]> interpolation:linear time:0 data:0,0,0
          - define temp_animators.<[part_id]>.frames.<[channel]>:->:<[new_first_frame]>
          - define temp_animators.<[part_id]>.frames.<[channel]> <[temp_animators.<[part_id]>.frames.<[channel]>].sort_by_value[get[time]]>
          - define contains_before_frames true
    - definemap temp_animation:
        animators: <[temp_animators]||<map>>
        length: <[lerp_in]>
        loop: lerp_in
        contains_before_frames: <[contains_before_frames]||false>
    - determine <[temp_animation]>

pmodels_end_animation:
    type: task
    description: Ends the animation the player model is currently playing
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model] | reset[(Boolean) - Whether the player model should be reset to the default position]
    script:
    - flag server pmodels_anim_active:<-:<[root_entity].uuid>
    - flag <[root_entity]> pmodels_animation_id:!
    - flag <[root_entity]> pmodels_anim_time:0
    - flag <[root_entity]> pmodels_animation_to_interpolate:!
    - flag <[root_entity]> pmodels_is_animating:false
    - flag <[root_entity]> pmodels_held_animation:!
    - if <[reset]||true>:
      - run pmodels_reset_model_position def.root_entity:<[root_entity]>

pmodels_move_to_frame:
    type: task
    description: Moves the player model to a frame in the animation
    debug: false
    definitions: root_entity[(EntityTag) - The root entity of the player model]|animation[(ElementTag) - The animation the player model will move to]|timespot[(Ticks) - The timespot the player model will move to]
    script:
    - define model_data <server.flag[pmodels_data.model_<[root_entity].flag[pmodel_model_id]>]||null>
    - define lerp_in <[root_entity].flag[pmodels_lerp]||false>
    - if <[lerp_in].is_truthy>:
      - define lerp_animation <[root_entity].flag[pmodels_animation_to_interpolate]>
      - if !<[lerp_animation.contains_before_frames]||false>:
        - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]||null>
        - define gather_before_frames true
      - else:
        - define animation_data <[lerp_animation]>
    - else:
      - define animation_data <server.flag[pmodels_data.animations_<[root_entity].flag[pmodel_model_id]>.<[animation]>]||null>
    - if <[animation_data]> == null:
      - stop
    - define loop <[animation_data.loop]>
    - if <[timespot]> > <[animation_data.length]>:
      - choose <[loop]>:
        - case loop:
          - define timespot <[timespot].mod[<[animation_data.length]>]>
        - case once:
          - if !<[lerp_in].is_truthy>:
            - define reset true
          - run pmodels_end_animation def.root_entity:<[root_entity]> def.reset:<[reset]||false>
          - stop
        - case hold:
          - define timespot <[animation_data.length]>
        - case lerp_in:
          - define timespot <[animation_data.length]>
          - run pmodels_animate def.root_entity:<[root_entity]> def.animation:<[animation]> def.lerp_in:false def.reset:false
    - define center <[root_entity].location.with_pitch[0].above[0.5]>
    - define global_scale <[root_entity].flag[pmodel_global_scale]>
    - define yaw_quaternion <location[0,1,0].to_axis_angle_quaternion[<[root_entity].flag[pmodel_yaw].add[180].to_radians.mul[-1]>]>
    - define orientation <[yaw_quaternion].mul[<[root_entity].flag[pmodel_global_rotation]>]>
    - define parentage <map>
    - define anim_parts <[root_entity].flag[pmodel_anim_part]||<list>>
    - foreach <[animation_data.animators]> key:part_id as:animator:
      - define framedata.position <location[0,0,0]>
      - define framedata.scale <location[1,1,1]>
      - define framedata.rotation <quaternion[identity]>
      - foreach position|rotation|scale as:channel:
        - define relevant_frames <[animator.frames.<[channel]>]||null>
        - if <[relevant_frames]> == null:
          - foreach next
        - define before_frame <[relevant_frames].filter[get[time].is_less_than_or_equal_to[<[timespot]>]].last||null>
        - define after_frame <[relevant_frames].filter[get[time].is_more_than_or_equal_to[<[timespot]>]].first||null>
        - if <[before_frame]> == null:
            - define before_frame <[after_frame]>
        - if <[after_frame]> == null:
            - define after_frame <[before_frame]>
        - if <[before_frame]> != null:
            - define time_range <[after_frame.time].sub[<[before_frame.time]>]>
            - if <[time_range]> == 0:
                - define time_percent 0
            - else:
                - define time_percent <[timespot].sub[<[before_frame.time]>].div[<[time_range]>]>
            - choose <[before_frame.interpolation]>:
                - case catmullrom:
                    - if <[channel]> == rotation:
                        - define data <[before_frame.data].as[quaternion].slerp[end=<[after_frame.data]>;amount=<[time_percent]>]>
                    - else:
                        - define before_extra <[relevant_frames].filter[get[time].is_less_than[<[before_frame.time]>]].last||null>
                        - if <[before_extra]> == null:
                            - define before_extra <[animation_data.loop].equals[loop].if_true[<[relevant_frames].last>].if_false[<[before_frame]>]>
                        - define after_extra <[relevant_frames].filter[get[time].is_more_than[<[after_frame.time]>]].first||null>
                        - if <[after_extra]> == null:
                            - define after_extra <[animation_data.loop].equals[loop].if_true[<[relevant_frames].first>].if_false[<[after_frame]>]>
                        - define p0 <[before_extra.data].as[location]>
                        - define p1 <[before_frame.data].as[location]>
                        - define p2 <[after_frame.data].as[location]>
                        - define p3 <[after_extra.data].as[location]>
                        - define data <proc[pmodels_catmullrom_proc].context[<[p0]>|<[p1]>|<[p2]>|<[p3]>|<[time_percent]>]>
                - case linear:
                    - if <[channel]> == rotation:
                        - define data <[before_frame.data].as[quaternion].slerp[end=<[after_frame.data]>;amount=<[time_percent]>]>
                    - else:
                        - define data <[after_frame.data].as[location].sub[<[before_frame.data]>].mul[<[time_percent]>].add[<[before_frame.data]>]>
                - case step:
                    - define data <[before_frame.data].as[location]>
            - define framedata.<[channel]> <[data]>
            - if <[gather_before_frames]||false>:
              - definemap lerp_before channel:<[channel]> interpolation:linear time:0 data:<[framedata.<[channel]>]>
              - define lerp_animation.animators.<[part_id]>.frames.<[channel]>:->:<[lerp_before]>
              - define lerp_animation.animators.<[part_id]>.frames.<[channel]> <[lerp_animation.animators.<[part_id]>.frames.<[channel]>].sort_by_value[get[time]]>
      - define this_part <[model_data.<[part_id]>]>
      - define pose <[this_part.rotation]>
      - define parent_id <[this_part.parent]||<[part_id]>>
      - define parent_pos <location[<[parentage.<[parent_id]>.position]||0,0,0>]>
      - define parent_scale <location[<[parentage.<[parent_id]>.scale]||1,1,1>]>
      - define parent_rot <quaternion[<[parentage.<[parent_id]>.rotation]||identity>]>
      - define parent_raw_offset <location[<[model_data.<[parent_id]>.origin]||0,0,0>]>
      - define rel_offset <location[<[this_part.origin]>].sub[<[parent_raw_offset]>]>
      - define rot_offset <[orientation].mul[<[parent_rot]>].transform[<[rel_offset]>]>
      - define new_pos <[parent_rot].transform[<[framedata.position]>].add[<[rot_offset]>].proc[pmodels_mul_vecs].context[<[global_scale]>].add[<[parent_pos]>]>
      - define new_rot <[parent_rot].mul[<[pose]>].mul[<[framedata.rotation]>].normalize>
      - define new_scale <[framedata.scale].proc[pmodels_mul_vecs].context[<[parent_scale]>]>
      - define parentage.<[part_id]>.position:<[new_pos]>
      - define parentage.<[part_id]>.rotation:<[new_rot]>
      - define parentage.<[part_id]>.scale:<[new_scale]>
      - foreach <[anim_parts.<[part_id]>]||<list>> as:ent:
        - teleport <[ent]> <[center]>
        - adjust <[ent]> translation:<[new_pos].div[16]>
        - adjust <[ent]> left_rotation:<[orientation].mul[<[new_rot]>]>
        - adjust <[ent]> scale:<[new_scale].proc[pmodels_mul_vecs].context[<[global_scale]>]>
    - if <[gather_before_frames]||false>:
      - define lerp_animation.contains_before_frames true
      - flag <[root_entity]> pmodels_animation_to_interpolate:<[lerp_animation]||<map>>
      - flag <[root_entity]> pmodels_get_before_lerp:!

    #-Third person camera
    - if <[root_entity].has_flag[emote_host]>:
        - define host      <[root_entity].flag[emote_host]>
        - define cam       <[root_entity].flag[camera]>
        - define stand     <[root_entity].flag[stand]>
        - define stand_loc <[stand].location.below[1.5]>

        - define yaw <[host].location.yaw>
        - define pitch <[host].location.pitch>

        #this makes the emoting models turn where the player is looking, but pitch wont be adjusted
        #- look <[root_entity]> yaw:<[yaw]> pitch:<[pitch]>
        - look <[stand]> yaw:<[yaw]> pitch:<[pitch]>
        - look <[cam]> <[stand_loc]>

        - teleport <[cam]> <[stand_loc].backward[3]>

pmodels_catmullrom_get_t:
    type: procedure
    debug: false
    definitions: t|p0|p1
    script:
    # This is more complex for different alpha values, but alpha=1 compresses down to a '.vector_length' call conveniently
    - determine <[p1].sub[<[p0]>].vector_length.add[<[t]>]>

# Procedure script by mcmonkey creator of DModels https://github.com/mcmonkeyprojects/DenizenModels
pmodels_catmullrom_proc:
    type: procedure
    description: Catmullrom interpolation for animations
    debug: false
    definitions: p0[Before Extra Frame]|p1[Before Frame]|p2[After Frame]|p3[After Extra Frame]|t[Time Percent]
    script:
    # Zero distances are impossible to calculate
    - if <[p2].sub[<[p1]>].vector_length> < 0.01:
        - determine <[p2]>
    # Based on https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline#Code_example_in_Unreal_C++
    # With safety checks added for impossible situations
    - define t0 0
    - define t1 <proc[pmodels_catmullrom_get_t].context[0|<[p0]>|<[p1]>]>
    - define t2 <proc[pmodels_catmullrom_get_t].context[<[t1]>|<[p1]>|<[p2]>]>
    - define t3 <proc[pmodels_catmullrom_get_t].context[<[t2]>|<[p2]>|<[p3]>]>
    # Divide-by-zero safety check
    - if <[t1].abs> < 0.001 || <[t2].sub[<[t1]>].abs> < 0.001 || <[t2].abs> < 0.001 || <[t3].sub[<[t1]>].abs> < 0.001:
        - determine <[p2].sub[<[p1]>].mul[<[t]>].add[<[p1]>]>
    - define t <[t2].sub[<[t1]>].mul[<[t]>].add[<[t1]>]>
    # ( t1-t )/( t1-t0 )*p0 + ( t-t0 )/( t1-t0 )*p1;
    - define a1 <[p0].mul[<[t1].sub[<[t]>].div[<[t1]>]>].add[<[p1].mul[<[t].div[<[t1]>]>]>]>
    # ( t2-t )/( t2-t1 )*p1 + ( t-t1 )/( t2-t1 )*p2;
    - define a2 <[p1].mul[<[t2].sub[<[t]>].div[<[t2].sub[<[t1]>]>]>].add[<[p2].mul[<[t].sub[<[t1]>].div[<[t2].sub[<[t1]>]>]>]>]>
    # FVector A3 = ( t3-t )/( t3-t2 )*p2 + ( t-t2 )/( t3-t2 )*p3;
    - define a3 <[a1].mul[<[t2].sub[<[t]>].div[<[t2]>]>].add[<[a2].mul[<[t].div[<[t2]>]>]>]>
    # FVector B1 = ( t2-t )/( t2-t0 )*A1 + ( t-t0 )/( t2-t0 )*A2;
    - define b1 <[a1].mul[<[t2].sub[<[t]>].div[<[t2]>]>].add[<[a2].mul[<[t].div[<[t2]>]>]>]>
    # FVector B2 = ( t3-t )/( t3-t1 )*A2 + ( t-t1 )/( t3-t1 )*A3;
    - define b2 <[a2].mul[<[t3].sub[<[t]>].div[<[t3].sub[<[t1]>]>]>].add[<[a3].mul[<[t].sub[<[t1]>].div[<[t3].sub[<[t1]>]>]>]>]>
    # FVector C  = ( t2-t )/( t2-t1 )*B1 + ( t-t1 )/( t2-t1 )*B2;
    - determine <[b1].mul[<[t2].sub[<[t]>].div[<[t2].sub[<[t1]>]>]>].add[<[b2].mul[<[t].sub[<[t1]>].div[<[t2].sub[<[t1]>]>]>]>]>

#===== Events ===============================================================

pmodels_events:
    type: world
    description: Events for Denizen Player Models
    debug: false
    events:
        on tick server_flagged:pmodels_anim_active:
        - foreach <server.flag[pmodels_anim_active]> as:root:
          - if <[root].is_spawned||false>:
            - run pmodels_move_to_frame def.root_entity:<[root]> def.animation:<[root].flag[pmodels_animation_id]||null> def.timespot:<[root].flag[pmodels_anim_time].div[20]>
            - flag <[root]> pmodels_anim_time:++
        on server start priority:-1000:
        # Cleanup
        - flag server pmodels_data:!
        - flag server pmodels_anim_active:!
        after player joins:
        - wait 1t
        - flag <player> pmodels_player_skin_type:<player.proc[pmodels_skin_type]>
        after server start:
        - if <script[pmodel_config].data_key[config].get[load_on_start].if_null[false].equals[true]>:
          - run pmodels_load_bbmodel
#================================================================================

#================================================================================================
