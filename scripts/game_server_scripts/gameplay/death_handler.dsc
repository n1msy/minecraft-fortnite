#TODO: when player leaves spectate, send em to menu

#-show death in third person?
#eh might be too buggy

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
    #when they leave for example
    - define player_spectating <player.flag[fort.spectating]>
    - if !<[player_spectating].is_online> || <[player_spectating].has_flag[fort.spectating]>:
      - stop
    - narrate "<element[<&l><player.name>].color[<color[#ffb62e]>]> <&7>has stopped spectating you" targets:<[player_spectating]>

    on player damaged by VOID flagged:fort:
    - determine passively cancelled
    - run fort_death_handler.death

    on player death:
    - define cause  <context.cause||null>
    - define killer <context.damager||<player.flag[fort.last_damager]||null>>
    - determine passively cancelled
    #dont use the vanilla drop mechanic
    - determine passively <list[]>

    - run fort_death_handler.death def:<map[killer=<[killer]>]>

    #-Update kill count
    - if <[killer]> != null:
      #track *who* they kill?
      # flag <[killer]> fort.killed_players:->:<player>
      - flag <[killer]> fort.kills:++
      #ENTITY_PLAYER_ATTACK_STRONG -> would use this, but it's not loud enough
      - playsound <[killer]> sound:ENTITY_PLAYER_ATTACK_CRIT pitch:0.9 volume:1
      - actionbar "<&chr[1].font[elim_text]><element[<&l>ELIMINATED].font[elim_text]> <element[<&c><&l><player.name>].font[elim_text]>" targets:<[killer]>

    # - [ Killfeed ] - #

    #-Update alive players (players left)
    - define players    <server.online_players_flagged[fort]>
    - define alive_icon <&chr[0002].font[icons]>
    - sidebar set_line scores:3 values:<element[<[alive_icon]> <server.online_players_flagged[!fort.spectating].size>].font[hud_text].color[<color[51,0,0]>]> players:<[players]>

  death:
    #using queued player

    - define killer <[data].get[killer]||null>

    #don't drop items on pregame island
    - run fort_item_handler.drop_everything if:<player.world.name.equals[nimnite_map]>
    - run fort_death_handler.fx.anim


    - define killer_name <[killer].name.if_null[<player.name>]>
    - title title:<&e><&l><[killer_name].font[elim_player]><&r> subtitle:<&chr[1].font[elim_text]><&l><element[ELIMINATED BY].font[elim_text]>

    #this is before adding the fort.spectating flag, so no need to remove the dead player from the list
    - define placement <server.online_players_flagged[fort].filter[has_flag[fort.spectating].not].size>
    - actionbar <&chr[1].font[elim_text]><element[<&l>YOU PLACED <&r>#<&e><&l><[placement]>].font[elim_text]>

    # - [ Spectating System ] - #
    #if they die without a killer, just spectate a random player that's alive
    - if <[killer]> != null:
      - define player_to_spectate <[killer]>
    - else:
      - define player_to_spectate <server.online_players_flagged[fort].filter[has_flag[fort.spectating].not].first||null>

    #add a spectators flag to the player being spectated too, or no?

    #in case the player who won somehow dies (which can happen if they leave before game ends fr)
    #disable damage after the dub has been taken
    - if <[player_to_spectate]> == null:
      - stop

    #move the player's current spectators to whoever they are spectating too
    - define spectators <server.online_players_flagged[fort.spectating].filter[flag[fort.spectating].equals[<player>]]>
    - define spectators <[spectators].include[<player>]> if:<player.is_online>

    - foreach <[spectators]> as:spectator:
      - flag <[spectator]> fort.spectating:<[player_to_spectate]>
      - adjust <[spectator]> spectator_target:<[player_to_spectate]>
      - narrate "<&7>You are now spectating <element[<&l><[player_to_spectate].name>].color[<color[#ffb62e]>]>" targets:<[spectator]>
      - narrate "<element[<&l><[spectator].name>].color[<color[#ffb62e]>]> <&7>is now spectating you" targets:<[player_to_spectate]>

    #update their hud so its correctly updated for spectating players too
    - run update_hud player:<[player_to_spectate]>

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