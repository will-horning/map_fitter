config = {}
config.MAP_CENTER = [38.907, -77.0368]
config.MAP_ZOOM = 11

$(document).ready ->
    map = L.mapbox.map('map', 'examples.map-0l53fhk2', { zoomControl:false })
    map.setView(config.MAP_CENTER, config.MAP_ZOOM)