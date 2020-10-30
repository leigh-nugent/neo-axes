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

ids <- three_plan %>% str_extract("[0-9]{2,}[ab]*")

#import to momocs
plans <- import_jpg(correct_files)

#convert to momocs outline/Out class
outlines <- Out(plans)

#plots all outlines to check for unsuccessful fills
panel(outlines, names = as.factor(no_errors$id))
panel(outlines)

errors <- c("10034", "10036", "10037", "10040", "10055", "10125", "10148", "10149",
            "10199", "10229", "10429", "10427", "10421", "10418", "10459", "10461",
            "10490", "10519", "10521", "10525", "10564", "10571", "10600", "10610",
            "10628", "10634", "10896", "11038", "11128", "20001", "20012", "50016",
            "50031", "50054", "50057", "50129", "60064", "60090", "60048", "60097",
            "60106", "60140", "60145", "60147", "60153", "60182", "60201", "60208", 
            "60211", "60212", "61014", "61025", "70052", "71002", "71004", "81008", 
            "81012", "10406", "10157", "10160", "10006", "50047")

axe_lookup <- three_plan %>% 
  enframe(name = NULL) %>%
  mutate(id = ids) %>%
  rename(file = value)

no_errors <- axe_lookup[!axe_lookup$id %in% errors, ]

correct_files <- no_errors$file

#aligning
aligned <- coo_aligncalliper(outlines)

set.seed(123)
id_random <- sample(x=min(sapply(aligned$coo, nrow)), size=length(aligned),
                    replace=TRUE)
stack(coo_slide(aligned, id=id_random))
homog <- coo_slide(aligned, id=id_random)

#checking harmonic power, how many to use in ef
ef_first <- efourier(outlines[1], 12, norm=FALSE)

ef_mid <- efourier(outlines[599], 20, norm=FALSE)

plot(cumsum(harm_pow(ef_mid)[-1]), type='o',
     main='Cumulated harmonic power without the first harmonic',
     ylab='Cumulated harmonic power', xlab='Harmonic rank')

#analysis

ef <- efourier(outlines, 20)
ef_norm <- efourier(homog, 20, norm=FALSE)

hcontrib(ef, harm.r = 1:20, col="lavender",
         main="lovely axes")

coo_oscillo(aligned[500], "efourier")

pca <- PCA(ef)
plot(pca)

kmeans <- KMEANS(pca, centers = 4,
                 algorithm = "Hartigan-Wong")

#plots all outlines with clusters coloured
panel(outlines, palette=col_spring, 
      fac=as.factor(kmeans$cluster), names=as.factor(no_errors$id))


