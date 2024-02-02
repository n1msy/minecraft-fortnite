#The full map display when you open the tablist.

tablist_map_handler:
  type: world
  debug: false
  events:
    on delta time secondly:
      - narrate "[This is a placeholder message for the tablist map]"
  temp:
        ## - [ Full map ] - ##

        #-shader does the map-tile handling
        - repeat 64:
          - define zeroes <element[0].repeat[<element[3].sub[<[value].length>]>]>
          - define char A<[zeroes]><[value]>
          - define map:->:<&chr[<[char]>].font[map].color[<color[1,1,<[value]>]>]>

        - define map <[map].unseparated>

        # - circle
        - define full_circle_display <empty>

        ## - [ FULL CIRCLE ] - ##
        - if <[next_storm_center].exists>:
          # circle_x and circle_y is in worldspace
          - define circle_x <[next_storm_center].x>
          - define circle_y <[next_storm_center].z>
          - define actualX <[circle_x].sub[<[top_left_x]>].div[2].round_down>
          - define actualY <[circle_y].sub[<[top_left_z]>].div[2].round_down>
          - define r_ <[actualX].mod[256]>
          - define g_ <[actualY].mod[256]>
          - define b_ <[storm_id].mul[16].add[<[actualY].div[256].round_down.mul[4]>].add[<[actualX].div[256].round_down>]>
          - define full_circle_color   <color[<[r_]>,<[g_]>,<[b_]>]>
          - define full_circle_display <&chr[E002].font[map].color[<[full_circle_color]>]>

          ## - [ FULL PURPLE CIRCLE ] - ##
        - if <[storm_center].exists>:
          - define circle_x <[storm_center].x>
          - define circle_y <[storm_center].z>
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

        # - marker
        #for full map
        #uses 1 less bit to send more accurate info for position
        - define rot_data <[yaw_data].mul[64].round_down>

        # 0 - 511
        - define x <[loc].x.sub[<[top_left_x]>].div[4].round_down>
        - define y <[loc].z.sub[<[top_left_z]>].div[4].round_down>
        - define full_marker_red <[rot_data].add[<[x].div[256].round_down.mul[64]>].add[<[y].div[256].round_down.mul[128]>]>

        - define real_g <[x].mod[256]>
        - define real_b <[y].mod[256]>
        #null is if it's oob
        - define full_marker_color <color[<[full_marker_red]>,<[real_g]>,<[real_b]>]||null>
        - define full_marker       <[world].name.equals[nimnite_map].if_true[<&chr[E000].font[map].color[<[full_marker_color]>].if_null[<empty>]>].if_false[<empty>]>

        #show storm timer info in tablist too?
        - if <[next_storm_center].exists>:
          - adjust <player> tab_list_info:<[full_marker]><[full_circle_display]><proc[spacing].context[<[offset].mul[2].sub[2]>]><[full_purple_circle_display]><n><[map]>
        - else:
          - adjust <player> tab_list_info:<[full_marker]><[full_circle_display]><[map]>