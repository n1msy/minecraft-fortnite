spacing:
  type: procedure
  debug: false
  definitions: int
  script:
    - if !<[int].is_integer>:
      - narrate "Not an integer"
      - determine "Not an integer"

    - define spacing <list>
    - define prefixA 0
    - define prefixB E
    - if <[int]> < 0:
      - define prefixA 1
      - define prefixB F
      - define int <[int].abs>

    - if <[int]> >= 16384:
      - define spacing:->:<&chr[<[prefixA]>00F].font[spacing]>
      - define int:-:16384
    - if <[int]> >= 8192:
      - define spacing:->:<&chr[<[prefixA]>00E].font[spacing]>
      - define int:-:8192
    - if <[int]> >= 4096:
      - define spacing:->:<&chr[<[prefixA]>00D].font[spacing]>
      - define int:-:4096
    - if <[int]> >= 2048:
      - define spacing:->:<&chr[<[prefixA]>00C].font[spacing]>
      - define int:-:2048
    - if <[int]> >= 1024:
      - define spacing:->:<&chr[<[prefixA]>00B].font[spacing]>
      - define int:-:1024
    - if <[int]> >= 512:
      - define spacing:->:<&chr[<[prefixA]>00A].font[spacing]>
      - define int:-:512
    - if <[int]> >= 256:
      - define spacing:->:<&chr[<[prefixA]>009].font[spacing]>
      - define int:-:256
    - if <[int]> >= 128:
      - define spacing:->:<&chr[<[prefixA]>008].font[spacing]>
      - define int:-:128
    - if <[int]> >= 64:
      - define spacing:->:<&chr[<[prefixA]>007].font[spacing]>
      - define int:-:64
    - if <[int]> >= 32:
      - define spacing:->:<&chr[<[prefixA]>006].font[spacing]>
      - define int:-:32

    - if <[int].mod[2]> == 1:
      - define spacing:->:<&chr[<[prefixA]>001].font[spacing]>

    - define int:<[int].div[2].round_down>
    - if <[int]> == 1:
      - define spacing:->:<&chr[<[prefixA]>002].font[spacing]>
    - else if <[int]> == 2:
      - define spacing:->:<&chr[<[prefixA]>003].font[spacing]>
    - else if <[int]> == 3:
      - define spacing:->:<&chr[<[prefixB]>000].font[spacing]>
    - else if <[int]> == 4:
      - define spacing:->:<&chr[<[prefixA]>004].font[spacing]>
    - else if <[int]> == 5:
      - define spacing:->:<&chr[<[prefixB]>001].font[spacing]>
    - else if <[int]> == 6:
      - define spacing:->:<&chr[<[prefixB]>002].font[spacing]>
    - else if <[int]> == 7:
      - define spacing:->:<&chr[<[prefixB]>003].font[spacing]>
    - else if <[int]> == 8:
      - define spacing:->:<&chr[<[prefixA]>005].font[spacing]>
    - else if <[int]> == 9:
      - define spacing:->:<&chr[<[prefixB]>004].font[spacing]>
    - else if <[int]> == 10:
      - define spacing:->:<&chr[<[prefixB]>005].font[spacing]>
    - else if <[int]> == 11:
      - define spacing:->:<&chr[<[prefixB]>006].font[spacing]>
    - else if <[int]> == 12:
      - define spacing:->:<&chr[<[prefixB]>007].font[spacing]>
    - else if <[int]> == 13:
      - define spacing:->:<&chr[<[prefixB]>008].font[spacing]>
    - else if <[int]> == 14:
      - define spacing:->:<&chr[<[prefixB]>009].font[spacing]>
    - else if <[int]> == 15:
      - define spacing:->:<&chr[<[prefixB]>00A].font[spacing]>

    - determine <[spacing].unseparated>