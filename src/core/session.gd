extends Node
# What this run of the game is playing: the hero picked on class select. Becomes the save slot in M5.

const CLASSES: Array[HeroClass] = [
	preload("res://src/hero/classes/barbarian.tres"),
	preload("res://src/hero/classes/mage.tres"),
]

var hero_class: HeroClass = CLASSES[0]
