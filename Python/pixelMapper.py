import sys
import os
import xml.etree.ElementTree as ET
from PIL import Image
import numpy as np

def isInt(s):
    try:
        i = int(s)
        return True, i
    except ValueError:
        return False

try:
    droppedFile = sys.argv[1]
    splitFile = os.path.splitext(droppedFile)

    if splitFile[len(splitFile)-1] == '.rbxmx':
        tree = ET.parse(droppedFile)
        data = []
        pixelData = []

        #If the data is not manipulated before being exported from roblox then
        #assuming strings with the attribute name="Value" should be safe to assume it is a part of the data we need to collect
        #We are also assuming that roblox adds them to the xml file in the order that they are created which seems to be the case
        #though if I am wrong I will have to find a work around, which would be based off the name of the StringValues

        for string in tree.iter("string"):
            if string.get("name") == 'Value':
                #Extract the data.
                data.append(string.text)

        #Remove the image resolution data and make it into its own list
        resolution = data.pop(0).split(',')

        #Go through the data and break it down into a 2D list.
        row = []
        for dataString in data:
            for subData in dataString.split(','):
                if subData != '':
                    splitData = subData.split('/')
                    pixel = (0,0,0,0)

                    if splitData[0] != 'N':
                        pixel = (splitData[0],splitData[1],splitData[2],255)
                    if len(row) >= int(resolution[0]):
                        pixelData.append(row)
                        row = []
                    row.append(pixel)
        if len(row) >= int(resolution[0]):
            pixelData.append(row)
            row = []

        #Format the list into an array compatible with Pillow's Image.fromarray()
        img = Image.fromarray(np.asarray(pixelData, dtype=np.uint8))
        #Save the image.
        img.save(splitFile[len(splitFile)-2] + '.png')

        print('Image saved as ' + splitFile[len(splitFile)-2] + '.png')

        #Give option to resize image.
        width, height = img.size
        print('Image resolution in pixels is ' + str(width) + 'x' + str(height))
        print('Would you like to resize?')
        response = ''
        while (response.lower() == 'y' or response.lower() == 'n') == False:
            response = input('Enter y for yes. Enter n for no.\n')
        if response == 'y':
            response = input('Enter integer of pixels greater than 0 in the X direction.\n')
            intResponse = isInt(response)
            while intResponse[0] == False:
                response = input('Enter integer of pixels greater than 0 in the X direction.\n')
                intResponse = isInt(response)
            width = intResponse[1]

            response = input('Enter integer of pixels greater than 0 in the Y direction.\n')
            intResponse = isInt(response)
            while intResponse[0] == False:
                response = input('Enter integer of pixels greater than 0 in the Y direction.\n')
                intResponse = isInt(response)
            height = intResponse[1]

            resolution = (width, height)
            img2 = img.resize(resolution, resample= Image.NEAREST)
            img2.save(splitFile[len(splitFile)-2] + '-' + str(width) + 'x' + str(height) + '.png')
            print('Image saved as ' + splitFile[len(splitFile)-2] + '-' + str(width) + 'x' + str(height) + '.png')
    else:
        print('Ensure you are passing a .rbxmx file')

except IndexError as err:
    print('OS error: {0}'.format(err))
    print('If you are confused, please reach out to myself or to my devforum post.')

