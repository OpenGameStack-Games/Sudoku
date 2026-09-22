import os

path = r"c:\Users\kevin\OGS_Projects\Sudoku\.worktrees\issue-95\game\tests\test_statistics_screen.gd"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace("ScrollContainer/", "")

# We need to change test_scroll_container_properties
text = text.replace(
"""func test_scroll_container_properties() -> void:
	_setup_scene()
	scene._ready()
	
	var scroll_container = scene.get_node_or_null("MarginContainer/VBoxContainer/ScrollContainer")
	assert_true(scroll_container != null, "ScrollContainer should exist")
	assert_true(scroll_container is ScrollContainer, "ScrollContainer should be of type ScrollContainer")
	
	if scroll_container is ScrollContainer:
		assert_eq(scroll_container.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED, "Horizontal scrolling should be disabled")
		assert_eq(scroll_container.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_AUTO, "Vertical scrolling should be enabled")
		
	_teardown_scene()""",
"""func test_no_scroll_container_properties() -> void:
	_setup_scene()
	scene._ready()
	
	var scroll_container = scene.get_node_or_null("MarginContainer/VBoxContainer/ScrollContainer")
	assert_true(scroll_container == null, "ScrollContainer should no longer exist to prevent scrollbars")
		
	var cards_container = scene.get_node_or_null("MarginContainer/VBoxContainer/CardsContainer")
	assert_true(cards_container != null, "CardsContainer should exist directly inside VBoxContainer")
	assert_eq(cards_container.size_flags_horizontal, Control.SIZE_EXPAND_FILL, "Should expand horizontally")
	
	_teardown_scene()""")

with open(path, "w", encoding="utf-8", newline="\n") as f:
    f.write(text)
