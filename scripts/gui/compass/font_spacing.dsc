# @ ██ [ Do not change anything here unless you know what you are doing ] ██
# @ ██ [ note - these two scripts:       ] ██
# - ██ [ - negative_spacing              ] ██
# - ██ [ - positive_spacing              ] ██
# % ██ [ are *not* customized to the new ] ██
# % ██ [ implemented negative/positive   ] ██
# % ██ [ spacing unicode system          ] ██
negative_spacing:
  type: procedure
  debug: false
  definitions: int
  script:
    - if !<[int].is_integer>:
      - determine "Invalid integer"

    - define spacing <list>

    - while <[int]> > 0:
      - if <[int]> >= 1024:
        - define int:-:1024
        - define spacing <[spacing].include[<&chr[F80E]>]>
      - else if <[int]> >= 512:
        - define int:-:512
        - define spacing <[spacing].include[<&chr[F80D]>]>
      - else if <[int]> >= 128:
        - define int:-:128
        - define spacing <[spacing].include[<&chr[F80C]>]>
      - else if <[int]> >= 64:
        - define int:-:64
        - define spacing <[spacing].include[<&chr[F80B]>]>
      - else if <[int]> >= 32:
        - define int:-:32
        - define spacing <[spacing].include[<&chr[F80A]>]>
      - else if <[int]> >= 16:
        - define int:-:16
        - define spacing <[spacing].include[<&chr[F809]>]>
      - else if <[int]> >= 8:
        - define int:-:8
        - define spacing <[spacing].include[<&chr[F808]>]>
      - else if <[int]> >= 7:
        - define int:-:7
        - define spacing <[spacing].include[<&chr[F807]>]>
      - else if <[int]> >= 6:
        - define int:-:6
        - define spacing <[spacing].include[<&chr[F806]>]>
      - else if <[int]> >= 5:
        - define int:-:5
        - define spacing <[spacing].include[<&chr[F805]>]>
      - else if <[int]> >= 4:
        - define int:-:4
        - define spacing <[spacing].include[<&chr[F804]>]>
      - else if <[int]> >= 3:
        - define int:-:3
        - define spacing <[spacing].include[<&chr[F803]>]>
      - else if <[int]> >= 2:
        - define int:-:2
        - define spacing <[spacing].include[<&chr[F802]>]>
      - else:
        - define int:-:1
        - define spacing <[spacing].include[<&chr[F801]>]>

    - determine <[spacing].unseparated>

positive_spacing:
  type: procedure
  debug: false
  definitions: int
  script:
    - if !<[int].is_integer>:
      - determine "Invalid integer"

    - define spacing <list>

    - while <[int]> > 0:
      - if <[int]> >= 1024:
        - define int:-:1024
        - define spacing <[spacing].include[<&chr[F82E]>]>
      - else if <[int]> >= 512:
        - define int:-:512
        - define spacing <[spacing].include[<&chr[F82D]>]>
      - else if <[int]> >= 128:
        - define int:-:128
        - define spacing <[spacing].include[<&chr[F82C]>]>
      - else if <[int]> >= 64:
        - define int:-:64
        - define spacing <[spacing].include[<&chr[F82B]>]>
      - else if <[int]> >= 32:
        - define int:-:32
        - define spacing <[spacing].include[<&chr[F82A]>]>
      - else if <[int]> >= 16:
        - define int:-:16
        - define spacing <[spacing].include[<&chr[F829]>]>
      - else if <[int]> >= 8:
        - define int:-:8
        - define spacing <[spacing].include[<&chr[F828]>]>
      - else if <[int]> >= 7:
        - define int:-:7
        - define spacing <[spacing].include[<&chr[F827]>]>
      - else if <[int]> >= 6:
        - define int:-:6
        - define spacing <[spacing].include[<&chr[F826]>]>
      - else if <[int]> >= 5:
        - define int:-:5
        - define spacing <[spacing].include[<&chr[F825]>]>
      - else if <[int]> >= 4:
        - define int:-:4
        - define spacing <[spacing].include[<&chr[F824]>]>
      - else if <[int]> >= 3:
        - define int:-:3
        - define spacing <[spacing].include[<&chr[F823]>]>
      - else if <[int]> >= 2:
        - define int:-:2
        - define spacing <[spacing].include[<&chr[F822]>]>
      - else:
        - define int:-:1
        - define spacing <[spacing].include[<&chr[F821]>]>

    - determine <[spacing].unseparated>