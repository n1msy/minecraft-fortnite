fort_commands:
  type: command
  name: fortnite
  debug: false
  description: Fortnite Setup Commands
  usage: /fortnite
  permission: fort.setup
  aliases:
  - fort
  script:
  - choose <context.args.first||null>:
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
    - case fill_chests:
      - define chests <server.flag[fort.chests]||0>
      - narrate "<&7>Filling all chests..."
      - foreach <[chests]> as:loc:
        - inject fort_chest_handler.fill_chest
      - narrate "<&a>All chests have been filled <&7>(<[chests].size>)<&a>."
    - default:
      - narrate "<&c>Invalid arg."