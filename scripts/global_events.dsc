fort_global_handler:
  type: world
  debug: false
  events:

    on player clicks in inventory flagged:fort.drop_menu:
    - determine passively cancelled
    - if !<context.item.has_flag[action]>:
      - stop
    - narrate <context.item.flag[action]>

    on player clicks paper in inventory:
    - determine passively cancelled
    - wait 1t
    - define i <context.item>
    - if !<[i].has_flag[type]>:
      - stop

    #-drop menu
    - choose <[i].flag[type]>:
      - case ammo:
        - define ammo_type <[i].flag[ammo_type]>
        - define total <player.flag[fort.ammo.<[ammo_type]>]>
        - define icon <&chr[E0<map[light=11;medium=22;heavy=33;shells=44;rockets=55].get[<[ammo_type]>]>].font[icons]>
        - define type <[ammo_type].to_titlecase>
      - case material:
        - define mat <[i].flag[mat]>
        - define total <player.flag[fort.<[mat]>.qty]>
        - define icon <&chr[A<map[wood=111;brick=222;metal=333].get[<[mat]>]>].font[icons]>
        - define type <[mat].to_titlecase>

    - define size 9
    - define title "<&f><[icon]> <&7>0<&f>/<[total]>"
    - define drop     <item[gold_nugget].with[flag=action:drop;display=<&f>Drop <&b>0 <&f><[type]> <[icon]><&f>?;lore=<list[<n><&9><&l>Left-Click <&f>to drop.|<&c><&l>Right-Click <&f>to drop cancel.]>]>
    - define min      <item[red_wool].with[flag=action:min;display=<&c><&l>Minimum;lore=<&e>Click to set.]>
    - define less_1   <item[red_stained_glass_pane].with[flag=qty:-1;display=<&c><&l>-1;lore=<&e>Click to subtract.]>
    - define less_10  <item[red_stained_glass_pane].with[flag=qty:-10;display=<&c><&l>-10;lore=<&e>Click to subtract.]>
    - define less_100 <item[red_stained_glass_pane].with[flag=qty:-10;display=<&c><&l>-100;lore=<&e>Click to subtract.]>
    - define more_1   <item[lime_stained_glass_pane].with[flag=qty:+1;display=<&a><&l>+1;lore=<&e>Click to add.]>
    - define more_10  <item[lime_stained_glass_pane].with[flag=qty:+10;display=<&a><&l>+10;lore=<&e>Click to add.]>
    - define more_100 <item[lime_stained_glass_pane].with[flag=qty:+1;display=<&a><&l>+100;lore=<&e>Click to add.]>
    - define max      <item[lime_wool].with[flag=action:min;display=<&a><&l>Maximum;lore=<&e>Click to set.]>

    - define contents <list[<[min]>|<[less_100]>|<[less_10]>|<[less_1]>|<[drop]>|<[more_1]>|<[more_10]>|<[more_100]>|<[max]>]>

    - define inv <inventory[generic[title=<[title]>;size=<[size]>;contents=<[contents]>]]>

    - inventory open d:<[inv]>
    - flag player fort.drop_menu.qty:0

    on player closes inventory flagged:fort.drop_menu:
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

fort_drop_menu:
  debug: false
  type: inventory
  inventory: CHEST
  title: Drop Items »
  size: 9
  definitions:
    drop: <item[gold_nugget].with[flag=action:drop;display=<list[<&r><n><&9><&l>Left-Click <&f>to drop.<n><&c><&l>Right-Click <&f>to drop cancel.]>]>
    min: <item[red_wool].with[flag=action:min;display=<&c><&l>Minimum]>
    less_1: <item[red_stained_glass_pane].with[flag=qty:-1;display=<&c><&l>-1]>
    less_10: <item[red_stained_glass_pane].with[flag=qty:-10;display=<&c><&l>-10]>
    less_100: <item[red_stained_glass_pane].with[flag=qty:-10;display=<&c><&l>-100]>
    more_1: <item[red_stained_glass_pane].with[flag=qty:+1;display=<&a><&l>+1]>
    more_10: <item[red_stained_glass_pane].with[flag=qty:+10;display=<&a><&l>+10]>
    more_100: <item[red_stained_glass_pane].with[flag=qty:+1;display=<&a><&l>+100]>
    max: <item[lime_wool].with[flag=action:min;display=<&a><&l>Maximum]>
  slots:
    - [min] [less_100] [less_10] [less_1] [drop] [more_1] [more_10] [more_100] [max]
