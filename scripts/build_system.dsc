
##turn this into a proc that checks if you can place or not
test:
  type: task
  debug: false
  script:
  - define loc <player.location>

  - define chunk <[loc].chunk>

  - define chunk_cuboid <[chunk].cuboid>

  - define y <[loc].y.sub[1]>

  - define corner_1 <[chunk_cuboid].min.with_y[<[y]>]>
  - define corner_2 <[chunk_cuboid].max.with_y[<[y]>]>

  - define grid_cuboid <[corner_1].to_cuboid[<[corner_2]>]>

  - define color red

  #6x6s
  - foreach <[grid_cuboid].blocks> as:block:
    - define i <[loop_index].sub[1]>
    - if <[i].mod[6]> == 0:
      - define color <map[light_blue=red;red=light_blue].get[<[color]>]>

    #- if <[i].mod[128]> == 0:
      #- define color <map[light_blue=red;red=light_blue].get[<[color]>]>

    - modifyblock <[color]>_concrete <[block]>

  #8x8s
  #- foreach <[grid_cuboid].blocks> as:block:
   # - define i <[loop_index].sub[1]>
   # - if <[i].mod[8]> == 0:
   #   - define color <map[light_blue=red;red=light_blue].get[<[color]>]>

   # - if <[i].mod[128]> == 0:
   #   - define color <map[light_blue=red;red=light_blue].get[<[color]>]>

   # - modifyblock <[color]>_concrete <[block]>

  #4x4s
  - foreach <[grid_cuboid].blocks> as:block:
    - define i <[loop_index].sub[1]>
    - if <[i].mod[4]> == 0:
      - define color <map[light_blue=red;red=light_blue].get[<[color]>]>

    - if <[i].mod[64]> == 0:
      - define color <map[light_blue=red;red=light_blue].get[<[color]>]>

    - modifyblock <[color]>_concrete <[block]>

build:
  type: task
  debug: false
  script:
  - if <player.has_flag[build]>:
    - flag player build:!
    - narrate "<&c>build removed"
    - stop

  - flag player build


  - while <player.is_online> && <player.has_flag[build]>:
    - define eye_loc <player.eye_location>
    - define yaw <map[North=90;South=-90;West=0;East=-180].get[<[eye_loc].yaw.simple>]>
    - define target_loc <[eye_loc].ray_trace[default=air;range=3]>
    - define build_loc <[target_loc].with_pitch[90].ray_trace>
    - define build_loc <[build_loc].with_y[<[build_loc].y.round>]>

    #if they're looking at an already-placed wall
    - if <[target_loc].has_flag[build]>:
      - wait 1t
      - while next

    - choose <player.held_item_slot>:
      - case 1:
        #centered wall (without custom 3rd person)
        #- define wall <[build_loc].with_yaw[<[yaw]>].backward_flat.to_cuboid[<[build_loc].with_yaw[<[yaw]>].forward_flat.above[2]>]>
        - define wall <[build_loc].with_yaw[<[yaw]>].to_cuboid[<[build_loc].with_yaw[<[yaw]>].backward_flat[2].above[2]>]>

        - define place_status yes
        - if !<[wall].blocks.filter[has_flag[build]].is_empty>:
          - define place_status no

        - if <[place_status]> == yes:
          - flag player build.struct:<[wall]>
        - else:
          - flag player build.struct:!

        #102, 161, 255 - blue
        #- debugblock <[wall].blocks> color:,255,0,128 d:2t
        - showfake <map[yes=light_blue_concrete;no=red_concrete].get[<[place_status]>]> <[wall].blocks> duration:2t

      - case 2:
        - actionbar floor
      - case 3:
        - actionbar stair
      - case 4:
        - actionbar pyramid

    - wait 1t

  - flag player build:!

build_system_handler:
  type: world
  debug: false
  events:
    on player left clicks block flagged:build.struct:
    - determine passively cancelled
    #wood health - 150
    #stone health - 400
    #metal health - 600
    - define material wood

    - define build <player.flag[build.struct]>
    - modifyblock <[build].blocks> oak_planks
    - flag <[build].blocks> build.<player.uuid>.health:<script[nimnite_config].data_key[materials.<[material]>.hp]>