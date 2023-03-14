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

  - while <player.is_online> && <player.has_flag[minimap]>:


    #turn loc to color
    - define loc <player.location.round>

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

    - define compass_dir <map[North=N;Northeast=NE;Northwest=NW;East=E;West=W;South=S;Southeast=SE;Southwest=SW].get[<[loc].direction>]>


    - define title "<[compass_dir]> <[whole_map]>"

    - bossbar update <[bb]> title:<[title]>
    - wait 1t

  - flag player minimap:!
  - if <server.current_bossbars.contains[<[bb]>]>:
    - bossbar remove <[bb]>