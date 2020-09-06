#! /usr/bin/env Rscript

library(tidyverse)
library(fs)
library(rebus)
library(here)

images <- dir_info(here("extracted-jpgs"),
                   recurse = TRUE,
                   type = "file",
                   glob = "*.jpg") %>%
  select(path)

images_meta <- images %>%
  mutate(folder = str_extract(path, "flint|stone"),
         basename = basename(path),
         no = str_extract(basename, "^[0-9a-b]*(?=-)")) %>%
  arrange(no, path) %>%
  group_by(no) %>%
  add_tally()

images_meta %>% distinct(no) %>% nrow()

images_meta %>% distinct(folder, no) %>% nrow()

images_meta %>% distinct(basename) %>% nrow()

discrepancies <- read_csv(here("data/discrepant-axe-info.csv")) %>%
  select(-id, -n)

collisions <- images_meta %>%
  filter(n > 2 | n < 1) %>%
  mutate_at("path", as.character) %>%
  left_join(discrepancies, by = "path")

pairs <- images_meta %>%
  filter(n == 2) %>%
  select(no, path) %>%
  mutate(sheet = row_number())

copy_rename <- pairs %>%
  ungroup() %>% as.data.frame() %>%
  mutate(type = if_else(sheet == 1, "sheets", "drawings"),
         base = basename(path),
         base_rename = paste(no, "jpg", sep = "."),
         new_path = str_replace(path, "extracted-jpgs/(flint|stone)", type) %>%
           str_replace(base, base_rename))

# dir_create(c("sheets", "drawings"))
# 
# file_copy(copy$path, copy$sheets_path)

# then images were manually moved to correct folders

pairs_sorted <- dir_info(c(here("drawings"), here("sheets"))) %>%
  select(path) %>%
  mutate(folder = str_extract(path, "drawings|sheets"),
         basename = basename(path),
         no = str_extract(basename, "^[0-9a-b]*(?=\\.jpg)"),
         relative_path = str_remove(path, paste0(here(), "/"))) %>%
  arrange(no) %>%
  select(no, folder, relative_path)

# post_rename <- pairs_sorted %>%
#   mutate(base_rename = paste(no, "jpg", sep = "."),
#          new_path = str_replace(path, basename, base_rename))
# 
# file_move(post_rename$path, post_rename$new_path)

# if all numbers matched should return 0 row tibble:
pairs_sorted %>%
  select(relative_path, folder, no) %>%
  pivot_wider(names_from = folder,
              values_from = relative_path) %>%
  filter(is.na(drawings) | is.na(sheets))

write_csv(pairs_sorted, "pairs-sorted.csv", na = "")
