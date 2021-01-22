# MSc dissertation: 'Exploring shape and size in British Neolithic axes: new methods on old data'

**Abstract:** British Neolithic axes, due to their numerousness and long survivability, provide a wealth of evidence with which to study non-subsistence productionand trade in this period. They have long been ubiquitous in archaeological literature, however one aspect about these pervasive tools which has rarely been explored is their differing morphology. In addition, much archaeological data is paper-based or not digitised, and most likely lies unused in national or personal archives. This paper sets out to extract data from an old analogue dataset containing information about a large sample of British Neolithic axes, and attempts to use this to investigate potential groups based on their shape and size, in addition to carrying out everything reproducibly.  Firstly data was extracted using crowdsourcing to transcribe record sheets and image processing techniques to digitise technical sketches. The sheet data, containing measurements, was then subjected to PCA and k-means clustering, and the processed images were Fourier-transformed and subjected to the same statistics.  The results of these analyses suggest that groups of similarly shaped axes exist within this sample. Further, this dissertation demonstrates a reproducible workflow which can be used for large projects built with substantial software.

## Introduction

This project has been made entirely reproducible using renv, venv, Docker and Makefile. It extracts data from an analog dataset created by Mike Pitts (Pitts 1996) and then uses this data for analysis. 

## Getting it to run

Clone the repository, then run `make build` followed by `make run`.

## Main aspects

### Data extraction

For the axe measurement data, transcriptions of the record sheets were sourced using MicroPasts (crowdsourced.micropasts.org), which are downloaded by the subsidiary `Makefile` (`micropasts.mk`) as 19 jsons containing data for 1825 record sheets. This data is then cleaned by `sheets.R`, which uses `correction-sheet.csv` to amend any incorrect data or typos. The final dataset created by `sheets.R` is `micropasts-neoaxes1.csv`, the filename being the name of my MicroPasts project. 

The axe drawings, of which there are also 1825 and are paired with the sheets, needed to be processed into binary silhouettes for use with `Momocs` outline morphometrics package. This was done using `opencv-python`. As each drawing contains multiple shapes (different views of the same axe), and only the front view was needed, the images needed to be cropped into separate shapes. The process for creating the silhouettes is as follows: first, the contours of each shape were found, then from these the bounding boxes could be found, and the coordinates saved to a csv per drawing; then each image is cropped on these coordinates by the `Makefile` using `imagemagick`; and finally each front view is then filled. If you would like to see the code and its output step-by-step, please check out `opencv-cropping.ipynb` and `fill-axe-outlines.ipynb`.

### The data

The extraction stage produces `micropasts-neoaxes1.csv`, which has had some data changed from the original record sheets due to discrepancies noticed in the raw data collection; and `outlines.Rds`, which is an R object created from importing the filled front images into `Momocs` and converting them into the data type supported by that package. The latter was performed outside of the R Markdown analysis file as it was rather computationally intensive and inhibited fast knitting.

