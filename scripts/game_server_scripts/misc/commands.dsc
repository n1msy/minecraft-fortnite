fort_commands:
  type: command
  name: fortnite
  debug: false
  description: Fortnite Setup Commands
  usage: /fortnite
  permission: fort.setup
  aliases:
  - fort
  tab completions:
    1: <list[lobby_setup|lobby_teleport|pregame_spawn|fill_chests|fill_ammo_boxes|supply_drop]>
  script:
  - choose <context.args.first||null>:

    - case skip:
    #skip the phase
      - flag server fort.temp.phase_skipped
      - narrate "<&a>Skipping current phase."

    # - [ SETUP COMMANDS ] - #
    - case lobby_setup:
      - run fort_lobby_setup
      - narrate "<&a>Nimnite lobby menu set."
      - if !<server.has_flag[fort.pregame.spawn]>:
        - narrate "<&c>[Warning] Pregame island hasn't been setup."
        - narrate "<&7>Type /fort pregame_setup to set."

    - case lobby_teleport:
      #- define loc <player.location.round.above[0.5]>
      - define loc <server.flag[fort.pregame.lobby_circle.loc]>
      - flag server fort.pregame.lobby_circle.loc:<[loc]>

      - define loc <[loc].with_pose[0,0]>
      - define circle <server.flag[fort.pregame.lobby_circle.circle]||null>
      - if <[circle]> != null && <[circle].is_spawned>:
        - remove <[circle]>

      - define text <server.flag[fort.pregame.lobby_circle.text]||null>
      - if <[text]> != null && <[text].is_spawned>:
        - remove <[text]>

      - define planes <server.flag[fort.pregame.lobby_circle.planes]||null>
      - flag server fort.pregame.lobby_circle.planes:!
      - if <[planes]> != null:
        - foreach <[planes]> as:pl:
          - remove <[pl]> if:<[pl].is_spawned>

      - define circle_icon <&chr[22].font[icons]>
      - spawn <entity[text_display].with[text=<[circle_icon]>;background_color=transparent;pivot=FIXED;scale=3,3,3]> <[loc].below[0.5].with_pitch[-90]> save:circle
      - flag server fort.pregame.lobby_circle.circle:<entry[circle].spawned_entity>

      #- define text <element[<&l>RETURN TO MENU].color_gradient[from=<color[#ffca29]>;to=<&e>]>
      - define text <&chr[23].font[icons]>
      - spawn <entity[text_display].with[text=<[text]>;background_color=transparent;pivot=CENTER;scale=1.35,1.35,1.35]> <[loc].above[2]> save:text
      - flag server fort.pregame.lobby_circle.text:<entry[text].spawned_entity>

      #-circular transparent outline
      #i think this might be off-center?
      - define radius 1.1
      - define cyl_height 1.7

      - define center <[loc].below[2.2]>

      - define circle <[center].points_around_y[radius=<[radius]>;points=16]>

      - foreach <[circle]> as:plane_loc:

        - define angle <[plane_loc].face[<[center]>].yaw.to_radians>
        - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

        #- define plane_loc <[plane_loc].face[<[loc]>]>
        #- define plane_loc <[plane_loc].with_yaw[<[plane_loc].yaw.mul[-1]>].with_pitch[0]>

        - spawn <entity[item_display].with[item=<item[white_stained_glass_pane].with[custom_model_data=2]>;translation=0,0.8,0;scale=1.2505,<[cyl_height]>,1.2505]> <[plane_loc].above[1.75].face[<[loc]>].with_pitch[0]> save:plane
        - define plane     <entry[plane].spawned_entity>
        - flag server fort.pregame.lobby_circle.planes:->:<[plane]>

      - define ellipsoid <[loc].to_ellipsoid[1.3,3,1.3]>
      - note <[ellipsoid]> as:fort_lobby_circle

      - run pregame_island_handler.lobby_circle.anim

    - case pregame_spawn:
      - flag server fort.pregame.spawn:<player.location.round.with_pose[0,-90]>
      - narrate "<&a>Nimnite pregame island spawn set."

    - case chest:
      #-much better to use the item instead and place them down
      - define loc <player.location.center.above[0.1]>
      - if <[loc].material.name> != air:
        - narrate "<&c>Invalid spot."
        - stop
      - define text "<&7><&l>[<&e><&l>Sneak<&7><&l>] <&f><&l>Search"
      - define angle <player.location.forward.direction[<player.location>].yaw.mul[-1].to_radians>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>
      - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=15]>;scale=1.25,1.25,1.25;left_rotation=<[left_rotation]>] <[loc]> save:chest
      - spawn TEXT_DISPLAY[text=<[text]>;pivot=center;scale=1,1,1;view_range=0.035;see_through=true] <[loc].above[0.75]> save:chest_text
      - modifyblock <[loc]> barrier
      - define loc <player.location.center>
      - flag <[loc]> fort.chest.model:<entry[chest].spawned_entity>
      - flag <[loc]> fort.chest.text:<entry[chest_text].spawned_entity>
      - flag <[loc]> fort.chest.yaw:<player.location.yaw.add[180].to_radians>
      #so it's not using the fx constantly when not in use
      - flag <[loc]> fort.chest.opened
      - flag server fort.chests:->:<[loc]>
      - narrate "<&a>Set chest at <&f><[loc].simple>"
    - case fill_chests fill_ammo_boxes:
      - define container_type <map[fill_chests=chests;fill_ammo_boxes=ammo_boxes].get[<context.args.first>]>
      - define containers <server.flag[fort.<[container_type]>]||<list[]>>
      - narrate "<&7>Filling all <[container_type].replace[_].with[ ]>..."

      - foreach <[containers]> as:loc:
        - inject fort_chest_handler.fill_<map[chests=chest;ammo_boxes=ammo_box].get[<[container_type]>]>

      - narrate "<&a>All <[container_type].replace[_].with[ ]> have been filled <&7>(<[containers].size>)<&a>."

    - case supply_drop:
      - define loc <player.location.with_pitch[0]>
      - run fort_chest_handler.send_supply_drop def:<map[loc=<[loc]>]>
      - narrate "<&a>Supply drop sent at <&f><[loc].simple><&a>."
    - default:
      - narrate "<&c>Invalid arg."