config = require './config.coffee'
 
$(document).ready ->
    map = L.mapbox.map('map', 'willhorning.ja8hjdhd', {zoomControl: false})
    map.setView(config.MAP_CENTER, config.MAP_ZOOM)
    map.on('mousedown', (e) -> map.dragging.enable())
    $('#latlngbounds').css('width', 220)

    overlayEdit = null 

    changeImagePopup = L.popup({closeOnClick: false, closeButton: false})
    changeImagePopup.setLatLng(config.MAP_CENTER)
    # changeImagePopup.setContent("""
    #     <form id="popupForm"> 
    #     Image URL:
    #     <br>
    #     <input type="text" id="image_url_input" value="/static/images/lenfant_map.jpg">
    #     <br>
    #     Location (Address or city name):
    #     <br>
    #     <input type="text" id="location_input" value="District of Columbia">
    #     <br>
    #     <input type="submit" value="Submit">
    #     </form>
    #     """
    # )
    changeImagePopup.setContent("""
        <form id="popupForm">
            <div class="form-group">
                <label for="imageUrl">Image URL</label>
                <input type="text" class="form-control" id="image_url_input" value="/static/images/lenfant_map.jpg">
            </div>
            <div class="form-group">
                <label for="location">Location (Address or city name)</label>
                <input type="text" class="form-control" id="location_input" value="District of Columbia">
            </div>
            <button type="submit" class="btn btn-primary btn-block">Submit</button>
        </form>                
        """
    )
    changeImagePopup.openOn(map)
    $('#popupForm').submit((e) ->
        e.preventDefault()
        params = {q: $('#location_input').val(), format: 'json'}
        $.getJSON(config.NOMINATIM_URL, params, (locs) ->
            if locs? and locs.length > 0
                loc = locs[0]
                max_area = 0
                for l in locs
                    bounds = (parseFloat(f) for f in l.boundingbox)
                    area = Math.abs((bounds[1] - bounds[0]) * (bounds[3] - bounds[2]))
                    if area > max_area
                        loc = l
                        max_area = area
                map.panTo([loc.lat, loc.lon])    
                bounds = (parseFloat(f) for f in loc.boundingbox)
                northeast = [bounds[1], bounds[3]]
                southwest = [bounds[0], bounds[2]]
                overlayEdit = require('./overlay-editor.coffee')(
                    $('#image_url_input').val(), 
                    map, 
                    [southwest, northeast],
                    {opacity: 0.5}
                )
                overlayEdit.lastLatLng = [loc.lat, loc.lon]
                overlayEdit.updateOverlay
                map.closePopup(changeImagePopup)
                map.fitBounds([southwest, northeast], {padding: [100, 100]})  
                $('#landmark-button').click(->
                    overlayEdit.placeLandmarkPair()
                )
                sidebar.show()
        )
    )       

    # L.Control.WidthSlider = L.Control.extend({
    #     options: {position: 'topright'},
    #     onAdd: (map) ->
    #         controlDiv = L.DomUtil.create('div', 'width-slider-control')     
    #         controlUI = L.DomUtil.create('div', 'width-slider', controlDiv)
    #         controlUI.title = 'Width Slider'
    #         return controlDiv
    # })

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


    makeHelpPopup = (loc, content) ->
        p = L.popup({closeOnClick: false})
        p.setLatLng(loc)
        p.setContent(content + '<br><br><a class="next-button" href="#">Next</a>')        
        return p

    $('#help-button').click(->
        bounds = map.getBounds()
        ne = bounds.getNorthEast()
        sw = bounds.getSouthWest()
        nePixelCoord = map.latLngToContainerPoint(ne)
        swPixelCoord = map.latLngToContainerPoint(sw)
        x = nePixelCoord.x - 155
        y = swPixelCoord.y - 335
        loc = map.containerPointToLatLng(L.point(x, y))
        pixelHeight = nePixelCoord.y - swPixelCoord.y
        pixelWidth = nePixelCoord.x - swPixelCoord.x
        mapHeight = ne.lat - sw.lat
        mapWidth = ne.lng - sw.lng
        centerLat = sw.lat + mapHeight / 2
        lng = ne.lng - mapWidth * 0.1
        popups = [
            makeHelpPopup(overlayEdit.ne.getLatLng(), 'Change the size and dimensions of the image by dragging these corner markers.'),
            makeHelpPopup(overlayEdit.getCenterLatLng(), 'Move the image by clicking and dragging it.'),
            makeHelpPopup(loc, 'You can also change the image dimensions or pan the map using the minimap.')
        ]
        i = 0
        popups[i].openOn(map)
        nextPopup = ->
            map.closePopup(popups[i])
            if popups.length > 0
                i += 1
                popups[i].openOn(map)
                $('.next-button').click(nextPopup)                
        $('.next-button').click(nextPopup)
    )
