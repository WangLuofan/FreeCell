extends Control
class_name Card

## 花色: 0 ~ 3
var card_suit: int = -1

## 数值: 1 ~ 13
var card_value: int = -1
@onready var text_rect: TextureRect = $TextureRect

func _ready() -> void:
	self.initialize_card()
	
func move_card_to(global_pos: Vector2, call_back: Callable = Callable()) -> Tween:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", global_pos, 0.25)
	if call_back.is_valid():
		tween.tween_callback(call_back)
	tween.play()
	return tween
	
## 初始化卡片
func initialize_card() -> void:
	var atlasTexture: AtlasTexture = self.text_rect.texture as AtlasTexture

	var newAtlasTexture: AtlasTexture = atlasTexture.duplicate()
	newAtlasTexture.region = Rect2(self.card_value * Consts.CARD_WIDTH, (self.card_suit * Consts.CARD_HEIGHT), Consts.CARD_WIDTH, Consts.CARD_HEIGHT)
	self.text_rect.texture = newAtlasTexture

## 设置卡牌花色和数值
func set_card(suit: int, value: int) -> void:
	self.card_suit = suit
	self.card_value = value
	
func can_receive(card: Card) -> bool:
	if self.is_same_suit(card):
		return false
	return self.card_value == card.card_value + 1
	
func is_same_suit(card: Card) -> bool:
	if self.card_suit % 2 == card.card_suit % 2:
		return true
	return false
