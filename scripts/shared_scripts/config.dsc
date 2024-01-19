nimnite_config:
  type: data
  #default: 60
  minimum_players: 4
  maximum_players: 100

  #how much mats players get
  harvesting_multiplier: 1

  #available versions: 1, 2
  bus_view_mode: 2

  materials:
    wood:
      hp: 150
    brick:
      hp: 400
    metal:
      hp: 600

  game_servers:
  #available options: solo, duos, squads
    fort_1:
      mode: solo

  Spitfire_Skin: ewogICJ0aW1lc3RhbXAiIDogMTY2MTc2ODM2MTA2MCwKICAicHJvZmlsZUlkIiA6ICIxNmFkYTc5YjFjMDk0MjllOWEyOGQ5MjgwZDNjNjE5ZiIsCiAgInByb2ZpbGVOYW1lIiA6ICJMYXp1bGl0ZV9adG9uZSIsCiAgInNpZ25hdHVyZVJlcXVpcmVkIiA6IHRydWUsCiAgInRleHR1cmVzIiA6IHsKICAgICJTS0lOIiA6IHsKICAgICAgInVybCIgOiAiaHR0cDovL3RleHR1cmVzLm1pbmVjcmFmdC5uZXQvdGV4dHVyZS80YWU4ZDU2NjA2ODMxMWMzZTU5ZTYzZTA0OGI3YzgyZTU4MzAxNGU0NGQ4ODRjMzk3ZGVmNmI2ZThiYWQwYmNlIgogICAgfQogIH0KfQ==;B5DN9OIB+ep5JfcFyfo5bWvIXPxyU049OS0ZB441UXJxZtjjayEJJLCuE59QwCss4BjmEG60080so9BO12VgFDmDla77EEBwg7pT6YWCndpYLvKRVqXlKSylrN1iQF4ojAyfprqjJOyjXgfK/K54SLviKM3C1anT5g/88B/Vgs1SAimtgjz10XiAeAjb/ePGzWz5tyAuN50h9ipNX+5mVMPeWaeuu0iNdcql5LvoY4RP4hDx4fq0gZTtKmkOqpIWdeBUKR7RollwrwtZrm4MwwDvJiNL9XqWIv6lkl26vo85YduPZiW9CoQo666khgGMwN/59E7UbZb8K+1/zaeWFfkRy94pz7B4naDYiyQjYelxAhoYEgAE+J+9/CqGicsV20oRIe8VXvUwKfailU9kNBcCujszY94xDwbKDhzws7RkDIwzT43iYaO7ift5B1vI6WxFfcabbqkLOMFPmYt55m3gquJ7uARjfa0M7g2SWNMSuFIuBiXZv5FGK/ENdPxWmeLrJlR2Xoi9WoJDSu6nUsTX3OOPZJC+Ifiz4Q9wr6F5GoZgHtmDqTJ3cQ8nykyGoPPgCwzxFf6c0kB7wXTo2M8uTsa9MWrvd0IaZlrgxB1Raw3LacjmRzvjkAPCGwKJPyiS6PGcozErCMn4i2/7mEZL49tT10F8WFsvfFvGQaI=

  killfeed:
    #a lot of these placeholders like "_killer_" and "_player_" aren't really necessary, but i like having them to visualize the msg better

    # - [ From Weapons ] - #
    pickaxe:
    #either pickaxe, hand, or gun (im gonna make it this way on purpose, just to spice it up, not because im lazy or anything -> this commentary is for people in the future to show them I KNOW THIS HAPPENS)
      - <gray>_killer_ Bludgeoned <red><bold>_player_
    shotgun:
      - <gray>_killer_ shotgunned <red><bold>_player_
    sniper:
    #show distance
      - <gray>_killer_ Sniped <red><bold>_player_
    sniper_noscope:
    #show distance
      - <gray>_killer_ NO-SCOPED <red><bold>_player_
    gun_default:
    #show distance if over 50m
    #with a ___ part is added in the handler
      - <gray>_killer_ Eliminated <red><bold>_player_

    # - [ From Void ] - #
    #i added these myself
    self_void:
      - <red><bold>_player_<reset> <gray>got fell into the void
    enemy_void:
      - <gray>_killer_ threw <red><bold>_player_<reset> <gray>into the void

    # - [ From Fall ] - #
    self_fall:
    #show distance (idk how, unless using waituntil every jump)
      - <red><bold>_player_<reset> <gray>didn't stick the landing
    enemy_fall:
      - <gray>_killer_ introduced <red><bold>_player_<reset> <gray>to Gravity
      - <gray>_killer_ Eliminated <red><bold>_player_<reset> <gray>with a great fall

    # - [ From Explosion ] - #
    self_explosion:
      - <red><bold>_player_<reset> <gray>is <gray><&o>Literally <gray>on fire
      - <red><bold>_player_<reset> <gray>went out with a <&l>BANG
      - <red><bold>_player_<reset> <gray>went out with a <&l>BOOM
    enemy_explosion:
      - <gray>_killer_ <&sq>sploded <red><bold>_player_

    # - [ From Storm ] - #
    self_storm:
    #idk if this one is right, but im adding them anyways
      - <red><bold>_player_<reset> <gray>got lost in the storm
    enemy_storm:
      - <gray>_killer_ eliminated <red><bold>_player_<reset> <gray>in the storm

    # - [ Leave/Self-Death ] - #
    self_death:
      - <red><bold>_player_<reset> <gray>played themselves
    quit:
      - <red><bold>_player_<reset> <gray>checked out early
      - <red><bold>_player_<reset> <gray>took the L

    #don't really need this, using the quit event instead
    #kick:
    #  - <red><bold>_player_<reset> <gray>was struck by the Banhammer

  structures:

    #was using server flags for these, but now using config system...
    #shouldn't i just flag all this data onto the trees themselves? -> only problem with that would be in case i wanted to change
    #structure data on the whim

    autumn_tree:
      type: TREE
      material: wood
      health: 300

    #-Pine Trees
    weird_pine_tree:
      type: TREE
      material: wood
      health: 300

    short_pine_tree_1:
      type: TREE
      material: wood
      health: 200

    short_pine_tree_2:
      type: TREE
      material: wood
      health: 200

    tall_pine_tree_1:
      type: TREE
      material: wood
      health: 300

    tall_pine_tree_2:
      type: TREE
      material: wood
      health: 300

    #-Oak Trees
    weird_oak_tree:
      type: TREE
      material: wood
      health: 600

    tall_oak_tree:
      type: TREE
      material: wood
      health: 600

    small_oak_tree_1:
      type: TREE
      material: wood
      health: 200

    small_oak_tree_2:
      type: TREE
      material: wood
      health: 200

    #-Moisty Trees
    moisty_1:
      type: TREE
      material: wood
      health: 600

    moisty_2:
      type: TREE
      material: wood
      health: 600

    moisty_3:
      type: TREE
      material: wood
      health: 600

    moisty_4:
      type: TREE
      material: wood
      health: 600

    moisty_5:
      type: TREE
      material: wood
      health: 600

    moisty_6:
      type: TREE
      material: wood
      health: 600

    moisty_7:
      type: TREE
      material: wood
      health: 600

    moisty_8:
      type: TREE
      material: wood
      health: 600

    moisty_9:
      type: TREE
      material: wood
      health: 600

    moisty_tree:
      type: TREE
      material: wood
      health: 600

    moisty_skinny_tree:
      type: TREE
      material: wood
      health: 300

    #-Short Rocks
    short_rock_1:
      type: ROCK
      material: brick
      health: 180

    short_rock_2:
      type: ROCK
      material: brick
      health: 300

    #-Tall Rocks
    tall_rock_1:
      type: ROCK
      material: brick
      health: 180

    tall_rock_2:
      type: ROCK
      material: brick
      health: 300

    tall_rock_3:
      type: ROCK
      material: brick
      Health: 450