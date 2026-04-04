extends Control
class_name Card

## 花色: 0 ~ 3
var card_suit: int = -1

## 数值: 1 ~ 13
var card_value: int = -1
@onready var text_rect: TextureRect = $TextureRect

func _ready() -> void:
	self.initialize_card()
	
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
