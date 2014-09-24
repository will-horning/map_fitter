config = require './config.coffee'

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
        @enableDrag()

    dragHandler: (e) =>
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

    enableDrag: -> 
        @map.on(e, @dragHandler) for e in ['mousedown', 'mousemove', 'mouseup']

    disableDrag: -> 
        @map.off(e, @dragHandler) for e in ['mousedown', 'mousemove', 'mouseup']

    placeLandmark: (e) =>


        if not @landmark1
            @landmark1 = L.circleMarker(e.latlng, {fillColor: '#ff0000', fillOpacity: 0.5}).addTo(@map)
            @show()
            if @landmarkPairs.length == 0
                $('#landmark-help').html('Now find the same landmark on your image and click on it.')
            else
                $('#landmark-help').html('Now place the second landmark on the image.')

        else if @landmark1 and L.latLngBounds(@bounds).contains(e.latlng)
            @landmark2 = L.circleMarker(e.latlng, {fillColor: '#0000ff', fillOpacity: 0.5}).addTo(@map)
            @landmarkPairs.push [@landmark1, @landmark2]
            if @landmarkPairs.length == 2
                $('#landmark-button').show()
                $('#landmark-help').html('')
                @fitToLandmark()
                @map.off('click', @placeLandmark)
            else
                $('#landmark-help').html('Now place the second landmark on the map.')
                @hide()
            [@landmark1, @landmark2] = [null, null]
            @enableDrag()

    placeLandmarkPair: () ->
        $('#landmark-button').hide()
        for pair in @landmarkPairs
            @map.removeLayer(m) for m in pair
        @landmarkPairs = []
        @disableDrag()
        @map.on('click', @placeLandmark)
        $('#landmark-help').html('Find a landmark on the map and click on it to place the first marker.')
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

    getCenterLatLng: ->
        return L.latLng([
            @sw.getLatLng().lat + (@ne.getLatLng().lat - @sw.getLatLng().lat) / 2,
            @sw.getLatLng().lng + (@ne.getLatLng().lng - @sw.getLatLng().lng) / 2
        ])

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

module.exports = (imgUrl, map, bounds, overlayOptions) ->
    return new OverlayEditor(imgUrl, map, bounds, overlayOptions)