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
      - define loc <player.location.center.above[0.1]>
      - if <[loc].material.name> != air:
        - narrate "<&c>Invalid spot."
        - stop
      - define text "<&7><&l>[<&e><&l><&keybind[key.sneak]><&7><&l>] <&f><&l>Search"
      - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=15]>;scale=1.25,1.25,1.25;left_rotation=0,1,0,0] <[loc]> save:chest
      - spawn TEXT_DISPLAY[text=<[text]>;pivot=center;scale=1,1,1;view_range=0.035;see_through=true] <[loc].above[0.75]> save:chest_text
      - modifyblock <[loc]> barrier
      - flag <[loc]> fort.chest:<entry[chest].spawned_entity>
      - flag <[loc]> fort.chest_text:<entry[chest_text].spawned_entity>
      - narrate "<&a>Set chest at <&f><[loc].simple>"
    - default:
      - narrate "<&c>Invalid arg."