library(fs)
library(tidyverse)
library(Momocs)
library(factoextra)

views <- dir_ls("drawings", glob = "*-c.csv") %>%
  map_dfr(read_csv, col_types = cols(.default = "c")) %>%
  group_by(drawing) %>%
  add_tally()

three_plan <- views %>%
  filter(n == 3, view == "plan") %>%
  ungroup() %>%
  select(filename) %>%
  mutate(filled = str_replace(filename, "\\.jpg", "-fill\\.jpg")) %>%
  pull(filled)

plans <- import_jpg(three_plan)

outlines <- Out(plans)

panel(outlines)

ef <- efourier(outlines, 12, norm=FALSE)

pca <- PCA(ef)
plot(pca, names=TRUE)

kmeans <- KMEANS(pca, centers = 4,
                 algorithm = "Hartigan-Wong")

panel(outlines, fac=as.factor(kmeans$cluster), names=as.factor(kmeans$cluster))

