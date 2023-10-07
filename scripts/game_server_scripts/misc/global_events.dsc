fort_global_handler:
  type: world
  debug: false
  definitions: data
  events:

    #-only show teammates in tablist?
    #on player receives tablist update:
    #- determine cancelled

    on player breaks block with:!fort_pickaxe_*:
    - determine cancelled

    on block fades:
    - determine cancelled

    on block falls:
    - determine cancelled

    on player picks up item flagged:build:
    - determine cancelled

    #make one task for dropping all items?
    ###make sure to remove the flag, since they technically can't play after they die
    on player death:
    - define cause  <context.cause||null>
    - define killer <context.damager||null>
    - define loc    <player.location>

    - define drops <context.drops>

    - determine passively <list[]>

    - flag player fort.emote:!

    - if <player.has_flag[build]>:
      - define drops <player.flag[build.last_inventory]>
      #dont really need to remove this flag, since the while also checks if the player is alive but oh well
      - flag player build:!

    #so clickable shit in the inventory doesn't drop
    - define drops <[drops].filter[has_flag[action].not].filter[has_flag[type].not]>

    #turn any scoped guns back into unscoped
    - if <player.has_flag[fort.gun_scoped]>:
      - define gun_in_hand <player.item_in_hand>
      - define cmd         <[gun_in_hand].custom_model_data>
      - define drops <[drops].exclude[<[gun_in_hand]>].include[<[gun_in_hand].with[custom_model_data=<[cmd].sub[1]>]>]>
      - flag player fort.gun_scoped:!

    #-drop ammo
    - foreach <list[light|medium|heavy|shells|rockets]> as:ammo_type:
      - if <player.flag[fort.ammo.<[ammo_type]>]> > 0:
        - define qty <player.flag[fort.ammo.<[ammo_type]>]>
        - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[qty]>;loc=<[loc]>]>
        - flag player fort.ammo.<[ammo_type]>:0

    #-drop mats
    - foreach <list[wood|brick|metal]> as:mat:
      - if <player.flag[fort.<[mat]>.qty]> > 0:
        - define qty <player.flag[fort.<[mat]>.qty]>
        - run fort_pic_handler.drop_mat def:<map[mat=<[mat]>;qty=<[qty]>]>
        - flag player fort.<[mat]>.qty:0

    #-drop guns
    - foreach <[drops].filter[script.name.starts_with[gun_]]> as:gun:
      - run fort_gun_handler.drop_gun def:<map[gun=<[gun]>]>

    #-drop all items (consumables)
    - foreach <[drops].filter[script.name.starts_with[fort_item_]]> as:item:
      - run fort_item_handler.drop_item def:<map[item=<[item].script.name>;qty=<[item].quantity>;loc=<[loc]>]>

    #no need to exclude the fort_pic, since it's not being dropped by any of these
    #clearing inventory in case players were holding the pencil and blueprint while building
    - inventory clear

    on entity damaged:
    - define e      <context.entity>
    - if !<[e].is_living>:
      - stop

    - if <[e].world.name> == pregame_island:
      - determine passively cancelled
      - stop

    - define damage <context.damage>
    - define shield <[e].armor_bonus||null>

    #-fall damage ignores shield
    - if <context.cause> == FALL:
      - if <[e].has_flag[fort.using_glider]>:
        - determine passively cancelled
        - stop

      - run fort_global_handler.land_fx
      #you take half the fall damage now
      - define damage <[damage].div[1.5]>
      #that way the annoying head thing doesn't happen when falling by the smallest amount
      - if <[damage]> < 5:
        - determine passively cancelled
          #(stop the damage indicator from continuing)
        - stop
      - else:
        - determine passively <[damage]>
    #-if not shield, just use regular damage system
    ##check this some time: in fort, is the damage indicator blue, even if the target takes damage
    ##for both shield and white health?
    - else if <[shield]> != null && <[shield]> > 0:
      #not cancelling, so animation can play
      - determine passively 0
      - define color <&b>
      - if <[shield]> >= <[damage]>:
        - adjust <[e]> armor_bonus:<[shield].sub[<[damage]>]>
      - else:
        #if shield is less than damage
        - adjust <[e]> armor_bonus:0
        - define damage <[damage].sub[<[shield]>]>
        - if <[e].health.sub[<[damage]>]> <= 0:
          - adjust <[e]> health:0
        #-shield break sfx
        - playsound <player> sound:BLOCK_GLASS_BREAK pitch:1.5

    - if <[e].is_player>:
      - playsound <[e]> sound:ITEM_ARMOR_EQUIP_LEATHER pitch:2

    #guns handle damage indicators a little differently
    - if !<[e].has_flag[fort.shot]>:
      - define color <&f> if:<[color].exists.not>
      - define entity <context.entity>
      - if <[entity].has_flag[spawned_dmodel_emotes]> && <[entity].flag[spawned_dmodel_emotes].has_flag[emote_hitbox]||false>:
        #this way, the damage indicator shows up on the animated emote and not the player
        - define entity <[entity].flag[spawned_dmodel_emotes].flag[emote_hitbox]>
      - run fort_global_handler.damage_indicator def:<map[damage=<[damage].mul[5].round>;entity=<context.entity>;color=<[color]>]>

    - if <[e].is_player>:
      - wait 1t
      - adjust <queue> linked_player:<[e]>
      - inject update_hud

    #since you only have access to 1-6 slots, and the other slots are category names
    #WAY better way of doing this but my brain is too tired to think rn
    on player clicks in inventory slot:2|3|4|5|7|8|9|10|11|12|13|14|15|16|17|18|28|29|30|31|32|33|34|35|36|19|20|21|22|23|24|25|26|27:
    #19-27 are the resources/ammo slots
    #in case it's part of the drop menu
    #this stop is for emotes
    - stop if:<context.clicked_inventory.inventory_type.equals[CRAFTING]>
    - stop if:<context.item.has_flag[action]||false>
    - if <util.list_numbers[from=19;to=27].contains[<context.slot>]> && <context.item.material.name> != air:
      - stop
    - if <list[2|3|4|5].contains[<context.slot>]> && <context.clicked_inventory.inventory_type> == PLAYER:
      #remove/re-add rarity bg
      #if they're clicking WITH a fort item or ON one, update the rarity
      - if <context.item.has_flag[rarity]> || <context.cursor_item.has_flag[rarity]>:
        - wait 0.5t
        - inject update_hud
      - stop

    - determine cancelled

    ##small bug where if you swap items the rarity thing disappears?
    on player drags in inventory:
    - if <context.slots.contains[<util.list_numbers[from=19;to=27]>]> && <context.item.material.name> != air:
      - stop
    - if <context.slots.contains_any[7|8|9|10|11|12|13|14|15|16|17|18|28|29|30|31|32|33|34|35|36|19|20|21|22|23|24|25|26|27]>:
      - determine passively cancelled
    - if <list[2|3|4|5].contains_any[<context.slots>]> && <context.clicked_inventory.inventory_type> == CRAFTING:
      - determine passively cancelled
    #remove/re-add rarity bg
    #if they're clicking WITH a fort item or ON one, update the rarity
    - if <context.item.has_flag[rarity]>:
      - wait 0.5t
      - inject update_hud

    on player clicks in inventory action:PLACE_SOME:
    - determine cancelled

    on player clicks in inventory flagged:fort.drop_menu:
    - define i <context.item>
    - if !<[i].has_flag[action]>:
      - stop
    - determine passively cancelled

    - define total    <player.flag[fort.drop_menu.total]>
    - define type     <player.flag[fort.drop_menu.type]>
    - define sub_type <player.flag[fort.drop_menu.sub_type].to_titlecase>
    - define current_qty <player.flag[fort.drop_menu.qty]>

    - choose <[i].flag[action]>:
      - case drop:
        - if <context.click> == LEFT:
          - playsound <player> sound:BLOCK_NOTE_BLOCK_BASS pitch:2
          - if <[current_qty]> > 0:
            - choose <[type]>:
              - case ammo:
                - flag player fort.ammo.<[sub_type]>:-:<[current_qty]>
                - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[sub_type]>;qty=<[current_qty]>]>
              - case material:
                - flag player fort.<[sub_type]>.qty:-:<[current_qty]>
                - run fort_pic_handler.drop_mat def:<map[mat=<[sub_type]>;qty=<[current_qty]>]>
              - default:
                - narrate "<&c>Oops... that wasn't supposed to happen. Whatever..."
          - inventory close
          - inject update_hud
        - else if <context.click> == RIGHT:
          - inventory close
        - stop
      - case max:
        - playsound <player> sound:BLOCK_NOTE_BLOCK_HAT
        - define qty <[total]>
      - case min:
        - playsound <player> sound:BLOCK_NOTE_BLOCK_HAT
        - define qty 1
      - default:
        - playsound <player> sound:BLOCK_NOTE_BLOCK_HAT
        - define add_qty     <[i].flag[action].as_decimal>
        - define qty <[current_qty].add[<[add_qty]>]>
        - if <[current_qty].add[<[add_qty]>]> > <[total]>:
          - define qty <[total]>
        - else if <[current_qty].add[<[add_qty]>]> < 0:
          - define qty 0

    - choose <[type]>:
      - case ammo:
        - define icon <&chr[E<map[light=111;medium=122;heavy=133;shells=144;rockets=155].get[<[sub_type]>]>].font[icons]>
        - define name "<[sub_type]> Ammo"
      - case material:
        - define icon <&chr[A<map[wood=112;brick=223;metal=334].get[<[sub_type]>]>].font[icons]>
        - define name <[sub_type]>

    - flag player fort.drop_menu.changed_qty
    #qty flag is handled in here
    - inject fort_global_handler.open_drop_menu

    on player clicks paper in inventory:
    - determine passively cancelled
    - wait 1t
    - define i <context.item>
    - if !<[i].has_flag[type]>:
      - stop

    - define type <[i].flag[type]>
    #-drop menu
    - choose <[type]>:
      - case ammo:
        - define type_name ammo_type
        - define sub_type      <[i].flag[ammo_type].to_titlecase>
        - define total         <player.flag[fort.ammo.<[sub_type]>]>
        - define icon          <&chr[E<map[light=111;medium=122;heavy=133;shells=144;rockets=155].get[<[sub_type]>]>].font[icons]>
        - define name         "<[sub_type]> Ammo"
        - define script_path   fort_gun_handler.drop_ammo
        - define flag_path     fort.ammo.<[sub_type]>
      - case material:
        - define type_name mat
        - define sub_type      <[i].flag[mat].to_titlecase>
        - define total         <player.flag[fort.<[sub_type]>.qty]>
        - define icon          <&chr[A<map[wood=112;brick=223;metal=334].get[<[sub_type]>]>].font[icons]>
        - define name          <[sub_type]>
        - define script_path   fort_pic_handler.drop_mat
        - define flag_path     fort.<[sub_type]>.qty

    - if <context.click> == RIGHT:
      - playsound <player> sound:BLOCK_NOTE_BLOCK_HAT
      #i they were already in the drop menu, dont erase the flags when it closes
      - if <player.has_flag[fort.drop_menu]>:
        - flag player fort.drop_menu.changed_qty

      - define qty 0
      - inject fort_global_handler.open_drop_menu
    - else if <context.click> == LEFT:
      - playsound <player> sound:BLOCK_NOTE_BLOCK_BASS pitch:2
      - flag player <[flag_path]>:--
      - run <[script_path]> def:<map[<[type_name]>=<[sub_type]>;qty=1]>
      - inject update_hud

    on player closes inventory flagged:fort.drop_menu:
    #meaning the inventory wasn't actually closed, just a new one was opened
    - if <player.has_flag[fort.drop_menu.changed_qty]>:
      - flag player fort.drop_menu.changed_qty:!
      - stop
    - flag player fort.drop_menu:!

    on *grass*|dead_bush physics:
    - determine cancelled

    on block drops item from breaking:
    - determine cancelled

    on player changes food level:
    - determine cancelled

    on player heals:
    - determine cancelled

  damage_indicator:

    ##make sure to make the damage indicators blue if shield

    - define damage <[data].get[damage]>
    - define entity <[data].get[entity]>
    - define color  <[data].get[color]>

    - define text          <[color]><&l><[damage]>
    - define pivot         center
    - define scale         <location[1,1,1]>
    - define text_shadowed true
    - define opacity 255

    - define loc <[entity].location.forward_flat[0.5].with_pose[0,0].add[<util.random.decimal[-2].to[2]>,2,<util.random.decimal[-2].to[2]>]>

    - spawn <entity[text_display].with[text=<[text]>;pivot=<[pivot]>;scale=<[scale]>;text_shadowed=<[text_shadowed]>;opacity=<[opacity]>;background_color=transparent]> <[loc]> save:e
    - define e <entry[e].spawned_entity>

    - wait 2t
    - adjust <[e]> interpolation_start:0
    - adjust <[e]> scale:<location[2,2,2]>
    - adjust <[e]> interpolation_duration:3t
    - adjust <[e]> opacity:255

    - wait 1s

    #i like this effect, but fortnite's is the same as when the harvest disappears (go up + fade)
    #zoom disappear effect, or opacity effect?
    - adjust <[e]> interpolation_start:0
    - adjust <[e]> scale:<location[0,0,0]>
    - adjust <[e]> interpolation_duration:3t
    - adjust <[e]> opacity:255

    - wait 3t
    - remove <[e]>

  open_drop_menu:
  #required definitions: <[icon]>, <[qty]>, and much more..

    - flag player fort.drop_menu.qty:<[qty]>
    - flag player fort.drop_menu.total:<[total]>
    - flag player fort.drop_menu.type:<[type]>
    - flag player fort.drop_menu.sub_type:<[sub_type]>

    - define size 9
    - define custom_gui <&f><proc[spacing].context[-8]><&chr[0007].font[icons]>
    - define title "<[custom_gui]><proc[spacing].context[-119]><&f><[icon]> <&7><[qty]><&f>/<[total]>"
    - define blank     <item[paper].with[custom_model_data=17]>
    - define drop      <[blank].with[flag=action:drop;display=<&f>Drop <&b><player.flag[fort.drop_menu.qty]||0> <&f><[name]> <[icon]><&f> ?;lore=<list[<n><&9><&l>Left-Click <&f>to drop.|<&c><&l>Right-Click <&f>to cancel drop.]>]>
    - define min       <[blank].with[flag=action:min;display=<&c><&l>Minimum;lore=<&e>Click to set.]>
    - define less_1    <[blank].with[flag=action:-1;display=<&c><&l>-1;lore=<&e>Click to subtract.]>
    - define less_10   <[blank].with[flag=action:-10;display=<&c><&l>-10;lore=<&e>Click to subtract.]>
    - define less_100  <[blank].with[flag=action:-100;display=<&c><&l>-100;lore=<&e>Click to subtract.]>
    - define more_1    <[blank].with[flag=action:+1;display=<&a><&l>+1;lore=<&e>Click to add.]>
    - define more_10   <[blank].with[flag=action:+10;display=<&a><&l>+10;lore=<&e>Click to add.]>
    - define more_100  <[blank].with[flag=action:+100;display=<&a><&l>+100;lore=<&e>Click to add.]>
    - define max       <[blank].with[flag=action:max;display=<&a><&l>Maximum;lore=<&e>Click to set.]>

    - define contents <list[<[min]>|<[less_100]>|<[less_10]>|<[less_1]>|<[drop]>|<[more_1]>|<[more_10]>|<[more_100]>|<[max]>]>
    - define inv <inventory[generic[title=<[title]>;size=<[size]>;contents=<[contents]>]]>

    - inventory open d:<[inv]>

  land_fx:

  - define loc <player.location.above[0.2]>
  - define circle <[loc].points_around_y[radius=1;points=10]>
  - foreach <[circle]> as:point:
    - define velocity <[point].sub[<[loc]>].normalize.div[8].with_y[0.15]>
    - playeffect effect:CLOUD offset:0 at:<[loc]> visibility:100 velocity:<[velocity]>

  death_fx:
  #-create the "on your knees" animation or no? because the player fades away anyways
    anim:
      - define loc <player.location>

      - wait 2s
      - run dmodels_spawn_model def.model_name:emotes def.location:<[loc].above[2.1]> def.yaw:<[loc].yaw> save:result
      - define spawned <entry[result].created_queue.determination.first||null>
      - run dmodels_set_scale def.root_entity:<[spawned]> def.scale:1.87,1.87,1.87
      - run dmodels_animate def.root_entity:<[spawned]> def.animation:death

      - define loc <[loc].with_pose[0,0]>
      - run fort_global_handler.death_fx.ray def:<map[loc=<[loc]>]>

      - playsound <[loc]> sound:BLOCK_BEACON_DEACTIVATE pitch:1.75
      - playsound <[loc]> sound:ENTITY_ALLAY_DEATH pitch:1.25

      - run fort_global_handler.death_fx.squares def:<map[loc=<[loc]>]>
      - wait 6t
      - run fort_global_handler.death_fx.circles def:<map[loc=<[loc]>]>

      #- playsound <[loc]> sound:BLOCK_ANVIL_DESTROY pitch:2

    ray:
      - define loc <[data].get[loc].above[2.535]>
      - define text <&chr[21].font[icons]>

      - spawn <entity[text_display].with[text=<[text]>;pivot=VERTICAL;translation=-0.06,0,0;scale=0,12,0;background_color=transparent]> <[loc]> save:ray
      - define ray <entry[ray].spawned_entity>

      - wait 1t

      - adjust <[ray]> interpolation_start:0
      - adjust <[ray]> scale:7,12,7
      - adjust <[ray]> interpolation_duration:2t

      - wait 2t

      - repeat 15:
        - adjust <[ray]> interpolation_start:0
        - define size <util.random.decimal[4].to[7.5]>
        - adjust <[ray]> scale:<[size]>,12,<[size]>
        - adjust <[ray]> interpolation_duration:2t
        - wait 2t

      - adjust <[ray]> interpolation_start:0
      - adjust <[ray]> scale:<[size].sub[2]>,0,<[size].sub[2]>
      - adjust <[ray]> interpolation_duration:3t

      - wait 3t

      - remove <[ray]> if:<[ray].is_spawned>

    squares:
      - define loc <[data].get[loc].above[0.3]>
      - define drone_Loc <[loc].above[2.3]>
        #shadowed or no?

      #the effect also looks really cool in first person (when doing it in the player's position)
      - repeat 30:

        #-"drone" (temp, wait for model?)
        - playeffect effect:REDSTONE at:<[drone_loc]> offset:0 visibility:50 special_data:1.1|<color[#828282]>

        - define size <util.random.decimal[0.8].to[1.62]>
        - define dest <[loc].above[<util.random.decimal[1.8].to[2.6]>].random_offset[0.15,0,0.15]>

        - define origin <[loc].random_offset[0.5,0,0.5]>

        - define start_translation <[origin].sub[<[loc]>]>
        - define end_translation   <[dest].sub[<[loc]>]>

        - spawn <entity[text_display].with[text=<element[⬛].color[#<list[D8F0FF|AAF4FF].random>]>;pivot=VERTICAL;scale=<[size]>,<[size]>,<[size]>;translation=<[start_translation]>;background_color=transparent]> <[loc]> save:fx
        - define fx <entry[fx].spawned_entity>
        - wait 1t

        - adjust <[fx]> interpolation_start:0
        - adjust <[fx]> translation:<[end_translation]>
        - adjust <[fx]> scale:0,0,0
        - adjust <[fx]> interpolation_duration:15t
        - run fort_global_handler.death_fx.remove_square def:<map[square=<[fx]>]>

    remove_square:
      - define square <[data].get[square]>
      - define wait <[data].get[wait]||17>
      - wait <[wait]>t
      - remove <[square]> if:<[square].is_spawned>

    circles:
      - define loc <[data].get[loc]>
      - define start_loc   <[loc].above[1.9]>
      - define translation <[loc].above[2.25].sub[<[start_loc]>]>

      - repeat 3:

        - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=21]>;scale=3.25,3.25,3.25] <[start_loc]> save:circle_<[value]>
        - define circle_<[value]> <entry[circle_<[value]>].spawned_entity>
        - define circles:->:<[circle_<[value]>]>

        - wait 3t

        - adjust <[circle_<[value]>]> interpolation_start:0
        - adjust <[circle_<[value]>]> translation:<[translation]>
        - adjust <[circle_<[value]>]> scale:0,0,0
        - adjust <[circle_<[value]>]> interpolation_duration:17t

      - wait 2s
      - remove <[circles].filter[is_spawned]>



