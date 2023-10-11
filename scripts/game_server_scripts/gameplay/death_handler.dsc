fort_death_handler:
  type: world
  debug: false
  definitions: data
  events:
    #check if players *don't* have fort.spectating, in case they *somehow* die while spectating?
    #not going to, because it's pretty much impossible. I'll do it if i see it happen once

    #so they can't use the teleport feature vanilla mc has
    on player teleports cause:SPECTATE flagged:fort.spectating:
    - determine passively cancelled

    on player stops spectating flagged:fort.spectating:
    - determine passively cancelled

    on player damaged by VOID flagged:fort:
    - determine passively cancelled
    - run fort_death_handler.death

    on player death:
    - define cause  <context.cause||null>
    - define killer <context.damager||null>

    - determine passively cancelled
    #dont use the vanilla drop mechanic
    - determine passively <list[]>

    - run fort_death_handler.death

    #-Update kill count + players left
    - if <[killer]> != null:
      #track *who* they kill?
      # flag <[killer]> fort.killed_players:->:<player>
      - flag <[killer]> fort.kills:++
      - define players    <server.online_players_flagged[fort]>
      #update alive players
      - define alive_icon <&chr[0002].font[icons]>
      - sidebar set_line scores:3 values:<element[<[alive_icon]> <server.online_players_flagged[!fort.spectating].size>].font[hud_text].color[<color[51,0,0]>]> players:<[players]>

      - run update_hud player:<[killer]> if:<[killer].is_player>

  death:
    #using queued player

    - define killer <[data].get[killer]||null>

    #don't drop items on pregame island
    - run fort_item_handler.drop_everything if:<player.world.name.equals[nimnite_map]>
    - run fort_death_handler.fx.anim

    - if <player.is_online>:
      #if they die without a killer, just spectate a random player that's alive
      - if <[killer]> == null:
        - define killer <server.online_players_flagged[fort].filter[has_flag[fort.spectating].not].first||null>
      #in case the player who won somehow dies (which wont happen (hopefully))
      #disable damage after the dub has been taken
      - if <[killer]> == null:
        - stop
      - flag player fort.spectating:<[killer]>
      - adjust <player> spectator_target:<[killer]>

  fx:
  #-create the "on your knees" animation or no? because the player fades away anyways
    anim:
      - define loc <player.location>
      - run dmodels_spawn_model def.model_name:emotes def.location:<[loc].above[2.1]> def.yaw:<[loc].yaw.add[180]> save:result
      - define spawned <entry[result].created_queue.determination.first||null>
      - run dmodels_set_scale def.root_entity:<[spawned]> def.scale:1.87,1.87,1.87
      - run dmodels_animate def.root_entity:<[spawned]> def.animation:death

      - define loc <[loc].with_pose[0,0]>
      - run fort_death_handler.fx.ray def:<map[loc=<[loc]>]>

      - playsound <[loc]> sound:BLOCK_BEACON_DEACTIVATE pitch:1.75
      - playsound <[loc]> sound:ENTITY_ALLAY_DEATH pitch:1.25

      - run fort_death_handler.fx.squares def:<map[loc=<[loc]>]>
      - wait 6t
      - run fort_death_handler.fx.circles def:<map[loc=<[loc]>]>

    ray:
      - define loc <[data].get[loc].above[2.535]>
      - define text <&chr[21].font[icons]>


      - spawn <entity[text_display].with[text=<[text]>;pivot=VERTICAL;translation=-0.06,0,0;scale=0,12,0;background_color=transparent]> <[loc]> save:ray
      - define ray <entry[ray].spawned_entity>

      #the background_color=transparent thing shows on the screen sometimes for a split second, so wait 1t (at scale = 0) to let it load
      - wait 2t

      - adjust <[ray]> interpolation_start:0
      - adjust <[ray]> scale:7,12,7
      - adjust <[ray]> interpolation_duration:2t

      - wait 2t

      - repeat 15:
        - adjust <[ray]> interpolation_start:0
        - define size <util.random.decimal[4].to[7.5]>
        - adjust <[ray]> scale:<[size]>,12,<[size]>
        - adjust <[ray]> interpolation_duration:2t
        - wait 2t

      - adjust <[ray]> interpolation_start:0
      - adjust <[ray]> scale:<[size].sub[2]>,0,<[size].sub[2]>
      - adjust <[ray]> interpolation_duration:3t

      - wait 3t

      - remove <[ray]> if:<[ray].is_spawned>

    squares:
      - define loc <[data].get[loc].above[0.3]>
      - define drone_Loc <[loc].above[2.3]>
        #shadowed or no?

      #the effect also looks really cool in first person (when doing it in the player's position)
      - repeat 30:

        #-"drone" (temp, wait for model?)
        - playeffect effect:REDSTONE at:<[drone_loc]> offset:0 visibility:50 special_data:1.1|<color[#828282]>

        - define size <util.random.decimal[0.8].to[1.62]>
        - define dest <[loc].above[<util.random.decimal[1.8].to[2.6]>].random_offset[0.15,0,0.15]>

        - define origin <[loc].random_offset[0.5,0,0.5]>

        - define start_translation <[origin].sub[<[loc]>]>
        - define end_translation   <[dest].sub[<[loc]>]>

        - spawn <entity[text_display].with[text=<element[⬛].color[#<list[D8F0FF|AAF4FF].random>]>;pivot=VERTICAL;scale=<[size]>,<[size]>,<[size]>;translation=<[start_translation]>;background_color=transparent]> <[loc]> save:fx
        - define fx <entry[fx].spawned_entity>
        - wait 1t

        - adjust <[fx]> interpolation_start:0
        - adjust <[fx]> translation:<[end_translation]>
        - adjust <[fx]> scale:0,0,0
        - adjust <[fx]> interpolation_duration:15t
        - run fort_death_handler.fx.remove_square def:<map[square=<[fx]>]>

    remove_square:
      - define square <[data].get[square]>
      - define wait <[data].get[wait]||17>
      - wait <[wait]>t
      - remove <[square]> if:<[square].is_spawned>

    circles:
      - define loc <[data].get[loc]>
      - define start_loc   <[loc].above[1.9]>
      - define translation <[loc].above[2.25].sub[<[start_loc]>]>

      - repeat 3:

        - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=21]>;scale=3.25,3.25,3.25] <[start_loc]> save:circle_<[value]>
        - define circle_<[value]> <entry[circle_<[value]>].spawned_entity>
        - define circles:->:<[circle_<[value]>]>

        - wait 3t

        - adjust <[circle_<[value]>]> interpolation_start:0
        - adjust <[circle_<[value]>]> translation:<[translation]>
        - adjust <[circle_<[value]>]> scale:0,0,0
        - adjust <[circle_<[value]>]> interpolation_duration:17t

      - wait 2s
      - remove <[circles].filter[is_spawned]>