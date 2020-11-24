#!/usr/bin/env Rscript

suppressPackageStartupMessages(
  {
    library(jsonlite)
    library(tidyverse)
    library(fs)
    library(janitor)
    library(rebus)
    library(rnrfa)
    library(leaflet)
  }
)

#options(tibble.print_max = Inf)

completed <- read_json("data/tasks.json") %>%
  enframe(name = NULL) %>%
  unnest_wider(value) %>%
  unnest(cols = c(info, links)) %>%
  mutate(across(where(is.list), as.character)) %>%
  mutate(axe_id = str_extract(info, lookbehind("/") %R% "[0-9ab]+" %R% lookahead("-"))) %>%
  select(url = info, task_id = id, axe_id)

field_types <- read_csv("data/info-ids.csv", col_types = cols(.default = "c"))

sheets_uncorrected <- dir_ls("data/micropasts", glob = "*.json") %>%
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

correction_sheet <- read_csv("data/correction-sheet.csv",
                             col_types = cols(.default = "c"),
                             na = character())

sheets <- sheets_uncorrected %>%
  left_join(correction_sheet, by = c("axe_id", "info_id")) %>%
  mutate(value = if_else(is.na(new_value), value, new_value)) %>%
  select(-new_value)

info_long <- sheets %>%
  filter(field_type == "info") %>%
  select(-field_type, -user_idip)

cat("Duplicates:\n")
info_long %>%
  group_by(axe_id, task_id, info_id) %>%
  add_tally(sort = TRUE) %>%
  filter(n > 1)

info_wide <- info_long %>%
  pivot_wider(names_from = info_id, values_from = value) %>%
  rename(.condition = condition)

#making new tibble with corrected condition names
conditions <- info_wide %>% distinct(.condition) %>%
  mutate(condition = case_when(
    str_detect(tolower(.condition), "frag") ~ "fragment",
    str_detect(tolower(.condition), "comp") ~ "complete",
    str_detect(tolower(.condition), "rough") ~ "roughout",
    str_detect(.condition, "reworked") ~ "reworked",
    TRUE ~ tolower(.condition)
  ))

measurements <- sheets %>%
  # filter(axe_id == "60104") %>%
  filter(field_type == "measurement") %>%
  select(-field_type, -user_idip, -task_id) %>%
  #group_by(axe_id, task_id, info_id) %>%
  #add_tally(sort = TRUE) %>%
  rename(.measurement = value) %>%
  mutate(measurement = suppressWarnings(
    .measurement %>%
           str_remove("\\[[.a-zA-Z 0]+\\]") %>%
           str_remove_all(" \\. ") %>%
           str_extract("[\\-0-9,.]+") %>%
           str_remove_all("[^[0-9.]]") %>%
           as.numeric())
    ) %>%
  select(-.measurement) %>%
  rename(feature = info_id) %>%
  pivot_wider(names_from = feature, values_from = measurement)

safe_osg_parse <- safely(osg_parse)

neo_axes_coords <- info_wide %>%
  select(axe_id, ngr) %>%
  filter(ngr != "unprov.") %>%
  mutate_at("ngr", str_replace, "unprov.", "50 50") %>%
  mutate_at("ngr", str_replace_all, "\\s", "") %>%
  # filter(!is.na(ngr)) %>%
  mutate(safe_parse = map(.x = ngr,
                          .f = ~ safe_osg_parse(.x, "WGS84")),
         result = map(.x = safe_parse,
                      .f = "result")) %>%
  unnest(result) %>%
  group_by(axe_id) %>%
  mutate(key = row_number()) %>%
  pivot_wider(id_cols = axe_id, names_from = "key", values_from = "result") %>%
  rename(lon = `1`, lat = `2`) %>%
  unnest(cols = c(lat, lon)) %>%
  ungroup()

#leaflet(data = neo_axes_coords) %>% 
  #addTiles() %>%
  #addMarkers(~lon, ~lat, popup = ~paste(lat, lon), label = ~axe_id)

neo_axes <- info_wide %>%
  left_join(neo_axes_coords, by = "axe_id") %>%
  left_join(conditions, by = ".condition") %>%
  left_join(measurements, by = "axe_id") %>%
  select(-.condition)

write_excel_csv(neo_axes, "data/micropasts-neoaxes1.csv", na = "")
