module.exports = (map) -> 
    L.control.fullscreen({position: 'topright'}).addTo(map)

    sidebar = L.control.sidebar('sidebar', {position:'left', autoPan: false})
    map.addControl(sidebar)
    $('.leaflet-sidebar').css('width', config.SIDEBAR_WIDTH)

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


    # sidebar.on('show', -> sidebarOpenControl.removeFrom(map))
    # sidebar.on('hidden', ->
    #     sidebarOpenControl.addTo(map)
    #     $('.leaflet-control-sidebar-open-interior').append('<button type="submit" class="btn btn-default">Blajjjjj </button>')

    # map.addControl(sidebarOpenControl)
    # $('.leaflet-control-sidebar-open-interior').append('<button type="submit" class="btn btn-default">Blajjjjj </button>')


