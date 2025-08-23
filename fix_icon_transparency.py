#!/usr/bin/env python3
from PIL import Image
import os

def make_transparent_icon(input_path, output_path):
    """Remove white background and make it transparent"""
    img = Image.open(input_path).convert("RGBA")
    
    # Get image data
    data = img.getdata()
    
    # Create new data with transparency
    new_data = []
    for item in data:
        # If pixel is white or close to white, make it transparent
        if item[0] > 240 and item[1] > 240 and item[2] > 240:
            new_data.append((255, 255, 255, 0))  # Transparent
        else:
            new_data.append(item)  # Keep original
    
    # Update image data
    img.putdata(new_data)
    img.save(output_path, "PNG")
    print(f"Created transparent icon: {output_path}")

# Process all icon sizes
icon_dir = "/Users/javenfang/Downloads/AppIcons/Assets.xcassets/AppIcon.appiconset/"
sizes = [16, 32, 64, 128, 256, 512, 1024]

for size in sizes:
    input_file = os.path.join(icon_dir, f"{size}.png")
    output_file = os.path.join(icon_dir, f"{size}_transparent.png")
    
    if os.path.exists(input_file):
        make_transparent_icon(input_file, output_file)
        # Replace original with transparent version
        os.rename(output_file, input_file)

print("All icons have been made transparent!")