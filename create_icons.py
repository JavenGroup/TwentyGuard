#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont

def create_20_icon(size):
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Set colors
    bg_color = (0, 0, 0, 255)  # Black background
    text_color = (255, 255, 255, 255)  # White text
    
    # Draw rounded rectangle background
    margin = size // 10
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=size // 8,
        fill=bg_color
    )
    
    # Calculate font size (roughly 60% of image height)
    font_size = int(size * 0.6)
    
    try:
        # Try to use system font
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        # Fallback to default font
        font = ImageFont.load_default()
    
    # Draw "20" text
    text = "20"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center the text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - bbox[1]
    
    draw.text((x, y), text, font=font, fill=text_color)
    
    return img

# Create different sizes
sizes = [16, 32, 64, 128, 256, 512, 1024]
output_dir = "/Users/javenfang/Coding/20-20-20/Sources/TwentyTwentyTwenty.xcassets/AppIcon.appiconset/"

for size in sizes:
    icon = create_20_icon(size)
    filename = f"app-icon-{size}.png"
    icon.save(os.path.join(output_dir, filename))
    print(f"Created {filename}")

print("All icons created successfully!")