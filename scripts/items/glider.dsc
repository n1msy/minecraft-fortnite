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

        - define eye_loc  <player.eye_location>

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
        - actionbar <[undeploy_text]> if:<player.has_flag[fort.using_glider.locked].not>

      - wait 1t

    #this should in theory ALWAYS be toggled to off since it will always take out the glider no matter what
    - run fort_glider_handler.toggle_glider

    - adjust <player> item_slot:<[previous_slot]>

    - flag player fort.using_glider:!

    - run build_toggle if:<[build_mode].exists>

  toggle_glider:
  #if they have the glider, remove it, if they don't, give it
    - if <player.has_flag[fort.using_glider.deployed]>:
      - define glider <player.flag[fort.using_glider.deployed]>
      - flag player fort.using_glider.deployed:!
      - remove <[glider]>
      - cast LEVITATION remove
    - else:
      - spawn <entity[item_display].with[item=<item[gold_nugget].with[custom_model_data=23;scale=3,3,3]>]> <player.location.above> save:glider
      - define glider <entry[glider].spawned_entity>
      - flag player fort.using_glider.deployed:<[glider]>

      - mount <[glider]>|<player>

      - cast LEVITATION duration:0 amplifier:-10 <player> no_ambient hide_particles no_icon no_clear