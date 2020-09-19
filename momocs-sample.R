library(Momocs)

lf <- list.files('filled-drawing-sample', full.names=TRUE)
lfp <- list.files('filled-drawing-sample/plan', full.names=TRUE)

axes <- import_jpg(lf)
plans <- import_jpg(lfp)

#Out(axes)

coo_plot(axes[30])

outlines <- Out(axes)
planout <- Out(plans)

panel(outlines, names=TRUE) 
panel(planout, names=TRUE)

ef <- efourier(outlines, 12, norm=FALSE)
efpl <- efourier(planout, 12, norm=FALSE)

coo_oscillo(outlines[8], "efourier")

pca <- PCA(ef)
plot(pca)

KMEANS(pca, centers = 5)

pcaplans <- PCA(efpl)
plot(pcaplans, names=TRUE)

KMEANS(pcaplans, centers = 3)

harm_pow(efpl)

