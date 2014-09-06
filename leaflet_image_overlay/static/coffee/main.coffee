config = {}
config.MAP_CENTER = [38.907, -77.0368]
config.MAP_ZOOM = 11
config.LENFANT_URL = '/static/images/lenfant_map.jpg'
config.LENFANT_BOUNDS = [
    config.MAP_CENTER,
    [config.MAP_CENTER[0] + 0.002, config.MAP_CENTER[1] + 0.001]
]

$(document).ready ->
    
    map = L.mapbox.map('map', 'examples.map-i86nkdio', { zoomControl:false })
    map.setView(config.MAP_CENTER, config.MAP_ZOOM)
    
    map.on('mousedown', (e) -> map.dragging.enable())
    map.on('zoomend', (e) -> moveCornerMarkers)

    # L.control.fullscreen({position: 'topright'}).addTo(map)

    map.on('popupopen', (e) ->
        console.log(e)
    )
    currentOpacity = 0.5
    overlayBounds = config.LENFANT_BOUNDS
    console.log overlayBounds
    overlay = L.imageOverlay(config.LENFANT_URL, overlayBounds, {opacity: 0.35}).addTo(map)
    bounds = L.latLngBounds(overlayBounds)
    ne = L.marker(bounds.getNorthEast(), {draggable: true}).bindPopup('Foo').addTo(map)
    nw = L.marker(bounds.getNorthWest(), {draggable: true}).addTo(map)
    se = L.marker(bounds.getSouthEast(), {draggable: true}).addTo(map)
    sw = L.marker(bounds.getSouthWest(), {draggable: true}).addTo(map)


    $('#northeast_input_lat').val(ne.getLatLng().lat)
    $('#northeast_input_lon').val(ne.getLatLng().lng)
    $('#southwest_input_lat').val(sw.getLatLng().lat)
    $('#southwest_input_lon').val(sw.getLatLng().lng)



    sidebar = L.control.sidebar('sidebar', {position:'left', autoPan: false})
    
    map.addControl(sidebar)

    slider = $('#slider').slider({min: 0, max: 1.0, step: 0.01, value: 0.5, })
    slider.on('slide', (e) -> 
        currentOpacity = e.value
        updateOverlay overlayBounds)
    sidebar.hide()
    $('.leaflet-sidebar').css('width', 300)
    L.Control.SidebarOpen = L.Control.extend({
        options: {position: 'topleft'},
        onAdd: (map) ->
            controlDiv = L.DomUtil.create('div', 'leaflet-control-sidebar-open')
            L.DomEvent
                .addListener(controlDiv, 'click', L.DomEvent.stopPropagation)
                .addListener(controlDiv, 'click', L.DomEvent.preventDefault)
                .addListener(controlDiv, 'click', -> sidebar.toggle())      
            controlUI = L.DomUtil.create('div', 'leaflet-control-sidebar-open-interior', controlDiv)
            controlUI.title = 'Map Commands'
            return controlDiv
    })

    sidebarOpenControl = new L.Control.SidebarOpen()

    sidebar.on('show', -> sidebarOpenControl.removeFrom(map))
    sidebar.on('hidden', ->
        sidebarOpenControl.addTo(map)
        $('.leaflet-control-sidebar-open-interior').append('<button type="submit" class="btn btn-default"><span class="glyphicon glyphicon-cog"></span> </button>')
    )
    map.addControl(sidebarOpenControl)
    $('.leaflet-control-sidebar-open-interior').append('<button type="submit" class="btn btn-default"><span class="glyphicon glyphicon-cog"></span> </button>')

    $('#image_url_input').bind('keypress', (e) ->
        if e.keyCode == 13 or e.which == 13
            config.LENFANT_URL = $('#image_url_input').val()
            updateOverlay overlayBounds
    )        
    $('.latlon-input').bind('keypress', (e) ->
        if e.keyCode == 13 or e.which == 13
            neLatLng = [parseFloat($('#northeast_input_lat').val()), parseFloat($('#northeast_input_lng').val())]
            swLatLng = [parseFloat($('#southwest_input_lat').val()), parseFloat($('#southwest_input_lng').val())]
            updateOverlay [swLatLng, neLatLng]
    )        



    moveCornerMarkers = (bounds) ->
        overlayBounds = bounds
        bounds = L.latLngBounds(bounds)
        ne.setLatLng(bounds.getNorthEast())
        nw.setLatLng(bounds.getNorthWest())
        se.setLatLng(bounds.getSouthEast())
        sw.setLatLng(bounds.getSouthWest())    
        $('#northeast_input_lat').val(ne.getLatLng().lat)
        $('#northeast_input_lng').val(ne.getLatLng().lng)
        $('#southwest_input_lat').val(sw.getLatLng().lat)
        $('#southwest_input_lng').val(sw.getLatLng().lng)

    updateOverlay = (bounds) ->
        console.log bounds
        overlayBounds = bounds
        map.removeLayer(overlay)
        overlay = L.imageOverlay(config.LENFANT_URL, bounds, {opacity: currentOpacity}).addTo(map)
        moveCornerMarkers bounds

    ne.on('drag', (e) ->
        overlayBounds[1] = [e.target._latlng.lat, e.target._latlng.lng]
        updateOverlay overlayBounds
    )
    nw.on('drag', (e) ->
        overlayBounds[1][0] = e.target._latlng.lat
        overlayBounds[0][1] = e.target._latlng.lng
        updateOverlay overlayBounds
    )
    se.on('drag', (e) ->
        overlayBounds[0][0] = e.target._latlng.lat
        overlayBounds[1][1] = e.target._latlng.lng
        updateOverlay overlayBounds
    )
    sw.on('drag', (e) ->
        overlayBounds[0] = [e.target._latlng.lat, e.target._latlng.lng]
        updateOverlay overlayBounds
    )

    moveCornerMarkers overlayBounds

    im = new Image()
    im.onload = ->
        md = false
        lastLatLng = config.MAP_CENTER
        overlayBounds = [
            config.MAP_CENTER,
            [config.MAP_CENTER[0] + 0.1 * im.height / im.width, config.MAP_CENTER[1] + 0.1]
        ]
        updateOverlay overlayBounds

        $('.leaflet-overlay-pane').mousedown((e) ->
            md = true
            map.dragging.disable()
            lastLatLng = map.mouseEventToLatLng(e)
        )
        
        $('#map').mousemove((e) ->
            if md
                map.dragging.disable()
                currentLatLng = map.mouseEventToLatLng(e)
                dLat = currentLatLng.lat - lastLatLng.lat
                dLng = currentLatLng.lng - lastLatLng.lng
                overlayBounds[0][0] += dLat
                overlayBounds[1][0] += dLat
                overlayBounds[0][1] += dLng
                overlayBounds[1][1] += dLng
                updateOverlay overlayBounds
                lastLatLng = currentLatLng
                map.dragging.enable()
        )
        $('.leaflet-overlay-pane').mouseup(->
            md = false
            map.dragging.enable()
        )
    im.src = config.LENFANT_URL

