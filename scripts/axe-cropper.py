#!/usr/bin/env python

import cv2
#import numpy as np
import pandas as pd
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('coords', help='axe drawing boxes coordinates csv')
parser.add_argument('cropped', help='cropped axe drawing jpg')
args = parser.parse_args()

df = pd.read_csv(args.coords)
view = df.loc[df.view == args.cropped]

img = cv2.imread(view.drawing.item())

start_row = view.y.item()
end_row = view.y.item() + view.h.item()
start_col = view.x.item()
end_col = view.x.item() + view.h.item()

cropped = img[start_row:end_row,start_col:end_col]

cv2.imwrite(view.view.item(), cropped)
