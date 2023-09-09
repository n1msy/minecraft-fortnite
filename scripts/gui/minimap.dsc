minimap:
  type: task
  debug: false
  script:
  - if <player.has_flag[minimap]>:
    - flag player minimap:!
    - stop

  - define uuid <player.uuid>

  - define bb minimap_<player.uuid>
  - bossbar create <[bb]>
  - bossbar create <[bb]>_yaw color:yellow
  - flag player minimap

  - define oldRotation <player.location.yaw.div[360].mul[1024].round>


  #this chooses which image to use for minimap
  - define in_game <player.world.equals[nimnite_map]>

  - while <player.is_online> && <player.has_flag[minimap]>:


    #turn loc to color
    - define loc <player.location.round>
    - define yaw <[loc].yaw>

    #-marker
    - define marker_red   <[yaw].is[LESS].than[0].if_true[<[yaw].add[360]>].if_false[<[yaw]>].div[360].mul[255]>
    #this is minimap marker
    - define marker_green 0

    - define marker_color <color[<[marker_red].round>,<[marker_green]>,0]>
    - define marker       <&chr[E000].font[map].color[<[marker_color]>]>

    #-minimap
    - define x <[loc].x>
    - define z <[loc].z>

    - define r <[x].mod[256]>
    - define g <[z].mod[256]>

    #can't be 0
    - if <[r]> < 0:
      - define r <[r].add[256]>
    - if <[g]> < 0:
      - define g <[g].add[256]>

    - define map_x <[x].add[512].div[256].round_down.add[1]>
    - define map_y <[z].add[512].div[256].round_down.add[1]>

    #array of characters
    - define row_1 <list[0001|0002|0003|0004]>
    - define row_2 <list[0005|0006|0007|0008]>
    - define row_3 <list[0009|0010|0011|0012]>
    - define row_4 <list[0013|0014|0015|0016]>

    - define base_coords <list[0,0|0,1|1,0|1,1]>

    - define chars:!
    - foreach <[base_coords]> as:coords:

      - define x <[coords].before[,]>
      - define y <[coords].after[,]>

      - define x_add <[r].is[LESS].than[128].if_true[<[x].mul[-1]>].if_false[<[x]>]>
      - define y_add <[g].is[LESS].than[128].if_true[<[y].mul[-1]>].if_false[<[y]>]>

      - define final_y <[map_y].add[<[y_add]>]>
      - define final_x <[map_x].add[<[x_add]>]>

      - if <[final_y]> <= 0 || <[final_y]> >= 5 || <[final_x]> <= 0 || <[final_x]> >= 5:
        - define char 0000
      - else:
        - define char <[row_<[final_y]>].get[<[final_x]>]>

      - define chars:->:<[char]>

    - define tiles:!
    - repeat 4:
      #value is display id
      - define loc_to_color <color[<[r]>,<[g]>,<[value].sub[1]>]>
      - define ch <[chars].get[<[value]>]>

      - if <[ch]> == 0000:
        - repeat next

      - define tiles:->:<&chr[<[ch]>].font[map].color[<[loc_to_color]>]>


    - define whole_map <[tiles].unseparated>

    ## - [ COMPASS ] - ##
    # compass display
    - define curRotation     <player.location.yaw.div[360].mul[1024].round_down>
    - define gameTime        <player.world.duration_since_created.in_ticks.mod[24000].mod[4]>
    - define rotation_color  <color[<[curRotation].mod[256]>,<[oldRotation].mod[256]>,<[curRotation].div[256].round_down.add[<[oldRotation].div[256].round_down.mul[4]>].add[<[gameTime].mul[16]>]>]>
    - define oldRotation     <[curRotation]>
    - define compass_display <&chr[B000].font[map].color[<[rotation_color]>]>

    # circle display
    - define circle_x 65
    - define circle_y 90
    - define storm_id 5
    - define relX     <[circle_x].sub[<[loc].x>].add[1024]>
    - define relZ     <[circle_y].sub[<[loc].z>].add[1024]>
    - define r_       <[relX].mod[256]>
    - define g_       <[relZ].mod[256]>
    - define b_       <[relX].div[256].round_down.add[<[relZ].div[256].round_down.mul[8]>].add[<[storm_id].div[4].round_down.mul[64]>]>
    - define offset   <[storm_id].mod[4].mul[2]>

    - define circle_color   <color[<[r_]>,<[g_]>,<[b_]>]>
    - define circle_display <&chr[E001].font[map].color[<[circle_color]>]>

    - define title <[compass_display]><[whole_map]><[marker]><proc[spacing].context[<[offset].sub[2].sub[<[tiles].size>]>]><[circle_display]>

    - define spacing <&sp.repeat[<element[3].sub[<[yaw].length>]>]>

    # just so you know, adding characters before/and after the title does change the offset. who would've guessed /s
    - bossbar update <[bb]> title:<[title]>
    - bossbar update <[bb]>_yaw title:<[yaw].color[65,0,0]> color:yellow

    - inject minimap.tab
    - wait 1t

  - flag player minimap:!
  - if <server.current_bossbars.contains[<[bb]>]>:
    - bossbar remove <[bb]>
  - if <server.current_bossbars.contains[<[bb]>_yaw]>:
    - bossbar remove <[bb]>_yaw

  tab:
    # - [ Full map ] - #
    - define neg_spacing <proc[spacing].context[-1]>
    - define border_radius 4
    - define map <list[]>
    - repeat 16:
      - define zeroes <element[0].repeat[<element[3].sub[<[value].length>]>]>
      - define char A<[zeroes]><[value]>
      - define row:->:<&chr[<[char]>].font[map]>
      - if <[value].mod[4]> == 0:
        - define map <[map].include[<&sp.repeat[<[border_radius].sub[1]>]><[row].separated_by[<[neg_spacing]>]><&sp.repeat[<[border_radius].sub[1]>]>]>
        - define row:!
    - define map <[map].separated_by[<n.repeat[10]>]>

    # - circle
    - define actualX <[circle_x]>
    - define actualY <[circle_y]>
    - define r_ <[actualX].mod[256]>
    - define g_ <[actualY].mod[256]>
    #- narrate <[actualX].div[256].round_down>/<[actualY].div[256].round_down>
    - define b_ <[storm_id].mul[16]>
    #- narrate <[r_]>,<[g_]>,<[b_]>
    - define full_circle_color   <color[<[r_]>,<[g_]>,<[b_]>]>
    - define full_circle_display <&chr[E002].font[map].color[<[full_circle_color]>]>

    # - marker
    #for full map
    #uses 1 less bit to send more accurate info for position
    - define rot_data <[yaw].is[LESS].than[0].if_true[<[yaw].add[360]>].if_false[<[yaw]>].div[360].mul[64].round_down>
    #- narrate <[rot_data]>

    #max is 128
    - define x <[loc].x.add[512].div[2].round_down>
    - define y <[loc].z.add[512].div[2].round_down>
    - define full_marker_red <[rot_data].add[<[x].div[256].round_down.mul[64]>].add[<[y].div[256].round_down.mul[128]>]>
    #- define full_marker_red <[rot_data].div[8].round>
    #- narrate <[]>
    - define real_g <[x].mod[256]>
    - define real_b <[y].mod[256]>
    - define full_marker_color <color[<[full_marker_red]>,<[real_g]>,<[real_b]>]>
    - define full_marker       <&chr[E000].font[map].color[<[full_marker_color]>]>

    - adjust <player> tab_list_info:<[full_marker]><[full_circle_display]><n><[map]><n.repeat[9]>