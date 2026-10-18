extends Control
## HudDisplay — draws health pips + resource meter + cinders (Mobile module HUD).

class_name HudDisplay

var _hp := 5
var _max_hp := 5
var _res := 0
var _res_max := 99
var _cinders := 0
var _boss_active := false
var _boss_name := ""
var _boss_hp := 0
var _boss_max := 1


func set_stats(hp: int, max_hp: int, res: int, cinders: int) -> void:
	_hp = hp
	_max_hp = max_hp
	_res = res
	_cinders = cinders
	queue_redraw()


func set_boss(boss_name: String, hp: int, max_hp: int) -> void:
	_boss_active = true
	_boss_name = boss_name
	_boss_hp = hp
	_boss_max = maxi(1, max_hp)
	queue_redraw()


func clear_boss() -> void:
	_boss_active = false
	queue_redraw()


func _draw() -> void:
	# Health pips, top-left.
	for i: int in _max_hp:
		var c := Vector2(28.0 + i * 40.0, 32.0)
		var fill := Color(0.95, 0.93, 0.89) if i < _hp else Color(1, 1, 1, 0.15)
		draw_circle(c, 13.0, fill)
	# Resource meter below pips.
	var bar := Rect2(16, 56, 220, 16)
	draw_rect(bar, Color(1, 1, 1, 0.15))
	var w: float = bar.size.x * clampf(float(_res) / float(_res_max), 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(w, bar.size.y)), Color(1.0, 0.48, 0.18))
	# Cinders, top-right.
	var font := ThemeDB.fallback_font
	var fs := 26
	var text := str(_cinders)
	var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var vw: float = get_viewport_rect().size.x
	var coin := Vector2(vw - tw - 48.0, 32.0)
	draw_circle(coin, 12.0, Color(1.0, 0.82, 0.4))
	draw_circle(coin, 12.0, Color(0.6, 0.4, 0.1))
	draw_arc(coin, 12.0, 0.0, TAU, 32, Color(0.6, 0.4, 0.1), 2.0)
	draw_circle(coin, 9.0, Color(1.0, 0.82, 0.4))
	draw_string(font, Vector2(vw - tw - 24.0, 41.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.82, 0.4))
	# Boss bar, top-center.
	if _boss_active:
		var bw := 560.0
		var bx: float = (vw - bw) * 0.5
		var fs2 := 24
		var nw: float = font.get_string_size(_boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		draw_string(font, Vector2((vw - nw) * 0.5, 34.0), _boss_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(0.95, 0.93, 0.89))
		var bbar := Rect2(bx, 44, bw, 18)
		draw_rect(bbar, Color(1, 1, 1, 0.15))
		var w2: float = bw * clampf(float(_boss_hp) / float(_boss_max), 0.0, 1.0)
		draw_rect(Rect2(bbar.position, Vector2(w2, bbar.size.y)), Color(1.0, 0.3, 0.37))
