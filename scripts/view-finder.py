#!/usr/bin/env python

import cv2
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('image', help='axe drawing jpg')
parser.add_argument('coords', help='axe drawing boxes coordinates csv')
args = parser.parse_args()

image = args.image
coords = args.coords

#read image and convert to grey
drawing = cv2.imread(image)
imgray = cv2.cvtColor(drawing, cv2.COLOR_BGR2GRAY)

#detect edges of drawings with Canny, note the very low threshold
edge_detected_image = cv2.Canny(imgray, 1, 100)

#find contours using dilated version of edge detected image with thicker lines
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(9,9))
dilated = cv2.dilate(edge_detected_image, kernel)
contours, hierarchy = cv2.findContours(dilated.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
outlines = drawing.copy()

#draw the contours onto the axe angles, trying to find curves
contour_list = []
for contour in contours:
    approx = cv2.approxPolyDP(contour,0.01*cv2.arcLength(contour,True),True)
    area = cv2.contourArea(contour)
    if ((len(approx) > 4) & (area > 60) ):
        contour_list.append(contour)

#get list of boxes
boxes = []
contour_areas = []
for c in contours:
    rect = cv2.boundingRect(c)
    if rect[2] < 100 or rect[3] < 100: continue
    x,y,w,h = rect
    list(rect)
    boxes.append(rect)
    area = cv2.contourArea(c)
    contour_areas.append(area)

#convert list of boxes to dataframe for export
boxes_df = pd.DataFrame(boxes, columns=['x', 'y', 'w', 'h'])
boxes_df.index.name = 'index'
boxes_df['drawing'] = image
boxes_df['contour_area'] = contour_areas

#export dataframe to csv with axe number in filename
boxes_df.to_csv(coords)
