minimap:
  type: task
  debug: false
  script:
  - if <player.has_flag[minimap]>:
    - flag player minimap:!
    - narrate "<&c>minimap removed"
    - stop

  - flag player minimap

  - while <player.is_online> && <player.has_flag[minimap]>:
    - define loc <player.location>
    - define size 70
    #goal = 72

    - define yaw <map[North=0;South=180;West=-90;East=90].get[<player.location.yaw.simple>]>

    - define center <[loc].center.above[100].with_yaw[<[yaw]>].backward_flat[<[size].div[1.6]>]>

    - define neg_spacing <&chr[F801]>
    - define next_line_spacing <&chr[F80F]>
    #- define pos_spacing <&chr[F901].font[denizen:overlay]>

    - define ordered_pixels <list[]>
    - repeat <[size]>:
      - define pixels:!
      #each pixel has a different offset for height
      - define pixel <&chr[<[value]>]>
      - define left <[center].forward[<[value]>].left[<[size].div[2]>]>
      - define right <[center].forward[<[value]>].right[<[size].div[2]>]>
      - define row <[left].points_between[<[right]>].parse[with_pitch[90].ray_trace[return=block].map_color]>

      - foreach <[row]> as:color:
        #so the same color isn't reapplied
        - if <[row].get[<[loop_index].add[1]>]||null> == <[color]>:
          - define pixels:->:<[pixel]>
          - foreach next
        - define pixels:->:<&color[<[color]>]><[pixel]>

      - define ordered_pixels:->:<[next_line_spacing]><[pixels].reverse.separated_by[<[neg_spacing]>]>

      #- define ordered_pixels:->:<[next_line_spacing]><[row].parse_tag[<[pixel].color[<[parse_value]>]>].reverse.separated_by[<[neg_spacing]>]>

    - define title <[ordered_pixels].unseparated.font[denizen:minimap].optimize_json>

    #- narrate <[title].to_raw_json.length>

    - title subtitle:<[title]> fade_in:0t
    - wait 10t

  - flag player minimap:!
