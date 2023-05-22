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
      - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=15]>;scale=1.25,1.25,1.25;left_rotation=0,1,0,0] <[loc]>
      - modifyblock <[loc]> barrier
      - narrate "<&a>Set chest at <&f><[loc].simple>"
    - default:
      - narrate "<&c>Invalid arg."