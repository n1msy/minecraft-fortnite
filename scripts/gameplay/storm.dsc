storm:
  type: task
  debug: false
  definitions: data
  script:
    #-test command: /ex run storm def:<map[from=x;to=x]>
    ##only gets smaller, not bigger
    - remove item_display
    #make circle size server flag
    #time for it to change sizes (ticks)
    - define time   5
    - define height 1500

    - define from <[data].get[from]>
    - define to   <[data].get[to]||null>

    - define magic_number 0.534188034
    - define from_scale <[from].mul[<[magic_number]>]>
    - define to_scale   <[to].mul[<[magic_number]>]||null>

    - define center <player.location.with_pose[0,0]>

    - define i <item[paper].with[custom_model_data=19]>
    - spawn <entity[ITEM_DISPLAY].with[item=<[i]>;scale=<[from_scale]>,<[height]>,<[from_scale]>;view_range=3]> <[center]> save:circle
    - define circle <entry[circle].spawned_entity>

    - if <[to]> == null:
      - stop

    - wait 1s

    #5.55555555=10.5

    #scale 10 is about 18 blocks
    #meaning 1 block = +0.55555555555

    - adjust <[circle]> interpolation_start:0
    - adjust <[circle]> scale:<[to_scale]>,<[height]>,<[to_scale]>
    - adjust <[circle]> interpolation_duration:<[time]>