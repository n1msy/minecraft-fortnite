#One minor difference between this and Val:
#When you pick up a gun from the ground, the gun you bought in the buy phase is removed and money is recovered
#instead of dropped too.

fort_gun_handler:
  type: world
  debug: false
  definitions: data
  events:

    on player picks up ammo_*:
    - determine passively cancelled
    - define add_qty    <context.item.quantity>
    - define ammo_type  <context.item.script.name.after_last[_]>
    - define total_ammo <player.flag[fort.ammo.<[ammo_type]>]||0>
    - if <[total_ammo]> >= 999:
      - stop

    - define new_total <[total_ammo].add[<[add_qty]>]>

    - if <[new_total]> > 999:
      - define left_over <[new_total].sub[999]>
      - define add_qty   <[add_qty].sub[<[left_over]>]>
      - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[left_over]>]>

    - adjust <player> fake_pickup:<context.entity>
    - remove <context.entity>

    - flag player fort.ammo.<[ammo_type]>:+:<[add_qty]>
    - inject update_hud

    after ammo_* merges:
    - define item <context.item>
    - define target <context.target>
    - define other_item <[target].item>

    #if they're different ammot ypes
    - if <[item].script.name> != <[other_item].script.name>:
      - determine passively cancelled
      - stop

    - define new_qty   <[other_item].quantity>

    - define ammo_type <[item].script.name.after_last[_]>
    - define ammo_icon <&chr[E0<map[light=11;medium=22;heavy=33;shells=44;rockets=55].get[<[ammo_type]>]>].font[icons]>
    - define text <[ammo_icon]><&f><&l>x<[new_qty]>

    - adjust <[target]> custom_name:<[text]>

    after player picks up gun_*:
    - define gun_uuid <context.item.flag[uuid]>
    - define mag_size <context.item.flag[mag_size]>
    - if !<server.has_flag[fort.temp.<[gun_uuid]>.loaded_ammo]>:
      - flag server fort.temp.<[gun_uuid]>.loaded_ammo:<[mag_size]>

    - inject update_hud

    after player drops gun_*:
    - inject update_hud

    # - [ scope ] - #
    after player starts sneaking:
    - if <player.item_in_hand.script.name.starts_with[gun_].not||true>:
      - stop
    - define gun <player.item_in_hand>

    - flag player fort.gun_scoped

    #zoom in
    - cast SPEED amplifier:-4 duration:9999s no_icon no_ambient hide_particles

    #wait until anything stops them from scoping
    - waituntil !<player.is_online> || !<player.is_sneaking> || <player.gamemode> == SPECTATOR || <player.item_in_hand> != <[gun]> rate:1t

    - cast SPEED remove
    - flag player fort.gun_scoped:!

    #"disable" left clicking with guns
    on player left clicks block with:gun_*:
    - determine passively cancelled
    - cast FAST_DIGGING amplifier:9999 duration:1s no_icon no_ambient hide_particles

    on player right clicks block with:gun_*:
    - determine passively cancelled

    #-cancel shooting while trying to reload

    - define gun        <player.item_in_hand>
    - define gun_name   <[gun].script.name.after[_]>
    - define gun_uuid   <[gun].flag[uuid]>

    #-out of ammo check
    - define loaded_ammo <server.flag[fort.temp.<[gun_uuid]>.loaded_ammo]>
    - if <[loaded_ammo]> == 0:
      - stop

    #all NON-AUTO guns have cooldowns
    - if <player.has_flag[fort.<[gun_name]>.cooldown]>:
      - stop

    - flag player gun_holding_down duration:5t

    - if <player.has_flag[is_shooting]>:
      - stop

    - run fort_gun_handler.shoot def:<map[gun=<[gun]>]>

  ## - [ Shoot Stuff ] - ##
  shoot:

    - define world           <player.world>
    - define gun             <[data].get[gun]>
    - define gun_name        <[gun].script.name.after[_]>
    - define gun_uuid        <[gun].flag[uuid]>
    - define ammo_type       <[gun].flag[ammo_type]>

    - define rarity              <[gun].flag[rarity]>
    - define base_damage         <[gun].flag[rarities.<[rarity]>.damage]>
    - define pellets             <[gun].flag[pellets]>
    - define base_bloom          <[gun].flag[base_bloom]>
    - define bloom_multiplier    <[gun].flag[bloom_multiplier]>
    - define headshot_multiplier <[gun].flag[headshot_multiplier]>

    - define custom_recoil_fx     <[gun].flag[custom_recoil_fx]>
    #phantom / vandal = 2
    #
    - define ticks_between_shots <[gun].flag[ticks_between_shots]||3>
    - define mod_value           <[ticks_between_shots].equals[1].if_true[0].if_false[1]>

    - if <[gun].has_flag[cooldown]>:
      - flag player fort.<[gun_name]>.cooldown duration:<[gun].flag[cooldown]>s

    - flag player is_shooting
    - while <player.has_flag[gun_holding_down]> && <player.is_online> && <player.item_in_hand> == <[gun]>:
      #do 1 instead of 0 so there's no delay on the first shot
      - if <[loop_index].mod[<[ticks_between_shots]>]> == <[mod_value]>:

        - define times_shot <[ticks_between_shots].equals[1].if_true[<[loop_index]>].if_false[<[loop_index].div[<[ticks_between_shots]>].round_down.add[1]>]>
        - run fort_gun_handler.recoil def:<map[gun_name=<[gun_name]>]>

        - inject fort_gun_handler.fire

        #sound
        - foreach <[gun].flag[Sounds].keys> as:sound:
          - define pitch <[gun].flag[Sounds.<[sound]>.Pitch]>
          - define volume <[gun].flag[Sounds.<[sound]>.Volume]>
          - playsound <player.location> sound:<[sound]> pitch:<[pitch]> volume:<[volume]>

        - inject fort_gun_handler.ammo_handler

        - flag player is_shooting.loc:<player.location>
        - if <[gun].has_flag[cooldown]> && <[times_shot]> == 1:
          - while stop

      - wait 0.5t
    - flag player is_shooting:!

    #crosshair reset for guns that want it
    - if !<player.has_flag[gun.<[gun_name]>.recoil]>:
      - stop

    #how much the pitch was changed
    - define recoil <player.flag[gun.<[gun_name]>.recoil]>

    - define recoiL_size <[recoil].div[6]>
    - repeat 6:
      - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.add[<[recoil_size]>]> offthread_repeat:3
      - wait 1t
    - flag player gun.<[gun_name]>.recoil:!

  fire:
  #required definitions:
  # - <[pellets]>

    - repeat <[pellets]>:

      #eye loc is used for the particle effects
      - define eye_loc    <player.eye_location>
      #origin is the actual origin point to destination ray
      - define origin     <[eye_loc]>

      # - [ Simple bloom calculator ] - #
      - define bloom <[base_bloom]>
      #if the player is in the air
      - if !<player.location.y.mul[16].is_integer>:
        - define bloom:+:0.75
      #if they're walking, increase bloom
      - if <player.has_flag[is_shooting.loc]> && <player.location.with_pose[0,0]> != <player.flag[is_shooting.loc].with_pose[0,0]>:
        - define bloom:+:0.5
      #if they're spamming, increase bloom
      - if <[times_shot]> > 1:
        - define bloom:+:0.5
      - define bloom <[bloom].mul[<[bloom_multiplier]>]>
      #apply bloom
      - define new_pitch <[origin].pitch.add[<util.random.decimal[-<[bloom]>].to[<[bloom]>]>]>
      - define new_yaw   <[origin].yaw.add[<util.random.decimal[-<[bloom]>].to[<[bloom]>]>]>
      - define origin    <[origin].with_pitch[<[new_pitch]>].with_yaw[<[new_yaw]>]>

      # - [ Ray ] - #
      #where the particle effect starts from
      #make it a procedure for each gun in the future?
      - define particle_origin <[origin].forward.relative[-0.33,-0.2,0.3]>
      - define ignored_entities <server.online_players.filter[gamemode.equals[SPECTATOR]].include[<player>].include[<[world].entities[armor_stand]>]>

      - define target          <[origin].ray_trace_target[ignore=<[ignored_entities]>;ray_size=1;range=200]||null>
      - define target_loc      <[origin].ray_trace[range=200;entities=*;ignore=<[ignored_entities]>;default=air]>

      - inject fort_gun_handler.shoot_fx

      # - [ Damage ] - #
      - if <[target]> != null && <[target].is_spawned>:

        # - [ Damage Falloff ] - #
        #maybe for future: to calculate distances, use the tiles provided in the wiki for distances and convert to tile sizes in mc for 1:1
        - define distance <[target_loc].distance[<[origin]>]>
        #1 = no damage falloff
        #0 = all damage gone
        #start off with 100% damage falloff
        - define damage_falloff 0
        - define distance_condensor 1.5
        - foreach <[gun].flag[damage_falloff].keys> as:max_dist:

          #since the distance from fortnite lengths doesn't exactly translate to mc lengths
          - define actual_max_dist <[max_dist].div[<[distance_condensor]>]>
          - if <[distance]> < <[actual_max_dist]>:
            - if <[loop_index]> == 1:
              - define damage_falloff 1
              - foreach stop

            - define max_falloff   <[gun].flag[damage_falloff.<[max_dist]>]>

            - if <[max_falloff]> == 0:
              - define damage_falloff 0
              - foreach stop

            - define min_dist        <[gun].flag[damage_falloff].keys.get[<[loop_index].sub[1]>]>
            - define actual_min_dist <[min_dist].div[<[distance_condensor]>]>
            - define min_falloff     <[gun].flag[damage_falloff.<[min_dist]>]>

            - define progress     <[distance].sub[<[actual_min_dist]>].div[<[actual_max_dist].sub[<[actual_min_dist]>]>]>

            - define damage_falloff <[min_falloff].sub[<[min_falloff].sub[<[max_falloff]>].mul[<[progress]>]>].div[100]>
            - foreach stop

        - define damage <[base_damage].div[<[pellets]>].mul[<[damage_falloff]>].round_down>

        #if it's headshot, multiply damage by headshot multiplier
        - define part_height <[target_loc].round_to[1].y.sub[<[target].location.y>]>
        - foreach <list[0.7|1.4|1.9]> as:height:
          - if <[part_height]> >= 0 && <[part_height]> <= <[height]>:
            - define body_part <list[Legs|Body|Head].get[<[Loop_Index]>]>
            - foreach stop

        - define damage <[damage].mul[<[headshot_multiplier]>].round_down> if:<[body_part].equals[Head]>

        - narrate <[damage]>

        #- hurt <[damage]> <[target]> source:<player>
        - if <[target].is_living>:
          - adjust <[target]> no_damage_duration:0

        - adjust <player> reset_attack_cooldown


  camera_shake:
    #default: 0.094
    - define mult <[data].get[mult]>
    - define ticks <[data].get[ticks]||2>
    - adjust <player> fov_multiplier:<[mult]>
    - wait <[ticks]>t
    - adjust <player> fov_multiplier

  recoil:

    - define gun_name <[data].get[gun_name]>
    - choose <[gun_name]>:
      - case pump_shotgun:
        - run fort_gun_handler.camera_shake def:<map[mult=0.08]>
        - define recoil 2
        - repeat <[recoil]>:
          - define pitch_sub <[value].div[1.5]>
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[pitch_sub]>]> offthread_repeat:3
          - wait 1t
        - repeat <[recoil].mul[4]>:
          - define pitch_sub <element[8].sub[<[value]>].sub[6].div[10]>
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[pitch_sub]>]> offthread_repeat:3
          - wait 1t
      - case tactical_smg:
        - run fort_gun_handler.camera_shake def:<map[mult=0.094;ticks=3]>
        - define size 0.1
        - if <player.has_flag[gun.<[gun_name]>.recoil]> && <player.flag[gun.<[gun_name]>.recoil].div[<[size]>].round_down> > 10:
          - stop
        - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[size]>]> offthread_repeat:3
        - flag player gun.<[gun_name]>.recoil:+:<[size]>
      - default:
        - run fort_gun_handler.camera_shake def:<map[mult=0.0965]>
        - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[0.7]> offthread_repeat:3
        - repeat 4:
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.add[0.175]> offthread_repeat:3
          - wait 1t

  # - [ Ammo ] - #
  ammo_handler:

    - flag server fort.temp.<[gun_uuid]>.loaded_ammo:--
    - define loaded_ammo <server.flag[fort.temp.<[gun_uuid]>.loaded_ammo]>

    - inject update_hud

    - if <[loaded_ammo]> == 0:
      - run fort_gun_handler.reload def:<map[gun=<[gun]>]>
      - while stop

  drop_ammo:

    - define ammo_type <[data].get[ammo_type]>
    - define qty       <[data].get[qty]>
    - define loc       <player.eye_location.forward[1.5].sub[0,0.5,0]>

    - define item <item[ammo_<[ammo_type]>].with[quantity=<[qty]>]>

    - drop <[item]> <[loc]> delay:1s save:drop
    - define drop <entry[drop].dropped_entity>

    - define icon <&chr[E0<map[light=11;medium=22;heavy=33;shells=44;rockets=55].get[<[ammo_type]>]>].font[icons]>

    - define text <[icon]><&f><&l>x<[qty]>
    - define loc <[drop].location>

    - adjust <[drop]> custom_name:<[text]>
    - adjust <[drop]> custom_name_visible:true

  reload:
    - define gun         <[data].get[gun]>
    - define gun_uuid    <[gun].flag[uuid]>
    - define rarity      <[gun].flag[rarity]>
    - define ammo_type   <[gun].flag[ammo_type]>
    - define mag_size    <[gun].flag[mag_size]>
    - define total_ammo  <player.flag[fort.ammo.<[ammo_type]>]||0>

    - if <[total_ammo]> == 0:
      - stop


    - flag player fort.reloading_gun

    #to ticks
    - define reload_time <[gun].flag[rarities.<[rarity]>.reload_time].mul[20]>
    - define text <element[Reloading...].to_list>

    - cast SLOW_DIGGING amplifier:255 duration:9999999s no_icon no_ambient hide_particles
    - repeat <[reload_time].div[3]>:

      #if they hold it and it's, it'll auto reload
      - if <player.item_in_hand> != <[gun]>:
        - define cancelled True
        - repeat stop

      - define completed <[value].mul[12].div[<[reload_time].div[3]>].round>
      - define reloading_text <&c><[text].get[1].to[<[completed]>].unseparated||<empty>><&7><[text].get[<[completed].add[1]>].to[12].unseparated||<empty>>

      #- actionbar <[completed].equals[12].if_true[<&c><[text].unseparated>].if_false[<[reloading_text]>]>
      - title subtitle:<[completed].equals[12].if_true[<&c><[text].unseparated>].if_false[<[reloading_text]>]> fade_in:0
      - playsound <player.location> sound:BLOCK_NOTE_BLOCK_HAT pitch:<[value].div[<[reload_time].div[2]>].add[1]> volume:1.2
      - wait 3t

    - if !<[cancelled].exists>:

      - if <[total_ammo]> < <[mag_size]>:
        - define new_loaded_ammo <[total_ammo]>
      - else:
        - define new_loaded_ammo <[mag_size]>
      - define new_total_ammo <[total_ammo].sub[<[new_loaded_ammo]>]>

      - flag server fort.temp.<[gun_uuid]>.loaded_ammo:<[new_loaded_ammo]>
      - flag player fort.ammo.<[ammo_type]>:<[new_total_ammo]>

      - inject update_hud
      - playsound <player.location> sound:BLOCK_NOTE_BLOCK_BIT pitch:1 volume:1.2
      #- actionbar <&a>Reloaded
      - title subtitle:<&a>Reloaded fade_in:0 fade_out:0.5 stay:5t

    - cast SLOW_DIGGING remove
    - flag player fort.reloading_gun:!


  shoot_fx:
    - if <player.is_sneaking> && <[gun].has_flag[has_scope]>:
      #scoped origin
      - define particle_origin <[eye_loc].forward[1.8].below[0.25]>
    - else:
      #default origin
      - define particle_origin <[eye_loc].forward.relative[-0.33,-0.2,0.3]>

    #checking for value so it doesn't repeat the same amount of pellets
    - if <[value]> == 1:
      - if <[custom_recoil_fx]>:
        - run fort_gun_handler.custom_recoil_fx.<[gun_name]> def:<map[particle_origin=<[particle_origin]>]>
      - else:
        - run fort_gun_handler.default_recoil_fx def:<map[particle_origin=<[particle_origin]>]>

    # - [ "Base" Shoot FX ] - #
    - define trail <[particle_origin].points_between[<[target_loc]>].distance[7]>

    # - Points Between (Potential: CRIT, WAX_ON, SCRAPE, ELECTRIC_SPARK, BLOCK_DUST, DRIP_LAVA, FALLING_NECTAR, DRIPPING_HONEY, END_ROD,ENCHANTMENT_TABLE)
    - define between <[particle_origin].points_between[<[target_loc]>].distance[0.5]>
    - playeffect at:<[between]> effect:CRIT offset:0 visibility:500

    # - Impact (Potential: CAMPFIRE_COSY_SMOKE, SMOKE_NORMAL, SQUID_INK)
    - define particle_dest <[target_loc].face[<[eye_loc]>].forward[0.1]>
    - playeffect at:<[particle_dest]> effect:sweep_attack offset:0 quantity:1 visibility:500 velocity:1.65,1.65,1.65

    # - Blood / Material hit
    - define mat <player.cursor_on.material.name||null>
    - if <[target]> != null:
      #splatter: red_glazed_terracotta
      - playeffect at:<[particle_dest]> effect:BLOCK_CRACK offset:0 quantity:3 visibility:500 special_data:red_wool
    - else if <[mat]> != null:
      - playeffect at:<[particle_dest]> effect:BLOCK_CRACK offset:0 quantity:8 visibility:500 special_data:<[mat]>

  default_recoil_fx:
    - define particle_origin <[data].get[particle_origin]>

    - define neg  <proc[spacing].context[-50]>
    - define text <[neg]><&chr[000<util.random.int[4].to[6]>].font[muzzle_flash]><[neg]>
    - spawn <entity[armor_stand].with[custom_name=<[text]>;custom_name_visible=true;gravity=false;collidable=false;invulnerable=true;visible=false]> <[particle_origin].below[2.4]> save:flash
    - define flash <entry[flash].spawned_entity>

    - wait 2t
    - remove <[flash]>

  custom_recoil_fx:

    pump_shotgun:
      - define particle_origin <[data].get[particle_origin]>

      - define neg  <proc[spacing].context[-50]>
      - define text <[neg]><&chr[000<util.random.int[1].to[3]>].font[muzzle_flash]><[neg]>

      - spawn <entity[armor_stand].with[custom_name=<[text]>;custom_name_visible=true;gravity=false;collidable=false;invulnerable=true;visible=false]> <[particle_origin].below[2.5]> save:flash
      - define flash <entry[flash].spawned_entity>

      - wait 2t
      - remove <[flash]>
      - playeffect at:<[particle_origin]> effect:SMOKE_NORMAL offset:0.05 quantity:1 visibility:500

#@ [ Gun Data ] @#

ammo_light:
  type: item
  material: gold_nugget
  display name: LIGHT
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    qty: 1

ammo_medium:
  type: item
  material: gold_nugget
  display name: MEDIUM
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    qty: 1

ammo_heavy:
  type: item
  material: gold_nugget
  display name: HEAVY
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    qty: 1

ammo_shells:
  type: item
  material: gold_nugget
  display name: SHELLS
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    qty: 1

ammo_rockets:
  type: item
  material: gold_nugget
  display name: ROCKETS
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    qty: 1


gun_pump_shotgun:
  type: item
  material: wooden_hoe
  display name: <&f><&l>PUMP SHOTGUN
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    #this value can be changed
    rarity: common
    icon_chr: 1
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 5
    ammo_type: shells
    mag_size: 5
    #in seconds
    cooldown: 1
    #how many pellets in one shot
    pellets: 10
    base_bloom: 1.8
    bloom_multiplier: 1
    headshot_multiplier: 2
    #if there's a slightly different shoot effect alongside the base ones
    custom_recoil_fx: true
    uuid: <util.random_uuid>
    #rarity-based states
    rarities:
      common:
        damage: 92
        reload_time: 5.1
        custom_model_data: x
      uncommon:
        damage: 101
        reload_time: 4.8
        custom_model_data: x
      rare:
        damage: 110
        reload_time: 4.4
        custom_model_data: x
      epic:
        damage: 119
        reload_time: 4.0
        custom_model_data: x
      legendary:
        damage: 128
        reload_time: 3.7
        custom_model_data: x
    #(in meters/blocks)
    #value is in percentage of damage
    #max means it wont deal any damage past that
    damage_falloff:
      7: 100
      10: 78
      15: 49
      31: 0

    sounds:
      ENTITY_FIREWORK_ROCKET_LARGE_BLAST:
        pitch: 0.8
        volume: 1.2
      ENTITY_DRAGON_FIREBALL_EXPLODE:
        pitch: 1.8
        volume: 1.2

gun_assault_rifle:
  type: item
  material: wooden_hoe
  display name: <&f><&l>ASSAULT RIFLE
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    #this value can be changed
    rarity: common
    icon_chr: 1
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 4
    ammo_type: medium
    mag_size: 30
    #in seconds
    #cooldown: 0
    pellets: 1
    base_bloom: 1.2
    bloom_multiplier: 1
    headshot_multiplier: 1.5
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    rarities:
      common:
        damage: 30
        reload_time: 2.7
        custom_model_data: x
      uncommon:
        damage: 31
        reload_time: 2.6
        custom_model_data: x
      rare:
        damage: 33
        reload_time: 2.5
        custom_model_data: x
      epic:
        damage: 35
        reload_time: 2.4
        custom_model_data: x
      legendary:
        damage: 36
        reload_time: 2.2
        custom_model_data: x
    #(in meters)
    #value is in percentage of damage
    damage_falloff:
      50: 100
      75: 80
      95: 66

    sounds:
      ENTITY_FIREWORK_ROCKET_BLAST_FAR:
        pitch: 1.07
        volume: 1.2

gun_tactical_smg:
  type: item
  material: wooden_hoe
  display name: <&f><&l>TACTICAL SMG
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    #this value can be changed
    rarity: uncommon
    icon_chr: 1
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 2
    ammo_type: light
    mag_size: 25
    #in seconds
    #cooldown: 0
    pellets: 1
    base_bloom: 1.15
    bloom_multiplier: 1.5
    headshot_multiplier: 1.75
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    rarities:
      #no common tac smgs
      uncommon:
        damage: 18
        reload_time: 2.2
        custom_model_data: x
      rare:
        damage: 19
        reload_time: 2.1
        custom_model_data: x
      epic:
        damage: 20
        reload_time: 2.0
        custom_model_data: x
      legendary:
        damage: 21
        reload_time: 1.9
        custom_model_data: x
    #(in meters)
    #value is in percentage of damage
    #no damage falloff was found, so im using same as AR
    damage_falloff:
      50: 100
      75: 80
      95: 66

    sounds:
      ENTITY_FIREWORK_ROCKET_BLAST_FAR:
        pitch: 1.2
        volume: 1.2
      UI_BUTTON_CLICK:
        pitch: 1.9
        volume: 0.4