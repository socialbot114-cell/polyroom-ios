"""Render thumb 256px transparente (chamado pelo PIPELINE). Uso:
blender -b art-source/X.blend -o thumbnails/<id>_ --python tools/render_thumb.py -f 1
"""
try:
    import bpy
    s = bpy.context.scene
    s.render.resolution_x = 256
    s.render.resolution_y = 256
    s.render.film_transparent = True
    s.render.image_settings.file_format = "PNG"
    print("thumb config OK")
except ImportError:
    print("fora do Blender")
