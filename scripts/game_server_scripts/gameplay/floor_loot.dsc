#TODO: if we ever feel like it, instead of storing item data in locations, store them in server flags with the
#TODO: interaction entity's uuid

fort_floor_loot_handler:
  type: world
  debug: false
  events:

    # - [ Remove Text Displays ] - #
    #to prevent paper warning in console

    #if i really really really wanted to, remove the dropped item and spawn it back when the dropped item is spawned again
    #but that would mean every time i drop an item, i would have to place an interaction entity there too
    #on player untracks DROPPED_ITEM:
    #- define drop <context.entity>
    #in case it was removed or picked up
    #- if !<[drop].is_spawned>:
    #  - stop
    #- if !<[drop].has_flag[text_display]> || !<[drop].flag[text_display].is_spawned>:
    #  - stop
    #- define display <[drop].flag[text_display]>
    #- flag <[drop]> text:<[display].text>
    #- announce removed:<[display].text> to_console
    #- remove <[display]>

    #on player tracks DROPPED_ITEM:
    #- define drop <context.entity>
    #- if !<[drop].has_flag[text_display]>:
    #  - stop
    #- if <[drop].flag[text_display].is_spawned>:
    #  - stop

    #- define text        <[drop].flag[text]>
    #- define translation 0,0.75,0

    #- spawn <entity[text_display].with[text=<[text]>;pivot=center;scale=1,1,1;translation=<[translation]>;view_range=0.06]> <[drop].location> save:txt
    #- define txt <entry[txt].spawned_entity>
    #- mount <[txt]>|<[drop]>
    #- flag <[drop]> text_display:<[txt]>

    #at this point, maybe just store the floor loot data in the entity?
    #since what if the int is tracked before the chunk for the location is loaded?
    on player tracks INTERACTION:
    - define int <context.entity>
    - if !<[int].has_flag[fort.floor.loc]>:
      - stop
    - define fl_loc    <[int].flag[fort.floor.loc]>
    - define drop_item <[fl_loc].flag[fort.floor.item]||null>
    #if it's null, it means the item has already been dropped
    - if <[drop_item]> == null:
      - stop

    - define drop_loc    <[fl_loc].above[0.5]>
    - define script_name <[drop_item].script.name||mat>

    - flag <[fl_loc]> fort.floor.item:!

    ##important safety
    - wait 3t
    #this might potentially fix the server crashing issue

    # - [ Spawn Floor Loot ] - #
    #in hindsight, i shouldve created a PROCEDURE instead of a run that gets the item based on the info

    # - if : [ gun ]
    - if <[script_name].starts_with[gun_]>:
      - run fort_gun_handler.drop_gun def:<map[gun=<[drop_item]>;loc=<[drop_loc]>;floor_loot_hitbox=<[int]>]>
      #maybe there should be a more consistent way of specifying the item to be dropped?
      - define ammo_type <[drop_item].flag[ammo_type]>
      - define ammo_qty  <item[ammo_<[ammo_type]>].flag[drop_quantity]>
      #should it be offset a little bit, or right on top of each other?
      - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[ammo_qty]>;loc=<[drop_loc]>;floor_loot_hitbox=<[int]>]>
    # - if : [ ammo ]
    - else if <[script_name].starts_with[ammo_]>:
      #ugh feels unecessarily messy
      - define ammo_type <[script_name].after[ammo_]>
      - define ammo_qty  <[drop_item].flag[drop_quantity]>
      - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[ammo_qty]>;loc=<[drop_loc]>;floor_loot_hitbox=<[int]>]>
    # - if [ item ]
    - else if <[script_name].starts_with[fort_item_]>:
      - define item_qty <[drop_item].flag[drop_quantity]||1>
      - run fort_item_handler.drop_item def:<map[item=<[drop_item]>;qty=<[item_qty]>;loc=<[drop_loc]>;floor_loot_hitbox=<[int]>]>
    # - if [ mat ]
    - else:
      - run fort_pic_handler.drop_mat def:<map[mat=<[drop_item]>;qty=20;loc=<[drop_loc]>;floor_loot_hitbox=<[int]>]>

  set_loot:
    - define floor_loot_spots <world[nimnite_map].flag[fort.floor_loot_locations]||<list[]>>

    - define loot_pool  <list[]>

    #divide percentages by 100 to get between 0 and 1
    #-
    - define total_guns <util.scripts.filter[name.starts_with[gun_]].exclude[<script[gun_particle_origin]>].parse[name.as[item]]>
    - foreach <[total_guns]> as:gun:
      #doing this in case some guns don't have certain rarities
      - define rarities <[gun].flag[rarities].keys>
      - foreach <[rarities]> as:rarity:
        - if <[gun].has_flag[rarities.<[rarity]>.floor_weight]>:
          - define weight    <[gun].flag[rarities.<[rarity]>.floor_weight].div[100]>
          - define data      <map[item=<[gun]>;weight=<[weight]>]>
          - define loot_pool <[loot_pool].include[<[data]>]>

    #maybe to make it more readable, just turn it into foreaches?
    #-
    - define items     <util.scripts.filter[name.starts_with[fort_item_]].exclude[<script[fort_item_handler]>].parse[name.as[item]]>
    - foreach <[items]> as:i:
      - if <[i].has_flag[floor_weight]>:
        - define weight    <[i].flag[floor_weight].div[100]>
        - define data      <map[item=<[i]>;weight=<[weight]>]>
        - define loot_pool <[loot_pool].include[<[data]>]>
    #-
    - define ammo      <util.scripts.filter[name.starts_with[ammo_]].parse[name.as[item]]>
    - foreach <[ammo]> as:am:
      - define weight    <[am].flag[floor_weight].div[100]>
      - define data      <map[item=<[am]>;weight=<[weight]>]>
      - define loot_pool <[loot_pool].include[<[data]>]>
    #-
    - foreach <list[wood/2.8|brick/2.1|metal/0.98]> as:mat_data:
      #input isn't as <item[]> for mats
      - define item      <[mat_data].before[/]>
      - define weight    <[mat_data].after[/].div[100]>
      - define data      <map[item=<[item]>;weight=<[weight]>]>
      - define loot_pool <[loot_pool].include[<[data]>]>
    #-
    - define total_weight 0
    - foreach <[loot_pool].parse[get[weight]]> as:w:
      - define total_weight:+:<[w]>

    - define none_weight <element[1].sub[<[total_weight]>]>
    - define none        <map[item=none;weight=<[none_weight]>]>

    #this list has to be *sorted*
    - define loot_pool <[loot_pool].include[<[none]>].sort_by_number[get[weight]].reverse>

    #-fill all floor loot spots
    - foreach <[floor_loot_spots]> as:loc:

      - define weight           0
      - define total_weight     0
      - define rand             <util.random.decimal[0].to[1]>

      #-find the item to choose for floor loot
      - foreach <[loot_pool]> as:item_data:
        - define item_weight  <[item_data].get[weight]>
        - define total_weight <[total_weight].add[<[item_weight]>]>

        #if it passes the probability, drop the item
        - if <[rand]> <= <[total_weight]>:
          - define drop_item <[item_data].get[item]>
          # - if [ none ]
          - if <[drop_item]> == none:
            - foreach stop
          #
          - define drop_loc  <[loc].above[0.5]>
          #no need to load the chunk if im just flagging the location
          ##- if !<[drop_loc].chunk.is_loaded>:
          ##  #- define chunk <[loc].chunk>
          ##  #- chunkload <[chunk]> duration:8s

          - flag <[loc]> fort.floor.item:<[drop_item]>
          #i forgot we can't just use the drop command...
          ##- define script_name <[drop_item].script.name||mat>
          # - if : [ gun ]
          ##- if <[script_name].starts_with[gun_]>:
          ##  - run fort_gun_handler.drop_gun def:<map[gun=<[drop_item]>;loc=<[drop_loc]>]>
            #maybe there should be a more consistent way of specifying the item to be dropped?
          ##  - define ammo_type <[drop_item].flag[ammo_type]>
          ##  - define ammo_qty  <item[ammo_<[ammo_type]>].flag[drop_quantity]>
            #should it be offset a little bit, or right on top of each other?
          ##  - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[ammo_qty]>;loc=<[drop_loc]>]>
          # - if : [ ammo ]
          ##- else if <[script_name].starts_with[ammo_]>:
            #ugh feels unecessarily messy
          ##  - define ammo_type <[script_name].after[ammo_]>
          ##  - define ammo_qty  <[drop_item].flag[drop_quantity]>
          ##  - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[ammo_qty]>;loc=<[drop_loc]>]>
          # - if [ item ]
          ##- else if <[script_name].starts_with[fort_item_]>:
          ##  - define item_qty <[drop_item].flag[drop_quantity]||1>
          ##  - run fort_item_handler.drop_item def:<map[item=<[drop_item]>;qty=<[item_qty]>;loc=<[drop_loc]>]>
          # - if [ mat ]
          ##- else:
          ##  - run fort_pic_handler.drop_mat def:<map[mat=<[drop_item]>;qty=20;loc=<[drop_loc]>]>
          - foreach stop


    - announce "<&b>[Nimnite]<&r> Done (<&a><[floor_loot_spots].size><&r> locations)" to_console