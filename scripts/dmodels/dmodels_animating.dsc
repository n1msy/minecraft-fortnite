###########################
# This file is part of dModels / Denizen Models.
# Refer to the header of "dmodels_main.dsc" for more information.
###########################


dmodels_end_animation:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'dmodels_spawn_model']
    description: Stops any animation currently playing on a model, and resets its position.
    script:
    - if !<[root_entity].is_truthy> || !<[root_entity].has_flag[dmodel_model_id]||false>:
        - debug error "[DModels] invalid end_animation root_entity <[root_entity]>"
        - stop
    - flag <[root_entity]> dmodels_animation_id:!
    - flag <[root_entity]> dmodels_anim_time:0
    - flag server dmodels_anim_active.<[root_entity].uuid>:!
    - run dmodels_reset_model_position def.root_entity:<[root_entity]>

dmodels_animate:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'dmodels_spawn_model'] | animation[The name of the animation to play (as set in BlockBench)]
    description: Starts a model animating the given animation, until the animation ends (if it does at all) or until the animation is changed or ended.
    script:
    - if !<[root_entity].is_truthy> || !<[root_entity].has_flag[dmodel_model_id]||false>:
        - debug error "[DModels] invalid animate root_entity <[root_entity]>"
        - stop
    - run dmodels_reset_model_position def.root_entity:<[root_entity]>
    - define animation_data <server.flag[dmodels_data.animations_<[root_entity].flag[dmodel_model_id]>.<[animation]>]||null>
    - if <[animation_data]> == null:
        - debug error "[DModels] Cannot animate entity <[root_entity].uuid> due to model <[root_entity].flag[dmodel_model_id]> not having an animation named <[animation]>"
        - stop
    - flag <[root_entity]> dmodels_animation_id:<[animation]>
    - flag <[root_entity]> dmodels_anim_time:0
    - flag server dmodels_anim_active.<[root_entity].uuid>:<[root_entity]>

dmodels_move_to_frame:
    type: task
    debug: false
    definitions: root_entity[The root EntityTag from 'dmodels_spawn_model'] | animation[The name of the animation to play (as set in BlockBench)] | timespot[The time (in seconds) from the start of the animation to select as the frame.]
    description: Moves a model's position to a single frame of an animation. Not intended for external use except for debugging animation issues.
    script:
    - define model_data <server.flag[dmodels_data.model_<[root_entity].flag[dmodel_model_id]>]>
    - define animation_data <server.flag[dmodels_data.animations_<[root_entity].flag[dmodel_model_id]>.<[animation]>]>
    - if <[timespot]> > <[animation_data.length]>:
        - choose <[animation_data.loop]>:
            - case loop:
                - define timespot <[timespot].mod[<[animation_data.length]>]>
            - case once:
                - flag server dmodels_anim_active.<[root_entity].uuid>:!
                - if <[root_entity].has_flag[dmodels_default_animation]>:
                    - run dmodels_animate def.root_entity:<[root_entity]> def.animation:<[root_entity].flag[dmodels_default_animation]>
                - else:
                    - run dmodels_reset_model_position def.root_entity:<[root_entity]>
                - stop
            - case hold:
                - define timespot <[animation_data.length]>
                - flag server dmodels_anim_active.<[root_entity].uuid>:!
    - define global_rotation <[root_entity].flag[dmodel_global_rotation]>
    - define global_scale <[root_entity].flag[dmodel_global_scale].mul[<script[dmodels_config].parsed_key[default_scale]>]>
    - define center <[root_entity].location.with_pitch[0].below[1]>
    - define yaw_quaternion <location[0,1,0].to_axis_angle_quaternion[<[root_entity].flag[dmodel_yaw].add[180].to_radians.mul[-1]>]>
    - define orientation <[yaw_quaternion].mul[<[global_rotation]>]>
    - define parentage <map>
    - foreach <[animation_data.animators]> key:part_id as:animator:
        - define framedata.position <location[0,0,0]>
        - define framedata.scale <location[1,1,1]>
        - define framedata.rotation <quaternion[identity]>
        - foreach position|rotation|scale as:channel:
            - define relevant_frames <[animator.frames].filter[get[channel].equals[<[channel]>]]>
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
                            # TODO: Actual impl? If this even exists in blockbench.
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
                            - define data <proc[dmodels_catmullrom_proc].context[<[p0]>|<[p1]>|<[p2]>|<[p3]>|<[time_percent]>]>
                    - case linear:
                        - if <[channel]> == rotation:
                            - define data <[before_frame.data].as[quaternion].slerp[end=<[after_frame.data]>;amount=<[time_percent]>]>
                        - else:
                            - define data <[after_frame.data].as[location].sub[<[before_frame.data]>].mul[<[time_percent]>].add[<[before_frame.data]>]>
                    - case step:
                        - define data <[before_frame.data].as[location]>
                - define framedata.<[channel]> <[data]>
        - define this_part <[model_data.<[part_id]>]>
        - define pose <[this_part.rotation]>
        - define parent_id <[this_part.parent]>
        - define parent_pos <location[<[parentage.<[parent_id]>.position]||0,0,0>]>
        - define parent_scale <location[<[parentage.<[parent_id]>.scale]||1,1,1>]>
        - define parent_rot <quaternion[<[parentage.<[parent_id]>.rotation]||identity>]>
        - define parent_raw_offset <location[<[model_data.<[parent_id]>.origin]||0,0,0>]>
        - define rel_offset <location[<[this_part.origin]>].sub[<[parent_raw_offset]>].proc[dmodels_mul_vecs].context[<[parent_scale]>]>
        - define rot_offset <[orientation].mul[<[parent_rot]>].transform[<[rel_offset]>]>
        - define new_pos <[parent_rot].transform[<[framedata.position]>].add[<[rot_offset]>].proc[dmodels_mul_vecs].context[<[global_scale]>].add[<[parent_pos]>]>
        - define new_rot <[parent_rot].mul[<[pose]>].mul[<[framedata.rotation]>].normalize>
        - define new_scale <[framedata.scale].proc[dmodels_mul_vecs].context[<[parent_scale]>]>
        - define parentage.<[part_id]>.position <[new_pos]>
        - define parentage.<[part_id]>.rotation <[new_rot]>
        - define parentage.<[part_id]>.scale <[new_scale]>
        - foreach <[root_entity].flag[dmodel_anim_part.<[part_id]>]||<list>> as:ent:
            - teleport <[ent]> <[center]>
            - adjust <[ent]> translation:<[new_pos].div[16].mul[0.25]>
            - adjust <[ent]> left_rotation:<[orientation].mul[<[new_rot]>]>
            - adjust <[ent]> scale:<[new_scale].proc[dmodels_mul_vecs].context[<[global_scale]>]>

dmodels_catmullrom_get_t:
    type: procedure
    debug: false
    definitions: t|p0|p1
    script:
    # This is more complex for different alpha values, but alpha=1 compresses down to a '.vector_length' call conveniently
    - determine <[p1].sub[<[p0]>].vector_length.add[<[t]>]>

dmodels_catmullrom_proc:
    type: procedure
    debug: false
    definitions: p0|p1|p2|p3|t
    script:
    # Zero distances are impossible to calculate
    - if <[p2].sub[<[p1]>].vector_length> < 0.01:
        - determine <[p2]>
    # Based on https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline#Code_example_in_Unreal_C++
    # With safety checks added for impossible situations
    - define t0 0
    - define t1 <proc[dmodels_catmullrom_get_t].context[0|<[p0]>|<[p1]>]>
    - define t2 <proc[dmodels_catmullrom_get_t].context[<[t1]>|<[p1]>|<[p2]>]>
    - define t3 <proc[dmodels_catmullrom_get_t].context[<[t2]>|<[p2]>|<[p3]>]>
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

dmodels_attach_to:
    type: task
    debug: false
    definitions: root_entity[The root entity gotten from 'dmodels_spawn_model'.] | target[The entity to be attached to.] | auto_animate[(OPTIONAL) set to 'true' to indicate the model should automatically apply animations based on the entity it's attached to. See 'core animations' list below.]
    description: Attaches a model's position/rotation to an entity.
    script:
    - if !<[root_entity].is_truthy> || !<[root_entity].has_flag[dmodel_model_id]||false>:
        - debug error "[DModels] invalid attach_to root_entity <[root_entity]>"
        - stop
    - if !<[target].is_truthy> || <[target]> !matches entity:
        - debug error "[DModels] invalid attach_to target <[target]>"
        - stop
    - flag <[root_entity]> dmodels_attached_to:<[target]>
    - flag <[root_entity]> dmodels_attach_auto_animate:<[auto_animate]||false>
    - flag server dmodels_attached.<[root_entity].uuid>:<[root_entity]>

dmodels_animator_world:
    type: world
    debug: false
    events:
        on tick server_flagged:dmodels_attached priority:-20:
        - foreach <server.flag[dmodels_attached]> as:root:
            - if <[root].is_spawned||false> && <[root].flag[dmodels_attached_to].is_spawned||false>:
                - define target <[root].flag[dmodels_attached_to]>
                - teleport <[root]> <[target].location>
                - if <[root].flag[dmodels_attach_auto_animate]> && !<[root].flag[dmodels_temp_alt_anim].is_truthy||false>:
                    - define preferred idle
                    - if <[target].is_sneaking||false>:
                        - define preferred crouching_idle
                    - if <[target].velocity.vector_length> > 0.1:
                        - define preferred running
                        - if <[target].velocity.vector_length> > 1.2:
                            - define preferred sprinting
                        - if <[target].velocity.y> > 0.1:
                            - define preferred jump
                    - if <[root].flag[dmodels_animation_id]||none> != <[preferred]> && <server.has_flag[dmodels_data.animations_<[root].flag[dmodel_model_id]>.<[preferred]>]||null>:
                        - run dmodels_animate def.root_entity:<[root]> def.animation:<[preferred]>
                - if !<[root].has_flag[dmodels_animation_id]>:
                    - run dmodels_reset_model_position def.root_entity:<[root]>
        on tick server_flagged:dmodels_anim_active priority:-10:
        - foreach <server.flag[dmodels_anim_active]> as:root:
            - if <[root].is_spawned||false>:
                - run dmodels_move_to_frame def.root_entity:<[root]> def.animation:<[root].flag[dmodels_animation_id]> def.timespot:<[root].flag[dmodels_anim_time].div[20]>
                - flag <[root]> dmodels_anim_time:++
