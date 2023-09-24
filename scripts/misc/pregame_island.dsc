#pregame_island_handler:
#  type: world
#  debug: false
#  definitions: square
#  events:
#    on player enters fort_lobby_circle:
#    - title title:<&font[denizen:black]><&chr[0004]><&chr[F801]><&chr[0004]> fade_in:7t stay:0s fade_out:1s
#    - cast LEVITATION duration:8t amplifier:3 no_ambient no_clear no_icon hide_particles
#    - wait 7t
#    - teleport <player> <server.flag[fort.menu_spawn].above[0.5]>

island_task:
  type: task
  debug: false
  script:
    - narrate a
  lobby_circle:
    anim:
      - define loc <server.flag[fort.pregame.lobby_circle.loc].with_pose[0,0]>
      - define circle <server.flag[fort.pregame.lobby_circle.circle]>

      - while <[circle].is_spawned>:
        - adjust <[circle]> interpolation_start:0
        - adjust <[circle]> left_rotation:<quaternion[0,0,1,0].mul[<location[0,0,-1].to_axis_angle_quaternion[<[loop_index].div[85]>]>]>
        - adjust <[circle]> interpolation_duration:1t

        #-square
        - if <[loop_index].mod[6]> == 0:
          - define size <util.random.decimal[1.2].to[1.9]>
          #- define dest <[loc].above[<util.random.decimal[1.8].to[2.6]>]>

          - define origin <[loc].below[0.4].random_offset[0.75,0,0.75]>
          - define end_translation   0,<util.random.decimal[1.8].to[2.6]>,0

          - spawn <entity[text_display].with[text=<element[⬛].color[#<list[D8F0FF|AAF4FF].random>]>;pivot=VERTICAL;scale=<[size]>,<[size]>,<[size]>;background_color=transparent]> <[origin]> save:fx
          - define fx <entry[fx].spawned_entity>

          - wait 1t

          - adjust <[fx]> interpolation_start:0
          - adjust <[fx]> translation:<[end_translation]>
          - adjust <[fx]> scale:0,0,0
          - adjust <[fx]> interpolation_duration:50t
          - run fort_global_handler.death_fx.remove_square def:<map[square=<[fx]>;wait=52]>
        - else:
          - wait 1t
