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

test:
  type: task
  debug: false
  script:
  - if <player.has_flag[test]>:
    - flag player test:!
    - stop
  - flag player test
  - while <player.has_flag[test]>:
    - animate <player> animation:START_USE_MAINHAND_ITEM
    #- repeat 10:
    #- animate <player> animation:START_USE_OFFHAND_ITEM
    - wait 1t

fort_glider_handler:
  type: world
  debug: false
  events:

    on player drops item flagged:for.using_glider:
    - determine canceled

    on player starts sneaking flagged:fort.using_glider:
    - if <player.has_flag[fort.using_glider.locked]>:
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

    - adjust <player> item_slot:9
    #<item[gold_nugget].with[custom_model_data=23]>

    - define lb <element[<&l><&lb>].color[<color[72,0,0]>]>
    - define rb <element[<&l><&rb>].color[<color[72,0,0]>]>

    - define sneak_button <[lb]><element[<&l>SNEAK].color[<color[75,0,0]>]><[rb]>

    - define deploy_text   "<[sneak_button]> <element[<&l>DEPLOY GLIDER].color[<color[71,0,0]>]>"
    - define undeploy_text "<[sneak_button]> <element[<&l>UNDEPLOY GLIDER].color[<color[71,0,0]>]>"

    - while !<player.is_on_ground> && <player.is_online>:

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

        - foreach <[left_foot]>|<[right_foot]>|<[left_hand]>|<[right_hand]> as:limb:
          - playeffect effect:REDSTONE offset:0 at:<[limb]> visibility:100 special_data:1|WHITE

        - actionbar <[deploy_text]>

      # - [ GLIDER ] - #
      - else:
        - define glider <player.flag[fort.using_glider.deployed]>

        #second check is if the yaw isn't the same as what it was
        - if <[loop_index].mod[2]> == 0 && <player.location.yaw> != <[yaw]||null> && !<[glider].has_flag[deploy_anim]> && !<[glider].has_flag[undeploy_anim]>:
          - define yaw   <[eye_loc].yaw>
          - define angle <[yaw].to_radians>
          - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

          - adjust <[glider]> interpolation_start:0
          - adjust <[glider]> left_rotation:<[left_rotation]>
          - adjust <[glider]> interpolation_duration:2t

        - actionbar <[undeploy_text]> if:<player.has_flag[fort.using_glider.locked].not>

      - wait 1t

    #this should in theory ALWAYS be toggled to off since it will always take out the glider no matter what
    - run fort_glider_handler.toggle_glider

    - adjust <player> item_slot:<[previous_slot]>

    - flag player fort.using_glider:!

    - run build_toggle if:<[build_mode].exists>

  toggle_glider:

    - define loc   <player.location>
    - define yaw   <[loc].yaw>
    - define angle <[yaw].to_radians>

  #if they have the glider, remove it, if they don't, give it
    - if <player.has_flag[fort.using_glider.deployed]>:
      - define glider <player.flag[fort.using_glider.deployed]>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[yaw].sub[180].to_radians>]>]>

      - if <[glider].has_flag[undeploy_anim]>:
        - stop

      - flag <[glider]> undeploy_anim duration:10t
      - adjust <[glider]> interpolation_start:0
      - adjust <[glider]> left_rotation:<[left_rotation]>
      - adjust <[glider]> translation:0,-0.5,0
      - adjust <[glider]> scale:0,0,0
      - adjust <[glider]> interpolation_duration:10t

      - take slot:9 from:<player.inventory>
      - cast LEVITATION remove
      - flag player fort.using_glider.deployed:!

      - wait 10t

      - remove <[glider]>

    - else:
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

      #starting off with left rotation as the opposite direction (to give spinning effect)
      - define starting_rotation <quaternion[0,-1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[yaw].add[180].to_radians>]>]>

      - spawn <entity[item_display].with[item=<item[gold_nugget].with[custom_model_data=23]>;scale=0,0,0;translation=0,-0.5,0;left_rotation=<[starting_rotation]>]> <[loc].with_pose[0,0].above> save:glider
      - define glider <entry[glider].spawned_entity>
      - flag player fort.using_glider.deployed:<[glider]>

      #"remove" the players hand from frame, so it *looks* like they're holding the glider (even though it's a random item)
      - give <item[white_stained_glass_pane].with[display=<&sp>;custom_model_data=1]> slot:9 to:<player.inventory>

      - mount <[glider]>|<player>
      - look <[glider]> pitch:0

      - cast LEVITATION duration:0 amplifier:-10 <player> no_ambient hide_particles no_icon no_clear

      ##do we really need all this extra checks?

      #in case it's from a previous queue/spam
      #- if <[glider].has_flag[deploy_anim]>:
      #  - stop

      #- flag <[glider]> deploy_anim duration:15t

      #- repeat 2:
      #  #in case they spawn another glider (from spamming)
      #  - if !<[glider].is_spawned>:
      #    - if !<player.has_flag[fort.using_glider.deployed]>:
      #      - stop
      #    - define glider <player.flag[fort.using_glider.deployed]>
      #    - flag <[glider]> deploy_anim duration:<element[15].sub[<[value]>]>
      #  - wait 1t
      - flag <[glider]> deploy_anim duration:15t
      - wait 2t


      - adjust <[glider]> interpolation_start:0
      - adjust <[glider]> left_rotation:<[left_rotation]>
      #best value: 1.6 (lower it a little so it can show in first person ?)
      - adjust <[glider]> translation:0,1.6,0
      - adjust <[glider]> scale:1,1,1
      - adjust <[glider]> interpolation_duration:10t
