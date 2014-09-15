config = {}
config.MAP_CENTER = [38.907, -77.0368]
config.MAP_ZOOM = 11
config.DEFAULT_IMAGE_URL = '/static/images/lenfant_map.jpg'
config.DEFAULT_OPACITY = 0.5
config.DEFAULT_BOUNDS = [
    [config.MAP_CENTER[0] - 0.1, config.MAP_CENTER[1] - 0.1],
    [config.MAP_CENTER[0] + 0.1, config.MAP_CENTER[1] + 0.1]
]
config.NOMINATIM_URL = 'http://nominatim.openstreetmap.org/';
image_url = config.DEFAULT_IMAGE_URL

$(document).ready ->
    
    map = L.mapbox.map('map', 'examples.map-i86nkdio', {zoomControl: false})
    map.setView(config.MAP_CENTER, config.MAP_ZOOM)
    map.on('mousedown', (e) -> map.dragging.enable())
    $('#latlngbounds').css('width', 220)

    class OverlayEditor
        constructor: (@imgUrl, @map, @bounds, @overlayOptions) ->
            @overlay = L.imageOverlay(@imgUrl, @bounds, @overlayOptions).addTo(@map)
            @hidden = false
            @landmarkPairs = []
            @mouseDown = false
            @lastLatLng = config.MAP_CENTER   
            @initMinimap()
            [@ne, @nw, @se, @sw] = @createCornerMarkers(@map)
            miniMapCorners = @createCornerMarkers(@miniMapLayers)
            [@neMinimap, @nwMinimap, @seMinimap, @swMinimap] = miniMapCorners
            @enableDragging()

        draggingHandler: (e) =>
            if e.type == 'mousedown'
                if L.latLngBounds(@bounds).contains(e.latlng) and not @hidden
                    @lastLatLng = e.latlng
                    @mouseDown = true
                    @map.dragging.disable()
                    m.closePopup() for m in [@ne, @nw, @se, @sw]
            else if e.type == 'mousemove'
                if @mouseDown
                    @map.dragging.disable()
                    currentLatLng = e.latlng
                    dLat = currentLatLng.lat - @lastLatLng.lat
                    dLng = currentLatLng.lng - @lastLatLng.lng
                    bounds = [
                        [@bounds[0][0] + dLat, @bounds[0][1] + dLng],
                        [@bounds[1][0] + dLat, @bounds[1][1] + dLng]
                    ]
                    @updateOverlay bounds
                    @lastLatLng = currentLatLng
                    @map.dragging.enable()
            else if e.type == 'mouseup'
                if @mouseDown
                    @mouseDown = false
                    @map.dragging.enable()

        enableDragging: ->
            @map.on('mousedown', @draggingHandler)
            @map.on('mousemove', @draggingHandler)
            @map.on('mouseup', @draggingHandler)

        disableDragging: ->
            @map.off('mousedown', @draggingHandler)
            @map.off('mousemove', @draggingHandler)
            @map.off('mouseup', @draggingHandler)

        placeLandmark: (e) => 
            if not @landmark1
                @landmark1 = L.circleMarker(e.latlng, {fillColor: '#ff0000', fillOpacity: 0.5}).addTo(map)
                @show()
            else if @landmark1 and L.latLngBounds(@bounds).contains(e.latlng)
                @landmark2 = L.circleMarker(e.latlng, {fillColor: '#0000ff', fillOpacity: 0.5}).addTo(map)
                @landmarkPairs.push [@landmark1, @landmark2]
                if @landmarkPairs.length == 2
                    @fitToLandmark()
                    @map.off('click', @placeLandmark)
                else
                    @hide()
                [@landmark1, @landmark2] = [null, null]
                @enableDragging()

        placeLandmarkPair: () ->
            for pair in @landmarkPairs
                @map.removeLayer(m) for m in pair
            @landmarkPairs = []
            @disableDragging()
            @map.on('click', @placeLandmark)
            @hide()

        fitToLandmark: () ->
            sw = @sw.getLatLng()
            ne = @ne.getLatLng()
            overlayLatLng1 = @landmarkPairs[0][1].getLatLng()
            overlayLatLng2 = @landmarkPairs[1][1].getLatLng()
            mapLatLng1 = @landmarkPairs[0][0].getLatLng()
            mapLatLng2 = @landmarkPairs[1][0].getLatLng()
            dx = overlayLatLng2.lng - overlayLatLng1.lng
            dy = overlayLatLng2.lat - overlayLatLng1.lat
            rx1 = (overlayLatLng1.lng - sw.lng) / dx
            ry1 = (overlayLatLng1.lat - sw.lat) / dy
            rx2 = (ne.lng - overlayLatLng2.lng) / dx
            ry2 = (ne.lat - overlayLatLng2.lat) / dy
            dxMap = mapLatLng2.lng - mapLatLng1.lng
            dyMap = mapLatLng2.lat - mapLatLng1.lat
            leftPadding = dxMap * rx1
            rightPadding = dxMap * rx2
            bottomPadding = dyMap * ry1
            topPadding = dyMap * ry2
            bounds = [[0,0], [0,0]]
            bounds[0][0] = mapLatLng1.lat - bottomPadding
            bounds[1][0] = mapLatLng2.lat + topPadding
            bounds[0][1] = mapLatLng1.lng - leftPadding
            bounds[1][1] = mapLatLng2.lng + rightPadding
            @updateOverlay bounds


        setNortheast: (latLng) ->
            @updateOverlay [@bounds[0], [latLng.lat, latLng.lng]]

        setNorthwest: (latLng) ->
            @updateOverlay [[@bounds[0][0], latLng.lng], [latLng.lat, @bounds[1][1]]]

        setSoutheast: (latLng) ->
            @updateOverlay [[latLng.lat, @bounds[0][1]], [@bounds[1][0], latLng.lng]]

        setSouthwest: (latLng) ->
            @updateOverlay [[latLng.lat, latLng.lng], @bounds[1]]

        createCornerMarkers: (target) ->
            latLngBounds = L.latLngBounds(@bounds)
            ne = L.marker(latLngBounds.getNorthEast(), {draggable: true}).addTo(target)
            nw = L.marker(latLngBounds.getNorthWest(), {draggable: true}).addTo(target)
            se = L.marker(latLngBounds.getSouthEast(), {draggable: true}).addTo(target)
            sw = L.marker(latLngBounds.getSouthWest(), {draggable: true}).addTo(target)
            ne.on('drag', (e) => @setNortheast(e.target._latlng))
            nw.on('drag', (e) => @setNorthwest(e.target._latlng))
            se.on('drag', (e) => @setSoutheast(e.target._latlng))
            sw.on('drag', (e) => @setSouthwest(e.target._latlng))
            return [ne, nw, se, sw]

        initMinimap: () ->
            @overlay2 = L.imageOverlay(@imgUrl, @bounds, @overlayOptions).addTo(@map)
            @minimapZoom = 13
            osm2 = new L.TileLayer(
                'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', 
                {
                    minZoom: 0, 
                    maxZoom: 13,
                    attribution: 'Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
                }
            )
            @miniMapLayers = L.layerGroup([osm2, @overlay2])
            @miniMap = new L.Control.MiniMap(
                @miniMapLayers, 
                {width: 300, height: 300, zoomLevelOffset: -3}
            ).addTo(@map)

        updateCornerMarkers: (bounds) ->
            @bounds = bounds
            latLngBounds = L.latLngBounds(bounds)
            @ne.setLatLng(latLngBounds.getNorthEast())
            @nw.setLatLng(latLngBounds.getNorthWest())
            @se.setLatLng(latLngBounds.getSouthEast())
            @sw.setLatLng(latLngBounds.getSouthWest())
            @neMinimap.setLatLng(latLngBounds.getNorthEast())
            @nwMinimap.setLatLng(latLngBounds.getNorthWest())
            @seMinimap.setLatLng(latLngBounds.getSouthEast())
            @swMinimap.setLatLng(latLngBounds.getSouthWest())
            $('#northeast_input_lat').val(@ne.getLatLng().lat)
            $('#northeast_input_lng').val(@ne.getLatLng().lng)
            $('#southwest_input_lat').val(@sw.getLatLng().lat)
            $('#southwest_input_lng').val(@sw.getLatLng().lng)
            m.bindPopup(m.getLatLng().lat + ', ' + m.getLatLng().lng) for m in [@ne, @sw, @se, @nw]

        updateOverlay: (bounds) ->
            for pair in @landmarkPairs
                latlng = pair[1].getLatLng()
                dx = (latlng.lng - @bounds[0][1])
                dy = (latlng.lat - @bounds[0][0])
                overlayWidth = @bounds[1][1] - @bounds[0][1]
                overlayHeight = @bounds[1][0] - @bounds[0][0]
                newOverlayWidth = bounds[1][1] - bounds[0][1]
                newOverlayHeight = bounds[1][0] - bounds[0][0]
                lat = bounds[0][0] + newOverlayHeight * dy / overlayHeight
                lng = bounds[0][1] + newOverlayWidth * dx / overlayWidth
                pair[1].setLatLng([lat, lng])
            @bounds = bounds        
            @map.removeLayer(@overlay)
            @overlay = L.imageOverlay(@imgUrl, @bounds, @overlayOptions).addTo(@map)
            @miniMapLayers.removeLayer(@overlay2)
            @overlay2 = L.imageOverlay(@imgUrl, @bounds, @overlayOptions).addTo(@map)
            @miniMapLayers.addLayer(@overlay2)
            @updateCornerMarkers bounds
            console.log @landmarkPairs

        hide: ->
            if not @hidden
                @map.removeLayer @overlay
                @map.removeLayer @ne
                @map.removeLayer @nw
                @map.removeLayer @se
                @map.removeLayer @sw
                @hidden = true
        
        show: ->
            if @hidden
                @map.addLayer @overlay
                @map.addLayer @ne
                @map.addLayer @nw
                @map.addLayer @se
                @map.addLayer @sw
                @hidden = false

        toggle: ->
            if @hidden
                @show()
            else
                @hide()

    overlayEdit = null 
    changeImagePopup = L.popup({closeOnClick: false, closeButton: false})
    changeImagePopup.setLatLng(config.MAP_CENTER)
    changeImagePopup.setContent("""
        <form id="popupForm">
        Image URL:
        <br>
        <input type="text" id="image_url_input" value="http://dcsymbols.com/chronology/dc1820.jpg">
        <br>
        Location (Address or city name):
        <br>
        <input type="text" id="location_input" value="District of Columbia">
        <br>
        <input type="submit" value="Submit">
        </form>
        """
    )
   
    changeImagePopup.openOn(map)
    $('#popupForm').submit((e) ->
        e.preventDefault()
        params = {q: $('#location_input').val(), format: 'json'}
        $.getJSON(config.NOMINATIM_URL, params, (loc) ->
            if loc? and loc.length > 0
                map.panTo([loc[0].lat, loc[0].lon])    
                bounds = (parseFloat(f) for f in loc[0].boundingbox)
                northeast = [bounds[1], bounds[3]]
                southwest = [bounds[0], bounds[2]]
                overlayEdit = new OverlayEditor(
                    $('#image_url_input').val(), 
                    map, 
                    [southwest, northeast],
                    {opacity: 0.5}
                )
                overlayEdit.lastLatLng = [loc[0].lat, loc[0].lon]
                overlayEdit.updateOverlay
                map.closePopup(changeImagePopup)
                map.fitBounds([southwest, northeast], {padding: [100, 100]})  

                $('#landmark-button').click(->
                    overlayEdit.placeLandmarkPair()
                )
        )
    )       

    L.Control.WidthSlider = L.Control.extend({
        options: {position: 'topright'},
        onAdd: (map) ->
            controlDiv = L.DomUtil.create('div', 'width-slider-control')     
            controlUI = L.DomUtil.create('div', 'width-slider', controlDiv)
            controlUI.title = 'Width Slider'
            return controlDiv
    })

    sidebar = L.control.sidebar('sidebar', {position:'left', autoPan: false})
    map.addControl(sidebar)
    $('#sidebar-slider').css('width', 190)
    slider = $('#sidebar-slider').slider({
        min: 0, max: 1.0, step: 0.01, value: 0.5 
    })
    slider.on('slide', (e) -> 
        overlayEdit.overlayOptions = {opacity: e.value}
        overlayEdit.updateOverlay overlayEdit.bounds
    )
    sidebar.hide()
    $('.leaflet-sidebar').css('width', 250)
    L.Control.SidebarOpen = L.Control.extend({
        options: {position: 'topleft'},
        onAdd: (map) ->
            controlDiv = L.DomUtil.create('div', 'leaflet-control-sidebar-open')
            L.DomEvent
                .addListener(controlDiv, 'click', L.DomEvent.stopPropagation)
                .addListener(controlDiv, 'click', L.DomEvent.preventDefault)
                .addListener(controlDiv, 'click', -> sidebar.toggle())      
            controlUI = L.DomUtil.create(
                'div', 
                'leaflet-control-sidebar-open-interior', 
                controlDiv
            )
            controlUI.title = 'Map Commands'
            return controlDiv
    })
    sidebarOpenControl = new L.Control.SidebarOpen()
    sidebar.on('show', -> sidebarOpenControl.removeFrom(map))
    sidebar_open_content = """
        <button type="submit" class="btn btn-default">
            <span class="glyphicon glyphicon-cog"></span> 
        </button>
    """
    sidebar.on('hidden', ->
        sidebarOpenControl.addTo(map)
        $('.leaflet-control-sidebar-open-interior').append(sidebar_open_content)
    )
    map.addControl(sidebarOpenControl)
    $('.leaflet-control-sidebar-open-interior').append(sidebar_open_content)

    $('.latlon-input').bind('keypress', (e) ->
        if e.keyCode == 13 or e.which == 13
            neLatLng = [
                parseFloat($('#northeast_input_lat').val()), 
                parseFloat($('#northeast_input_lng').val())
            ]
            swLatLng = [
                parseFloat($('#southwest_input_lat').val()), 
                parseFloat($('#southwest_input_lng').val())
            ]
            overlayEdit.updateOverlay [swLatLng, neLatLng]
    )        