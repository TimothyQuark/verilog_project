# -*- coding: utf-8 -*-

from PIL import Image

source_img = Image.open('example_file.bmp')
(width, height) = source_img.size

pixels = source_img.load()
# This reduces to 12 bit precision (4 bit per color) in range 0-15. Remainder is truncated
for x in range(width):
    for y in range(height):
        pixels[x,y] = tuple([p // 16 for p in pixels[x,y]])
        

# Basically we have taken the colors for each pixel and added to a list
#. Every 3 terms is one pixel, and it has been converted to hex
pixel_col = []
for y in range(height):
    for x in range(width):
        temp = pixels[x,y]
        bin_terms = []
        for col in temp:
            if col <= 1:
                bin_terms.append('000' + str(format(col, 'b')))
            elif col <= 3:
                bin_terms.append('00' + str(format(col, 'b')))
            elif col <= 7:
                bin_terms.append('0' + str(format(col, 'b')))
            else:
                bin_terms.append(str(format(col, 'b')))
        comb = str(bin_terms[0]) + str(bin_terms[1]) + str(bin_terms[2])
        pixel_col.append(comb)

        
#Convert to hex so that it can be read
hex_col = []
for col in pixel_col:
    hex_pix = 0
    hex_pix = hex(int(col, 2))
        
    hex_col.append(hex_pix)
    

with open('example_output' + '.mem', 'w') as f:
    for line in hex_col:
        if line != '0x0': # Strange exception where the hex converter would leave a blank line in memory instead of the intended hex value if value = 0
            f.write(str(line).lstrip('0x') + '\n')
        else:
            f.write(str(0) + '\n')
        
