fort_explosive_handler:
  type: world
  debug: false
  definitions: data
  events:
    #guide lines
    on player right clicks block with:fort_item_grenade|fort_item_impulse_grenade:
    - repeat 4:
      - define eye_loc <player.eye_location>
      - define origin <[eye_loc].relative[-0.25,0,0.35]>
      - define target_loc <[eye_loc].ray_trace[default=air;range=100]>
      - define points <[origin].points_between[<[target_loc]>].distance[0.75].exclude[<[origin]>]>
      - foreach <[points]> as:p:
        - define particle_loc <[p].below[<[loop_index].sub[4].power[2].div[95]>]>
        - playeffect effect:REDSTONE at:<[particle_loc]> quantity:1 offset:0 visibility:300 special_data:0.5|AQUA targets:<player>
        #max repeat is 30 no matter what OR they hit a wall
        - if <[particle_loc].material.name> != AIR:
          - foreach stop
      - wait 1t


    on player left clicks block with:fort_item_impulse_grenade:
    - define i       <context.item>
    - define eye_loc <player.eye_location>
    - define origin <[eye_loc].relative[-0.25,0,0.35]>
    - define target_loc <[eye_loc].ray_trace[default=air;range=100]>
    - define points <[origin].points_between[<[target_loc]>].distance[0.75]>

    - playsound <player> sound:ENTITY_SNOWBALL_THROW pitch:0.9

    - take item:<[i]>
    - drop gold_nugget <[origin]> delay:9999s save:grenade
    - define grenade <entry[grenade].dropped_entity>

    - foreach <[points]> as:p:
      - define move_loc    <[p].below[<[loop_index].sub[4].power[2].div[95]>]>
      - define grenade_loc <[grenade].location>
      - playeffect effect:CLOUD at:<[grenade_loc]> quantity:1 offset:0 visibility:300
      - adjust <[grenade]> velocity:<[move_loc].sub[<[grenade_loc]>]>
      #max repeat is 30 no matter what OR they hit a wall
      - if <[grenade].is_on_ground> || <[grenade_loc].find_blocks.within[0.1].any>:
        - foreach stop

      - wait 1t

    - define grenade_loc <[grenade].location>
    - remove <[grenade]>

    - spawn <entity[item_display].with[item=<item[gold_nugget]>]> <[grenade_loc]> save:e
    - define e <entry[e].spawned_entity>


    - playsound <player> sound:BLOCK_NOTE_BLOCK_BIT pitch:1.6
    - wait 4t
    - playsound <player> sound:BLOCK_NOTE_BLOCK_BIT pitch:1.6
    - wait 4t

    - remove <[e]>
    - playsound <[grenade_loc]> sound:ENTITY_GENERIC_EXPLODE pitch:2 volume:1.6
    - run fort_explosive_handler.impulse_explosion_fx def:<map[grenade_loc=<[grenade_loc]>]>

    - define entities <[grenade_loc].find_entities.within[3.2]>
    - foreach <[entities]> as:e:
      - adjust <[e]> velocity:<[e].location.above[1].sub[<[grenade_loc]>]>

    on player left clicks block with:fort_item_grenade:
    - define i       <context.item>
    - define eye_loc <player.eye_location>
    - define origin <[eye_loc].relative[-0.25,0,0.35]>
    - define target_loc <[eye_loc].ray_trace[default=air;range=100]>
    - define points <[origin].points_between[<[target_loc]>].distance[0.75]>

    - playsound <player> sound:ENTITY_SNOWBALL_THROW pitch:0.9

    - take item:<[i]>
    - drop gold_nugget <[origin]> delay:10s save:grenade
    - define grenade <entry[grenade].dropped_entity>
    - run fort_explosive_handler.primed def:<map[grenade=<[grenade]>]>

    - flag server fort.grenade.<queue> duration:3s
    - foreach <[points]> as:p:
      - define move_loc    <[p].below[<[loop_index].sub[4].power[2].div[95]>]>
      - define grenade_loc <[grenade].location>
      - playeffect effect:CLOUD at:<[grenade_loc]> quantity:1 offset:0 visibility:300
      - adjust <[grenade]> velocity:<[move_loc].sub[<[grenade_loc]>]>
      #max repeat is 30 no matter what OR they hit a wall
      - if <[grenade].is_on_ground>:
        - foreach stop

      - if !<server.has_flag[fort.grenade.<queue>]>:
        - define explode True
        - foreach stop
      - wait 1t

    - if !<[explode].exists>:
      #bounce
      #- if <[grenade_loc].center.below.material.name> == air:
        #- shoot snowball[item=gold_nugget] origin:<[grenade_loc]> destination:<[grenade_loc].add[<[grenade_loc].direction.vector.mul[2]>]> speed:0.3 no_rotate
        #- playsound <[grenade_loc]> sound:BLOCK_BASALT_STEP volume:1.2 pitch:1.5
      - waituntil !<server.has_flag[fort.grenade.<queue>]> max:3s

    - define grenade_loc <[grenade].location>
    - remove <[grenade]>

    - playsound <[grenade_loc]> sound:ENTITY_GENERIC_EXPLODE pitch:1 volume:1.8
    - run fort_explosive_handler.explosion_fx def:<map[grenade_loc=<[grenade_loc]>]>

    - define body_damage      <[i].flag[body_damage]>
    - define structure_damage <[i].flag[structure_damage]>

    - define radius 4

    - define nearby_tiles <[grenade_loc].find_blocks_flagged[build.center].within[<[radius]>].parse[flag[build.center].flag[build.structure]].deduplicate>
    - foreach <[nearby_tiles]> as:tile:
      - define center   <[tile].center.flag[build.center]>
      - define hp       <[center].flag[build.health]>
      - define mat_type <[center].flag[build.material]>
      #filtering so connected blocks aren't affected
      - define blocks   <[center].flag[build.structure].blocks.filter[flag[build.center].equals[<[center]>]]>
      - define max_health <script[nimnite_config].data_key[materials.<[mat_type]>.hp]>
      - define new_health <[hp].sub[<[structure_damage]>]>
      - if <[new_health]> > 0:
        - flag <[center]> build.health:<[new_health]>
        - define progress <element[10].sub[<[new_health].div[<[max_health]>].mul[10]>]>
        - foreach <[blocks]> as:b:
          - blockcrack <[b]> progress:<[progress]> players:<server.online_players>
        - foreach next

      #otherwise, break the tile and anything else connected to it
      - foreach <[blocks]> as:b:
        - blockcrack <[b]> progress:0 players:<server.online_players>
        - playeffect effect:BLOCK_CRACK at:<[b].center> offset:0 special_data:<[b].material> quantity:10 visibility:100
      - inject build_system_handler.break

    - define nearby_entities <[grenade_loc].find_entities.within[<[radius]>]>
    - hurt <[body_damage].div[5]> <[nearby_entities]> source:<player>

  primed:
    - define grenade <[data].get[grenade]>
    - wait 1.5s
    - playsound <[grenade].location> sound:ENTITY_TNT_PRIMED pitch:1.5 volume:1.2

  explosion_fx:
    - define grenade_loc <[data].get[grenade_loc]>
    - define size 3
    - repeat <[size]>:
      - define outline <[grenade_loc].to_ellipsoid[<[value].add[1]>,<[value].add[1]>,<[value].add[1]>].shell>
      - define inside  <[grenade_loc].to_ellipsoid[<[value]>,<[value]>,<[value]>].shell>
      #Red (center) = <color[255,92,43]>
      #Orange (middle) = <color[255,157,59]>
      #Yellow (out) = <color[250,191,27]>
      - if <[Value]> <= <[size].div[2]>:
        - define Color <color[255,92,43]>
      - else if <[Value]> > <[size].div[2]> && <[Value]> < <[size].div[1.25]>:
        - define Color <color[255,157,59]>
      - else:
        - define Color <color[250,191,27]>

      - playeffect effect:REDSTONE at:<[inside]> offset:0.3 quantity:2 visibility:300 special_data:2|<[Color]>
      - playeffect effect:SMOKE_NORMAL at:<[outline]> offset:0.3 quantity:8 visibility:300
      #- playeffect effect:REDSTONE at:<[outline]> offset:0.5 quantity:5 visibility:300 special_data:1.5|BLACK
      - playeffect effect:EXPLOSION_LARGE at:<[grenade_loc]> quantity:20 offset:<[value].div[3]> visibility:300
      - wait 1t

  impulse_explosion_fx:
    - define grenade_loc <[data].get[grenade_loc]>
    - define size 3
    - repeat <[size]>:
      - foreach inside|outside as:sphere:
        - define <[sphere]> <list[]>
        - repeat 18 as:circle_value:
          - define angle <[circle_value].mul[10]>
          - define circle <util.list_numbers_to[15].parse_tag[<[grenade_loc].add[<location[0,<[value].add[<[circle_value].sub[1]>]>,0].rotate_around_z[<[Parse_Value].to_radians.mul[24]>].rotate_around_x[0].rotate_around_y[<[angle].to_radians>]>]>]>
          - define <[sphere]> <[<[sphere]>].include[<[circle]>]>

      - define outline <[grenade_loc].to_ellipsoid[<[value].add[1]>,<[value].add[1]>,<[value].add[1]>].shell>
      - define inside  <[grenade_loc].to_ellipsoid[<[value]>,<[value]>,<[value]>].shell>

      - playeffect effect:REDSTONE at:<[inside]> offset:0.25 quantity:2 visibility:300 special_data:1.5|<color[#7aebff]>
      - playeffect effect:REDSTONE at:<[outline]> offset:0.25 quantity:5 visibility:300 special_data:1|WHITE
      - wait 1t

fort_item_grenade:
  type: item
  material: gold_nugget
  display name: <&f><&l>GRENADE
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    rarity: common
    stack_size: 6
    body_damage: 100
    structure_damage: 375

fort_item_impulse_grenade:
  type: item
  material: gold_nugget
  display name: <&f><&l>IMPULSE GRENADE
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    rarity: rare
    stack_size: 9