class_name DayNightSystem
extends Node

signal time_changed(day: int, minutes: float)
signal day_started(day: int)

const DAY_END_MINUTES: float = 1440.0
const MORNING_MINUTES: float = 360.0

var day: int = 1
var minutes: float = 480.0
var minutes_per_second: float = 6.0
var paused: bool = false

func advance(delta: float) -> void:
    if paused:
        return
    minutes += delta * minutes_per_second
    if minutes >= DAY_END_MINUTES:
        day += 1
        minutes = MORNING_MINUTES
        day_started.emit(day)
    time_changed.emit(day, minutes)

func set_time(saved_day: int, saved_minutes: float) -> void:
    day = maxi(1, saved_day)
    minutes = clampf(saved_minutes, 0.0, DAY_END_MINUTES - 1.0)
    time_changed.emit(day, minutes)

func clock_text() -> String:
    var hour := int(minutes / 60.0) % 24
    var minute := int(minutes) % 60
    return "%02d:%02d" % [hour, minute]

func is_night() -> bool:
    var hour := minutes / 60.0
    return hour >= 18.0 or hour < 6.0
