# MSc dissertation: 'Exploring shape and size in British Neolithic axes: new methods on old data'

**Abstract:** British Neolithic axes, due to their numerousness and long survivability, provide a wealth of evidence with which to study non-subsistence productionand trade in this period. They have long been ubiquitous in archaeological literature, however one aspect about these pervasive tools which has rarely been explored is their differing morphology. In addition, much archaeological data is paper-based or not digitised, and most likely lies unused in national or personal archives. This paper sets out to extract data from an old analogue dataset containing information about a large sample of British Neolithic axes, and attempts to use this to investigate potential groups based on their shape and size, in addition to carrying out everything reproducibly.  Firstly data was extracted using crowdsourcing to transcribe record sheets and image processing techniques to digitise technical sketches. The sheet data, containing measurements, was then subjected to PCA and k-means clustering, and the processed images were Fourier-transformed and subjected to the same statistics.  The results of these analyses suggest that groups of similarly shaped axes exist within this sample. Further, this dissertation demonstrates a reproducible workflow which can be used for large projects built with substantial software.

## Introduction

This project has been made entirely reproducible using renv, venv, Docker and Makefile. It extracts data from scanned drawings and jsons containing transcribed data from analogue record sheets. The original dataset of record sheets and drawings was created and compiled by Mike Pitts (Pitts 1996).

## Licensing

The GNU General Public License 3.0 on this repository does not apply to the `/drawings` folder. This contains Mike Pitts' original axe drawings, which are not my work. The drawings and the record sheets – the latter not being included in this repository – are hosted on the Implement Petrology Group's website [here](https://implementpetrology.org/resources/mike-pitts-archive/).

## Getting it to run

Clone the repository, then run `make build` followed by `make run`.

## Main aspects

### Data extraction :page_with_curl:

For the axe measurement data, transcriptions of the record sheets were crowdsourced using [MicroPasts](crowdsourced.micropasts.org), which are downloaded by the subsidiary `Makefile` (`micropasts.mk`) as 19 jsons containing data for 1825 record sheets. This data is then cleaned by `sheets.R`, which uses `correction-sheet.csv` to amend any incorrect data or typos. The final dataset created by `sheets.R` is `micropasts-neoaxes1.csv`, the filename being the name of my MicroPasts project. 

The axe drawings, of which there are also 1825 and are paired with the sheets, needed to be processed into binary silhouettes for use with `Momocs` outline morphometrics package. This was done using `opencv-python`. As each drawing contains multiple shapes (different views of the same axe), and only the front view was needed, the images needed to be cropped into separate shapes. The process for creating the silhouettes is as follows: first, the contours of each shape were found, then from these the bounding boxes could be found, and the coordinates saved to a csv per drawing; then each image is cropped on these coordinates by the `Makefile` using `imagemagick`; and finally each front view is then filled. 

If you would like to see the code and its output step-by-step, please check out `appendices/opencv-cropping.ipynb` and `appendices/fill-axe-outlines.ipynb`. There is potential for this method to be repurposed to split other images containing more than one shape into multiple images. In addition, if you are planning to use `Momocs`, this workflow can be repurposed to create silhouettes from other shapes, and also serves as a reproducible way to create them, which is novel.

### The data :floppy_disk:

Extraction stage produces `micropasts-neoaxes1.csv`, which has had some data changed from the original record sheets due to discrepancies noticed in the raw data collection; and `outlines.Rds`, which is an R object created from importing the filled front images into `Momocs` and converting them into the data type supported by that package. The latter was performed outside of the R Markdown analysis file as it was rather computationally intensive and inhibited fast knitting. In addition to provenance information, National Grid Reference,  `micropasts-neoaxes1.csv` has 56 columns relating to different axe measurements such as weight, maximum thickness, length of poll edge, blade angle and so on, which are abbreviated; please see the list of abbreviations in `Dissertation.pdf` if interested in some clarity on these.

### The analysis 📈

Both `micropasts-neoaxes1.csv` and `outlines.Rds` were subjected to comparable multivariate analyses to reveal groups in the axe data and drawings, resulting in some pretty graphs and graphics :sparkles:

The MicroPasts record sheet data was preliminarily explored using univariate density and violin plots, after which principal components analysis (PCA) and k-means clustering were used to reveal potential groups of axes which may exist based on size. To explore which measurements were deciding membership of which cluster, densities of the resulting clusters were plotted, in addition to the clusters being plotted onto the PCA. This half of the analysis used `factoextra` and `ggplot` to generate the plots.

The axe outlines were further inspected for erroneous shapes caused by any flaws in the image processing step (more on this below), then harmonic power and contribution plots were used to determine how many harmonics would be appropriate to use for elliptical Fourier transform. Once all outlines had been converted into lists of four Fourier coefficients, they could then be analysed using PCA and k-means. All plots and graphics in this section were generated using the `Momocs` package.

Finally, the k-means clusters resulting from both halves of the analysis were plotted onto maps of Britain using the National Grid References of the axes in each cluster. `ggmap` and `ggplot` were used for this.

## What else can be done with this code and data?

As mentioned above, the image processing step to extract the axe silhouettes from the original drawings is not perfect, and resulted in 688 incorrect shapes out of 1825. The method for this can definitely be improved, for example by increasing the size of the bounding boxes around the shapes so that some outlines are not truncated. I will be working to improve this so that more data can be extracted from the drawings dataset in the coming months.

A second point is that there are 626 silhouettes which have not been checked due to time constraints for submission of this work. These could potentially have successful silhouettes within them, so checking through these would provide more opportunity for further enlarging the outlines dataset.

Finally, as is also mentioned above, the workflow for processing the binary silhouettes has the potential to be repurposed for other shapes, so please feel free to use this to create your own silhouettes for outline morphometric analysis using `Momocs`. 

## References

Pitts, M. (1996). The stone axe in Neolithic Britain. *Proceedings of the Prehistoric Society*, 62, pp.311–371.

