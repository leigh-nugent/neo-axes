library(jsonlite)
library(tidyverse)
library(fs)
library(magrittr)
library(rebus)

#options(tibble.print_max = Inf)

completed <- read_json("tasks.json") %>%
  enframe(name = NULL) %>%
  unnest_wider(value) %>%
  unnest(cols = c(info, links)) %>%
  mutate(across(where(is.list), as.character)) %>%
  mutate(axe_id = str_extract(info, lookbehind("/") %R% "[0-9ab]+" %R% lookahead("-"))) %>%
  select(url = info, task_id = id, axe_id)
  
sheets <- dir_ls("micropasts", glob = "*.json") %>%
  map(read_json) %>%
  flatten() %>%
  enframe() %>%
  unnest_wider(value) %>%
  left_join(completed, by = "task_id") %>%
  select(axe_id, task_id, id,  info) %>%
  unnest_longer(info, values_to = "value") %>%
  arrange(task_id, id, info_id) %>%
  group_by(task_id) %>%
  filter(id == max(id)) %>%
  pivot_wider(names_from = info_id)
  # select(task_id, info_id, value)