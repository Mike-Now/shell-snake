#! /bin/bash

# Constants
BORDER_LINE='#'
BORDER_CORNER='#'
SNAKE_SEGMENT="o"
TIME_DELTA=0.1

INPUT_FIFO=fifo1

# Global vars
snake_segments=
snake_direction=R

function cleanup(){
  show_cursor
  remove_on_exit_hook
  echo "Thank you for playing!"
}

function main() {
    add_on_exit_hook cleanup
    local rows=$(tput lines)
    local cols=$(tput cols)
    local eraser_str=$(create_empty_str $((cols-2)) " ")
    calc_initial_snake_position $rows $cols
    clear
    hide_cursor
    save_cursor_position
    draw_board $rows $cols
    local input=
    while true; do
        input=
        read -t 0.1 -n 1 input
        restore_cursor_position
        clean_board $rows $cols "$eraser_str"
        restore_cursor_position
        change_snake_direction "$input"
        draw_snake
        move_snake
        sleep $TIME_DELTA
    done
}

function change_snake_direction() {
    local input=$1

    case "$input" in
        w) snake_direction=U;;
        s) snake_direction=D;;
        a) snake_direction=L;;
        d) snake_direction=R;;
    esac
}

function save_context() {
    tput smcup
}

function restore_context() {
    tput rmcup
}

function draw_board() {
    local rows=$1; shift
    local cols=$1
    draw_border $rows $cols
}

function create_empty_str () {
    local len=$1
    printf '%*s' "$len" | tr ' ' " "
}

function clean_board() {
    local rows=$1; shift
    local cols=$1; shift
    local eraser_str="$1"
    place_cursor 1 1
    for ((i=2;i<$rows;i++)); do
        echo -n "$eraser_str"
        place_cursor $i 1
    done
}

function move_snake() {
    local next_y next_x
    local head_pos="${snake_segments[-1]}"
    head_pos=(${head_pos//,/ })
    next_y=${head_pos[0]}
    next_x=${head_pos[1]}
    case $snake_direction in
        U)
            ((next_y--)) ;;
        D)
            ((next_y++)) ;;
        L)
            ((next_x--)) ;;
        R)
            ((next_x++)) ;;
    esac

    snake_segments+=( "$next_y,$next_x")
    snake_segments=("${snake_segments[@]:1}")
}


function draw_snake() {
    for tup in ${snake_segments[@]}; do
        local tupArr=(${tup//,/ })
        local y=${tupArr[0]}
        local x=${tupArr[1]}
        place_cursor $y $x
        echo -n $SNAKE_SEGMENT
    done
}

function calc_initial_snake_position() {
    local rows=$1; shift
    local cols=$1

    local mid_row=$(($rows / 2))
    local mid_col=$(($cols / 2))
    snake_segments=("$mid_row,$mid_col"\ 
"$mid_row,$(($mid_col+1))"\ 
"$mid_row,$(($mid_col+2))")
} 

function draw_border() {
    local rows=$1; shift
    local cols=$1
    for ((i=0;i<$cols;i++)); do
        echo -n $BORDER_LINE
    done
    echo
    for ((i=0;i<$rows-2;i++)); do
        echo -n $BORDER_LINE
        move_cursor_right $(($cols-1))
        echo $BORDER_LINE
    done
    for ((i=0;i<$cols;i++)); do
        echo -n $BORDER_LINE
    done
}

# Origin (0,0) is in the left upper corner
function place_cursor() {
    local y=$1;local x=$2
    tput cup $y $x
}

function move_cursor_right() {
    tput cuf $1
}

function move_cursor_left() {
    tput cub $1
}

function move_cursor_up() {
    tput cuu $1
}


function move_cursor_down() {
    tput cud $1
}

function save_cursor_position() {
    tput sc
}

function restore_cursor_position() {
    tput rc
}

function add_on_exit_hook() {
    trap "$@" EXIT
}

function remove_on_exit_hook() {
    trap '' EXIT
}

function show_cursor() {
    tput cnorm
}

function hide_cursor() {
    tput civis
}

function read_input() {
    (while true;do
        read -s -n 1 c
        echo -n $c
    done)> $INPUT_FIFO
}

function create_fifo() {
    mkfifo $INPUT_FIFO
}

function remove_fifo() {
    rm $INPUT_FIFO
}

create_fifo
(main < $INPUT_FIFO)&
read_input
cleanup

