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
            # @miniMap._miniMap.setMaxBounds(@bounds)
            latLngBounds = L.latLngBounds(@bounds)
            @ne = L.marker(latLngBounds.getNorthEast(), {draggable: true}).addTo(@map)
            @nw = L.marker(latLngBounds.getNorthWest(), {draggable: true}).addTo(@map)
            @se = L.marker(latLngBounds.getSouthEast(), {draggable: true}).addTo(@map)
            @sw = L.marker(latLngBounds.getSouthWest(), {draggable: true}).addTo(@map)
            @ne2 = L.marker(latLngBounds.getNorthEast(), {draggable: true}).addTo(@miniMapLayers)
            @nw2 = L.marker(latLngBounds.getNorthWest(), {draggable: true}).addTo(@miniMapLayers)
            @se2 = L.marker(latLngBounds.getSouthEast(), {draggable: true}).addTo(@miniMapLayers)
            @sw2 = L.marker(latLngBounds.getSouthWest(), {draggable: true}).addTo(@miniMapLayers)

            thisOverlayEditor = this
            # @map.on('dragend', (e) -> thisOverlayEditor.miniMap._miniMap.setZoom(thisOverlayEditor.minimapZoom))
            # @map.on('dragend', (e) -> console.log 'fo')
            @ne.on('drag', (e) ->
                thisOverlayEditor.bounds[1] = [e.target._latlng.lat, e.target._latlng.lng]
                thisOverlayEditor.updateOverlay thisOverlayEditor.bounds
            )
            @nw.on('drag', (e) ->
                thisOverlayEditor.bounds[1][0] = e.target._latlng.lat
                thisOverlayEditor.bounds[0][1] = e.target._latlng.lng
                thisOverlayEditor.updateOverlay thisOverlayEditor.bounds
            )
            @se.on('drag', (e) ->
                thisOverlayEditor.bounds[0][0] = e.target._latlng.lat
                thisOverlayEditor.bounds[1][1] = e.target._latlng.lng
                thisOverlayEditor.updateOverlay thisOverlayEditor.bounds
            )
            @sw.on('drag', (e) ->
                thisOverlayEditor.bounds[0] = [e.target._latlng.lat, e.target._latlng.lng]
                thisOverlayEditor.updateOverlay thisOverlayEditor.bounds
            )
            @ne2.on('drag', (e) ->
                thisOverlayEditor.bounds[1] = [e.target._latlng.lat, e.target._latlng.lng]
                thisOverlayEditor.updateOverlay thisOverlayEditor.bounds
            )
            @nw2.on('drag', (e) ->
                thisOverlayEditor.bounds[1][0] = e.target._latlng.lat
                thisOverlayEditor.bounds[0][1] = e.target._latlng.lng
                thisOverlayEditor.updateOverlay thisOverlayEditor.bounds
            )
            @se2.on('drag', (e) ->
                thisOverlayEditor.bounds[0][0] = e.target._latlng.lat
                thisOverlayEditor.bounds[1][1] = e.target._latlng.lng
                thisOverlayEditor.updateOverlay thisOverlayEditor.bounds
            )
            @sw2.on('drag', (e) ->
                thisOverlayEditor.bounds[0] = [e.target._latlng.lat, e.target._latlng.lng]
                thisOverlayEditor.updateOverlay thisOverlayEditor.bounds
            )
            @mouseDown = false
            @lastLatLng = config.MAP_CENTER   
            @map.on('mousedown', (e) ->
                if L.latLngBounds(thisOverlayEditor.bounds).contains(e.latlng)
                    thisOverlayEditor.lastLatLng = e.latlng
                    thisOverlayEditor.mouseDown = true
                    thisOverlayEditor.map.dragging.disable()
                    m.closePopup() for m in [
                        thisOverlayEditor.ne, 
                        thisOverlayEditor.nw, 
                        thisOverlayEditor.se, 
                        thisOverlayEditor.sw
                    ]
            )
            @map.on('mousemove', (e) ->
                if thisOverlayEditor.mouseDown
                    thisOverlayEditor.map.dragging.disable()
                    currentLatLng = e.latlng
                    dLat = currentLatLng.lat - thisOverlayEditor.lastLatLng.lat
                    dLng = currentLatLng.lng - thisOverlayEditor.lastLatLng.lng
                    thisOverlayEditor.bounds[0][0] += dLat
                    thisOverlayEditor.bounds[1][0] += dLat
                    thisOverlayEditor.bounds[0][1] += dLng
                    thisOverlayEditor.bounds[1][1] += dLng
                    thisOverlayEditor.updateOverlay thisOverlayEditor.bounds
                    thisOverlayEditor.lastLatLng = currentLatLng
                    thisOverlayEditor.map.dragging.enable()
            )
            @map.on('mouseup', (e) ->
                thisOverlayEditor.mouseDown = false
                thisOverlayEditor.map.dragging.enable()
            )
            @r = L.rectangle(@bounds)
            @r2 = L.rectangle(@bounds)
            @neMinimap = L.marker([0,0], {draggable: true})
            @neMinimap.addTo(map)
            # @nwMinimap = L.marker([0,0])
            # @seMinimap = L.marker([0,0])
            # @swMinimap = L.marker([0,0])

            # @map.on('zoomend', (e) ->
            #     thisOverlayEditor.updateMinimap()
            # )
            # @map.on('move', (e) ->
            #     thisOverlayEditor.updateMinimap()
            # )
        updateCornerMarkers: (bounds) ->
            @bounds = bounds
            latLngBounds = L.latLngBounds(bounds)
            @ne.setLatLng(latLngBounds.getNorthEast())
            @nw.setLatLng(latLngBounds.getNorthWest())
            @se.setLatLng(latLngBounds.getSouthEast())
            @sw.setLatLng(latLngBounds.getSouthWest())
            @ne2.setLatLng(latLngBounds.getNorthEast())
            @nw2.setLatLng(latLngBounds.getNorthWest())
            @se2.setLatLng(latLngBounds.getSouthEast())
            @sw2.setLatLng(latLngBounds.getSouthWest())
            $('#northeast_input_lat').val(@ne.getLatLng().lat)
            $('#northeast_input_lng').val(@ne.getLatLng().lng)
            $('#southwest_input_lat').val(@sw.getLatLng().lat)
            $('#southwest_input_lng').val(@sw.getLatLng().lng)
            m.bindPopup(m.getLatLng().lat + ', ' + m.getLatLng().lng) for m in [@ne, @sw, @se, @nw]
            swlatlon = [@sw.getLatLng().lat, @sw.getLatLng().lng]
            nelatlon = [@ne.getLatLng().lat, @ne.getLatLng().lng]
            $('#latlngbounds').html('L.latLngBounds([' + swlatlon.join(',') + ',' + nelatlon.join(',') + '])')


        updateOverlay: (bounds) ->
            @bounds = bounds        
            @map.removeLayer(@overlay)
            @overlay = L.imageOverlay(@imgUrl, @bounds, @overlayOptions).addTo(@map)
            @miniMapLayers.removeLayer(@overlay2)
            @overlay2 = L.imageOverlay(@imgUrl, @bounds, @overlayOptions).addTo(@map)
            @miniMapLayers.addLayer(@overlay2)
            @updateCornerMarkers bounds
            # @updateMinimap()

        

    overlayEdit = null 
    changeImagePopup = L.popup({closeOnClick: false, closeButton: false})
    changeImagePopup.setLatLng(config.MAP_CENTER)
    changeImagePopup.setContent("""
        <form id="popupForm">
            <input type="text" id="image_url_input" value="http://dcsymbols.com/chronology/dc1820.jpg">
            <input type="text" id="location_input" value="District of Columbia">
            <input type="submit" value="submit">
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
    slider = $('#sidebar-slider').slider({min: 0, max: 1.0, step: 0.01, value: 0.5 })
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
            controlUI = L.DomUtil.create('div', 'leaflet-control-sidebar-open-interior', controlDiv)
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
            neLatLng = [parseFloat($('#northeast_input_lat').val()), parseFloat($('#northeast_input_lng').val())]
            swLatLng = [parseFloat($('#southwest_input_lat').val()), parseFloat($('#southwest_input_lng').val())]
            overlayEdit.updateOverlay [swLatLng, neLatLng]
    )        