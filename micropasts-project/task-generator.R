#!/usr/bin/env Rscript

library(tidyverse)
library(fs)

prefix <- "https://leigh-nugent.github.io/neo-axes-transcribe/"

tasks <- read_csv("pairs-sorted.csv", col_types = cols(.default = "c")) %>%
  filter(folder == "sheets") %>%
  mutate(url_b = paste0(prefix, path)) %>%
  select(url_b)

write_csv(tasks, "tasks/paired-no-collision-tasks.csv", na = "")
