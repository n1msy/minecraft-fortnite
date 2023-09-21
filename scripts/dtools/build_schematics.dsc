#can be cleaner i feel like
fort_struct_wand:
  type: item
  material: blaze_rod
  display name: <&b>Structure Wand
  flags:
    schem: none

fort_struct_command:
  type: command
  name: fort_struct
  debug: false
  description: Fortnite Build Structure Schematic Commands
  usage: /fort_struct
  permission: fort.setup
  aliases:
  - fs

  tab complete:
    #ik this can be prettier and more organized but idc

    - define args   <context.args>
    - define r_args <context.raw_args>

    - define structures <server.flag[fort.structure].keys||<list[]>>

    #new arg has a special exemption, since it requires more than 2 arguments
    - if <[r_args].starts_with[save<&sp>]>:
      #so the tab completions dont appear after being put in already once
      - if <[args].size> >= 2 && <[r_args].ends_with[<&sp>]> || <[args].size> > 2:
        - stop
      - determine <list[tree|rock]>
      - stop

    - if <[r_args].starts_with[set<&sp>]> && <[args].size> <= 2:
      - if <[args].size> >= 2 && <[r_args].ends_with[<&sp>]>:
        - determine <list[health]>
      - determine <[structures]>
      - stop

    - if <[r_args].starts_with[remove<&sp>]> && <[args].size> <= 2:
      - determine <[structures]>
      - stop

    - if <[r_args].starts_with[wand<&sp>]> && <[args].size> <= 2:
      - determine <[structures]>
      - stop


    - determine <list[save|remove|set|list]>

  script:
    #most trees give around 50 wood
    #most stone structures give around 40
    - define structures <server.flag[fort.structure].keys||<list[]>>

    - define arg <context.args.first||null>
    - choose <[arg]>:

      # - [ Save Structure as Schematic ] - #
      - case save:

        - define cuboid <player.we_selection||null>
        - if <[cuboid]> == null:
          - narrate "<&c>Invalid selection."
          - stop

        - define type <context.args.get[2]||null>
        - if !<list[tree|rock].contains[<[type]>]>:
          - narrate "<&c>Specify a type. Valid options: Tree, Rock"
          - stop

        - define name <context.args.get[3]||null>
        - if <[name]> == null:
          - narrate "<&c>Invalid name."
          - stop

        - if <[structures].contains[<[name]>]>:
          - narrate "<&c>A schematic by this name already exists."
          - stop

        - define center <[cuboid].center>

        - ~schematic create name:fort_structure_<[name]> <player.location.center.with_y[<[cuboid].min.y>]> area:<[cuboid]> flags
        - ~schematic save name:fort_structure_<[name]>

        - flag server fort.structure.<[name]>.type:<[type]>
        - flag server fort.structure.<[name]>.material:<script[nimnite_config].data_key[structures.<[type]>.material]>
        - flag server fort.structure.<[name]>.health:<script[nimnite_config].data_key[structures.<[type]>.default_hp]>

        - narrate "<&a>Schematic saved as <&7><&dq><&f>fort_structure_<[name]>.schem<&7><&dq>"

      # - [ Set Structure Info ] - #
      - case set:

        - define name <context.args.get[2]||null>
        - if !<[structures].contains[<[name]>]>:
          - narrate "<&c>Invalid schematic name."
          - stop

        - define arg <context.args.get[3]||null>
        - if !<list[health].contains[<[arg]>]>:
          - narrate "<&c>Invalid sub-arg. Valid options: Health"
          - stop

        - define input <context.args.get[4]||null>
        - if <[arg]> == health && !<[input].is_integer>:
          - narrate "<&c>Invalid input."
          - stop

        - flag server fort.structure.<[name]>.health:<[input]>

        - narrate "<&a>Set <&7><&dq><&f><[name]><&7><&dq> <&a>health to: <&f><[input].format_number>"

      # - [ Get Structure Wand ] - #
      - case wand:

        - define name <context.args.get[2]||null>
        - if !<[structures].contains[<[name]>]>:
          - define name none

        - define display_name "<&b>Structure Wand <&f>(<[name]>)"

        - narrate "<&a>You recieved a <[display_name]> <&a>."
        - if <[name]> == none:
          - narrate "<&7>No structure was set. <&a>Right-click <&7>your current wand to select one.<n><&7>Or, type <&f>/fs (name) <&7>with an empty hand to receive a new wand with the structure specified."

        - if <player.item_in_hand.script.name||null> == fort_struct_wand:
          - if <[name]> == none:
            - stop
          - define slot <player.held_item_slot>
          - inventory adjust slot:<[slot]> display:<[display_name]>
          - inventory adjust slot:<[slot]> flag:schem:<[name]>
        - else:
          - give <item[fort_struct_wand].with[display=<[display_name]>;flag=schem:<[name]>]>

        - if !<player.has_flag[fort_struct.using_wand]> && <[name]> != none:
          - wait 1t
          - run fort_struct_handler.selector

      # - [ Remove Schematic ] - #
      - case remove:
        - define name <context.args.get[2]||null>
        - if !<[structures].contains[<[name]>]>:
          - narrate "<&c>Invalid schematic name."
          - stop

        - flag server fort.structure.<[name]>:!

        - if <schematic.list.contains[fort_structure_<[name]>]>:
          - ~schematic unload name:fort_structure_<[name]>

        #in case it's being removed before even being saved
        - if <util.has_file[schematics/fort_structure_<[name]>.schem]>:
          - adjust system delete_file:schematics/fort_structure_<[name]>.schem

        - flag server fort.structure.<[name]>:!

        - narrate "<&c>Removed <&7><&dq><&f>fort_structure_<[name]>.schem<&7><&dq>"

      - case list:
        - inject fort_struct_command.view_list

      - default:
        - narrate "<&c>Invalid command."

  view_list:
    - define structures <server.flag[fort.structure].keys||<list[]>>

    - if <[structures].is_empty>:
      - narrate "<&c>You have no saved structures.<n><&7>To create a structure schematic, type <&f>/fs save (name)<&7>."
      - stop

    - narrate "<n>Listing all structures:"
    - foreach <[structures]> as:name:

      - define display_name "<&f><&dq><&e><[name]><&f><&dq> Pallete Info"
      - define type         "<&7>Type: <&b><server.flag[fort.structure.<[name]>.type].to_uppercase>"
      - define material     "<&7>Material: <&b><server.flag[fort.structure.<[name]>.material]>"
      - define hp           "<&7>Health: <&b><server.flag[fort.structure.<[name]>.health]>"

      - define action       "<&a>Click to get wand."

      - define info <element[<&b><&l>[View Info]].on_hover[<[display_name]><n><n><[type]><n><[material]><n><[hp]><n><n><[action]>]>
      - narrate "<&8>- <&e><[name]> <[info].on_click[/fs wand <[name]>]>"
    - narrate <empty>

fort_struct_handler:
  type: world
  debug: false
  events:
    on player left clicks block with:fort_struct_wand flagged:fort_struct.using_wand:
      - determine passively cancelled
      - define name <context.item.flag[schem]>
      - if <[name]> == none:
        - stop

      - if !<schematic.list.contains[fort_structure_<[name]>]>:
        - ~schematic load name:fort_structure_<[name]>

      - define origin <player.flag[fort_struct.using_wand.origin]>

      - ~schematic paste name:fort_structure_<[name]> <[origin]> noair flags

      #get all the blocks before pasting, in case there's another structure cuboid overlapping
      - define cuboid  <schematic[fort_structure_<[name]>].cuboid[<[origin]>]>
      - define blocks <[cuboid].blocks.filter[material.name.equals[air].not].filter[has_flag[build].not]>

      - define center <[cuboid].center>

      #each structure has their own uuid?

      - define hp       <server.flag[fort.structure.<[name]>.health]>
      - define material <server.flag[fort.structure.<[name]>.material]>
      - define type     <server.flag[fort.structure.<[name]>.type]>

      - flag <[center]> build.structure:<[cuboid]>
      - flag <[center]> build.type:<[type]>
      - flag <[center]> build.health:<[hp]>
      - flag <[center]> build.material:<[material]>
      - flag <[center]> build.natural

      - flag <[blocks]> build.center:<[center]>

    on player right clicks block with:fort_struct_wand:

      - define origin <player.eye_location.ray_trace[default=air;range=200]>
      - if <[origin].has_flag[build.center]> && <[origin].flag[build.center].has_flag[build.natural]>:
        - define center <[origin].flag[build.center]>
        - define struct <[center].flag[build.structure]>
        - define blocks <[struct].blocks.filter[has_flag[build.center]].filter[flag[build.center].equals[<[center]>]]>
        - flag <[blocks]> build:!
        - modifyblock <[blocks]> air

      - else:

        - inject fort_struct_command.view_list
        - ratelimit <player> 1t

    on player drops fort_struct_wand:
      - determine passively cancelled
      - define name <context.item.flag[schem]>
      - if <[name]> == none:
        - stop
      - if !<schematic.list.contains[fort_structure_<[name]>]>:
        - ~schematic load name:fort_structure_<[name]>

      - define angle 90
      #- define angle 45 if:<server.flag[fort.structure.<[name]>.type].equals[rock]>
      - schematic rotate name:fort_structure_<[name]> angle:<[angle]>
      - flag player fort_struct.using_wand:!
      - wait 1t
      - run fort_struct_handler.selector

    after player holds item item:fort_struct_wand:
      #second check is in case the structure was removed
      - define structures <server.flag[fort.structure].keys||<list[]>>
      - define name       <player.item_in_hand.flag[schem]>
      - if <[name]> != none && <[structures].contains[<[name]>]>:
        - run fort_struct_handler.selector

  selector:
    - define name none
    - define type null
    - flag player fort_struct.using_wand
    - while <player.item_in_hand.script.name||null> == fort_struct_wand && <player.has_flag[fort_struct.using_wand]>:

      - define eye_loc <player.eye_location>

      - define origin <[eye_loc].ray_trace[default=air;range=200]>

      - flag player fort_struct.using_wand.origin:<[origin]>

      - if <[origin].has_flag[build.center]> && <[origin].flag[build.center].has_flag[build.natural]>:
        - actionbar "<&e><&l>RIGHT-CLICK <&c>to remove structure."

        - define struct <[origin].flag[build.center].flag[build.structure]>
        - debugblock <[struct].blocks> color:255,49,49,50 d:2t players:<player>

        - if <[display_blocks].exists>:
          - remove <[display_blocks].filter[is_spawned]>
        - flag player fort_struct.using_wand.displays_spawned:!

      - else:
        #loading the entities in for the first time
        - if !<player.has_flag[fort_struct.using_wand.displays_spawned]>:

          - define name <player.item_in_hand.flag[schem]>

          - if !<schematic.list.contains[fort_structure_<[name]>]>:
            - ~schematic load name:fort_structure_<[name]>

          - if <[display_blocks].exists> && <[display_blocks].any>:
            - remove <[display_blocks].filter[is_spawned]>

          - define display_blocks <list[]>

          - define cuboid <schematic[fort_structure_<[name]>].cuboid[<[origin]>]>
          - define min <[cuboid].min>
          - foreach <[cuboid].blocks> as:block:
            - define mat <schematic[fort_structure_<[name]>].block[<[block].sub[<[min]>]>]>

            - spawn <entity[block_display].with[material=<[mat]>;glowing=true]> <[block]> save:b_display

            - define display_blocks <[display_blocks].include[<entry[b_display].spawned_entity>]>

          - flag player fort_struct.using_wand.displays_spawned

        - define cuboid <schematic[fort_structure_<[name]>].cuboid[<[origin]>]>
        #- debugblock <[cuboid].blocks> color:0,0,0,50 d:1t players:<server.online_players>

        - foreach <[cuboid].blocks> as:block:
          - teleport <[display_blocks].get[<[loop_index]>]> <[block]>

      - wait 1t

    - if <[display_blocks].exists> && <[display_blocks].any>:
      - remove <[display_blocks].filter[is_spawned]>

    - flag player fort_struct.using_wand:!