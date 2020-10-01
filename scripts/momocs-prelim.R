library(fs)
library(tidyverse)
library(Momocs)

#getting image ids
views <- dir_ls("drawings", glob = "*-c.csv") %>%
  map_dfr(read_csv, col_types = cols(.default = "c")) %>%
  group_by(drawing) %>%
  add_tally()

#finding only the plans from axes which have 3 views
three_plan <- views %>%
  filter(n == 3, view == "plan") %>%
  ungroup() %>%
  select(filename) %>%
  mutate(filled = str_replace(filename, "\\.jpg", "-fill\\.jpg")) %>%
  pull(filled)

#import to momocs
plans <- import_jpg(three_plan)

#convert to momocs outline/Out class
outlines <- Out(plans)

#plots all outlines
panel(outlines)

outlines %>% stack()

#preliminary normalization steps
aligned <- coo_aligncalliper(outlines)

homog_coo <- coo_sample(aligned, n=40)

homog_coo$ldk <- Ldk(homog_coo)

#checking harmonic power, how many to use in ef
ef_first <- efourier(outlines[1], 12, norm=FALSE)

ef_mid <- efourier(aligned[599], 12, norm=FALSE)

plot(cumsum(harm_pow(ef_first)[-1]), type='o',
     main='Cumulated harmonic power without the first harmonic',
     ylab='Cumulated harmonic power', xlab='Harmonic rank')

#analysis

ef <- efourier(outlines, 4)
ef_aligned <- efourier(aligned, 4, norm=FALSE)
ef_homog <- efourier(homog_coo, 4, norm=FALSE)

coo_oscillo(aligned[500], "efourier")

pca <- PCA(ef_homog)
plot_PCA(pca)

kmeans <- KMEANS(pca, centers = 2,
                 algorithm = "Hartigan-Wong")

#plots all outlines with clusters coloured
panel(homog_coo, fac=as.factor(kmeans$cluster), names=as.factor(kmeans$cluster))
panel(slice(homog_coo, 599:1198), fac=as.factor(kmeans$cluster), names=as.factor(kmeans$cluster))


