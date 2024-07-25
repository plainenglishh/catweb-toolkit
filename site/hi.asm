$speed   1   ; Speed of the character movement in pixels per second
$frame_t 0.1 ; Time between frames
$char    %64 ; The character

.setup @pageload
    set &a, 0
    set &b, 0

.character_move_left @keypress ~A
    add &b, -$frame_t

.character_move_right @keypress ~D
    add &b, $frame_t

.character_move_up @keypress ~W
    add &a, -$frame_t

.character_move_down @keypress ~S
    add &a, $frame_t

.update
    sop "Position", $char, [{b}, {a}]

.main @pageload
    ; Update loop
    rpti
        del $frame_t
        bra .update
    end