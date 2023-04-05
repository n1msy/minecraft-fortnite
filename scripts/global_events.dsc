fort_global_handler:
  type: world
  debug: false
  events:

    on player damaged by FALL:
    #you take half the fall damage now
    - define damage <context.damage.div[2]>
    #that way the annoying head thing doesn't happen when falling by the smallest amount
    - if <[damage]> < 1:
      - determine passively cancelled
      - stop

    - determine <[damage]>

    on player changes food level:
    - determine cancelled

    on player heals:
    - determine cancelled