library(jsonlite)
library(tidyverse)
library(fs)
library(magrittr)
library(rebus)
library(janitor)
library(rnrfa)
library(ggmap)
library(dotenv)
library(leaflet)

micropasts <- read_csv("micropasts-neoaxes1.csv")

safe_osg_parse <- safely(osg_parse)

neo_axes_coords <- micropasts %>%
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

missing_ngr <- anti_join(micropasts, neo_axes_coords, by = "axe_id")

write_excel_csv(missing_ngr, "missing-ngrs.csv", na = "")

leaflet(data = neo_axes_coords) %>% 
  addTiles() %>%
  addMarkers(~lon, ~lat, popup = ~paste(lat, lon), label = ~axe_id)
