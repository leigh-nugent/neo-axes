#!/usr/bin/env Rscript

library(tidyverse)
library(fs)
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

#converting to outlines to examine
plans_uncorrected <- import_jpg(three_plan)

outlines_uncorrected <- Out(plans_uncorrected)

write_rds(outlines_uncorrected, "data/outlines.Rds")
