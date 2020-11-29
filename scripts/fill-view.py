#!/usr/bin/env python

import cv2
import numpy as np
import pandas as pd
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('view', help='axe view jpg')
parser.add_argument('filled', help='filled axe view jpg')
args = parser.parse_args()

image = cv2.imread(args.view)
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
outlines = image.copy()

img = cv2.fastNlMeansDenoising(gray,None, 1, 7, 21)

clahe = cv2.createCLAHE(clipLimit=1, tileGridSize=(10,10))
cl1 = clahe.apply(img)

thresh, prof_thresh = cv2.threshold(cl1, 250, 255, cv2.THRESH_BINARY_INV)

kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(8,8))
dilated = cv2.dilate(prof_thresh, kernel, iterations=2)

contours, hierarchy = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

contour_list = []
for contour in contours:
    approx = cv2.approxPolyDP(contour,0.01*cv2.arcLength(contour,True),True)
    area = cv2.contourArea(contour)
    if ((len(approx) > 4) & (area > 60) ):
        contour_list.append(contour)

outlines_copy = outlines.copy()
        
cv2.drawContours(outlines_copy, contour_list, -1, (0,0,0), thickness=cv2.FILLED)

maxcont = max(contours, key = cv2.contourArea)
x,y,w,h = cv2.boundingRect(maxcont)
        
large_cont = []

for cont in contours:
    if cv2.contourArea(cont) >= cv2.contourArea(maxcont):
        large_cont.append(cont)
        
image_copy = image.copy()

cv2.drawContours(image_copy, large_cont, -1, (0,0,0), thickness=cv2.FILLED)

thresh, outlines_thresh = cv2.threshold(image_copy, 250, 255, cv2.THRESH_BINARY_INV)

closing = cv2.morphologyEx(outlines_thresh, cv2.MORPH_OPEN, kernel, iterations=10)

silhouette = cv2.bitwise_not(closing)

cv2.imwrite(args.filled, silhouette)
