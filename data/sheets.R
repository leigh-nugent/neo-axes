#!/usr/bin/env Rscript

library(jsonlite)
library(tidyverse)
library(fs)
library(magrittr)
library(rebus)
library(janitor)
library(rnrfa)
library(ggmap)
library(dotenv)

#options(tibble.print_max = Inf)

completed <- read_json("tasks.json") %>%
  enframe(name = NULL) %>%
  unnest_wider(value) %>%
  unnest(cols = c(info, links)) %>%
  mutate(across(where(is.list), as.character)) %>%
  mutate(axe_id = str_extract(info, lookbehind("/") %R% "[0-9ab]+" %R% lookahead("-"))) %>%
  select(url = info, task_id = id, axe_id)

field_types <- read_csv("info-ids.csv")

sheets_uncorrected <- dir_ls("micropasts", glob = "*.json") %>%
  map(read_json) %>%
  flatten() %>%
  enframe() %>%
  unnest_wider(value) %>%
  left_join(completed, by = "task_id") %>%
  unite(user_idip, c(user_id, user_ip), na.rm = TRUE) %>%
  mutate(across("user_idip", str_remove, "NA_")) %>%
  select(user_idip, axe_id, task_id, id, info) %>%
  unnest_longer(info, values_to = "value") %>%
  arrange(task_id, id, info_id) %>%
  group_by(task_id) %>%
  filter(id == max(id)) %>%
  ungroup() %>%
  select(user_idip, axe_id, task_id, info_id, value) %>%
  left_join(field_types, by = "info_id") %>%
  arrange(axe_id, field_type)

correction_sheet <- read_csv("correction-sheet.csv",
                             col_types = cols(.default = "c"),
                             na = character())

sheets <- sheets_uncorrected %>%
  left_join(correction_sheet, by = c("axe_id", "info_id")) %>%
  mutate(value = if_else(is.na(new_value), value, new_value)) %>%
  select(-new_value)

info <- sheets %>%
  filter(field_type == "info") %>%
  select(-field_type) %>%
  pivot_wider(names_from = info_id, values_from = value) %>%
  rename(.condition = condition)

#making new tibble with corrected condition names
conditions <- info %>% distinct(.condition) %>%
  mutate(condition = case_when(
    str_detect(tolower(.condition), "frag") ~ "fragment",
    str_detect(tolower(.condition), "comp") ~ "complete",
    str_detect(tolower(.condition), "rough") ~ "roughout",
    str_detect(.condition, "reworked") ~ "reworked fragment",
    TRUE ~ tolower(.condition)
  ))

measurements <- sheets %>%
  # filter(axe_id == "60104") %>%
  filter(field_type == "measurement") %>%
  select(-field_type) %>%
  rename(.measurement = value) %>%
  mutate(measurement = .measurement %>%
           str_remove("\\[[.a-zA-Z 0]+\\]") %>%
           str_remove_all(" \\. ") %>%
           str_extract("[\\-0-9,.]+") %>%
           str_remove_all("[^[0-9.]]") %>%
           as.numeric()) %>%
  mutate(measurement = if_else(task_id == "96456" & info_id == "lefedwid", 20, measurement)) %>%
  select(-user_idip, -task_id, -.measurement) %>%
  rename(feature = info_id) %>%
  pivot_wider(names_from = feature, values_from = measurement)

neo_axes <- info %>%
  left_join(conditions, by = ".condition") %>%
  left_join(measurements, by = "axe_id") %>%
  select(-.condition)

write_excel_csv(neo_axes, "micropasts-neoaxes1.csv", na = "")
