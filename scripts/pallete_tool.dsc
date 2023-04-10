# - [ Pallete Command Server Flags ] - #
#How much health the structure should have. Default is 150.
# - Pallete.<[pallete_name]>.Health
#Either wall or floor.
# - Pallete.<[pallete_name]>.Type
#Wood, Brick, or Metal (it will be what the player gets from mining it). Default is wood.
# - Pallete.<[pallete_name]>.Material

#The current open editors and their relative information.
#changed from "." to "_" so "open_editors" isn't counted as a pallete.
# - Pallete_Open_Editors

pallete_wand:
  type: item
  material: blaze_rod
  display name: Pallete Wand
  flags:
    pallete: none

pallete_command:
  type: command
  name: pallete
  debug: false
  description: Customize a 5x5 pallete for Nimnite building.
  usage: /pallete
  aliases:
    - p
  tab completions:
    1: <list[new|save|open|close|remove|list|material|health|wand|help]>
  tab complete:
  - define args   <context.args>
  - define r_args <context.raw_args>

  #new arg has a special exemption, since it requires more than 2 arguments
  - if <[r_args].starts_with[new<&sp>]> && <[args].size> <= 2:
    #so the tab completions dont appear after being put in already once
    - if <[args].size> >= 2 && <[r_args].ends_with[<&sp>]>:
      - determine <server.flag[pallete].keys.exclude[open_editors]||<empty>>
      - stop
    - determine <list[floor|wall]>
    - stop

  - if <[r_args].ends_with[<&sp>]> || <[args].size> >= 2:
    - determine <server.flag[pallete].keys.exclude[open_editors]||<empty>>

  definitions: data
  script:
    - define action <context.args.first||null>

    - foreach <list[new|save|open|close|remove|list|material|health|wand|help]> as:a:
      - define hover "<&a>Shift-click me.<n><&8>/p <&f><[a]>"
      - define cmd   "/p <[a]> "
      - define valid_actions:->:<[a].on_hover[<[hover]>].with_insertion[<[cmd]>]>
    - define valid_actions <&e><[valid_actions].separated_by[<&7>, <&e>]>

    - if <[action]> == null:
      - narrate "<&c>You must specify an <&n>action<&c>! <n><&7>Actions include: <[valid_actions]>."
      - stop

    - define grad <&gradient[from=lime;to=white]>
    - define current_palletes <server.flag[pallete].keys||<list[]>>

    - choose <[action]>:
      # - [ Action: Create a new pallete. ] - #
      - case new:

        - define type <context.args.get[2]||null>
        - if <[type]> == null:
          - narrate "<&c>Please specify a <&n>type<&c> for your pallete.<n><&7>Types include: <&f>floor<&7>, <&f>wall<&7>."
          - stop

        - define name <context.args.get[3]||null>
        - if <[name]> == null:
          - narrate "<&c>Please specify a <&n>name<&c> for your pallete."
          - stop

        - if <[current_palletes].contains[<[name]>]>:
          - narrate "<&c>This pallete already exists. Please use a different name."
          - stop

        - flag server pallete.<[name]>.health:150
        - flag server pallete.<[name]>.material:wood
        - flag server pallete.<[name]>.type:<[type]>

        - inject pallete_command.open_editor

        - narrate "<[grad]>Created new pallete editor for <&f><&dq><&e><[name]><&f><&dq><[grad]>."
        - narrate "<&7>Make sure to type <&f>/p save <[name]> <&7>to save current changes."

      # - [ Action: Set the blocks of the pallete. ] - #
      # if it isn't set, the pallete doesn't exist yet
      - case save:
        - define name <context.args.get[2]||null>
        - if <[name]> == null:
          - narrate "<&c>Please specify a <&n>name<&c> for your pallete."
          - stop

        - if !<[current_palletes].contains[<[name]>]>:
          - narrate "<&c>This pallete doesn't exist.<n><&7>To create a pallete, type <&f>/p new (name)<&7>."
          - stop

        - if !<server.flag[pallete_open_editors].keys.contains[<[name]>]||false>:
          - narrate "<&c>To save a pallete, its editor must be open.<n><&7>To open a pallete, type <&f>/p open (name)<&7>."
          - stop

        - define tile <server.flag[pallete_open_editors.<[name]>.tile]>
        - if <schematic.list.contains[pallete_<[name]>]>:
          - ~schematic unload name:pallete_<[name]>
        - ~schematic create name:pallete_<[name]> <[tile].center> area:<[tile]>
        - ~schematic save name:pallete_<[name]>
        - narrate "<[grad]>Saved pallete <&f><&dq><&e><[name]><&f><&dq><[grad]>."

      # - [ Action: Open an existing pallete to edit. ] - #
      - case open:
        - define name <context.args.get[2]||null>
        - if <[name]> == null:
          - narrate "<&c>Please specify a <&n>name<&c> for your pallete."
          - stop

        - if !<[current_palletes].contains[<[name]>]>:
          - narrate "<&c>This pallete doesn't exist.<n><&7>To create a pallete, type <&f>/p new (name)<&7>."
          - stop

        - if <server.flag[pallete_open_editors].keys.contains[<[name]>]||false>:
          - define editor_loc <server.flag[pallete_open_editors.<[name]>.text_display].location>
          - define here <element[<&a><&n>here].on_hover[<&a>Click to teleport.<n><&8><[editor_loc].simple>].on_click[/ex teleport <player> <[editor_loc]>]>
          - narrate "<&c>An editor for <&f><&dq><&e><[name]><&f><&dq> <&c>already exists <[here]><&c>."
          - stop

        - define type <server.flag[pallete.<[name]>.type]>

        - if !<schematic.list.contains[pallete_<[name]>]>:
          - ~schematic load name:pallete_<[name]>

        - inject pallete_command.open_editor

        - ~schematic paste name:pallete_<[name]> <[pallete_editor_origin]> noair

      # - [ Action: Close an existing pallete editor. ] - #
      - case close:
        - define name <context.args.get[2]||null>
        - if <[name]> == null:
          - narrate "<&c>Please specify a <&n>name<&c> for your pallete."
          - stop

        - if !<[current_palletes].contains[<[name]>]>:
          - narrate "<&c>This pallete doesn't exist.<n><&7>To create a pallete, type <&f>/p new (name)<&7>."
          - stop

        - if !<server.flag[pallete_open_editors].keys.contains[<[name]>]||false>:
          - narrate "<&c>The editor for this pallete isn't open.<n><&7>To open a pallete, type <&f>/p open (name)<&7>."
          - stop

        - run pallete_command.close_editor def:<map[name=<[name]>;save=true]>

        - narrate "<[grad]>Closed pallete editor for <&f><&dq><&e><[name]><&f><&dq><[grad]>."

      # - [ Action: Remove an existing pallete. ] - #
      - case remove:
        - define name <context.args.get[2]||null>
        - if <[name]> == null:
          - narrate "<&c>Please specify a <&n>name<&c> for your pallete."
          - stop

        - if !<[current_palletes].contains[<[name]>]>:
          - narrate "<&c>This pallete doesn't exist.<n><&7>To create a pallete, type <&f>/p new (name)<&7>."
          - stop

        - run pallete_command.close_editor def:<map[name=<[name]>;save=false]>

        - flag server pallete.<[name]>:!

        #in case it's being removed before even being saved
        - if <util.has_file[schematics/pallete_<[name]>.schem]>:
          - adjust system delete_file:schematics/pallete_<[name]>.schem

        - narrate "<&gradient[from=red;to=white]>Removed pallete <&f><&dq><&e><[name]><&f><&dq><&f>."

      # - [ Action: View all current palletes. ] - #
      - case list:
        - inject pallete_command.view_list

      # - [ Action: Get a pallete-placing wand. ] - #
      - case wand:

        - define name <context.args.get[2]||null>

        - if !<[current_palletes].contains[<[name]>]>:
          - define name none

        - define display_name "<&e>Pallete Wand <&f>(<[name]>)"

        - narrate "<[grad]>You recieved a <[display_name]> <[grad]>."
        - if <[name]> == none:
          - narrate "<&7>No pallete was set. <&a>Right-click <&7>your current wand to select one.<n><&7>Or, type <&f>/p wand (name) <&7>with an empty hand to receive a new wand with the pallete specified."

        - if <player.item_in_hand.script.name||null> == pallete_wand:
          - if <[name]> == none:
            - stop
          - define slot <player.held_item_slot>
          - inventory adjust slot:<[slot]> display:<[display_name]>
          - inventory adjust slot:<[slot]> flag:pallete:<[name]>
        - else:
          - give <item[pallete_wand].with[display=<[display_name]>;flag=pallete:<[name]>]>

        - if !<player.has_flag[pallete.using_wand]> && <[name]> != none:
          - wait 1t
          - run pallete_wand_handler.selector

      # - [ Action: Get a pallete-placing wand. ] - #
      - case material:
        - define name <context.args.get[2]||null>
        - if <[name]> == null:
          - narrate "<&c>Please specify a <&n>name<&c> for your pallete."
          - stop

        - define mat <context.args.get[3]||null>
        - if !<list[wood|brick|metal].contains[<[mat]>]>:
          - narrate "<&c>Invalid material specified.<n><&7>Materials include: <&f>wood<&7>, <&f>brick<&7>, <&f>metal<&7>."
          - stop

        - flag server pallete.<[name]>.material:<[mat]>
        - narrate "<[grad]>You set the material of <&f><&dq><&e><[name]><&f><&dq> <[grad]>to <&b><[mat]><[grad]>."

      - case health:
        - define name <context.args.get[2]||null>
        - if <[name]> == null:
          - narrate "<&c>Please specify a <&n>name<&c> for your pallete."
          - stop

        - define hp <context.args.get[3]||null>
        - if !<[hp].is_integer> || <[hp]> <= 0:
          - narrate "<&c>Invalid health specified.<n><&7>Health must be a number starting from <&f>1<&7>."
          - stop

        - flag server pallete.<[name]>.health:<[hp]>
        - narrate "<[grad]>You set the health of <&f><&dq><&e><[name]><&f><&dq> <[grad]>to <&b><[hp].format_number><[grad]>."

      # - [ Action: View all available commands. ] - #
      - case help:
        - narrate "<[grad]>Pallete Tool Help Menu"
        - narrate "<&8>/<&e>p <&b>new <&7>(name) <&8>- <&f>Create a new pallete."
        - narrate "<&8>/<&e>p <&b>remove <&7>(name) <&8>- <&f>Remove a pallete."
        - narrate "<&8>/<&e>p <&b>save <&7>(name) <&8>- <&f>Save your pallete."
        - narrate "<&8>/<&e>p <&b>open <&7>(name) <&8>- <&f>Open a pallete editor."
        - narrate "<&8>/<&e>p <&b>close <&7>(name) <&8>- <&f>Close a pallete editor."
        - narrate "<&8>/<&e>p <&b>health <&7>(name) (health)<&8>- <&f>Change the health of the build."
        - narrate "<&8>/<&e>p <&b>material <&7>(name) (material)<&8>- <&f>Change the material of the build."
        - narrate "<&8>/<&e>p <&b>wand <&7>(name) <&8>- <&f>Recieve a pallete wand."
        - narrate "<&8>/<&e>p <&b>list <&8>- <&f>View all palletes."
        - narrate "<&8>/<&e>p <&b>help <&8>- <&f>Open this help menu."
        - narrate "<&7>Press <&f>Q <&7>to rotate your selection."

      - default:
        - narrate "<&c>Invalid action!<n><&8>Actions include: <[valid_actions]>"

  view_list:
  #required definitions:
  # - <[current_palletes]>
  # - <[grad]>

    - if <[current_palletes].is_empty>:
      - narrate "<&c>You have no palletes.<n><&7>To create a pallete, type <&f>/p new (name)<&7>."
      - stop

    - narrate "<n><[grad]>Listing all palletes:"
    - foreach <[current_palletes]> as:name:

      - define display_name "<&f><&dq><&e><[name]><&f><&dq> <[grad]>Pallete Info"
      - define type         "<&7>Type: <&b><server.flag[pallete.<[name]>.type].to_uppercase>"
      - define material     "<&7>Material: <&b><server.flag[pallete.<[name]>.material]>"
      - define hp           "<&7>Health: <&b><server.flag[pallete.<[name]>.health]>"

      - define action1      "<&a>Click to get wand."
      - define action2      "<&9>Shift-click to open editor."

      - define info <element[<&b><&l>[View Info]].on_hover[<[display_name]><n><n><[type]><n><[material]><n><[hp]><n><n><[action1]><n><[action2]>]>
      - narrate "<&8>- <&e><[name]> <[info].with_insertion[/p open <[name]>].on_click[/p wand <[name]>]>"
    - narrate <empty>

  open_editor:
  #required definitions:
  # - <[name]>
  # - <[type]>
  #

    - define eye_loc <player.eye_location>
    - define pallete_editor_origin <[eye_loc].ray_trace[default=air;range=3]>

    #in case they're looking up in the air
    - if <[pallete_editor_origin].material.name> == air:
      - define pallete_editor_origin <[pallete_editor_origin].with_pitch[90].ray_trace>

    - if <[type]> == wall:
      - define pallete_editor_origin <[pallete_editor_origin].above[2]>
      - define expand <map[east=0,2,2;west=0,2,2;north=-2,2,0;south=-2,2,0].get[<[eye_loc].yaw.simple>]>

    - else if <[type]> == floor:
      - define expand 2,0,2

    - define text "Pallete Editor for <&f><&dq><&e><[name]><&f><&dq>"
    - spawn <entity[text_display].with[display_entity_data=<map[text=<[text]>;billboard=center]>]> <[pallete_editor_origin].center.above[3.5]> save:editor_text
    - define editor_text <entry[editor_text].spawned_entity>

    - define tile <[pallete_editor_origin].to_cuboid[<[pallete_editor_origin]>].expand[<[expand]>]>
    - define blocks <[tile].blocks>

    - if !<util.has_file[schematics/pallete_<[name]>.schem]> && !<schematic.list.contains[pallete_<[name]>]>:
      - ~schematic create name:pallete_<[name]> <[tile].center> area:<[tile]>
    - else if !<schematic.list.contains[pallete_<[name]>]>:
      - ~schematic load name:pallete_<[name]>

    - flag server pallete_open_editors.<[name]>.tile:<[tile]>
    - flag server pallete_open_editors.<[name]>.blocks:<[blocks]>
    - flag server pallete_open_editors.<[name]>.text_display:<[editor_text]>

    - debugblock <[blocks]> color:0,0,0,75 d:15m players:<server.online_players>

    - run pallete_command.editor_expiration def:<map[name=<[name]>]>

  close_editor:
    - define name        <[data].get[name]>
    - define save        <[data].get[save]>
    - define grad <&gradient[from=lime;to=white]>
    - define editor_text <server.flag[pallete_open_editors.<[name]>.text_display]>
    - define blocks      <server.flag[pallete_open_editors.<[name]>.blocks]>

    - if <[save]>:
      - define tile <server.flag[pallete_open_editors.<[name]>.tile]>
      - if <schematic.list.contains[pallete_<[name]>]>:
        - ~schematic unload name:pallete_<[name]>
      - ~schematic create name:pallete_<[name]> <[tile].center> area:<[tile]>
      - ~schematic save name:pallete_<[name]>
      - narrate "<[grad]>Saved pallete <&f><&dq><&e><[name]><&f><&dq> <[grad]>before closing."

    - modifyblock <[blocks]> air
    - flag server pallete_open_editors.<[name]>:!

    - if <[editor_text].is_spawned>:
      - remove <[editor_text]>

    #this command clears ALL debugblocks, so here we renew all the debugblocks for the current open editors
    - debugblock clear players:<server.online_players>
    - foreach <server.flag[pallete_open_editors].keys||<list[]>> as:name:
      - debugblock <server.flag[pallete_open_editors.<[name]>.blocks]> color:0,0,0,75 d:15m players:<server.online_players>

  #-auto remove pallete after 10m
  editor_expiration:
    - define name <[data].get[name]>
    - repeat 10:
      - define open_editors <server.flag[pallete_open_editors].keys||<list[]>>
      - if !<[open_editors].contains[<[name]>]>:
        #it means the editor is already closed and there's no point in waiting
        - stop
      - wait 1m
    - if !<[open_editors].contains[<[name]>]>:
      - stop
    - run pallete_command.close_editor def:<map[name=<[name]>;save=true]>
    - if <player.is_online>:
      - narrate "<&7>Your pallete editor session for <&f><&dq><&e><[name]><&f><&dq> has expired."
      - narrate "<&7>If you'd like to continue, please create a new one with <&f>/p open <[name]>"

pallete_wand_handler:
  type: world
  debug: false
  events:
    on player left clicks block with:pallete_wand flagged:pallete.using_wand.origin:
      - determine passively cancelled
      - define name <context.item.flag[pallete]>
      - if <[name]> == none:
        - stop
      - if !<schematic.list.contains[pallete_<[name]>]>:
        - ~schematic load name:pallete_<[name]>

      - define origin <player.flag[pallete.using_wand.origin]>
      - ~schematic paste name:pallete_<[name]> <[origin]> noair

      - define tile   <schematic[pallete_<[name]>].cuboid[<[origin]>]>
      - define center <[tile].center>

      - define hp       <server.flag[pallete.<[name]>.health]>
      - define material <server.flag[pallete.<[name]>.material]>
      - define type     <server.flag[pallete.<[name]>.type]>

      - flag <[center]> build.structure:<[tile]>
      - flag <[center]> build.type:<[type]>
      - flag <[center]> build.health:<[hp]>
      - flag <[center]> build.material:<[material]>

      - flag <[tile].blocks> build.center:<[center]>

      - playsound <[center]> sound:<map[wood=BLOCK_WOOD_PLACE;brick=BLOCK_WOOD_PLACE;metal=BLOCK_STONE_PLACE].get[<[material]>]> pitch:0.8

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
      - define x <proc[round4].context[<[origin].x>]>
      - define z <proc[round4].context[<[origin].z>]>

      - define origin <[origin].with_x[<[x]>].with_z[<[z]>].below>
      - define origin <[origin].above[2].forward_flat[2]> if:<[type].exists.and[<[type].equals[wall]>]>

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