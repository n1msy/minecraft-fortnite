#clean this shit up insanely (at school)

#this script is very messy because im tired and need to rush it asap

#clean up this code more?

fort_struct_wand:
  type: item
  material: blaze_rod
  display name: <&b>Structure Wand
  flags:
    schem: none

fort_schem_command:
  type: command
  name: fort_schem
  debug: false
  description: Fortnite Build Schematic Commands
  usage: /fort_schem
  permission: fort.setup
  aliases:
  - fort

  tab complete:
    #ik this can be prettier and more organized but idc

    - define args   <context.args>
    - define r_args <context.raw_args>

    - define structures <server.flag[fort.structure].keys||<list[]>>

    #new arg has a special exemption, since it requires more than 2 arguments
    - if <[r_args].starts_with[save<&sp>]> && <[args].size> <= 2:
      #so the tab completions dont appear after being put in already once
      - if <[args].size> >= 2 && <[r_args].ends_with[<&sp>]>:
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


    - determine <list[save|remove|set]>
  script:
    #most trees give around 50 wood
    #most stone structures give around 40
    - define structures <server.flag[fort.structure].keys||<list[]>>

    - define arg <context.args.first||null>
    - choose <[arg]>:
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

        - ~schematic create name:fort_structure_<[name]> <player.location.center.with_y[<[cuboid].min.y>]> area:<[cuboid]>
        - ~schematic save name:fort_structure_<[name]>

        - flag server fort.structure.<[name]>.type:<[type]>
        - flag server fort.structure.<[name]>.material:<script[nimnite_config].data_key[structures.<[type]>.material]>
        - flag server fort.structure.<[name]>.health:<script[nimnite_config].data_key[structures.<[type]>.default_hp]>

        - narrate "<&a>Schematic saved as <&7><&dq><&f>fort_structure_<[name]>.schem<&7><&dq>"

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

      - case wand:

        - define name <context.args.get[2]||null>
        - if !<[structures].contains[<[name]>]>:
          - define name none

        - define display_name "<&b>Structure Wand <&f>(<[name]>)"

        - narrate "<&a>You recieved a <[display_name]> <&a>."
        - if <[name]> == none:
          - narrate "<&7>No schematic was set. <&a>Right-click <&7>your current wand to select one.<n><&7>Or, type <&f>/fort_schem (name) <&7>with an empty hand to receive a new wand with the pallete specified."

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
          - run fort_schem_handler.selector

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

      - default:
        - narrate "<&c>Invalid command."

fort_schem_handler:
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

      - define cuboid  <schematic[fort_structure_<[name]>].cuboid[<[origin]>]>
      - define center <[cuboid].center>

      #each structure has their own uuid?
      - define blocks <[cuboid].blocks.filter[has_flag[build.natural]].filter[flag[build.natural[]]]>

      - define hp       <server.flag[fort.structure.<[name]>.health]>
      - define material <server.flag[fort.structure.<[name]>.material]>
      - define type     <server.flag[fort.structure.<[name]>.type]>

      - flag <[blocks]> build.structure:<[cuboid]>
      - flag <[blocks]> build.type:<[type]>
      - flag <[blocks]> build.health:<[hp]>
      - flag <[blocks]> build.material:<[material]>

    on player right clicks block with:pallete_wand:
      - define grad <&gradient[from=lime;to=white]>
      - define current_palletes <server.flag[pallete].keys||<list[]>>
      - inject pallete_command.view_list
      - ratelimit <player> 1t

    on player drops pallete_wand:
      - determine passively cancelled
      - define name <context.item.flag[pallete]>
      - if <[name]> == none:
        - stop
      - if !<schematic.list.contains[pallete_<[name]>]>:
        - ~schematic load name:pallete_<[name]>
      - schematic rotate name:pallete_<[name]> angle:90
      - flag player pallete.using_wand:!
      - wait 1t
      - run pallete_wand_handler.selector
    after player holds item item:pallete_wand:
      - run pallete_wand_handler.selector
  selector:
    - define name none
    - define type null
    - flag player pallete.using_wand
    - while <player.item_in_hand.script.name||null> == pallete_wand && <player.has_flag[pallete.using_wand]>:
      - define eye_loc <player.eye_location>
      - define origin <[eye_loc].ray_trace[default=air;range=3]>

      # - [ Calculate the grid location. ] - #
      #- define x <proc[round4].context[<[origin].x>]>
      #- define z <proc[round4].context[<[origin].z>]>

      #- define origin <[origin].with_x[<[x]>].with_z[<[z]>].below>
      - define origin <[origin].forward[2]> if:<[type].exists.and[<[type].equals[wall]>]>

      - flag player pallete.using_wand.origin:<[origin]>

      - if <[name]> != <player.item_in_hand.flag[pallete]>:
        - define name <player.item_in_hand.flag[pallete]>
        - define type <server.flag[pallete.<[name]>.type]>
        - if <[type]> == wall:
          - define origin <[origin].above[2]>

        - if !<schematic.list.contains[pallete_<[name]>]>:
          - ~schematic load name:pallete_<[name]>

        - if <[display_blocks].exists> && <[display_blocks].any>:
          - remove <[display_blocks].filter[is_spawned]>

        - define display_blocks <list[]>

        - define cuboid <schematic[pallete_<[name]>].cuboid[<[origin]>]>
        - define min <[cuboid].min>
        - foreach <[cuboid].blocks> as:block:
          - define mat <schematic[pallete_<[name]>].block[<[block].sub[<[min]>]>]>

          - spawn <entity[block_display].with[material=<[mat]>;glowing=true]> <[block]> save:b_display

          - define display_blocks <[display_blocks].include[<entry[b_display].spawned_entity>]>

      - define cuboid <schematic[pallete_<[name]>].cuboid[<[origin]>]>
      - debugblock <[cuboid].blocks> color:0,0,0,50 d:1t players:<server.online_players>

      - foreach <[cuboid].blocks> as:block:
        - teleport <[display_blocks].get[<[loop_index]>]> <[block]>

      - wait 1t

    - if <[display_blocks].exists> && <[display_blocks].any>:
      - remove <[display_blocks].filter[is_spawned]>

    - flag player pallete.using_wand:!