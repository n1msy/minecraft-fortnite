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

    after player spectates player flagged:fort.spectating:
    #we don't really need the second check in reality, but ill keep it for debugging/future needs
    #no need to remove spectate flag either, since when they quit flag is removed
    - wait 4s
    - while <player.is_online> && <player.has_flag[fort.spectating]>:
      - if !<player.has_flag[fort.leave_match_delay]>:
        - actionbar <&chr[1].font[elim_text]><element[<&l><&lb><&e><&l>SNEAK<&f><&l><&rb> <&c><&l>LEAVE MATCH].font[elim_text]>
      - wait 2s

    on player stops spectating flagged:fort.spectating:
    - determine passively cancelled
    - define player_spectating <player.flag[fort.spectating]>
    #(second check in case the other player died and is spectating someone else now)
    #this event fires multiple times for some reason, so third check is to make sure this event already fired
    #and don't do it again
    - if !<[player_spectating].is_online> || <[player_spectating].has_flag[fort.spectating]>:
      - stop
    #leave match delay so players dont instantly accidentally leave the game
    - if <player.has_flag[fort.left_match]> || <player.has_flag[fort.leave_match_delay]>:
      - stop
    - narrate "<element[<&l><player.name>].color[<color[#ffb62e]>]> <&7>has stopped spectating you" targets:<[player_spectating]>
    - adjust <player> send_to:fort_lobby
    - flag player fort.left_match

    #don't run it, instead kill them with VOID cause, so the death message is correct
    #- run fort_death_handler.death

    on player death:
    - define cause  <context.cause||null>
    - define killer <context.damager||<player.flag[fort.last_damager]||null>>

    - determine passively cancelled
    #-don't die if the phase is END
    - if <server.flag[fort.temp.phase]||null> == END:
      - stop

    #-killfeed
    #don't really need to inject, but it's much cleaner
    #updating kill feed before death effect, for gun distance to be calculated
    - inject fort_death_handler.killfeed

    - run fort_death_handler.death def:<map[killer=<[killer]>;loc=<player.location>]>

    ##does kill count update in hud?
    #-Update kill count
    - if <[killer]> != null:
      #track *who* they kill?
      # flag <[killer]> fort.killed_players:->:<player>
      - flag <[killer]> fort.kills:++
      - flag server fort.temp.kills.<[killer].uuid>:++
      #ENTITY_PLAYER_ATTACK_STRONG -> would use this, but it's not loud enough
      - playsound <[killer]> sound:ENTITY_PLAYER_ATTACK_CRIT pitch:0.9 volume:1
      - actionbar "<&chr[1].font[elim_text]><element[<&l>ELIMINATED].font[elim_text]> <element[<&c><&l><player.name>].font[elim_text]>" targets:<[killer]>

  death:
    #using queued player

    - define killer   <[data].get[killer]||null>
    - define quit     <[data].get[quit]||false>
    - define dead_loc <[data].get[loc]>

    #dont play the death animation if players leave on the bus
    - if !<player.has_flag[fort.on_bus]>:
      #don't drop items on pregame island
      - run fort_item_handler.drop_everything if:<player.world.name.equals[nimnite_map]>
      - run fort_death_handler.fx.anim def:<map[loc=<[dead_loc]>]>

    #just in case they weren't removed from the storm properly
    - run fort_storm_handler.exit_storm
    #in case they were in the storm
    - flag player fort.in_storm:!

    #- remove minimap for spectators
    #check just in case their minimap was somehow disabled already
    - run minimap if:<player.has_flag[fort.minimap]>

    - define killer_name <[killer].name.if_null[<player.name>]>
    - title title:<&e><&l><[killer_name].font[elim_player]><&r> subtitle:<&chr[1].font[elim_text]><&l><element[ELIMINATED BY].font[elim_text]>

    #this check means dont look for any spectators if players die and they're still on the pregame island
    - if <server.has_flag[fort.temp.available]>:
      - stop

    #killfeed (if they quit and didn't actually die)
    - if <[quit]>:
      - define msg_template <script[nimnite_config].data_key[killfeed.quit].random.parse_minimessage>
      - define death_message <[msg_template].replace_text[_player_].with[<player.name>]>
      - announce <[death_message].parsed>
    - else:
      #-make sure this message doesn't stay after the next match?
      #this is before adding the fort.spectating flag, so no need to remove the dead player from the list
      - define placement <server.online_players_flagged[fort].filter[has_flag[fort.spectating].not].size>
      - define placement_text "<&l>YOU PLACED <&r>#<&e><&l><[placement]>"
      #- bossbar update fort_info title:<[placement_text]> color:YELLOW players:<player>
      - title subtitle:<[placement_text]> fade_in:0t stay:15s fade_out:10t

    #-Update alive players (players left)
    #excluding killer, since their hud updates already in .death
    - define players       <server.online_players_flagged[fort].exclude[<[killer]>]>
    - define players_alive <server.online_players_flagged[!fort.spectating]>
    - define alive_icon <&chr[0002].font[icons]>

    - sidebar set_line scores:4 values:<element[<[alive_icon]> <[players_alive].size>].font[hud_text].color[<color[51,0,0]>]> players:<[players]>

    # - [ Victory Check ] - #
    #if is in case they player leaves after theyve won
    - run fort_core_handler.victory_check def:<map[dead_player=<player>]> if:<server.flag[fort.temp.phase].equals[END].not>

    # - [ Spectating System ] - #
    #if they die without a killer, just spectate a random player that's alive
    - if <[killer]> != null && <[killer]> != <player>:
      - define player_to_spectate <[killer]>
    - else:
      - define player_to_spectate <server.online_players_flagged[fort].filter[has_flag[fort.spectating].not].exclude[<player>].first||null>

    #add a spectators flag to the player being spectated too, or no?

    #in case the player who won somehow dies (which can happen if they leave before game ends fr)
    #disable damage after the dub has been taken
    - if <[player_to_spectate]> == null:
      #if the team who won leaves, just send everyone else back too
      - if <server.flag[fort.temp.phase]> == end:
        - inject fort_core_handler.reset_server
      - stop

    #move the player's current spectators to whoever they are spectating too
    - define spectators <server.online_players_flagged[fort.spectating].filter[flag[fort.spectating].equals[<player>]].exclude[<player>]>
    - define spectators <[spectators].include[<player>]> if:<player.is_online>

    #spectating sometimes doesn't work
    - foreach <[spectators]> as:spectator:
      #flagging this NOT in separate task, so the hud can update correctly
      - flag <[spectator]> fort.spectating:<[player_to_spectate]>
      #add a delay so they dont instantly accidentally leave / trigger the event
      - flag <[spectator]> fort.leave_match_delay duration:5s

      #-running this in separate queue as delayed function, since spectator_target mech is a little wonky and id like to add a delay
      - run fort_death_handler.spectate_target def:<map[spectator=<[spectator]>;target=<[player_to_spectate]>]>

    #update their hud so its correctly updated for spectating players too
    - run update_hud player:<[player_to_spectate]>

  spectate_target:
    - define spectator <[data].get[spectator]>
    - define target    <[data].get[target]>

    #turning them spectator so theyd be invis on teleport to player
    - adjust <[spectator]> gamemode:spectator
    #if they're too far away, they wont spectate properly
    - teleport <[spectator]> <[target].location>
    #delay a little
    - wait 2t
    #since it's delayed, JUST IN CASE the player_to_spectate dies within those 2t
    #might have to check if the target is online and living too in case they leave after theyve won and there's no one else to spectate?
    #first check in case theres 2 players left and there's no one left to spectate?
    - if <[spectator].flag[fort.spectating]||null> != <[target]> || <[target].has_flag[fort.spectating]> || !<[target].is_online>:
      - stop
    - adjust <[spectator]> spectator_target:<[target]>
    - narrate "<&7>You are now spectating <element[<&l><[target].name>].color[<color[#ffb62e]>]>" targets:<[spectator]>
    - narrate "<element[<&l><[spectator].name>].color[<color[#ffb62e]>]> <&7>is now spectating you" targets:<[target]>

  ## - [ Killfeed ] - ##
  killfeed:
  #injected "on player death", just for the sake of cleanliness
    - define name <player.name>
    - define killer_name <[killer].name||null>

    - if <[killer]> == <player>:
    #-self death
      - define msg_template <script[nimnite_config].data_key[killfeed.self_death].random.parse_minimessage>
    - else:
      #-kill type is either SELF (if there's no killer) or ENEMY (if there is a killer)
      - define kill_type <[killer].equals[null].if_true[self].if_false[enemy]>
      - choose <[cause]>:
        - case BLOCK_EXPLOSION ENTITY_EXPLOSION:
          - define msg_template <script[nimnite_config].data_key[killfeed.<[kill_type]>_explosion].random.parse_minimessage>

        - case FALL:
          - define msg_template <script[nimnite_config].data_key[killfeed.<[kill_type]>_fall].random.parse_minimessage>

        #from storm
        - case WORLD_BORDER:
          - define msg_template <script[nimnite_config].data_key[killfeed.<[kill_type]>_storm].random.parse_minimessage>

        - case VOID:
          - define msg_template <script[nimnite_config].data_key[killfeed.<[kill_type]>_void].random.parse_minimessage>

        - case ENTITY_ATTACK:
          #if it's entity attack, then it means killer *has* to exist
          - define weapon <[killer].item_in_hand>
          #fallback is in case they used an item with no script attached (ie air)
          - if <[weapon].script.name.starts_with[gun_]||false>:
            - define gun_type <[weapon].flag[type]>
            - define distance <[killer].location.distance[<player.location>].round>
            - choose <[gun_type]>:
              - case shotgun:
                - define msg_template <script[nimnite_config].data_key[killfeed.shotgun].random.parse_minimessage>
              - case sniper:
                - if !<[killer].has_flag[fort.gun_scoped]>:
                  - define msg_template "<script[nimnite_config].data_key[killfeed.sniper_noscope].random.parse_minimessage> <&7>(<&f><[distance]> m<&7>)"
                - else:
                  - define msg_template "<script[nimnite_config].data_key[killfeed.sniper].random.parse_minimessage> <&7>(<&f><[distance]> m<&7>)"
              - default:
                - define msg_template "<script[nimnite_config].data_key[killfeed.gun_default].random.parse_minimessage> <&7>with a <[gun_type]>"
                - if <[distance]> > 50:
                  - define msg_template "<[msg_template]> <&7>(<&f><[distance]> m<&7>)"
          - else:
            #default is pickaxe msg
            - define msg_template <script[nimnite_config].data_key[killfeed.pickaxe].random.parse_minimessage>

    - if <[msg_template].exists>:
      - define death_message <[msg_template].replace_text[_killer_].with[<[killer_name]>].replace_text[_player_].with[<[name]>]>
    - else:
    #-in case the cause was none of these, let players know to report it (unknown)
      - define death_message "<&c><&l><[name]> <&7>died for some reason... <element[<&f><&l><&lb><&e><&l>HOVER<&f><&l><&rb>].on_hover[<&f>Hey, if you see this message, this is an <&c>error<&f>.<n><&f>Please let Nimsy know. <&7>CAUSE: <&a><[cause]>]>"

    - announce <[death_message].parsed>

  fx:
    anim:
      - define loc <[data].get[loc].if_null[<player.location>]>
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