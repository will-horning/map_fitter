(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var MAP_CENTER;

MAP_CENTER = [38.907, -77.0368];

module.exports = {
  MAP_CENTER: MAP_CENTER,
  MAP_ZOOM: 11,
  DEFAULT_IMAGE_URL: '/static/images/lenfant_map.jpg',
  DEFAULT_OPACITY: 0.5,
  DEFAULT_BOUNDS: [[MAP_CENTER[0] - 0.1, MAP_CENTER[1] - 0.1], [MAP_CENTER[0] + 0.2, MAP_CENTER[1] + 0.1]],
  NOMINATIM_URL: 'http://nominatim.openstreetmap.org/'
};



},{}],2:[function(require,module,exports){
var config;

config = require('./config.coffee');

$(document).ready(function() {
  var changeImagePopup, makeHelpPopup, map, overlayEdit, sidebar, sidebarOpenControl, sidebar_open_content, slider;
  map = L.mapbox.map('map', 'willhorning.ja8hjdhd', {
    zoomControl: false
  });
  map.setView(config.MAP_CENTER, config.MAP_ZOOM);
  map.on('mousedown', function(e) {
    return map.dragging.enable();
  });
  $('#latlngbounds').css('width', 220);
  overlayEdit = null;
  changeImagePopup = L.popup({
    closeOnClick: false,
    closeButton: false
  });
  changeImagePopup.setLatLng(config.MAP_CENTER);
  changeImagePopup.setContent("<form id=\"popupForm\">\n    <div class=\"form-group\">\n        <label for=\"imageUrl\">Image URL</label>\n        <input type=\"text\" class=\"form-control\" id=\"image_url_input\" value=\"/static/images/lenfant_map.jpg\">\n    </div>\n    <div class=\"form-group\">\n        <label for=\"location\">Location (Address or city name)</label>\n        <input type=\"text\" class=\"form-control\" id=\"location_input\" value=\"District of Columbia\">\n    </div>\n    <button type=\"submit\" class=\"btn btn-primary btn-block\">Submit</button>\n</form>                \n");
  changeImagePopup.openOn(map);
  $('#popupForm').submit(function(e) {
    var params;
    e.preventDefault();
    params = {
      q: $('#location_input').val(),
      format: 'json'
    };
    return $.getJSON(config.NOMINATIM_URL, params, function(loc) {
      var bounds, f, northeast, southwest;
      if ((loc != null) && loc.length > 0) {
        map.panTo([loc[0].lat, loc[0].lon]);
        bounds = (function() {
          var _i, _len, _ref, _results;
          _ref = loc[0].boundingbox;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            f = _ref[_i];
            _results.push(parseFloat(f));
          }
          return _results;
        })();
        northeast = [bounds[1], bounds[3]];
        southwest = [bounds[0], bounds[2]];
        overlayEdit = require('./overlay-editor.coffee')($('#image_url_input').val(), map, [southwest, northeast], {
          opacity: 0.5
        });
        overlayEdit.lastLatLng = [loc[0].lat, loc[0].lon];
        overlayEdit.updateOverlay;
        map.closePopup(changeImagePopup);
        map.fitBounds([southwest, northeast], {
          padding: [100, 100]
        });
        $('#landmark-button').click(function() {
          return overlayEdit.placeLandmarkPair();
        });
        return sidebar.show();
      }
    });
  });
  sidebar = L.control.sidebar('sidebar', {
    position: 'left',
    autoPan: false
  });
  map.addControl(sidebar);
  $('#sidebar-slider').css('width', 190);
  slider = $('#sidebar-slider').slider({
    min: 0,
    max: 1.0,
    step: 0.01,
    value: 0.5
  });
  slider.on('slide', function(e) {
    overlayEdit.overlayOptions = {
      opacity: e.value
    };
    return overlayEdit.updateOverlay(overlayEdit.bounds);
  });
  sidebar.hide();
  $('.leaflet-sidebar').css('width', 250);
  L.Control.SidebarOpen = L.Control.extend({
    options: {
      position: 'topleft'
    },
    onAdd: function(map) {
      var controlDiv, controlUI;
      controlDiv = L.DomUtil.create('div', 'leaflet-control-sidebar-open');
      L.DomEvent.addListener(controlDiv, 'click', L.DomEvent.stopPropagation).addListener(controlDiv, 'click', L.DomEvent.preventDefault).addListener(controlDiv, 'click', function() {
        return sidebar.toggle();
      });
      controlUI = L.DomUtil.create('div', 'leaflet-control-sidebar-open-interior', controlDiv);
      controlUI.title = 'Map Commands';
      return controlDiv;
    }
  });
  sidebarOpenControl = new L.Control.SidebarOpen();
  sidebar.on('show', function() {
    return sidebarOpenControl.removeFrom(map);
  });
  sidebar_open_content = "<button type=\"submit\" class=\"btn btn-default\">\n    <span class=\"glyphicon glyphicon-cog\"></span> \n</button>";
  sidebar.on('hidden', function() {
    sidebarOpenControl.addTo(map);
    return $('.leaflet-control-sidebar-open-interior').append(sidebar_open_content);
  });
  map.addControl(sidebarOpenControl);
  $('.leaflet-control-sidebar-open-interior').append(sidebar_open_content);
  $('.latlon-input').bind('keypress', function(e) {
    var neLatLng, swLatLng;
    if (e.keyCode === 13 || e.which === 13) {
      neLatLng = [parseFloat($('#northeast_input_lat').val()), parseFloat($('#northeast_input_lng').val())];
      swLatLng = [parseFloat($('#southwest_input_lat').val()), parseFloat($('#southwest_input_lng').val())];
      return overlayEdit.updateOverlay([swLatLng, neLatLng]);
    }
  });
  makeHelpPopup = function(loc, content) {
    var p;
    p = L.popup({
      closeOnClick: false
    });
    p.setLatLng(loc);
    p.setContent(content + '<br><br><a class="next-button" href="#">Next</a>');
    return p;
  };
  return $('#help-button').click(function() {
    var bounds, centerLat, i, lng, loc, mapHeight, mapWidth, ne, nePixelCoord, nextPopup, pixelHeight, pixelWidth, popups, sw, swPixelCoord, x, y;
    bounds = map.getBounds();
    ne = bounds.getNorthEast();
    sw = bounds.getSouthWest();
    nePixelCoord = map.latLngToContainerPoint(ne);
    swPixelCoord = map.latLngToContainerPoint(sw);
    x = nePixelCoord.x - 155;
    y = swPixelCoord.y - 335;
    loc = map.containerPointToLatLng(L.point(x, y));
    pixelHeight = nePixelCoord.y - swPixelCoord.y;
    pixelWidth = nePixelCoord.x - swPixelCoord.x;
    mapHeight = ne.lat - sw.lat;
    mapWidth = ne.lng - sw.lng;
    centerLat = sw.lat + mapHeight / 2;
    lng = ne.lng - mapWidth * 0.1;
    popups = [makeHelpPopup(overlayEdit.ne.getLatLng(), 'Change the size and dimensions of the image by dragging these corner markers.'), makeHelpPopup(overlayEdit.getCenterLatLng(), 'Move the image by clicking and dragging it.'), makeHelpPopup(loc, 'You can also change the image dimensions or pan the map using the minimap.')];
    i = 0;
    popups[i].openOn(map);
    nextPopup = function() {
      map.closePopup(popups[i]);
      if (popups.length > 0) {
        i += 1;
        popups[i].openOn(map);
        return $('.next-button').click(nextPopup);
      }
    };
    return $('.next-button').click(nextPopup);
  });
});



},{"./config.coffee":1,"./overlay-editor.coffee":3}],3:[function(require,module,exports){
var OverlayEditor, config,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

config = require('./config.coffee');

OverlayEditor = (function() {
  function OverlayEditor(imgUrl, map, bounds, overlayOptions) {
    var miniMapCorners, _ref;
    this.imgUrl = imgUrl;
    this.map = map;
    this.bounds = bounds;
    this.overlayOptions = overlayOptions;
    this.placeLandmark = __bind(this.placeLandmark, this);
    this.dragHandler = __bind(this.dragHandler, this);
    this.overlay = L.imageOverlay(this.imgUrl, this.bounds, this.overlayOptions).addTo(this.map);
    this.hidden = false;
    this.landmarkPairs = [];
    this.mouseDown = false;
    this.lastLatLng = config.MAP_CENTER;
    this.initMinimap();
    _ref = this.createCornerMarkers(this.map), this.ne = _ref[0], this.nw = _ref[1], this.se = _ref[2], this.sw = _ref[3];
    miniMapCorners = this.createCornerMarkers(this.miniMapLayers);
    this.neMinimap = miniMapCorners[0], this.nwMinimap = miniMapCorners[1], this.seMinimap = miniMapCorners[2], this.swMinimap = miniMapCorners[3];
    this.enableDrag();
  }

  OverlayEditor.prototype.dragHandler = function(e) {
    var bounds, currentLatLng, dLat, dLng, m, _i, _len, _ref, _results;
    if (e.type === 'mousedown') {
      if (L.latLngBounds(this.bounds).contains(e.latlng) && !this.hidden) {
        this.lastLatLng = e.latlng;
        this.mouseDown = true;
        this.map.dragging.disable();
        _ref = [this.ne, this.nw, this.se, this.sw];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          m = _ref[_i];
          _results.push(m.closePopup());
        }
        return _results;
      }
    } else if (e.type === 'mousemove') {
      if (this.mouseDown) {
        this.map.dragging.disable();
        currentLatLng = e.latlng;
        dLat = currentLatLng.lat - this.lastLatLng.lat;
        dLng = currentLatLng.lng - this.lastLatLng.lng;
        bounds = [[this.bounds[0][0] + dLat, this.bounds[0][1] + dLng], [this.bounds[1][0] + dLat, this.bounds[1][1] + dLng]];
        this.updateOverlay(bounds);
        this.lastLatLng = currentLatLng;
        return this.map.dragging.enable();
      }
    } else if (e.type === 'mouseup') {
      if (this.mouseDown) {
        this.mouseDown = false;
        return this.map.dragging.enable();
      }
    }
  };

  OverlayEditor.prototype.enableDrag = function() {
    var e, _i, _len, _ref, _results;
    _ref = ['mousedown', 'mousemove', 'mouseup'];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      _results.push(this.map.on(e, this.dragHandler));
    }
    return _results;
  };

  OverlayEditor.prototype.disableDrag = function() {
    var e, _i, _len, _ref, _results;
    _ref = ['mousedown', 'mousemove', 'mouseup'];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      _results.push(this.map.off(e, this.dragHandler));
    }
    return _results;
  };

  OverlayEditor.prototype.placeLandmark = function(e) {
    var _ref;
    if (!this.landmark1) {
      this.landmark1 = L.circleMarker(e.latlng, {
        fillColor: '#ff0000',
        fillOpacity: 0.5
      }).addTo(this.map);
      this.show();
      if (this.landmarkPairs.length === 0) {
        return $('#landmark-help').html('Now find the same landmark on your image and click on it.');
      } else {
        return $('#landmark-help').html('Now place the second landmark on the image.');
      }
    } else if (this.landmark1 && L.latLngBounds(this.bounds).contains(e.latlng)) {
      this.landmark2 = L.circleMarker(e.latlng, {
        fillColor: '#0000ff',
        fillOpacity: 0.5
      }).addTo(this.map);
      this.landmarkPairs.push([this.landmark1, this.landmark2]);
      if (this.landmarkPairs.length === 2) {
        $('#landmark-button').show();
        $('#landmark-help').html('');
        this.fitToLandmark();
        this.map.off('click', this.placeLandmark);
      } else {
        $('#landmark-help').html('Now place the second landmark on the map.');
        this.hide();
      }
      _ref = [null, null], this.landmark1 = _ref[0], this.landmark2 = _ref[1];
      return this.enableDrag();
    }
  };

  OverlayEditor.prototype.placeLandmarkPair = function() {
    var m, pair, _i, _j, _len, _len1, _ref;
    $('#landmark-button').hide();
    _ref = this.landmarkPairs;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pair = _ref[_i];
      for (_j = 0, _len1 = pair.length; _j < _len1; _j++) {
        m = pair[_j];
        this.map.removeLayer(m);
      }
    }
    this.landmarkPairs = [];
    this.disableDrag();
    this.map.on('click', this.placeLandmark);
    $('#landmark-help').html('Find a landmark on the map and click on it to place the first marker.');
    return this.hide();
  };

  OverlayEditor.prototype.fitToLandmark = function() {
    var bottomPadding, bounds, dx, dxMap, dy, dyMap, leftPadding, mapLatLng1, mapLatLng2, ne, overlayLatLng1, overlayLatLng2, rightPadding, rx1, rx2, ry1, ry2, sw, topPadding;
    sw = this.sw.getLatLng();
    ne = this.ne.getLatLng();
    overlayLatLng1 = this.landmarkPairs[0][1].getLatLng();
    overlayLatLng2 = this.landmarkPairs[1][1].getLatLng();
    mapLatLng1 = this.landmarkPairs[0][0].getLatLng();
    mapLatLng2 = this.landmarkPairs[1][0].getLatLng();
    dx = overlayLatLng2.lng - overlayLatLng1.lng;
    dy = overlayLatLng2.lat - overlayLatLng1.lat;
    rx1 = (overlayLatLng1.lng - sw.lng) / dx;
    ry1 = (overlayLatLng1.lat - sw.lat) / dy;
    rx2 = (ne.lng - overlayLatLng2.lng) / dx;
    ry2 = (ne.lat - overlayLatLng2.lat) / dy;
    dxMap = mapLatLng2.lng - mapLatLng1.lng;
    dyMap = mapLatLng2.lat - mapLatLng1.lat;
    leftPadding = dxMap * rx1;
    rightPadding = dxMap * rx2;
    bottomPadding = dyMap * ry1;
    topPadding = dyMap * ry2;
    bounds = [[0, 0], [0, 0]];
    bounds[0][0] = mapLatLng1.lat - bottomPadding;
    bounds[1][0] = mapLatLng2.lat + topPadding;
    bounds[0][1] = mapLatLng1.lng - leftPadding;
    bounds[1][1] = mapLatLng2.lng + rightPadding;
    return this.updateOverlay(bounds);
  };

  OverlayEditor.prototype.setNortheast = function(latLng) {
    return this.updateOverlay([this.bounds[0], [latLng.lat, latLng.lng]]);
  };

  OverlayEditor.prototype.setNorthwest = function(latLng) {
    return this.updateOverlay([[this.bounds[0][0], latLng.lng], [latLng.lat, this.bounds[1][1]]]);
  };

  OverlayEditor.prototype.setSoutheast = function(latLng) {
    return this.updateOverlay([[latLng.lat, this.bounds[0][1]], [this.bounds[1][0], latLng.lng]]);
  };

  OverlayEditor.prototype.setSouthwest = function(latLng) {
    return this.updateOverlay([[latLng.lat, latLng.lng], this.bounds[1]]);
  };

  OverlayEditor.prototype.createCornerMarkers = function(target) {
    var latLngBounds, ne, nw, se, sw;
    latLngBounds = L.latLngBounds(this.bounds);
    ne = L.marker(latLngBounds.getNorthEast(), {
      draggable: true
    }).addTo(target);
    nw = L.marker(latLngBounds.getNorthWest(), {
      draggable: true
    }).addTo(target);
    se = L.marker(latLngBounds.getSouthEast(), {
      draggable: true
    }).addTo(target);
    sw = L.marker(latLngBounds.getSouthWest(), {
      draggable: true
    }).addTo(target);
    ne.on('drag', (function(_this) {
      return function(e) {
        return _this.setNortheast(e.target._latlng);
      };
    })(this));
    nw.on('drag', (function(_this) {
      return function(e) {
        return _this.setNorthwest(e.target._latlng);
      };
    })(this));
    se.on('drag', (function(_this) {
      return function(e) {
        return _this.setSoutheast(e.target._latlng);
      };
    })(this));
    sw.on('drag', (function(_this) {
      return function(e) {
        return _this.setSouthwest(e.target._latlng);
      };
    })(this));
    return [ne, nw, se, sw];
  };

  OverlayEditor.prototype.initMinimap = function() {
    var osm2;
    this.overlay2 = L.imageOverlay(this.imgUrl, this.bounds, this.overlayOptions).addTo(this.map);
    this.minimapZoom = 13;
    osm2 = new L.TileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      minZoom: 0,
      maxZoom: 13,
      attribution: 'Map data © <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
    });
    this.miniMapLayers = L.layerGroup([osm2, this.overlay2]);
    return this.miniMap = new L.Control.MiniMap(this.miniMapLayers, {
      width: 300,
      height: 300,
      zoomLevelOffset: -3
    }).addTo(this.map);
  };

  OverlayEditor.prototype.updateCornerMarkers = function(bounds) {
    var latLngBounds, m, _i, _len, _ref, _results;
    this.bounds = bounds;
    latLngBounds = L.latLngBounds(bounds);
    this.ne.setLatLng(latLngBounds.getNorthEast());
    this.nw.setLatLng(latLngBounds.getNorthWest());
    this.se.setLatLng(latLngBounds.getSouthEast());
    this.sw.setLatLng(latLngBounds.getSouthWest());
    this.neMinimap.setLatLng(latLngBounds.getNorthEast());
    this.nwMinimap.setLatLng(latLngBounds.getNorthWest());
    this.seMinimap.setLatLng(latLngBounds.getSouthEast());
    this.swMinimap.setLatLng(latLngBounds.getSouthWest());
    $('#northeast_input_lat').val(this.ne.getLatLng().lat);
    $('#northeast_input_lng').val(this.ne.getLatLng().lng);
    $('#southwest_input_lat').val(this.sw.getLatLng().lat);
    $('#southwest_input_lng').val(this.sw.getLatLng().lng);
    _ref = [this.ne, this.sw, this.se, this.nw];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      m = _ref[_i];
      _results.push(m.bindPopup(m.getLatLng().lat + ', ' + m.getLatLng().lng));
    }
    return _results;
  };

  OverlayEditor.prototype.getCenterLatLng = function() {
    return L.latLng([this.sw.getLatLng().lat + (this.ne.getLatLng().lat - this.sw.getLatLng().lat) / 2, this.sw.getLatLng().lng + (this.ne.getLatLng().lng - this.sw.getLatLng().lng) / 2]);
  };

  OverlayEditor.prototype.updateOverlay = function(bounds) {
    var dx, dy, lat, latlng, lng, newOverlayHeight, newOverlayWidth, overlayHeight, overlayWidth, pair, _i, _len, _ref;
    _ref = this.landmarkPairs;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pair = _ref[_i];
      latlng = pair[1].getLatLng();
      dx = latlng.lng - this.bounds[0][1];
      dy = latlng.lat - this.bounds[0][0];
      overlayWidth = this.bounds[1][1] - this.bounds[0][1];
      overlayHeight = this.bounds[1][0] - this.bounds[0][0];
      newOverlayWidth = bounds[1][1] - bounds[0][1];
      newOverlayHeight = bounds[1][0] - bounds[0][0];
      lat = bounds[0][0] + newOverlayHeight * dy / overlayHeight;
      lng = bounds[0][1] + newOverlayWidth * dx / overlayWidth;
      pair[1].setLatLng([lat, lng]);
    }
    this.bounds = bounds;
    this.map.removeLayer(this.overlay);
    this.overlay = L.imageOverlay(this.imgUrl, this.bounds, this.overlayOptions).addTo(this.map);
    this.miniMapLayers.removeLayer(this.overlay2);
    this.overlay2 = L.imageOverlay(this.imgUrl, this.bounds, this.overlayOptions).addTo(this.map);
    this.miniMapLayers.addLayer(this.overlay2);
    return this.updateCornerMarkers(bounds);
  };

  OverlayEditor.prototype.hide = function() {
    if (!this.hidden) {
      this.map.removeLayer(this.overlay);
      this.map.removeLayer(this.ne);
      this.map.removeLayer(this.nw);
      this.map.removeLayer(this.se);
      this.map.removeLayer(this.sw);
      return this.hidden = true;
    }
  };

  OverlayEditor.prototype.show = function() {
    if (this.hidden) {
      this.map.addLayer(this.overlay);
      this.map.addLayer(this.ne);
      this.map.addLayer(this.nw);
      this.map.addLayer(this.se);
      this.map.addLayer(this.sw);
      return this.hidden = false;
    }
  };

  OverlayEditor.prototype.toggle = function() {
    if (this.hidden) {
      return this.show();
    } else {
      return this.hide();
    }
  };

  return OverlayEditor;

})();

module.exports = function(imgUrl, map, bounds, overlayOptions) {
  return new OverlayEditor(imgUrl, map, bounds, overlayOptions);
};



},{"./config.coffee":1}]},{},[2])