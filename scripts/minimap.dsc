minimap:
  type: task
  debug: false
  script:
  - if <player.has_flag[minimap]>:
    - flag player minimap:!
    - narrate "<&c>minimap removed"
    - stop

  - define uuid <player.uuid>

  - define bb minimap_<player.uuid>
  - bossbar create <[bb]>
  - flag player minimap

  - define oldRotation <player.location.yaw.div[360].mul[1024].round>

  - while <player.is_online> && <player.has_flag[minimap]>:


    #turn loc to color
    - define loc <player.location.round>
    - define yaw <[loc].yaw>

    #-marker
    - define marker_red <[yaw].is[LESS].than[0].if_true[<[yaw].add[360]>].if_false[<[yaw]>].div[360].mul[255]>

    - define marker_color <color[<[marker_red].round>,0,0]>
    - define marker <&chr[E000].font[map].color[<[marker_color]>]>

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

    #not working
    # define base_coords <list[<map[x=0;y=0]>|<map[x=0;y=1]>|<map[x=1;y=0]>|<map[x=1;y=1]>]>
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

    # compass display
    - define curRotation <player.location.yaw.div[360].mul[1024].round>
    - define gameTime <player.world.duration_since_created.in_ticks.mod[24000].mod[4]>
    - define rotation_color <color[<[curRotation].mod[256]>,<[oldRotation].mod[256]>,<[curRotation].div[256].round_down.add[<[oldRotation].div[256].round_down.mul[4]>].add[<[gameTime].mul[16]>]>]>
    - define oldRotation <[curRotation]>
    - define compass_display <&chr[B000].font[map].color[<[rotation_color]>]>

    # circle display
    - define circle 100
    - define storm_id 15
    - define relX <[circle].sub[<[loc].x>].add[1024]>
    - define relZ <[circle].sub[<[loc].z>].add[1024]>
    - define r_ <[relX].mod[256]>
    - define g_ <[relZ].mod[256]>
    - define b_ <[relX].div[256].round_down.add[<[relZ].div[256].round_down.mul[8]>].add[<[storm_id].div[4].round_down.mul[64]>]>
    - define offset <[storm_id].mod[4].mul[2]>

    - define circle_color <color[<[r_]>,<[g_]>,<[b_]>]>
    - define circle_display <&chr[E001].font[map].color[<[circle_color]>]>


    - define title <[compass_display]><[whole_map]><[marker]><proc[spacing].context[<[offset].sub[2].sub[<[tiles].size>]>]><[circle_display]>

    - bossbar update <[bb]> title:<[title]>
    - wait 1t

  - flag player minimap:!
  - if <server.current_bossbars.contains[<[bb]>]>:
    - bossbar remove <[bb]>

  tab:
    - define neg_spacing <&chr[F801].font[denizen:overlay]>

    - define border_radius 4

    - define tab_map <list[]>

    - repeat 16:

      - define zeroes <element[0].repeat[<element[3].sub[<[value].length>]>]>
      - define char A<[zeroes]><[value]>

      - define row:->:<&chr[<[char]>].font[map]>

      - if <[value].mod[4]> == 0:
        - define tab_map <[tab_map].include[<&sp.repeat[<[border_radius].sub[1]>]><[row].separated_by[<[neg_spacing]>]><&sp.repeat[<[border_radius].sub[1]>]>]>
        - define row:!

    - define tab_map <[tab_map].separated_by[<n.repeat[7]>]>

    - adjust <player> tab_list_info:<n.repeat[<[border_radius]>]><[tab_map]><n.repeat[<[border_radius]>]>