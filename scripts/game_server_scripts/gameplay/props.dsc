test:
  type: task
  debug: false
  script:
  - define prop_hb    <player.target>
  - define prop_model <[prop_hb].flag[fort.prop.model]>
  #- define mat_type
  - define particle_loc <[prop_model].location.add[<[prop_model].translation>]>
  - playeffect effect:BLOCK_CRACK at:<[particle_loc]> offset:0.1 special_data:IRON_BARS quantity:10 visibility:30

fort_prop_handler:
  type: world
  debug: false
  definitions: data
  events:
    on INTERACTION damaged:
    - stop if:<context.entity.has_flag[fort.prop].not>
    - define damager <context.damager||null>
    - define prop_hb    <context.entity>
    - define prop_model <[prop_hb].flag[fort.prop.model]>

    #-removing the props
    - if <player.is_sneaking> && <player.is_op>:
      - define loc        <[prop_hb].location>
      - define name       <[prop_hb].flag[fort.prop.name]>

      - if <[prop_hb].has_flag[fort.prop.attached_center]>:
        - flag <[prop_hb].flag[fort.prop.attached_center]> build.attached_containers:<-:<[prop_hb]>

      - remove <[prop_model]>|<[prop_hb]>
      - flag <player.world> fort.props:<-:<[prop_hb]>
      - narrate "<&c>Removed <[name]> at <&f><[loc].simple>"
      - stop

    ##this is added for safety purposes
    #just so no one accidentally hits the model and the flag data for its health is messed up
    - if <bungee.server> == BUILD:
      - stop

    #-if players break it with a pickaxe, run the harvesting stuff
    - if <[damager]> != null && <[damager].item_in_hand.script.name.starts_with[fort_pickaxe]||false>:
      - define damage 50
      - run fort_pic_handler.harvest def:<map[type=<[prop_hb].flag[fort.prop.material]>]>

    #this part would only fire if it's either by hand, or pickaxe (ill let hands destroy too, whatever)
    #if check in case damage was already defined by pickaxe
    - define damage <context.damage> if:!<[damage].exists>

    #-run breaking stuff
    - run fort_prop_handler.damage_prop def:<map[prop_hb=<[prop_hb]>;damage=<[damage]>]>

    on player right clicks block with:fort_prop_*:
    - determine passively cancelled
    - ratelimit <player> 1t
    - define i   <context.item>
    - define loc <context.location.above.center||null>

    - if <[loc]> == null || <[loc].material.name> != air:
      - narrate "<&c>Invalid spot."
      - stop

    #- define yaw <player.eye_location.yaw>
    #angle snapping
    - define yaw <map[North=180;South=0;East=-90;West=90].get[<player.eye_location.yaw.simple>]>
    - define angle <[yaw].to_radians>
    - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

    - define cmd           <[i].custom_model_data>
    - define scale         <[i].flag[scale]||1>
    - define translation   0,0.797,0

    - define model_loc <[loc]>

    - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=<[cmd]>]>;scale=<[scale]>,<[scale]>,<[scale]>;left_rotation=<[left_rotation]>;translation=<[translation]>] <[model_loc]> save:prop
    - define prop_model <entry[prop].spawned_entity>

    - spawn INTERACTION[height=2.25;width=1.5] <[model_loc].below[0.4]> save:prop_hitbox
    - define prop_hb <entry[prop_hitbox].spawned_entity>

    - define placed_on <context.location>
    - if <[placed_on].has_flag[build.center]>:
      - define center_attached_to <[placed_on].flag[build.center]>
      - flag <[center_attached_to]> build.attached_props:->:<[prop_hb]>

    - flag <[prop_hb]> fort.prop.model:<[prop_model]>
    - flag <[prop_hb]> fort.prop.material:<[i].flag[material]>
    - flag <[prop_hb]> fort.prop.health:<[i].flag[health]>
    - flag <[prop_hb]> fort.prop.name:<[i].script.name.after[fort_prop_]>
    - flag <[prop_hb]> fort.prop.attached_center:<[center_attached_to]> if:<[center_attached_to].exists>

    - flag <[loc].world> fort.props:->:<[prop_hb]>

    - narrate "<&a>Set <[i].display> at <&f><[loc].simple>"

  damage_prop:
    - define prop_hb    <[data].get[prop_hb]>
    - define prop_model <[prop_hb].flag[fort.prop.model]>
    - define mat_type   <[prop_hb].flag[fort.prop.material]>
    - define damage     <[data].get[damage]>

    - run fort_prop_handler.damage_anim def:<map[prop_model=<[prop_model]>;mat_type=<[mat_type]>]>
    - define health <[prop_hb].flag[fort.prop.health]>
    - define new_health <[health].sub[<[damage]>]>

    #-break it
    - if <[new_health]> <= 0:
      - run fort_prop_handler.break def:<map[prop_hb=<[prop_hb]>]>
      - stop

    - define fx_loc <[prop_model].location.add[<[prop_model].translation>]>
    - definemap mat_data_list:
        wood:
          special_data: OAK_PLANKS
          sound: BLOCK_CHERRY_WOOD_HIT
          pitch: 1.4
        brick:
          special_data: BRICKS
          sound: BLOCK_MUD_BRICKS_STEP
          pitch: 0.9
        metal:
          special_data: IRON_BARS
          sound: BLOCK_NETHERITE_BLOCK_HIT
          pitch: 1.3
    - define mat_data <[mat_data_list].get[<[mat_type]>]>
    - playsound <[fx_loc]> sound:<[mat_data].get[sound]> pitch:<[mat_data].get[pitch]>

    - flag <[prop_hb]> fort.prop.health:<[new_health]>

  damage_anim:
    - define prop_model <[data].get[prop_model]>
    - define scale      <[prop_model].scale>

    - define particle_loc <[prop_model].location.add[<[prop_model].translation>]>
    - playeffect effect:BLOCK_CRACK at:<[particle_loc]> offset:0.1 special_data:OAK_PLANKS quantity:10 visibility:30

    - adjust <[prop_model]> interpolation_start:0
    - adjust <[prop_model]> scale:<[scale].add[0.08,0.08,0.08]>
    - adjust <[prop_model]> interpolation_duration:2t

    - wait 2t

    - stop if:!<[prop_model].is_spawned>
    - adjust <[prop_model]> interpolation_start:0
    - adjust <[prop_model]> scale:<[scale]>
    - adjust <[prop_model]> interpolation_duration:2t

  break:
    - define prop_hb    <[data].get[prop_hb]>
    - define prop_model <[prop_hb].flag[fort.prop.model]>
    - define mat_type   <[prop_hb].flag[fort.prop.material]>
    - definemap mat_data_list:
        wood:
          special_data: OAK_PLANKS
          sound: BLOCK_CHERRY_WOOD_BREAK
          pitch: 1.3
        brick:
          special_data: BRICKS
          sound: BLOCK_MUD_BRICKS_BREAK
          pitch: 1.2
        metal:
          special_data: IRON_BARS
          sound: BLOCK_NETHERITE_BLOCK_BREAK
          pitch: 1.2
    - define mat_data <[mat_data_list].get[<[mat_type]>]>
    - define fx_loc <[prop_model].location.add[<[prop_model].translation>]>

    - playsound <[fx_loc]> sound:<[mat_data].get[sound]> pitch:<[mat_data].get[pitch]>
    - playeffect effect:BLOCK_CRACK at:<[fx_loc]> offset:0.3 special_data:<[mat_data].get[special_data]> quantity:25 visibility:30
    #no need to remove attached centers flag from attached center, since it'll check if it's spawned or not
    - remove <[prop_model]>|<[prop_hb]>

fort_prop_bookshelf:
  type: item
  material: gold_nugget
  display name: Bookshelf
  mechanisms:
    custom_model_data: 24
    hides: ALL
  flags:
    material: wood
    health: 50
    translation: 0,0.797,0
    hitbox:
      height: 2.25
      width: 1.5

fort_prop_bookshelf_small:
  type: item
  material: gold_nugget
  display name: Small Bookshelf
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: 50

fort_prop_rack:
  type: item
  material: gold_nugget
  display name: Rack
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: metal
    health: 120

fort_prop_closet:
  type: item
  material: gold_nugget
  display name: Closet
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: 50

fort_prop_red_chair:
  type: item
  material: gold_nugget
  display name: Red Chair
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: 50

fort_prop_television:
  type: item
  material: gold_nugget
  display name: Television
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: 50

fort_prop_refrigerator:
  type: item
  material: gold_nugget
  display name: Refrigerator
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: brick
    health: 120

fort_prop_toilet:
  type: item
  material: gold_nugget
  display name: Toilet
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: brick
    health: 150

fort_prop_bathtub:
  type: item
  material: gold_nugget
  display name: Bathtub
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: brick
    health: 75

fort_prop_bed:
  type: item
  material: gold_nugget
  display name: Bed
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: wood
    health: 120

fort_prop_tires:
  type: item
  material: gold_nugget
  display name: Tires
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    material: metal
    health: unbreakable