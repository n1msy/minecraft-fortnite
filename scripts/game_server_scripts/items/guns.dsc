#CENTER THE AMOO TEXT OR NO?

drop_all_items:
  type: task
  debug: false
  script:
  - foreach <util.scripts.filter[name.starts_with[gun_]].parse[name.as[item]]> as:i:
    - drop <[i]> <player.location.random_offset[10,0,10]>

  - foreach <util.scripts.filter[name.starts_with[fort_item_]].parse[name.as[item]]> as:i:
    - drop <[i]> <player.location.random_offset[10,0,10]>

fort_gun_handler:
  type: world
  debug: false
  definitions: data
  events:

    on entity exits vehicle flagged:rocket_riding:
    - define rocket <context.vehicle>
      #waiting 5t so they dont instantly get hit when they get off the rocket
    - flag <context.entity> rocket_riding:!
    - wait 15t
    - if <[rocket].is_spawned>:
      - flag <[rocket]> riders:<-:<context.entity>

    on player picks up ammo_*:
    - determine passively cancelled
    - define add_qty    <context.entity.flag[quantity]>
    - define ammo_type  <context.item.script.name.after_last[_]>
    - define total_ammo <player.flag[fort.ammo.<[ammo_type]>]||0>
    - if <[total_ammo]> >= 999:
      - stop

    - define new_total <[total_ammo].add[<[add_qty]>]>

    - if <[new_total]> > 999:
      - define left_over <[new_total].sub[999]>
      - define add_qty   <[add_qty].sub[<[left_over]>]>
      - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[left_over]>]>

    - define e <context.entity>
    - adjust <player> fake_pickup:<[e]>
    - if <[e].has_flag[text_display]>:
      - remove <[e].flag[text_display]>
    - remove <[e]>

    - flag player fort.ammo.<[ammo_type]>:+:<[add_qty]>
    - inject update_hud

    on ammo_* merges:
    - determine passively cancelled
    - define old_drop <context.entity>
    - define new_drop <context.target>

    #if different ammo types
    - if <[old_drop].item.script.name> != <[new_drop].item.script.name>:
      - stop


    - if <[new_drop].flag[quantity]> == 999:
      - stop

    - define new_qty   <[new_drop].flag[quantity]>
    - define old_qty   <[old_drop].flag[quantity]>
    - define total_qty <[old_qty].add[<[new_qty]>]>

    - if <[old_drop].has_flag[text_display]>:
      - remove <[old_drop].flag[text_display]> if:<[old_drop].flag[text_display].is_spawned>

    - define ammo_type <[new_drop].item.script.name.after_last[_]>
    - define ammo_icon <&chr[E0<map[light=11;medium=22;heavy=33;shells=44;rockets=55].get[<[ammo_type]>]>].font[icons]>
    - define text <[ammo_icon]><&f><&l>x<[total_qty]>

    #no need to remove text display, since it removes when the item is removed too
    - remove <[old_drop]>
    - flag <[new_drop]> quantity:<[total_qty]>
    - if <[new_drop].has_flag[text_display]>:
      - adjust <[new_drop].flag[text_display]> text:<[text]>

    on player picks up gun_*:

    #so players dont go over 6 slots
    - if <player.inventory.slot[2|3|4|5|6].filter[material.name.equals[air]].is_empty>:
      - determine passively cancelled
      - stop

    - if <context.entity.has_flag[text_display]>:
      - remove <context.entity.flag[text_display]> if:<context.entity.flag[text_display].is_spawned>

    #safety
    - wait 1t
    - define gun      <context.item>
    - define gun_slot <player.inventory.find_item[<[gun]>]>

    - if <[gun_slot]> == -1:
      - stop

    - define gun_uuid <[gun].flag[uuid]>
    - define mag_size <[gun].flag[mag_size]>

    #remove rarity color
    - inventory adjust slot:<[gun_slot]> color:<color[#000000]>

    #when initialize the gun
    - if !<server.has_flag[fort.temp.<[gun_uuid]>.loaded_ammo]>:
      - flag server fort.temp.<[gun_uuid]>.loaded_ammo:<[mag_size]>

      - define rarity <[gun].flag[rarity]>
      - define rarity_line <[rarity].to_titlecase.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=ffaf24].get[<[rarity]>]>]>

      - define stars_line <&f><map[Common=★;Uncommon=★★;Rare=★★★;Epic=★★★★;Legendary=★★★★★].get[<[rarity]>]><n>

      - define damage              <[gun].flag[rarities.<[rarity]>.damage]>
      - define pellets             <[gun].flag[pellets]>
      - define ticks_between_shots <[gun].flag[ticks_between_shots]>
      - define dps <[damage].mul[20].div[<[ticks_between_shots]>].div[<[pellets]>]>
      - define ammo_icon <&chr[E0<map[light=11;medium=22;heavy=33;shells=44;rockets=55].get[<[gun].flag[ammo_type]>]>].font[icons]>
      - define dps_line "<[ammo_icon]> <&7>DPS <&f><&l><[dps]><n>"

      - define fire_rate       <element[20].div[<[ticks_between_shots]>].round_to[1]>
      - define fire_rate_line "<&7>Fire Rate <&f><[fire_rate]>"

      - define mag_line       "<&7>Magazine Size <&f><[gun].flag[mag_size]>"

      - define reload_line    "<&7>Reload Time <&f><[gun].flag[rarities.<[rarity]>.reload_time]>"
      - define lore <list[<[rarity_line]>|<[stars_line]>|<[dps_line]>|<[fire_rate_line]>|<[mag_line]>|<[reload_line]>]>
      - inventory adjust slot:<[gun_slot]> lore:<[lore]>

    - inject update_hud

    #if gun is empty when picking it up, reload
    - define loaded_ammo <server.flag[fort.temp.<[gun_uuid]>.loaded_ammo]>
    - if <[loaded_ammo]> <= 0:
      - run fort_gun_handler.reload def:<map[gun=<[gun]>]>

    on player drops gun_*:
    #so players can't drop their gun while scoped
    #do this^ OR let them drop the gun and just change the gun model data back to what it was?
    - if <player.has_flag[fort.gun_scoped]>:
      - determine passively cancelled
      #flag so reload event doesn't fire
      - flag player fort.dropped_gun duration:1t
      - stop

    - wait 1t
    - define gun    <context.item>
    - define drop   <context.entity>

    - run fort_gun_handler.drop_gun def:<map[gun=<[gun]>;drop=<[drop]>]>

    - inject update_hud

    # - [ Scope ] - #
    after player starts sneaking:
    - define look_loc <player.eye_location.ray_trace[return=block;range=2.7;default=air].center>
    - foreach <list[chest|ammo_box]> as:container_type:
      - if <[look_loc].has_flag[fort.<[container_type]>]> && !<[look_loc].has_flag[fort.chest.<[container_type]>]>:
        - inject fort_chest_handler.open
        - stop

    - if <player.eye_location.ray_trace_target[range=2.4;ignore=<player>].has_flag[fort.supply_drop.hitbox]||false>:
      - inject fort_chest_handler.open_supply_drop
      - stop

    - if <player.item_in_hand.script.name.starts_with[gun_].not||true>:
      - stop
    #
    #in case the sneaks somehow overlap with each other
    #(so they're already scoped, odd bug that asd found)
    #(maybe lag was the cause)
    - if <player.has_flag[fort.gun_scoped]>:
      - stop

    - define gun      <player.item_in_hand>
    - define gun_uuid <[gun].flag[uuid]>
    - define slot     <player.held_item_slot>
    - define cmd      <[gun].custom_model_data>

    - if <[gun].has_flag[sniper]> && <player.has_flag[fort.reloading_gun]>:
      - stop

    #because it has two models (one with and one without a rocket)
    - if <[gun].script.name.after[gun_]> == rocket_launcher && <player.has_flag[fort.reloading_gun]>:
      - stop

    - flag player fort.gun_scoped


    - if <[gun].has_flag[sniper]>:
      - playsound <player> sound:ITEM_SPYGLASS_USE pitch:1
      - equip head:carved_pumpkin
      - adjust <player> fov_multiplier:1
      #hide the gun
      - cast SLOW_DIGGING amplifier:255 duration:9999999s no_icon no_ambient hide_particles
    - else:
      #scope model
      - inventory adjust slot:<[slot]> custom_model_data:<[cmd].add[1]>
      #zoom in
      - cast SPEED amplifier:-4 duration:9999s no_icon no_ambient hide_particles

    #wait until anything stops them from scoping
    - waituntil !<player.has_flag[fort.gun_scoped]> || <player.has_flag[fort.reset_sniper_scope]> || !<player.is_online> || !<player.is_sneaking> || <player.gamemode> == SPECTATOR || <player.item_in_hand.flag[uuid]||null> != <[gun_uuid]> rate:1t

    - if <[gun].has_flag[sniper]>:
      - inject fort_gun_handler.reset_sniper_scope
    - else:
      #-issue: when player dies?
      #no need to check if they dropped, since they can't drop when scoped
      - inventory adjust slot:<[slot]> custom_model_data:<[cmd]>
    - cast SPEED remove

    - flag player fort.gun_scoped:!

    #left clicking with gun = reload
    on player left clicks block with:gun_*:
    - determine passively cancelled
    - cast FAST_DIGGING amplifier:9999 duration:1s no_icon no_ambient hide_particles
    - stop if:<player.has_flag[fort.dropped_gun].or[<player.has_flag[fort.opened_door_with_gun]>]>

    - define gun <context.item>
    - define loaded_ammo <server.flag[fort.temp.<[gun].flag[uuid]>.loaded_ammo]>
    - if <[loaded_ammo]> < <[gun].flag[mag_size]>:
      - stop if:<player.has_flag[fort.reloading_gun]>
      - wait 1t
      - flag player fort.gun_scoped:!
      - run fort_gun_handler.reload def:<map[gun=<[gun]>]>
      - stop

    - title "subtitle:<&c>Already reloaded." fade_in:0 stay:1 fade_out:15t
    - playsound <player> sound:UI_BUTTON_CLICK pitch:1.8

    on player right clicks entity with:gun_*:
    - determine passively cancelled
    - inject fort_gun_handler.use_gun

    on player right clicks block with:gun_*:
    - if <context.location.material.name.contains_text[door]||false>:
      - flag player fort.opened_door_with_gun duration:1t
      - cast FAST_DIGGING amplifier:9999 duration:1s no_icon no_ambient hide_particles
      - stop
    - determine passively cancelled
    - inject fort_gun_handler.use_gun
    #-cancel shooting while trying to reload


  use_gun:
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

    - if <[gun].has_flag[first_shot_accuracy]> && !<player.has_flag[gun_holding_down]>:
      - define gun <[gun].with[flag=base_bloom:0]>

    - flag player gun_holding_down duration:5t

    - if <player.has_flag[is_shooting]>:
      - stop

    - if <[gun].has_flag[sniper]> && <player.has_flag[fort.gun_scoped]>:
      - inject fort_gun_handler.reset_sniper_scope

    #cancel the emote if they're emoting
    - if <player.has_flag[fort.emote]>:
      - flag player fort.emote:!
      #wait so the player shoots from where they were emoting and not spectating
      - wait 1t

    - run fort_gun_handler.shoot def:<map[gun=<[gun]>]>

  reset_sniper_scope:
    - playsound <player> sound:ITEM_SPYGLASS_USE pitch:1
    - equip head:air
    - adjust <player> fov_multiplier
    - cast SLOW_DIGGING remove
    #separate flag (this is checked "on player starts sneaking")
    #so that the shoot event knows you're still scoped in
    - flag player fort.reset_sniper_scope duration:1t

  ## - [ Shoot Stuff ] - ##
  shoot:

    - define world           <player.world>
    - define gun             <[data].get[gun]>
    - define gun_name        <[gun].script.name.after[_]>
    - define gun_uuid        <[gun].flag[uuid]>
    - define ammo_type       <[gun].flag[ammo_type]>

    #for special exceptions like grenade/rocket launchers
    - define custom_shoot    <[gun].has_flag[custom_shoot]>

    - define rarity              <[gun].flag[rarity]>
    #divide by 5, since the damage is based on the 100 scale
    - define base_damage         <[gun].flag[rarities.<[rarity]>.damage].div[5]>
    - define pellets             <[gun].flag[pellets]>
    #mul base_damage by 5, since tiles use 100 hp scale and not 20
    - define structure_damage    <[gun].flag[rarities.<[rarity]>.structure_damage]||<[base_damage].mul[5]>>
    - define structure_damage    <[structure_damage].div[<[pellets]>]>
    - define base_bloom          <[gun].flag[base_bloom]>
    - define bloom_multiplier    <[gun].flag[bloom_multiplier]>
    - define headshot_multiplier <[gun].flag[headshot_multiplier]>

    - define custom_recoil_fx     <[gun].flag[custom_recoil_fx]>
    #phantom / vandal = 2
    #
    - define ticks_between_shots <[gun].flag[ticks_between_shots]||3>
    #for any gun like the burst
    - define shots_between_wait  <[gun].flag[shots_between_wait]||0>
    - define mod_value           <[ticks_between_shots].equals[1].if_true[0].if_false[1]>
    - define times_shot          0

    - if <[gun].has_flag[cooldown]>:
      - flag player fort.<[gun_name]>.cooldown duration:<[gun].flag[cooldown]>s

    - flag player is_shooting
    - flag player fort.reloading_gun:!
    - while <player.has_flag[gun_holding_down]> && <player.is_online> && <player.item_in_hand.flag[uuid]||null> == <[gun_uuid]>:
      #do 1 instead of 0 so there's no delay on the first shot
      - if <[loop_index].mod[<[ticks_between_shots]>]> == <[mod_value]>:
        - define times_shot <[ticks_between_shots].equals[1].if_true[<[loop_index]>].if_false[<[loop_index].div[<[ticks_between_shots]>].round_down.add[1]>]>
        - run fort_gun_handler.recoil def:<map[gun_name=<[gun_name]>]>

        - if <[custom_shoot]>:
          #structure_damage since both rocket launchers and grenade launchers use it
          - run fort_gun_handler.custom_shoot.<[gun_name]> def:<map[damage=<[base_damage]>;structure_damage=<[structure_damage]>]>
        - else:
          - inject fort_gun_handler.fire

        #for guns with multiple pellets at once (ie shot guns)
        - if <[hit_targets].exists>:
          - foreach <[hit_targets]> as:h_target:
            - define color <&f>
            #player hit
            - playsound <player> sound:ITEM_ARMOR_EQUIP_LEATHER pitch:2
            - if <[hit_data.<[h_target]>.hit_head]>:
              - define color <&e>
              #crisp headshot sound effect
              - playsound <player> sound:BLOCK_AMETHYST_BLOCK_BREAK pitch:1.5
            - if <[h_target].armor_bonus||0> > 0:
              - define color <&b>

              #multiply the damage to show visually that it's in the 100 scale
            - run fort_global_handler.damage_indicator def:<map[damage=<[hit_data.<[h_target]>.damage].mul[5].round>;entity=<[h_target]>;color=<[color]>]>

        #sound
        - foreach <[gun].flag[Sounds].keys> as:sound:
          - define pitch <[gun].flag[Sounds.<[sound]>.Pitch]>
          - define volume <[gun].flag[Sounds.<[sound]>.Volume]>
          - playsound <player.location> sound:<[sound]> pitch:<[pitch]> volume:<[volume]>

        - inject fort_gun_handler.ammo_handler

        - flag player is_shooting.loc:<player.location>
        - if <[gun].has_flag[cooldown]> && <[times_shot]> == 1:
          - while stop

      - if <[shots_between_wait]> != 0 && <[times_shot].mod[<[shots_between_wait]>]> == 0:
        #this can become its own flag eventually too if needed
        - wait 3t

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
      - if <[gun].has_flag[sniper]> && <player.has_flag[fort.gun_scoped]>:
        - define bloom 0
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
      - define ignored_entities <server.online_players.filter[gamemode.equals[SPECTATOR]].include[<player>].include[<[world].entities[armor_stand|dropped_item]>]>

      #entity
      - define target          <[origin].ray_trace_target[ignore=<[ignored_entities]>;ray_size=1;range=200]||null>
      #impact before block (air)
      - define target_loc      <[origin].ray_trace[range=200;entities=*;ignore=<[ignored_entities]>;default=air]>
      #block
      - define target_block    <[origin].ray_trace[range=200;entities=*;ignore=<[ignored_entities]>;default=air;return=block]>

      - inject fort_gun_handler.shoot_fx

      # - [ Damage ] - #
      #structure damage (damagefalloff doesn't apply)
      #fallback, in case chunk isn't loaded
      - if <[target_block].has_flag[build.center]||false>:
        - define center     <[target_block].flag[build.center]>
        - define center_key <[center].simple>
        #doing this for support for multiple tiles being hit at once
        - define damaged_structures.<[center_key]>.damage:+:<[structure_damage]>
        #defining center correctly too (i dont have to keep on redefining, but it's an extra if check sooo)
        - define damaged_structures.<[center_key]>.center:<[center]>

      - if <[target]> != null && <[target].is_spawned>:
        # - [ Damage Falloff ] - #
        #maybe for future: to calculate distances, use the tiles provided in the wiki for distances and convert to tile sizes in mc for 1:1
        - define distance <[target_loc].distance[<[origin]>]>
        #1 = no damage falloff
        #0 = all damage gone
        #start off with 100% damage falloff
        - if !<[gun].has_flag[damage_falloff]>:
          #for snipers basically
          - define damage_falloff 1
        - else:
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

        # - [ LIVING TARGETS ] - #
        - if <[target].is_living> || <[target].has_flag[emote.hitbox.host]>:

          #if it's headshot, multiply damage by headshot multiplier
          - define part_height <[target_loc].round_to[1].y.sub[<[target].location.y>]>
          - foreach <list[0.7|1.4|1.9]> as:height:
            - if <[part_height]> >= 0 && <[part_height]> <= <[height]>:
              - define body_part <list[Legs|Body|Head].get[<[Loop_Index]>]>
              - foreach stop

          #-should it automatically cancel the emote animation when hit?
          - if <[target].has_flag[emote.hitbox.host]>:
            - define target_hitbox <[target]>
            - define target        <[target].flag[emote.hitbox.host]>

          #shot flag is for damage indicator
          - flag <[target]> fort.shot duration:1t
          - define damage <[damage].mul[<[headshot_multiplier]>].round_down> if:<[body_part].equals[Head]>
          - hurt <[damage]> <[target]> source:<player> if:<[target].world.name.equals[pregame_island].not>
          #total damage to consider all damage combined if multiple pellets are used per shot
          - if <[pellets]> > 1:
            #multiple list support in case pellets hit multiple people
            - define total_damage 0
            - if <[hit_data.<[target]>.damage].exists>:
              - define total_damage <[hit_data.<[target]>.damage]>
            - define hit_data.<[target]>.damage:<[total_damage].add[<[damage]>]>
            - define hit_data.<[target]>.hit_head:<[body_part].equals[Head]>
            - define hit_targets:->:<[target]> if:<[hit_targets].contains[<[target]>].not||true>
          - else:
            - define color <&f>
            - playsound <player> sound:ITEM_ARMOR_EQUIP_LEATHER pitch:2
            - if <[body_part]> == Head:
              - define color <&e>
              - playsound <player> sound:BLOCK_AMETHYST_BLOCK_BREAK pitch:1.5
            - if <[target].armor_bonus||0> > 0:
              - define color <&b>
            - adjust <[target]> no_damage_duration:0
            #multiple pellets uses slightly different logic for the damage_indicator, so you findout when you check if <[hit_targets]> exists
            - run fort_global_handler.damage_indicator def:<map[damage=<[damage].mul[5].round_down>;entity=<[target_hitbox].if_null[<[target]>]>;color=<[color]>]>

          - adjust <[target]> no_damage_duration:0

          #-show damage indicator even if it's 0?
          - adjust <player> reset_attack_cooldown

        # - [ SUPPLY DROPS ] - #
        - else if <[target].has_flag[fort.supply_drop.hitbox.health]>:
          - define color <&f>
          - flag <[target]> fort.supply_drop.hitbox.health:-:<[damage]>
          - if <[target].flag[fort.supply_drop.hitbox.health]> <= 0:
            - flag <[target]> fort.supply_drop.hitbox.health:!

          - define health_display <[target].flag[fort.supply_drop.health_bar]>
          - if <[health_display].is_spawned>:
            - define hp     <[target].flag[fort.supply_drop.hitbox.health]||0>
            - define max_hp 150
            - adjust <[health_display]> show_to_players
            - define health_r <[hp].div[<[max_hp]>].mul[255].round_down>
            - define bar_icon    <&chr[C005].font[icons].color[<[health_r]>,2,50]>
            - define health_text "<[hp].format_number> <element[｜ <[max_hp].format_number>].color[209,255,196]>"
            - define health_text <[bar_icon]><proc[spacing].context[-163]><[health_text]><proc[spacing].context[126]>
            - adjust <[health_display]> text:<[health_text]>

          #-show damage indicator even if it's 0?
          - run fort_global_handler.damage_indicator def:<map[damage=<[damage].mul[5].round_down>;entity=<[target]>;color=<[color]>]>
          - adjust <player> reset_attack_cooldown

        # - [ DAMAGE TO PROPS ] - #
        #my main concern is that people spam it with a gun and it causes issues
        - else if <[target].has_flag[fort.prop]>:
          #rest of the hurt stuff is handled within the prop file itself
          - run fort_prop_handler.damage_prop def:<map[prop_hb=<[target]>;damage=<[damage].mul[5]>]>

    #outside of the repeat, handling damage *after* all pellets are shot to prevent lag
    - if <[damaged_structures].exists>:
      #this way, the damage structure command only fires ONCE per tile
      - foreach <[damaged_structures].keys> as:center_key:
        - define center     <[damaged_structures.<[center_key]>.center]>
        #in case it's already broken
        - if !<[center].has_flag[build]>:
          - foreach next
        - define struct_dmg <[damaged_structures.<[center_key]>.damage]>
        #in case it's already broken
        - run build_system_handler.structure_damage def:<map[center=<[center]>;damage=<[struct_dmg]>]>

  custom_shoot:
    grenade_launcher:

      - define body_damage      <[data].get[damage]>
      - define structure_damage <[data].get[structure_damage]>

      - define particle_origin <proc[gun_particle_origin].context[grenade_launcher]>
      - run fort_gun_handler.default_recoil_fx def:<map[particle_origin=<[particle_origin]>]>

      - define eye_loc    <player.eye_location>
      - define origin     <[eye_loc].forward>
      - define origin     <[origin].below[0.2]> if:<player.has_flag[fort.gun_scoped]>

      - define ignored_entities <server.online_players.filter[gamemode.equals[SPECTATOR]].include[<player>].include[<player.world.entities[armor_stand]>]>
      - define target_loc       <[origin].ray_trace[range=200;entities=*;ignore=<[ignored_entities]>;default=air]>

      - define e          <entity[snowball].with[item=<item[gold_nugget].with[custom_model_data=2]>]>
      - shoot <[e]> origin:<[origin]> height:0.2 save:grenade

      - define grenade <entry[grenade].shot_entity>
      - while <[grenade].is_spawned> && !<[grenade].is_on_ground>:
        - define grenade_loc <[grenade].location>
        - if <[loop_index]> > 5:
          - playeffect effect:CLOUD at:<[grenade_loc].above[0.3]> quantity:1 offset:0 visibility:300
        - if <[loop_index].div[20]> == 5:
          - while stop
        - wait 1t

      - wait 3t
      - run fort_explosive_handler.explosion_fx def:<map[grenade_loc=<[grenade_loc]>;size=3]>
      - run fort_explosive_handler.explosion_damage def:<map[radius=4;body_damage=<[body_damage]>;structure_damage=<[structure_damage]>;grenade_loc=<[grenade_loc]>]>

    rocket_launcher:
      ##minor visual problem: armor stand can't have same pitch as origin location?
      - define body_damage      <[data].get[damage]>
      - define structure_damage <[data].get[structure_damage]>

      #safety so scope is gone since it updates every tick
      - if <player.has_flag[fort.gun_scoped]>:
        - flag player fort.gun_scoped:!
        - wait 1t

      - inventory adjust slot:<player.held_item_slot> custom_model_data:22

      - define particle_origin <proc[gun_particle_origin].context[rocket_launcher]>
      - run fort_gun_handler.default_recoil_fx def:<map[particle_origin=<[particle_origin]>]>

      - playeffect effect:CLOUD at:<[particle_origin]> offset:0.3 quantity:8 visibility:300 velocity:<[particle_origin].backward[1.5].sub[<[particle_origin]>].div[3.5]>
      - playeffect effect:SMOKE_NORMAL at:<[particle_origin]> offset:0.5 quantity:25 visibility:300
      - playeffect effect:REDSTONE at:<[particle_origin]> offset:0.3 quantity:15 visibility:300 special_data:1|<color[255,157,59]>

      - define eye_loc    <player.eye_location>
      - define origin     <[eye_loc].forward[1.5]>
      #- define origin     <[origin].below[0.2]> if:<player.has_flag[fort.gun_scoped]>

      #-use item displays and display entities?
      #or rather, use item displays and interactions?

      #- spawn <entity[item_display].with[item=<item[leather_helmet].with[custom_model_data=14]>;scale=1,1,1]> <[origin]> save:e
      - spawn <entity[armor_stand].with[equipment=<map.with[helmet].as[<item[gold_nugget].with[custom_model_data=3]>]>;gravity=false;collidable=false;invulnerable=true;visible=false]> <[origin].below[1.685]> save:e
      - define rocket <entry[e].spawned_entity>
      - define rocket_loc <[rocket].location.above[1.685]>
      #default = 0.65
      - define speed 0.65
      #this lets multiple people ride one rocket
      - define total_riders <list[]>
      - flag <[rocket]> riders:<list[]>
      - while <[rocket].is_spawned> && <[rocket_loc].material.name> == air:
        - define rocket_loc <[rocket].location.above[1.685]>
        - teleport <[rocket]> <[rocket_loc].below[1.685].forward[<[speed]>]>

        - if <[loop_index]> > 5:
          - playeffect effect:SMOKE_NORMAL at:<[rocket_loc]> offset:0.25 quantity:12 visibility:300
          - playeffect effect:REDSTONE at:<[rocket_loc]> offset:0.1 quantity:4 visibility:300 special_data:1.3|<list[<color[255,157,59]>|<color[250,191,27]>].random>
          - playeffect effect:FLAME at:<[rocket_loc]> offset:0.1 quantity:1 visibility:300

          - define entities <[rocket_loc].find_entities.within[0.2].exclude[<[rocket]>].exclude[<[rocket].flag[riders]>]>
          - foreach <[entities]> as:e:
            - if <[e].location.y.add[0.2]> > <[rocket_loc].y>:
              - flag <[e]> rocket_riding:<[rocket]>
              - flag <[rocket]> riders:->:<[e]>
              - define total_riders:->:<[e]>
              - mount <[e]>|<[rocket]>
            - else:
              #if just 1 person is in front, it' ll explode, otherwise it'll continue
              - while stop
        #max it can stay in air is x sec
        - if <[loop_index].div[20]> == 15:
          - while stop

        - wait 1t

      - flag <[total_riders]> rocket_riding:!
      - if <[rocket].is_spawned>:
        - define rocket_loc <[rocket].location.above[1.685]>
        - remove <[rocket]>

      - run fort_explosive_handler.explosion_fx def:<map[grenade_loc=<[rocket_loc]>;size=4]>
      - run fort_explosive_handler.explosion_damage def:<map[radius=5;body_damage=<[body_damage]>;structure_damage=<[structure_damage]>;grenade_loc=<[rocket_loc]>]>

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
      - case burst_assault_rifle:
        - run fort_gun_handler.camera_shake def:<map[mult=0.0965]>
        - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[0.6]> offthread_repeat:3
        - repeat 4:
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.add[0.15]> offthread_repeat:3 if:<player.is_online>
          - wait 1t
      - case tactical_shotgun:
        - run fort_gun_handler.camera_shake def:<map[mult=0.083]>
        - define base   0.6
        - define smooth 0.15
        - define up     <[base]>
        - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[base]>]> offthread_repeat:3
        #smoother effect
        - repeat 3:
          - define up <[up].add[<[smooth]>]>
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[smooth]>]> offthread_repeat:3 if:<player.is_online>
          - wait 1t
        #meaning go down (original amount + smooth amount)
        #higher = slower
        - define speed          8
        - define down_increment <[up].div[<[speed]>]>
        - repeat <[speed]>:
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.add[<[down_increment]>]> offthread_repeat:3 if:<player.is_online>
          - wait 1t
      - case rocket_launcher:
        - run fort_gun_handler.camera_shake def:<map[mult=0.0965]>
        - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[1]> offthread_repeat:3 if:<player.is_online>
        - repeat 8:
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.add[0.125]> offthread_repeat:3 if:<player.is_online>
          - wait 1t

      - case grenade_launcher:
        - run fort_gun_handler.camera_shake def:<map[mult=0.08]>
        - define base   1.5
        - define smooth 0.15
        - define up     <[base]>
        - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[base]>]> offthread_repeat:3 if:<player.is_online>
        #smoother effect
        - repeat 3:
          - define up <[up].add[<[smooth]>]>
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[smooth]>]> offthread_repeat:3 if:<player.is_online>
          - wait 1t
        #meaning go down (original amount + smooth amount)
        #higher = slower
        - define speed          6
        - define down_increment <[up].div[<[speed]>]>
        - repeat <[speed]>:
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.add[<[down_increment]>]> offthread_repeat:3 if:<player.is_online>
          - wait 1t

      - case bolt_action_sniper_rifle:
        - run fort_gun_handler.camera_shake def:<map[mult=0.08]>
        - define recoil 2
        - repeat <[recoil]>:
          - define pitch_sub <[value].div[1.5]>
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[pitch_sub]>]> offthread_repeat:3 if:<player.is_online>
          - wait 1t
        - repeat <[recoil].mul[3]>:
          - define pitch_sub <element[6].sub[<[value]>].sub[4].div[4.5]>
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[pitch_sub]>]> offthread_repeat:3 if:<player.is_online>
          - wait 1t
      #they're similar enough recoils
      - case revolver pump_shotgun:
        - run fort_gun_handler.camera_shake def:<map[mult=0.08]>
        - define recoil 2
        - repeat <[recoil]>:
          - define pitch_sub <[value].div[1.5]>
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[pitch_sub]>]> offthread_repeat:3 if:<player.is_online>
          - wait 1t
        - repeat <[recoil].mul[4]>:
          - define pitch_sub <element[8].sub[<[value]>].sub[6].div[10]>
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[pitch_sub]>]> offthread_repeat:3 if:<player.is_online>
          - wait 1t
      - case tactical_smg smg:
        - run fort_gun_handler.camera_shake def:<map[mult=0.094;ticks=3]>
        - define size 0.1
        - if <player.has_flag[gun.<[gun_name]>.recoil]> && <player.flag[gun.<[gun_name]>.recoil].div[<[size]>].round_down> > 10:
          - stop
        - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[<[size]>]> offthread_repeat:3 if:<player.is_online>
        - flag player gun.<[gun_name]>.recoil:+:<[size]>
      - default:
        - run fort_gun_handler.camera_shake def:<map[mult=0.0965]>
        - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.sub[0.7]> offthread_repeat:3 if:<player.is_online>
        - repeat 4:
          - look <player> yaw:<player.location.yaw> pitch:<player.location.pitch.add[0.175]> offthread_repeat:3 if:<player.is_online>
          - wait 1t

  # - [ Ammo ] - #
  ammo_handler:

    - flag server fort.temp.<[gun_uuid]>.loaded_ammo:--
    - define loaded_ammo <server.flag[fort.temp.<[gun_uuid]>.loaded_ammo]>

    #run, not inject, since there are waits in it
    - run update_hud

    - if <[loaded_ammo]> <= 0:
      - run fort_gun_handler.reload def:<map[gun=<[gun]>]>
      - while stop

  drop_ammo:
    #make my own quantity system for ammo, so it can cap at 999 and not 350?

    - define ammo_type <[data].get[ammo_type]>
    - define qty       <[data].get[qty]>
    - define loc       <[data].get[loc]||null>
    - define loc       <player.eye_location.forward[1.5].sub[0,0.5,0]> if:<[loc].equals[null]>

    - define item <item[ammo_<[ammo_type]>]>

    - drop <[item]> <[loc]> delay:1s save:drop
    - define drop <entry[drop].dropped_entity>

    - flag <[drop]> quantity:<[qty]>

    - define icon <&chr[E0<map[light=11;medium=22;heavy=33;shells=44;rockets=55].get[<[ammo_type]>]>].font[icons]>

    - define text <[icon]><&f><&l>x<[qty]>

    - run fort_item_handler.item_text def:<map[text=<[text]>;drop=<[drop]>]>

    #- team name:ammo add:<[drop]> color:GRAY
    #- adjust <[drop]> glowing:true

  drop_gun:
    - define gun  <[data].get[gun]>
    - define drop <[data].get[drop]||null>
    - define loc  <[data].get[loc]||null>
    - define loc  <player.location> if:<[loc].equals[null]>

    - define rarity <[gun].flag[rarity]>

    - if <[drop]> == null:
      - define gun <[gun].with[custom_model_data=<[gun].flag[rarities.<[rarity]>.custom_model_data]>]> if:<[gun].flag[rarities.<[rarity]>.custom_model_data].is_truthy>
      - drop <[gun]> <[loc]> save:drop
      - define drop <entry[drop].dropped_entity>

    - define name   <[gun].display.strip_color>

    - define text <&l><[name].to_uppercase.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=ffaf24].get[<[rarity]>]>]>

    - run fort_item_handler.item_text def:<map[text=<[text]>;drop=<[drop]>;rarity=<[rarity]>]>

    #- team name:<[rarity]> add:<[drop]> color:<map[Common=GRAY;Uncommon=GREEN;Rare=AQUA;Epic=LIGHT_PURPLE;Legendary=GOLD].get[<[rarity]>]>
    #- adjust <[drop]> glowing:true

  reload:
    #TODO: divide the bullets so you can load a certain amount of bullets, then stop (it doesn't have to be fully reloaded before you can shoot again)
    ##only works for some, like tactical shotgun, maybe it's shotties only?

    - define gun         <[data].get[gun]>
    - define gun_name    <[gun].script.name.after[gun_]>
    - define gun_uuid    <[gun].flag[uuid]>
    - define rarity      <[gun].flag[rarity]>
    - define ammo_type   <[gun].flag[ammo_type]>
    - define mag_size    <[gun].flag[mag_size]>
    - define total_ammo  <player.flag[fort.ammo.<[ammo_type]>]||0>

    - define auto_reload <[data].get[auto_reload]||false>

    # disallow player to reload if negative or equal to 0 ammo
    - if <[total_ammo]> <= 0:
      # ensure the player has 0 ammo and not negative ammo
      - flag player fort.ammo.<[ammo_type]>:0
      #auto reload just makes it so the "no reload" text doesn't appear every time you hold the item
      - if !<[auto_reload]>:
        - cast FAST_DIGGING amplifier:9999 duration:1s no_icon no_ambient hide_particles
        - title "subtitle:<&c>No ammo to reload with." fade_in:0 stay:1 fade_out:15t
        - playsound <player> sound:UI_BUTTON_CLICK pitch:1.8
      - stop

    - flag player fort.reloading_gun

    #to ticks
    - define reload_time <[gun].flag[rarities.<[rarity]>.reload_time].mul[20]>
    - define text <element[Reloading...].to_list>

    - cast SLOW_DIGGING amplifier:255 duration:9999999s no_icon no_ambient hide_particles if:<[gun_name].equals[rocket_launcher].not>
    - repeat <[reload_time].div[3]>:

      # check if the player has stopped reloading during the sequence
      - if !<player.has_flag[fort.reloading_gun]>:
        - define cancelled True
        - repeat stop

      # if they hold it and it's, it'll auto reload
      - if <player.item_in_hand.flag[uuid]||null> != <[gun_uuid]>:
        - define cancelled True
        - repeat stop

      - define completed <[value].mul[12].div[<[reload_time].div[3]>].round_up>
      - define reloading_text <&c><[text].get[1].to[<[completed]>].unseparated||<empty>><&7><[text].get[<[completed].add[1]>].to[12].unseparated||<empty>>

      #- actionbar <[completed].equals[12].if_true[<&c><[text].unseparated>].if_false[<[reloading_text]>]>
      - title subtitle:<[completed].equals[12].if_true[<&c><[text].unseparated>].if_false[<[reloading_text]>]> fade_in:0
      - playsound <player.location> sound:BLOCK_NOTE_BLOCK_HAT pitch:<[value].div[<[reload_time].div[2]>].add[1]> volume:1.2

      - wait 3t

    - if !<[cancelled].exists>:

      - define current_loaded_ammo <server.flag[fort.temp.<[gun_uuid]>.loaded_ammo]>

      - if <[total_ammo]> < <[mag_size]>:
        - define new_loaded_ammo <[total_ammo]>
      - else:
        - define new_loaded_ammo <[mag_size]>
      - define new_total_ammo <[total_ammo].sub[<[mag_size].sub[<[current_loaded_ammo]>]>]>

      # ensure that new_loaded_ammo is 0 and not negative.
      - if <[new_loaded_ammo]> < 0:
        - define <[new_loaded_ammo]> 0

      # ensure that new_total_ammo is 0 and not negative.
      - if <[new_total_ammo]> < 0:
        - define <[new_total_ammo]> 0

      - flag server fort.temp.<[gun_uuid]>.loaded_ammo:<[new_loaded_ammo]>
      - flag player fort.ammo.<[ammo_type]>:<[new_total_ammo]>

      # "return" rocket into gun
      - if <[gun].script.name.after[gun_]> == rocket_launcher:
        - inventory adjust slot:<player.held_item_slot> custom_model_data:20

      - inject update_hud
      - playsound <player.location> sound:BLOCK_NOTE_BLOCK_BIT pitch:1 volume:1.2
      #- actionbar <&a>Reloaded
      - title subtitle:<&a>Reloaded fade_in:0 fade_out:0.5 stay:5t
    - else:
      - title subtitle:<&sp>

    - cast SLOW_DIGGING remove
    - flag player fort.reloading_gun:!

  shoot_fx:
    #default origin
    - define particle_origin <proc[gun_particle_origin].context[<[gun_name]>]>

    #checking for value so it doesn't repeat the same amount of pellets
    - if <[value]> == 1:
      #shotguns aren't autos, so the muzzle flash should pop up every time
      - if <[custom_recoil_fx]> || <[gun_name]> == pump_shotgun:
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
    - playeffect at:<[particle_dest]> effect:sweep_attack offset:0 quantity:1 visibility:250 velocity:1.65,1.65,1.65

    # - Blood / Material hit
    - define mat <[target_block].material.name||null>
    #checking is living so ONLY living creatures get blood splatters, which means anything else that isn't defined (like supply drops)
    #wont have effects from them
    - if <[target]> != null && <[target].is_living>:
      #splatter: red_glazed_terracotta
      - playeffect at:<[particle_dest]> effect:BLOCK_CRACK offset:0 quantity:3 visibility:150 special_data:red_wool
    - else if <[target]> != null && <[target].has_flag[fort.prop]>:
      #first check in case the target was removed by prop handler
      - define special_data <map[wood=OAK_PLANKS;brick=BRICKS;metal=IRON_BARS].get[<[target].flag[fort.prop.material]>]>
      - playeffect at:<[particle_dest]> effect:BLOCK_CRACK offset:0 quantity:3 visibility:150 special_data:<[special_data]>
    - else if <[mat]> != null && <[mat]> != barrier:
      - playeffect at:<[particle_dest]> effect:BLOCK_CRACK offset:0 quantity:8 visibility:150 special_data:<[mat]>

  default_recoil_fx:
    - define particle_origin <[data].get[particle_origin]>

    - define neg  <proc[spacing].context[-50]>
    - define text <[neg]><&chr[000<util.random.int[4].to[6]>].font[muzzle_flash]><[neg]>
    #- spawn <entity[armor_stand].with[custom_name=<[text]>;custom_name_visible=true;gravity=false;collidable=false;invulnerable=true;visible=false]> <[particle_origin].below[2.4]> save:flash
    - spawn <entity[text_display].with[text=<[text]>;pivot=CENTER;scale=1,1,1]> <[particle_origin].below[0.19].left[0.01]> save:flash
    - define flash <entry[flash].spawned_entity>

    - wait 3t
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

gun_particle_origin:
  type: procedure
  debug: false
  definitions: gun
  script:
  - define eye_loc <player.eye_location>
  - if !<player.has_flag[fort.gun_scoped]>:
    - choose <[gun]>:
      - case burst_assault_rifle:
        - determine <[eye_loc].forward.relative[-0.32,-0.15,0.3]>
      - case rocket_launcher:
        - determine <[eye_loc].forward[0.8].relative[-0.33,0.027,0.3].right[0.17]>
      - case grenade_launcher:
        - determine <[eye_loc].forward[0.65].relative[-0.33,-0.055,0.3].right[0.02]>
      - case pistol:
        - determine <[eye_loc].forward[0.6].relative[-0.33,-0.2,0.3].right[0.055]>
      - case revolver:
        - determine <[eye_loc].forward[0.5].relative[-0.33,-0.08,0.3].right[0.01]>
      - case bolt_action_sniper_rifle:
        - determine <[eye_loc].forward.relative[-0.33,0,0.3].left[0.04]>
      - case smg:
        - determine <[eye_loc].forward[0.8].relative[-0.3,-0.18,0.3]>
      - case tactical_smg:
        - determine <[eye_loc].forward[0.6].relative[-0.3,-0.2,0.3]>
      - case pump_shotgun:
        - determine <[eye_loc].forward.relative[-0.33,0.05,0.3]>
      - case tactical_shotgun:
        - determine <[eye_loc].forward[0.6].relative[-0.31,-0.09,0.3]>
      - case assault_rifle:
        - determine <[eye_loc].forward.relative[-0.33,-0.15,0.3]>
      - default:
        - determine <[eye_loc].forward.relative[-0.33,-0.2,0.3]>
  - else:
    - choose <[gun]>:
      - case burst_assault_rifle:
        - determine <[eye_loc].forward[1.8].below[0.09]>
      - case grenade_launcher:
        - determine <[eye_loc].forward[1.8].above[0.08]>
      - case pistol:
        - determine <[eye_loc].forward[1.8].below[0.1]>
      - case revolver:
        - determine <[eye_loc].forward[1.8].above[0.08]>
      - case bolt_action_sniper_rifle:
        - determine <[eye_loc].forward[1.8].above[0.2]>
      - case smg:
        - determine <[eye_loc].forward[1.8].below[0.15]>
      - case tactical_smg:
        - determine <[eye_loc].forward[1.8].below[0.2]>
      - case pump_shotgun:
        - determine <[eye_loc].forward[1.8].above[0.2]>
      - case tactical_shotgun:
        - determine <[eye_loc].forward[1.8].below[0.05]>
      - case assault_rifle:
        - determine <[eye_loc].forward[1.8].below[0.065]>
      - default:
        - determine <[eye_loc].forward[1.8].below[0.25]>

#@ [ Gun Data ] @#

# [ Do this ? ] #

#4.3 Content Update (June 5, 2018)

#Damage fall-off vs. structures removed for Rifles, SMGs, Pistols, and LMGs.

#-check how much ammo each ammo type drops from chests?
ammo_light:
  type: item
  material: leather_helmet
  display name: LIGHT
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    qty: 1
    drop_quantity: 18
    floor_weight: 4.32

ammo_medium:
  type: item
  material: leather_helmet
  display name: MEDIUM
  mechanisms:
    custom_model_data: 2
    hides: ALL
  flags:
    qty: 1
    drop_quantity: 10
    floor_weight: 4.32

ammo_heavy:
  type: item
  material: leather_helmet
  display name: HEAVY
  mechanisms:
    custom_model_data: 3
    hides: ALL
  flags:
    qty: 1
    #how much it should drop by chests
    drop_quantity: 6
    floor_weight: 2.16

ammo_shells:
  type: item
  material: leather_helmet
  display name: SHELLS
  mechanisms:
    custom_model_data: 4
    hides: ALL
  flags:
    qty: 1
    drop_quantity: 4
    floor_weight: 3.45

ammo_rockets:
  type: item
  material: leather_helmet
  display name: ROCKETS
  mechanisms:
    custom_model_data: 5
    hides: ALL
  flags:
    qty: 1
    drop_quantity: 2
    floor_weight: 0.43


gun_pump_shotgun:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[PUMP SHOTGUN].font[item_name]>
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    type: Shotgun
    #this value can be changed
    rarity: common
    icon_chr: 13
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
    #-you can't get pumps from chests apparently
    rarities:
      common:
        chance: 22
        damage: 92
        structure_damage: 45
        reload_time: 5.1
        custom_model_data: 1
      uncommon:
        chance: 34
        floor_weight: 5.5
        damage: 101
        structure_damage: 49
        reload_time: 4.8
        custom_model_data: 1
      rare:
        chance: 8
        damage: 110
        floor_weight: 1.83
        structure_damage: 50
        reload_time: 4.4
        custom_model_data: 1
      epic:
        chance: 1.36
        damage: 119
        structure_damage: 54
        reload_time: 4.0
        custom_model_data: 1
      legendary:
        chance: 0.34
        damage: 128
        structure_damage: 55
        reload_time: 3.7
        custom_model_data: 1
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

gun_tactical_shotgun:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[TACTICAL SHOTGUN].font[item_name]>
  mechanisms:
    custom_model_data: 23
    hides: ALL
  flags:
    type: Shotgun
    #this value can be changed
    rarity: common
    icon_chr: 14
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 5
    ammo_type: shells
    mag_size: 8
    #in seconds
    cooldown: 0.55
    #how many pellets in one shot
    pellets: 10
    base_bloom: 2.8
    bloom_multiplier: 1
    headshot_multiplier: 1.75
    #if there's a slightly different shoot effect alongside the base ones
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    #rarity-based states
    rarities:
      common:
        chance: 22
        floor_weight: 5.25
        damage: 77
        structure_damage: 50
        reload_time: 6.27
        custom_model_data: 23
      uncommon:
        chance: 34
        damage: 81
        floor_weight: 1.44
        structure_damage: 52
        reload_time: 5.99
        custom_model_data: 23
      rare:
        chance: 8
        floor_weight: 0.53
        damage: 85
        structure_damage: 55
        reload_time: 5.7
        custom_model_data: 23
      epic:
        chance: 1.36
        damage: 89
        structure_damage: 75
        reload_time: 5.41
        ##25
        custom_model_data: 23
      legendary:
        chance: 0.34
        damage: 94
        structure_damage: 78
        reload_time: 5.13
        ##25
        custom_model_data: 23
    #(in meters/blocks)
    #value is in percentage of damage
    #max means it wont deal any damage past that
    damage_falloff:
      8: 100
      10: 90
      15: 70
      30: 0

    sounds:
      ENTITY_FIREWORK_ROCKET_BLAST:
        pitch: 1.8
        volume: 1.2
      ENTITY_DRAGON_FIREBALL_EXPLODE:
        pitch: 2
        volume: 1.2
      BLOCK_SAND_BREAK:
        pitch: 0.5
        volume: 1.4

gun_assault_rifle:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[ASSAULT RIFLE].font[item_name]>
  mechanisms:
    custom_model_data: 3
    hides: ALL
  flags:
    type: Rifle
    #this value can be changed
    rarity: common
    icon_chr: 1
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 5
    ammo_type: medium
    mag_size: 30
    #in seconds
    cooldown: 0.1
    pellets: 1
    base_bloom: 1.2
    bloom_multiplier: 1
    headshot_multiplier: 1.5
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    rarities:
      common:
        chance: 43
        floor_weight: 3.24
        damage: 30
        reload_time: 2.7
        custom_model_data: 3
      uncommon:
        chance: 39
        floor_weight: 1.62
        damage: 31
        reload_time: 2.6
        custom_model_data: 3
      rare:
        chance: 39
        floor_weight: 0.65
        damage: 33
        reload_time: 2.5
        custom_model_data: 3
      epic:
        chance: 2
        floor_weight: 0.24
        damage: 35
        reload_time: 2.4
        icon_chr: 2
        custom_model_data: 5
      legendary:
        chance: 0.5
        floor_weight: 0.06
        damage: 36
        reload_time: 2.2
        icon_chr: 2
        custom_model_data: 5
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

gun_burst_assault_rifle:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[BURST ASSAULT RIFLE].font[item_name]>
  mechanisms:
    custom_model_data: 25
    hides: ALL
  flags:
    type: Rifle
    #this value can be changed
    rarity: common
    icon_chr: 3
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 2
    ammo_type: medium
    mag_size: 30
    #in seconds
    #cooldown: 0
    #sorta as a way to offset the timing, specifically for the burst
    shots_between_wait: 3
    pellets: 1
    base_bloom: 1.3
    bloom_multiplier: 1
    headshot_multiplier: 1.5
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    rarities:
      common:
        chance: 43
        floor_weight: 3.07
        damage: 27
        reload_time: 2.9
        custom_model_data: 25
      uncommon:
        chance: 39
        floor_weight: 1.23
        damage: 29
        reload_time: 2.7
        custom_model_data: 25
      rare:
        chance: 39
        floor_weight: 0.46
        damage: 30
        reload_time: 2.6
        custom_model_data: 25
      epic:
        chance: 2
        floor_weight: 0.185
        damage: 32
        reload_time: 2.5
        icon_chr: 4
        custom_model_data: 27
      legendary:
        chance: 0.5
        floor_weight: 0.06
        damage: 33
        reload_time: 2.3
        icon_chr: 4
        custom_model_data: 27
    #(in meters)
    #value is in percentage of damage
    damage_falloff:
      50: 100
      75: 80
      95: 66

    sounds:
      ENTITY_FIREWORK_ROCKET_BLAST_FAR:
        pitch: 1.3
        volume: 1.2

gun_tactical_smg:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[TACTICAL SMG].font[item_name]>
  mechanisms:
    custom_model_data: 7
    hides: ALL
  flags:
    type: SMG
    #this value can be changed
    rarity: uncommon
    icon_chr: 12
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
        chance: 22
        floor_weight: 3.8
        damage: 18
        reload_time: 2.2
        custom_model_data: 7
      rare:
        chance: 34
        floor_weight: 1.5
        damage: 19
        reload_time: 2.1
        custom_model_data: 7
      epic:
        chance: 1.36
        floor_weight: 0.35
        damage: 20
        reload_time: 2.0
        custom_model_data: 7
      legendary:
        chance: 0.34
        damage: 21
        reload_time: 1.9
        custom_model_data: 7
    #(in meters)
    #value is in percentage of damage
    #no damage falloff was found, so im using same as AR
    damage_falloff:
      50: 100
      75: 80
      95: 66

    sounds:
      ENTITY_FIREWORK_ROCKET_BLAST:
        pitch: 1.2
        volume: 0.3
      UI_BUTTON_CLICK:
        pitch: 2
        volume: 1.2

gun_smg:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[SMG].font[item_name]>
  mechanisms:
    custom_model_data: 9
    hides: ALL
  flags:
    type: SMG
    #this value can be changed
    rarity: common
    icon_chr: 11
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 2
    ammo_type: light
    mag_size: 30
    #in seconds
    #cooldown: 0
    pellets: 1
    base_bloom: 1.15
    bloom_multiplier: 1.5
    headshot_multiplier: 1.75
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    rarities:
      common:
        chance: 14
        floor_weight: 3.455
        damage: 16
        reload_time: 2.31
        custom_model_data: 9
      uncommon:
        chance: 39.7
        floor_weight: 1.15
        damage: 17
        reload_time: 2.2
        custom_model_data: 9
      rare:
        chance: 9.33
        floor_weight: 0.39
        damage: 18
        reload_time: 2.1
        custom_model_data: 9
      epic:
        chance: 1.59
        floor_weight: 0.2279
        damage: 19
        reload_time: 2.0
        custom_model_data: 9
      legendary:
        chance: 0.4
        floor_weight: 0.0848
        damage: 20
        reload_time: 1.89
        custom_model_data: 9
    #(in meters)
    #value is in percentage of damage
    #no damage falloff was found, so im using same as AR
    damage_falloff:
      20: 100
      40: 45

    sounds:
      ENTITY_FIREWORK_ROCKET_BLAST_FAR:
        pitch: 1.2
        volume: 1.2
      UI_BUTTON_CLICK:
        pitch: 1.9
        volume: 0.4

gun_bolt_action_sniper_rifle:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[BOLT-ACTION SNIPER RIFLE].font[item_name]>
  mechanisms:
    custom_model_data: 11
    hides: ALL
  flags:
    type: Sniper
    #this value can be changed
    rarity: common
    sniper: true
    icon_chr: 8
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 5
    ammo_type: heavy
    mag_size: 1
    #in seconds
    cooldown: 1
    #how many pellets in one shot
    pellets: 1
    base_bloom: 2.5
    bloom_multiplier: 1.2
    headshot_multiplier: 2.5
    #if there's a slightly different shoot effect alongside the base ones
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    #rarity-based states
    rarities:
      #idk about common uncommon?
      common:
        chance: 10
        damage: 99
        reload_time: 3.3
        custom_model_data: 11
      uncommon:
        chance: 51.72
        damage: 105
        reload_time: 3.15
        custom_model_data: 11
      rare:
        chance: 25.86
        floor_weight: 0.35
        damage: 110
        reload_time: 3
        custom_model_data: 11
      epic:
        chance: 2.76
        floor_weight: 0.1
        damage: 116
        reload_time: 2.5
        custom_model_data: 11
      legendary:
        chance: 0.69
        floor_weight: 0.03
        damage: 121
        reload_time: 2.35
        custom_model_data: 11
    #-no damage falloff
    sounds:
      ENTITY_FIREWORK_ROCKET_BLAST:
        pitch: 2
        volume: 4
      ENTITY_FIREWORK_ROCKET_LARGE_BLAST_FAR:
        pitch: 1.9
        volume: 2

gun_revolver:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[REVOLVER].font[item_name]>
  mechanisms:
    custom_model_data: 12
    hides: ALL
  flags:
    type: Pistol
    #this value can be changed
    rarity: common
    icon_chr: 6
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 5
    ammo_type: medium
    mag_size: 6
    #in seconds
    cooldown: 0.75
    pellets: 1
    base_bloom: 1.3
    bloom_multiplier: 1
    headshot_multiplier: 1.5
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    rarities:
      common:
        chance: 11
        floor_weight: 4
        damage: 54
        reload_time: 2.2
        custom_model_data: 12
      uncommon:
        chance: 61.3
        floor_weight: 0.9
        damage: 57
        reload_time: 2.1
        custom_model_data: 12
      rare:
        chance: 24.5
        floor_weight: 0.3
        damage: 60
        reload_time: 2
        custom_model_data: 12
      epic:
        chance: 24.5
        damage: 94.5
        reload_time: 1.9
        icon_chr: 7
        custom_model_data: 14
      legendary:
        chance: 4.4
        damage: 99
        reload_time: 1.8
        icon_chr: 7
        custom_model_data: 14
    #-no damage falloff (?)

    sounds:
      ENTITY_FIREWORK_ROCKET_LARGE_BLAST:
        pitch: 1.47
        volume: 4
      ENTITY_FIREWORK_ROCKET_LARGE_BLAST_FAR:
        pitch: 1.4
        volume: 4

gun_pistol:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[PISTOL].font[item_name]>
  mechanisms:
    custom_model_data: 16
    hides: ALL
  flags:
    type: Pistol
    #this value can be changed
    rarity: common
    icon_chr: 5
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 5
    ammo_type: light
    mag_size: 16
    #in seconds
    cooldown: 0.1
    pellets: 1
    base_bloom: 1.35
    bloom_multiplier: 1.8
    headshot_multiplier: 2
    first_shot_accuracy: true
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    rarities:
      common:
        chance: 11
        floor_weight: 4
        damage: 24
        reload_time: 1.54
        custom_model_data: 16
      uncommon:
        chance: 61.3
        floor_weight: 1.2
        damage: 25
        reload_time: 1.47
        custom_model_data: 16
      rare:
        chance: 24.5
        damage: 26
        reload_time: 1.4
        custom_model_data: 16
      epic:
        chance: 9.8
        damage: 28
        reload_time: 1.33
        custom_model_data: 16
      legendary:
        chance: 4.4
        damage: 29
        reload_time: 1.26
        custom_model_data: 16
    #-no damage falloff (?)

    sounds:
      ENTITY_FIREWORK_ROCKET_BLAST_FAR:
        pitch: 1.7
        volume: 1.2

#using chances from a different chart, but it doesn't matter since it's all within the same subcategory (rpgs),
#meaning their drop rates are still balances somewhat

gun_grenade_launcher:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[GRENADE LAUNCHER].font[item_name]>
  mechanisms:
    custom_model_data: 18
    hides: ALL
  flags:
    type: RPG
    #this value can be changed
    rarity: rare
    #meaning it's not a conventional gun
    custom_shoot: true
    icon_chr: 9
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 5
    ammo_type: rockets
    mag_size: 6
    #in seconds
    cooldown: 0.8
    pellets: 1
    #no bloom really
    base_bloom: 1
    bloom_multiplier: 1
    #cannot headshot
    headshot_multiplier: 1
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    rarities:
      rare:
        chance: 1.84
        damage: 70
        structure_damage: 200
        reload_time: 1.4
        custom_model_data: 18
      epic:
        chance: 0.25
        damage: 74
        structure_damage: 210
        reload_time: 1.33
        custom_model_data: 18
      legendary:
        chance: 0.0608
        damage: 77
        structure_damage: 220
        reload_time: 1.26
        custom_model_data: 18
    #-no damage falloff

    sounds:
      ENTITY_FIREWORK_ROCKET_BLAST:
        pitch: 0
        volume: 1.2
      ENTITY_SHULKER_SHOOT:
        pitch: 0.65
        volume: 1.2

gun_rocket_launcher:
  type: item
  material: leather_horse_armor
  display name: <&chr[1].font[item_name]><&f><&l><element[ROCKET LAUNCHER].font[item_name]>
  mechanisms:
    custom_model_data: 20
    hides: ALL
  flags:
    type: RPG
    #this value can be changed
    rarity: rare
    #meaning it's not a conventional gun
    custom_shoot: true
    icon_chr: 10
    #global stats
    #min is 5 if you want singular shots
    ticks_between_shots: 5
    ammo_type: rockets
    mag_size: 1
    #in seconds
    cooldown: 1
    pellets: 1
    #no bloom really
    base_bloom: 1
    bloom_multiplier: 1
    #cannot headshot
    headshot_multiplier: 1
    custom_recoil_fx: false
    uuid: <util.random_uuid>
    rarities:
      rare:
        chance: 2
        damage: 100
        structure_damage: 300
        reload_time: 3.60
        custom_model_data: 20
      epic:
        chance: 0.752
        damage: 115
        structure_damage: 315
        reload_time: 3.06
        custom_model_data: 20
      legendary:
        chance: 0.1056
        damage: 130
        structure_damage: 330
        reload_time: 2.52
        custom_model_data: 20
    #-no damage falloff

    sounds:
      ENTITY_FIREWORK_ROCKET_BLAST:
        pitch: 0
        volume: 1.2
      ENTITY_BLAZE_SHOOT:
        pitch: 1
        volume: 1.2
      ENTITY_FIREWORK_ROCKET_LAUNCH:
        pitch: 0.6
        volume: 1.2