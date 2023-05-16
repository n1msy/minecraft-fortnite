fort_global_handler:
  type: world
  debug: false
  events:

    #since you only have access to 1-6 slots
    on player clicks in inventory slot:7|8|9:
    - determine passively cancelled

    on player drags in inventory:
    - if <context.slots.contains_any[7|8|9]>:
      - determine cancelled

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

    on block drops item from breaking:
    - stop if:<context.location.world.name.equals[fortnite_map].not>
    - determine cancelled

    on player damaged by FALL:
    #you take half the fall damage now
    - define damage <context.damage.div[2]>
    #that way the annoying head thing doesn't happen when falling by the smallest amount
    - if <[damage]> < 2:
      - determine passively cancelled
      - stop

    - determine <[damage]>

    on player changes food level:
    - determine cancelled

    on player heals:
    - determine cancelled

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
    - define drop      <[blank].with[flag=action:drop;display=<&f>Drop <&b>0 <&f><[name]> <[icon]><&f> ?;lore=<list[<n><&9><&l>Left-Click <&f>to drop.|<&c><&l>Right-Click <&f>to drop cancel.]>]>
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

