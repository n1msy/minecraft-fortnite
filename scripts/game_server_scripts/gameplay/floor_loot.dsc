fort_floor_loot_handler:
  type: world
  debug: false
  events:
    on player tracks INTERACTION:
    - define int <context.entity>
    - if !<[int].has_flag[fort.floor.loc]>:
      - stop
    - define drop_item <[int].flag[fort.floor.loc].flag[fort.floor.item]||null>
    #if it's null, it means the item has already been dropped
    - if <[drop_item]> == null:
      - stop

    - define script_name <[drop_item].script.name||mat>
    # - if : [ gun ]
    - if <[script_name].starts_with[gun_]>:
      - run fort_gun_handler.drop_gun def:<map[gun=<[drop_item]>;loc=<[drop_loc]>]>
      #maybe there should be a more consistent way of specifying the item to be dropped?
      - define ammo_type <[drop_item].flag[ammo_type]>
      - define ammo_qty  <item[ammo_<[ammo_type]>].flag[drop_quantity]>
      #should it be offset a little bit, or right on top of each other?
      - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[ammo_qty]>;loc=<[drop_loc]>]>
    # - if : [ ammo ]
    - else if <[script_name].starts_with[ammo_]>:
      #ugh feels unecessarily messy
      - define ammo_type <[script_name].after[ammo_]>
      - define ammo_qty  <[drop_item].flag[drop_quantity]>
      - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[ammo_qty]>;loc=<[drop_loc]>]>
    # - if [ item ]
    - else if <[script_name].starts_with[fort_item_]>:
      - define item_qty <[drop_item].flag[drop_quantity]||1>
      - run fort_item_handler.drop_item def:<map[item=<[drop_item]>;qty=<[item_qty]>;loc=<[drop_loc]>]>
    # - if [ mat ]
    - else:
      - run fort_pic_handler.drop_mat def:<map[mat=<[drop_item]>;qty=20;loc=<[drop_loc]>]>

    # - [ Spawn Floor Loot ] - #

  set_floor_loot:
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