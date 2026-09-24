extends SceneTree

func _init():
    var font_path = "res://assets/fonts/NotoSansSymbols-Regular.ttf"
    var theme_path = "res://resources/theme_1930s.tres"
    
    var font = load(font_path)
    if not font:
        print("Failed to load font")
        quit(1)
        return
        
    var theme = load(theme_path) as Theme
    if not theme:
        print("Failed to load theme")
        quit(1)
        return
    
    # We want to add it as a fallback for buttons and labels.
    # Button font: SystemFont_button
    var btn_font = theme.get_font("font", "Button")
    if btn_font is SystemFont:
        var fallbacks = btn_font.fallbacks
        if not font in fallbacks:
            fallbacks.append(font)
            btn_font.fallbacks = fallbacks
            print("Added to Button font fallbacks")
            
    # Labels don't have a default font, but they use clu_font, input_font etc.
    # Let's set it as default font, or add to SystemFont_vdruh etc.
    var label_fonts = ["clue_font", "input_font", "note_font", "note_font_bold"]
    for fname in label_fonts:
        if theme.has_font(fname, "Label"):
            var lf = theme.get_font(fname, "Label")
            if lf is SystemFont:
                var fallbacks = lf.fallbacks
                if not font in fallbacks:
                    fallbacks.append(font)
                    lf.fallbacks = fallbacks
                    print("Added to Label font: ", fname)
                    
    # Ensure Label/fonts/font is explicitly set so Undo/Redo icons inherit it
    theme.set_font("font", "Label", btn_font)
    
    ResourceSaver.save(theme, theme_path)
    print("Theme saved successfully.")
    quit(0)
