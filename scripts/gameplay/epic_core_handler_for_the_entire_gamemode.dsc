#/ex narrate <location[75.5,0,55.5].points_around_y[radius=50;points=16].to_polygon.with_y_min[0].with_y_max[300].outline>
fort_core_handler:
  type: task
  debug: false
  definitions: seconds|phase|text|diameter|forming
  #phases:
  #1) bus (doors will open in x)
  #2) fall (jump off bus)
  #3) grace_period
  #4) storm_shrink

  script:

  #-Doors open
  #doors open in 20 seconds
  - ~run fort_core_handler.timer def.seconds:20  def.phase:BUS

  #-Bus drop
  #everybody off, last stop in 55 seconds
  - ~run fort_core_handler.timer def.seconds:55  def.phase:FALL

  #-Storm forms
  #storm forming in 1 Minute
  - ~run fort_core_handler.timer def.seconds:60  def.phase:GRACE_PERIOD def.forming:FORMING

  #-stage 1
  #storm eye shrinks in 3 minutes 20 seconds
  - ~run fort_core_handler.timer def.seconds:200 def.phase:GRACE_PERIOD
  #storm eye shrinking 3 minutes
  - ~run fort_core_handler.timer def.seconds:180 def.phase:STORM_SHRINK def.diameter:1600

  #-stage 2
  #storm eye shrinks in 2 minutes
  - ~run fort_core_handler.timer def.seconds:120 def.phase:GRACE_PERIOD
  #storm eye shrinking 2 minutes
  - ~run fort_core_handler.timer def.seconds:120 def.phase:STORM_SHRINK def.diameter:800

  #-stage 3
  #storm eye shrinks in 1 Minute 30 seconds
  - ~run fort_core_handler.timer def.seconds:90  def.phase:GRACE_PERIOD
  #storm eye shrinking 1 Minute 30 seconds
  - ~run fort_core_handler.timer def.seconds:90  def.phase:STORM_SHRINK def.diameter:400

  #-stage 4
  #storm eye shrinks in 1 Minute 20 Seconds
  - ~run fort_core_handler.timer def.seconds:80  def.phase:GRACE_PERIOD
  #storm eye shrinking 1 Minute 10 seconds
  - ~run fort_core_handler.timer def.seconds:70  def.phase:STORM_SHRINK def.diameter:200

  #-stage 5
  #storm eye shrinks in 50 Seconds
  - ~run fort_core_handler.timer def.seconds:50  def.phase:GRACE_PERIOD
  #storm eye shrinking 1 Minute
  - ~run fort_core_handler.timer def.seconds:60  def.phase:STORM_SHRINK def.diameter:100

  #-stage 6
  #storm eye shrinks in 30 Seconds
  - ~run fort_core_handler.timer def.seconds:30  def.phase:GRACE_PERIOD
  #storm eye shrinking 1 Minute
  - ~run fort_core_handler.timer def.seconds:60  def.phase:STORM_SHRINK def.diameter:50

  #-stage 7
  #storm eye shrinking 55 seconds
  - ~run fort_core_handler.timer def.seconds:55  def.phase:STORM_SHRINK def.diameter:35

  #-stage 8
  #storm eye shrinking 45 seconds
  - ~run fort_core_handler.timer def.seconds:45  def.phase:STORM_SHRINK def.diameter:20

  #-stage 9
  #storm eye shrinking 1 Minute 15 seconds
  - ~run fort_core_handler.timer def.seconds:75  def.phase:STORM_SHRINK def.diameter:0

  timer:
    - flag server fort.temp.phase:<[phase]>

    - define icon <&chr[<map[bus=0025;fall=0003;grace_period=B005;storm_shrink=0005].get[<[phase]>]>].get[icons]>

    - choose <[phase]>:
      - case bus:
        - define announce_icon <&chr[A025].get[icons]>
        - define text "DOORS WILL OPEN IN"
        - define +spacing <proc[spacing].context[89]>
        - define -spacing <proc[spacing].context[-97]>
      - case fall:
        - define announce_icon <&chr[B003].get[icons]>
        - define text "EVERYBODY OFF, LAST STOP IN"
        - define +spacing <proc[spacing].context[114]>
        - define -spacing <proc[spacing].context[-130]>
      - case grace_period:
        - define announce_icon <&chr[B006].get[icons]>
        - define text "STORM EYE <[FORMING]||SHRINKS> IN"

        - if <[seconds]> <= 60:
          - define +spacing <proc[spacing].context[86]>
          - define -spacing <proc[spacing].context[-113]>
        - else:
          #1 min and x seconds
          - define +spacing <proc[spacing].context[113]>
          - define -spacing <proc[spacing].context[-141]>

      - case storm_shrink:
        - define announce_icon <&chr[A005].get[icons]>
        - define text "STORM EYE SHRINKING"

        - if <[seconds]> <= 60:
          - define +spacing <proc[spacing].context[82]>
          - define -spacing <proc[spacing].context[-112]>
        - else:
          #1 min and x seconds
          - define +spacing <proc[spacing].context[109]>
          - define -spacing <proc[spacing].context[-138]>

    - repeat <[seconds]>:
      ##<server.online_players_flagged[fort]>
      - define players      <world[ft24].players>
      - define seconds_left <[seconds].sub[<[value]>]>
      - define timer        <time[2069/01/01].add[<[seconds_left]>].format[m:ss]>

      #flag is for hud
      - flag server fort.temp.timer:<[timer]>
      - sidebar set_line scores:5 values:<element[<[icon]> <[timer]>].font[hud_text].color[<color[50,0,0]>]> players:<[players]>

      #do this in a separate task?
      #-turn this info into titles instead of bossbars?
      - if <[value]> <= 5:
        - bossbar update fort_info title:<[+spacing]><[announce_icon]><[-spacing]><&l><[text].font[lobby_text]><&sp><&d><&l><[seconds_left].as[duration].formatted_words.to_titlecase.font[lobby_text]> color:YELLOW players:<[players]>
      - else if <[value]> == 6:
        - bossbar update fort_info title:<empty> players:<[players]>

      - wait 1s

fort_bus_handler:
  type: world
  debug: false
  events:
    on player steers entity flagged:fort.in_bus:
    - narrate a