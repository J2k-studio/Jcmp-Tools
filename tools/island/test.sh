#!/bin/sh
# island: the messages to the app (OSC island;...), durations, the links timer and alarm, the list, errors
set -eu
cd "$(dirname "$0")"; sh build.sh >/dev/null
N="$PWD/_out/island"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
[ "$("$N" --version)" = "island 0.1.0" ] || { echo "island test: version"; exit 1; }
osc() { printf '\033]7777;island;%s\007' "$1"; }
check() { want=$(osc "$1"); shift; got=$("$@"); [ "$got" = "$want" ] || { echo "island test: $* said [$got], wanted [$want]"; exit 1; }; }
check "timer;300;" "$N" timer 5m
check "timer;5400;tea time" "$N" timer 1h30m tea time
check "timer;90;" "$N" timer 90
check "timer;45;" "$N" timer 45s
check "timer;7200;" "$N" timer 2h
check "alarm;07:30;;" "$N" alarm 07:30
check "alarm;7:5;wake up;daily" "$N" alarm 7:5 wake up daily
check "alarm;8:00;;" "$N" alarm 8
check "on" "$N" on
check "off" "$N" off
check "mode;over" "$N" over
check "mode;app" "$N" app
check "place;middle" "$N" middle
check "place;hole" "$N" hole
check "notice;hello there" "$N" notice hello there
check "cancel;3" "$N" timer cancel 3
check "cancelall;alarm" "$N" alarm cancel all
cp "$N" "$T/island"; "$T/island" --install "$T" || { echo "island test: --install"; exit 1; }
[ -L "$T/timer" ] && [ -L "$T/alarm" ] || { echo "island test: the links"; exit 1; }
want=$(osc "timer;600;pasta"); got=$("$T/timer" 10m pasta); [ "$got" = "$want" ] || { echo "island test: the link timer said [$got]"; exit 1; }
want=$(osc "alarm;06:15;;daily"); got=$("$T/alarm" 06:15 daily); [ "$got" = "$want" ] || { echo "island test: the link alarm said [$got]"; exit 1; }
"$N" timer abc > /dev/null 2>&1 && { echo "island test: a wrong duration must fail"; exit 1; }
"$N" timer > /dev/null 2>&1 && { echo "island test: timer without a time must fail"; exit 1; }
"$N" alarm 25:00 > /dev/null 2>&1 && { echo "island test: a wrong time must fail"; exit 1; }
"$N" alarm 07:61 > /dev/null 2>&1 && { echo "island test: a wrong minute must fail"; exit 1; }
"$N" nothing > /dev/null 2>&1 && { echo "island test: an unknown command must fail"; exit 1; }
# the list, read from the file that the app writes
mkdir -p "$T/home/.config/jaric"
END=$(( $(date +%s) + 125 ))
printf '1 timer %s tea\n2 alarm 07:30 daily wake up\n' "$END" > "$T/home/.config/jaric/island.txt"
out=$(HOME="$T/home" "$N" list)
echo "$out" | grep -q "^1  timer  0h 2m" || { echo "island test: list timer: $out"; exit 1; }
echo "$out" | grep -q "2 alarm 07:30 daily wake up" || { echo "island test: list alarm: $out"; exit 1; }
HOME="$T/home" "$N" timer list | grep -q "tea" || { echo "island test: timer list"; exit 1; }
HOME="$T/home" "$N" alarm list | grep -q "wake up" || { echo "island test: alarm list"; exit 1; }
HOME="$T/home" "$N" alarm list | grep -q "tea" && { echo "island test: alarm list must not show timers"; exit 1; }
echo "island tests: ok"
