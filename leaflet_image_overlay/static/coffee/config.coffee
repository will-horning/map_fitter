MAP_CENTER = [38.907, -77.0368]
module.exports = {
    MAP_CENTER: MAP_CENTER
    MAP_ZOOM: 11
    DEFAULT_IMAGE_URL: '/static/images/lenfant_map.jpg'
    DEFAULT_OPACITY: 0.5
    DEFAULT_BOUNDS: [
        [MAP_CENTER[0] - 0.1, MAP_CENTER[1] - 0.1],
        [MAP_CENTER[0] + 0.2, MAP_CENTER[1] + 0.1]
    ]
    NOMINATIM_URL: 'http://nominatim.openstreetmap.org/'
}