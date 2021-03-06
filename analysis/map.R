library(tidyverse)
library(sf)
library(pricingtutorial)
library(leaflet)

exposures_by_hasc <- risks_table_mapped %>%
  mutate(hasc = paste0("BR.", substr(region, 1, 2))) %>%
  group_by(hasc) %>%
  summarize(exposures = sum(exposure))

bra_layer0 <- sf::st_read("external_data/gadm36_BRA_gpkg/gadm36_BRA.gpkg", layer = "gadm36_BRA_0")
bra_layer1 <- sf::st_read("external_data/gadm36_BRA_gpkg/gadm36_BRA.gpkg", layer = "gadm36_BRA_1")

bra_layer0 <- bra_layer0 %>% rmapshaper::ms_simplify()
bra_layer1 <- bra_layer1 %>% rmapshaper::ms_simplify()

brazil <- bra_layer1 %>%
  left_join(exposures_by_hasc, by = c(HASC_1 = "hasc"))

bins <- c(0, 10^3,10^4, 10^5, 10^6, Inf)
pal <- colorBin("YlOrRd", domain = brazil$exposures, bins = bins)

bra_bbox <- sf::st_bbox(bra_layer1) %>% unname()

earth <-sf::st_polygon(list(rbind(
  c(360, -360),
  c(360, 360),
  c(-360, 360),
  c(-360, -360),
  c(360, -360)
))) %>%
  sf::st_sfc(crs = sf::st_crs(bra_layer0), check_ring_dir = T) %>%
  sf::st_sf()


bra_cutout <- sf::st_difference(earth, bra_layer0)

labels <- paste0("<b>",brazil$NAME_1,"</b><br>","Exposures: ", scales::comma(brazil$exposures))

brazil %>%
  leaflet(options = leafletOptions(minZoom = 4)) %>%
  addTiles() %>%
  addPolygons(
    data = bra_cutout,
    weight  = 0,
    opacity = 1,
    color = "white",
    fillOpacity = 1
  ) %>%
  addPolygons(
    fillColor = ~pal(exposures),
    weight = 2,
    opacity = 1,
    color = "white",
    dashArray = "3",
    fillOpacity = 0.7,
    label = lapply(labels, htmltools::HTML),
    highlight = highlightOptions(
      weight = 5,
      color = "#666",
      dashArray = "",
      fillOpacity = 0.7,
      bringToFront = TRUE)
  ) %>%
  setMaxBounds(bra_bbox[1], bra_bbox[2], bra_bbox[3], bra_bbox[4]) %>%
  setView(mean(bra_bbox[c(1,3)]), mean(bra_bbox[c(2,4)]), zoom = 4)
