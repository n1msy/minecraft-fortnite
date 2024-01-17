#give the player an item, or mount a display entity?
#currently mounting, so player can't click or anything
#add player's skin arms onto glider?

#-two methods to detect button to deploy glider:
#1) sneaking (cntrl) (with levitation)
#2) jumping (space) (with mount)


#make a custom gliding animation and give players the third person view instead? (might be super laggy, since it would have to update every tick for each player)

#-actual: battle bus height: 864
#-best result: 175
#how i calculated: battle bus from loot lake y in fort = 832 m = 832 blocks
#battle bus height = loot lake y + 832 blocks = 32 + 832 = 864

##play a noise when falling for enemies to indicate they're falling?

##might be a bit too many particle effects; if too laggy, tone it down

######GLIDER STILL NOT REMOVING WHEN HITTING THE GROUND

fort_glider_handler:
  type: world
  debug: false
  events:

    on player clicks block flagged:fort.using_glider:
    - determine passively cancelled
    - cast FAST_DIGGING amplifier:9999 duration:1s no_icon no_ambient hide_particles

    on player drops item flagged:fort.using_glider:
    - determine cancelled

    #after, to prevent the even from firing multiple times (like when jumping off bus)
    after player starts sneaking flagged:fort.using_glider:
    - if <player.has_flag[fort.using_glider.locked]>:
      - stop

    - if <player.has_flag[fort.bus_jumped]>:
      - stop

    - run fort_glider_handler.toggle_glider

    #only for deployment, since custom gliding logic prevents sprinting already
    on player starts sprinting flagged:fort.using_glider.deployed:
    - determine cancelled


  fall:

    - define previous_slot <player.held_item_slot>
    #for hud menu to keep the slot selected the same
    - flag player fort.using_glider.previous_slot:<[previous_slot]>

    #disable building temporarily
    - if <player.has_flag[build]>:
      - define build_mode True
      - run build_toggle

    #cancel battle bus wind sound in case they were on it
    #- adjust <player> stop_sound:minecraft:item.elytra.flying
    - adjust <player> item_slot:9
    #<item[gold_nugget].with[custom_model_data=23]>

    - define lb <element[<&l><&lb>].color[<color[72,0,0]>]>
    - define rb <element[<&l><&rb>].color[<color[72,0,0]>]>

    - define sneak_button <[lb]><element[<&l>SNEAK].color[<color[75,0,0]>]><[rb]>

    - define deploy_text   "<[sneak_button]> <element[<&l>DEPLOY GLIDER].color[<color[71,0,0]>]>"
    - define undeploy_text "<[sneak_button]> <element[<&l>UNDEPLOY GLIDER].color[<color[71,0,0]>]>"

    - while <player.is_online> && !<player.is_on_ground> && !<player.has_flag[fort.spectating]>:

      - define loc        <player.location>
      - define eye_loc  <player.eye_location>
      - define ground_loc <[loc].with_pitch[90].ray_trace[default=air]>

      - if <[loc].distance[<[ground_loc]>]> <= 50:
        - flag player fort.using_glider.locked
        #in case they deployed it before and have a glider already
        - if !<player.has_flag[fort.using_glider.deployed]>:
          - run fort_glider_handler.toggle_glider
        - actionbar <empty>

      # - [ FALLING ] - #
      - if !<player.has_flag[fort.using_glider.deployed]>:
        - if <[gliding_time].exists>:
          - define gliding_time:!
          - adjust <player> stop_sound:minecraft:item.elytra.flying

        - adjust <player> gliding:true

        #so players can't glide upwards + they glide at a constant rate
        #instead of normalizing the speed, dividing by a lot, so players can still somewhat steer the speed at which they fall
        - define velocity <[eye_loc].forward[1].sub[<[eye_loc]>].div[1.25].with_y[-0.5]>

        - adjust <player> velocity:<[velocity]>

        #-fx
        - define left_foot  <player.location.relative[0.1,0,0]>
        - define right_foot <player.location.relative[-0.1,0,0]>
        - define left_hand  <player.location.relative[0.4,0,1]>
        - define right_hand <player.location.relative[-0.4,0,1]>
        - define limbs      <list[<[left_foot]>|<[right_foot]>|<[left_hand]>|<[right_hand]>]>

        - playeffect effect:REDSTONE offset:0 at:<[limbs]> visibility:25 special_data:1|WHITE

        - actionbar <[deploy_text]>

      # - [ GLIDER ] - #
      - else:
        - define glider <player.flag[fort.using_glider.deployed]>
        #- define gliding_model <player.flag[fort.using_glider.gliding_model]>

        #- teleport <[gliding_model]> <[loc].above[2]>

        - define velocity <[eye_loc].forward[1].sub[<[eye_loc]>].div[2].with_y[-0.15]>
        - adjust <player> velocity:<[velocity]>

        #how long they've been using the glider for (only used for sound effect currently)
        - define gliding_time:++

        #since glide effect is removed, it wont play this sound anymore
        #play every 6 seconds
        - playsound <player> sound:ITEM_ELYTRA_FLYING pitch:1.3 volume:0.1 if:<[loop_index].mod[145].equals[0].or[<[gliding_time].equals[1]>]>

        #second check is if the yaw isn't the same as what it was
        - if !<[glider].has_flag[deploy_anim]> && !<[glider].has_flag[undeploy_anim]>:

          #-wind fx
          - if <[loop_index].mod[3]> == 0:
            #so the wind fx doesn't look as vertical
            - define left_side  <[eye_loc].with_pitch[0].below[0.2].backward[0.6].left[1.45]>
            - define right_side <[eye_loc].with_pitch[0].below[0.2].backward[0.6].right[1.45]>

            #redstone
            #- define left_side  <[eye_loc].below[0.55].with_pitch[0].backward[0.6].left[1.4]>
            #- define right_side <[eye_loc].below[0.55].with_pitch[0].backward[0.6].right[1.4]>

            - foreach <[left_side]>|<[right_side]> as:side:
              - define vel <[side].with_pitch[-45].backward.sub[<[side]>].div[2]>
              - playeffect effect:CLOUD offset:0 at:<[side]> velocity:<[vel]> visibility:25
              #special_data:0.9|WHITE

          #-glider rotation
          - if <[loop_index].mod[2]> == 0 && <player.location.yaw> != <[yaw]||null>:
            - define yaw         <[eye_loc].yaw>
            #(the commented out is including pitch)
            - define angle <[yaw].to_radians>
            - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

            - adjust <[glider]> interpolation_start:0
            - adjust <[glider]> left_rotation:<[left_rotation]>
            - adjust <[glider]> interpolation_duration:2t

        - actionbar <[undeploy_text]> if:<player.has_flag[fort.using_glider.locked].not>

      - wait 1t

      - if <[loc].y> < -42:
        #doing this causes the death effect to fire
        - hurt <player.health> cause:VOID
        - remove <[glider]> if:<[glider].is_spawned>
        - stop

    #-added a safety to remove the glider, not sure if it works or not though -> just tested, still not working, changed to 2t to see if it'll work
    #- wait 2t

    #-do this? (it might break if i ever try to add a /rejoin thing though)
    #in case they quit mid-glider
    #- if !<player.is_online>:
      #- remove <[glider]> if:<[glider].is_spawned>
      #- stop

    - flag player fort.using_glider.remove_on_land
    - run fort_glider_handler.toggle_glider

    - adjust <player> stop_sound:minecraft:item.elytra.flying

    #-in case they die
    - if !<player.has_flag[fort.spectating]>:
      - playsound <player.location> sound:BLOCK_ANCIENT_DEBRIS_STEP pitch:2
      - run fort_global_handler.land_fx

    - adjust <player> item_slot:<[previous_slot]>

    - run build_toggle if:<[build_mode].exists>

    #waiting in case the fall event fires and players take damage
    - wait 10t
    - flag player fort.using_glider:!

  toggle_glider:

    - if <player.has_flag[fort.using_glider.landed]>:
      - stop

    - define loc   <player.location>
    - define yaw   <[loc].yaw>
    - define angle <[yaw].to_radians>

  #if they have the glider, remove it, if they don't, give it
    - if <player.has_flag[fort.using_glider.deployed]>:
      - define glider <player.flag[fort.using_glider.deployed]>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[yaw].sub[180].to_radians>]>]>

      - if <[glider].has_flag[undeploy_anim]>:
        - stop

      - playsound <player> sound:ENTITY_ALLAY_AMBIENT_WITHOUT_ITEM pitch:1.5 volume:1
      - playsound <player> sound:ENTITY_PLAYER_ATTACK_NODAMAGE pitch:0.3 volume:1.5

      - flag <[glider]> undeploy_anim duration:10t
      - adjust <[glider]> interpolation_start:0
      - adjust <[glider]> left_rotation:<[left_rotation]>
      - adjust <[glider]> translation:0,-0.5,0
      - adjust <[glider]> scale:0,0,0
      - adjust <[glider]> interpolation_duration:10t

      - take slot:9 from:<player.inventory>
      #- cast LEVITATION remove
      #- cast INVISIBILITY remove
      - flag player fort.using_glider.deployed:!

      - if <player.has_flag[fort.using_glider.remove_on_land]>:
        - flag player fort.using_glider.landed

      #- define gliding_model <player.flag[fort.using_glider.gliding_model]||null>
      #- if <[gliding_model]> != null:
        #- run dmodels_delete def.root_entity:<[gliding_model]>

      - wait 10t

      - remove <[glider]>

    - else:

      #- if <[glider].has_flag[undeploy_anim]>:
        #- stop

      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

      #starting off with left rotation as the opposite direction (to give spinning effect)
      - define starting_rotation <quaternion[0,-1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[yaw].add[180].to_radians>]>]>

      - spawn <entity[item_display].with[item=<item[gold_nugget].with[custom_model_data=23]>;scale=0,0,0;translation=0,-0.5,0;left_rotation=<[starting_rotation]>]> <[loc].with_pose[0,0].above> save:glider
      - define glider <entry[glider].spawned_entity>
      - flag player fort.using_glider.deployed:<[glider]>

      #"remove" the players hand from frame, so it *looks* like they're holding the glider (even though it's a random item)
      - give <item[gold_nugget].with[display=<&sp>;custom_model_data=23;flag=glider:true]> slot:9 to:<player.inventory>

      #- run dmodels_spawn_model def.player:<player> def.model_name:emotes def.location:<[loc].above[2]> def.yaw:<[yaw]> save:result
      #- define gliding_model <entry[result].created_queue.determination.first||null>
      #- run dmodels_set_scale def.root_entity:<[gliding_model]> def.scale:1.87,1.87,1.87
      #- flag player fort.using_glider.gliding_model:<[gliding_model]>

      - mount <[glider]>|<player>

      - look <[glider]> pitch:0

      #instead of casting levitation, just using the same velocity logic as before
      #- cast LEVITATION duration:0 amplifier:-10 <player> no_ambient hide_particles no_icon no_clear

      ##make sure other players can hear this
      - playsound <player> sound:ENTITY_ALLAY_AMBIENT_WITH_ITEM pitch:0.8 volume:0.8
      - playsound <player> sound:ITEM_ARMOR_EQUIP_ELYTRA pitch:0.8 volume:1.7

      - flag <[glider]> deploy_anim duration:15t
      - wait 2t


      - adjust <[glider]> interpolation_start:0
      - adjust <[glider]> left_rotation:<[left_rotation]>
      #best value: 1.6 (lower it a little so it can show in first person ?)
      - adjust <[glider]> translation:0,1.6,0
      - adjust <[glider]> scale:1,1,1
      - adjust <[glider]> interpolation_duration:10t

  remove_glider:
    - define loc   <player.location>
    - define yaw   <[loc].yaw>

    - if !<player.has_flag[fort.using_glider]> || <player.flag[fort.usin_glider.deployed].is_spawned.not||true>:
      - stop

    - define glider <player.flag[fort.using_glider.deployed]>
    - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[yaw].sub[180].to_radians>]>]>

    - playsound <player> sound:ENTITY_ALLAY_AMBIENT_WITHOUT_ITEM pitch:1.5 volume:1
    - playsound <player> sound:ENTITY_PLAYER_ATTACK_NODAMAGE pitch:0.3 volume:1.5

    - flag <[glider]> undeploy_anim duration:10t
    - adjust <[glider]> interpolation_start:0
    - adjust <[glider]> left_rotation:<[left_rotation]>
    - adjust <[glider]> translation:0,-0.5,0
    - adjust <[glider]> scale:0,0,0
    - adjust <[glider]> interpolation_duration:10t

    - take slot:9 from:<player.inventory>

    - flag player fort.using_glider.deployed:!

    - wait 10t

    - remove <[glider]>
