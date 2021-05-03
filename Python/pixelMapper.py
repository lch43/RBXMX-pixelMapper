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
        #all of the loops are perfectly fine as in most cases they will only
        #find one object.

        #From what I have experienced, the order the objects are in the xml
        #document are first based on parents, and then based on the order
        #each object was created. So going through the document in this manner
        #seems to work perfectly fine. If this gives issues, please reach out
        #and I will find a more perfect solution.

        #Start at root - roblox
        root = tree.getroot()
        #Search through all <roblox>\<item>
        for item in root.findall("Item"):
            #See if you found <roblox>\<Item class="Folder">
            if item.get('class') == 'Folder':
                #Search through all <roblox>\<Item class="Folder">\<item>
                for item2 in item.findall("Item"):
                    #If we find a string value
                    if item2.get('class') == 'StringValue':
                        #Go into the properties of each string value
                        for prop in item2.findall('Properties'):
                            #Find all <string>s inside of  each StringValue. One is the name, and other is the value
                            for string in prop.findall('string'):
                                #If <string name="Value"> then we can extract the data
                                if string.get("name") == 'Value':
                                    #Extract the data.
                                    data.append(string.text)
                break
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

