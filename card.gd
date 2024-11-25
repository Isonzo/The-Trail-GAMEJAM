extends Resource
class_name Card

@export var title: String
@export var description: String
@export var type: String
@export var good_effect_params: Array[EffectParam] = []
@export var bad_effect_params: Array[EffectParam] = []
@export var special_effect: String = ""
@export var special_desc: String
@export var image: Texture
@export var removes_self: bool
