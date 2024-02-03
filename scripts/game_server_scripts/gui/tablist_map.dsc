#The full map display when you open the tablist.

tablist_map_handler:
  type: world
  debug: false
  events:
    on delta time secondly:
      #all the map tiles (assorted via shader)
      - define map <server.flag[fort.map_tiles]>

      - define top_left_x -1073
      - define top_left_z -1073

      - define next_storm_diameter <server.flag[fort.temp.storm.new_diameter]||2304>
      - define next_storm_center <server.flag[fort.temp.storm.new_center]||null>

      # - [ White circle ] - #
      #display the next circle (calculate where it would be and compress it for the shader to show)
      - if <[next_storm_center]> != null:

          #storm diameter has to be 1600 or below for next_storm_center to return != null
          - define storm_id <map[1600=1;800=2;400=3;200=4;100=5;50=6;35=7;20=8;1=9].get[<[next_storm_diameter]>]>

          - define circle_x <[next_storm_center].x>
          - define circle_y <[next_storm_center].z>
          - define actualX <[circle_x].sub[<[top_left_x]>].div[2].round_down>
          - define actualY <[circle_y].sub[<[top_left_z]>].div[2].round_down>
          - define r_ <[actualX].mod[256]>
          - define g_ <[actualY].mod[256]>
          - define b_ <[storm_id].mul[16].add[<[actualY].div[256].round_down.mul[4]>].add[<[actualX].div[256].round_down>]>
          - define full_circle_color   <color[<[r_]>,<[g_]>,<[b_]>]>
          - define white_circle        <&chr[E002].font[map].color[<[full_circle_color]>]>

      ## - [ Storm Outline ] - ##
      - define storm_center   <server.flag[fort.temp.storm.center]||null>
      #second check is to make sure to actually display the storm id
      - if <[storm_center]> != null && <[storm_id].exists>:
          - define storm_center   <server.flag[fort.temp.storm.center]>
          - define storm_diameter <server.flag[fort.temp.storm.diameter]>
          - define circle_x <[storm_center].x>
          - define circle_y <[storm_center].z>
          - define storm_radius <[storm_diameter].div[2]>
          # storm_radius is in blocks
          - define sr <[storm_radius].mul[2].round_down>
          - define actualX <[circle_x].sub[<[top_left_x]>].div[2].round_down>
          - define actualY <[circle_y].sub[<[top_left_z]>].div[2].round_down>
          - define r_ <[actualX].mod[256]>
          - define g_ <[actualY].mod[256]>
          - define b_ <[sr].mod[16].mul[16].add[<[actualY].div[256].round_down.mul[4]>].add[<[actualX].div[256].round_down>]>
          - define full_purple_circle_color   <color[<[r_]>,<[g_]>,<[b_]>]>
          - define full_purple_circle_display <&chr[E004].font[map].color[<[full_purple_circle_color]>]>
          - define offset <[sr].div[16].round_down>

          - define storm_circle <proc[spacing].context[<[offset].mul[2].sub[2]>]><[full_purple_circle_display]><n>


      - define players <server.online_players_flagged[fort]>

      #i dont think this really matters
      #how many players to update per tick
      - define update_freq <[players].size.div[20].round_up>
      - define batch  <[players].sub_lists[<[update_freq]>]>

      # - [ Update Tablist Maps + Individual Markers ] - #
      - foreach <[batch]> as:p_list:
        - foreach <[p_list]> as:p:
          - if !<[p].is_online>:
            - foreach next
          #get individual marker data
          - define world <[p].world>
          - define loc <[p].location>
          - define yaw <[loc].yaw>
          - define yaw_data <[yaw].is[LESS].than[0].if_true[<[yaw].add[360]>].if_false[<[yaw]>].div[360]>
          - define rot_data <[yaw_data].mul[64].round_down>

          - define x <[loc].x.sub[<[top_left_x]>].div[4].round_down>
          - define y <[loc].z.sub[<[top_left_z]>].div[4].round_down>
          - define full_marker_red <[rot_data].add[<[x].div[256].round_down.mul[64]>].add[<[y].div[256].round_down.mul[128]>]>

          - define real_g <[x].mod[256]>
          - define real_b <[y].mod[256]>
          #null is if it's oob
          - define full_marker_color <color[<[full_marker_red]>,<[real_g]>,<[real_b]>]||null>
          - define full_marker       <[world].name.equals[nimnite_map].if_true[<&chr[E000].font[map].color[<[full_marker_color]>].if_null[<empty>]>].if_false[<empty>]>

          - adjust <[p]> tab_list_info:<[full_marker]><[white_circle]||<empty>><[storm_circle]||<empty>><[map]>

        - wait 1t

  #just caching this data so there's no reason to get it every time
  cache_map_tiles:
    - repeat 64:
      - define zeroes <element[0].repeat[<element[3].sub[<[value].length>]>]>
      - define char A<[zeroes]><[value]>
      - define map:->:<&chr[<[char]>].font[map].color[<color[1,1,<[value]>]>]>

    - define map <[map].unseparated>
    - flag server fort.map_tiles:<[map]>