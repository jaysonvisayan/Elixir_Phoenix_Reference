var mapStyles = [
  {
    "elementType": "geometry",
    "stylers": [
    {
      "color": "#f5f5f5"
    }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
    {
      "visibility": "off"
    }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
    {
      "color": "#000000"
    }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
    {
      "color": "#f5f5f5"
    }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
    {
      "color": "#bdbdbd"
    }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
    {
      "color": "#eeeeee"
    }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
    {
      "color": "#757575"
    }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
    {
      "color": "#e5e5e5"
    }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
    {
      "color": "#9e9e9e"
    }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
    {
      "color": "#ffffff"
    }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.fill",
    "stylers": [
    {
      "color": "#94dfff"
    }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
    {
      "color": "#454545"
    }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
    {
      "color": "#dadada"
    }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [
    {
      "color": "#94dfff"
    }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
    {
      "color": "#3f3f3f"
    }
    ]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry.fill",
    "stylers": [
    {
      "color": "#94dfff"
    }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry.fill",
    "stylers": [
    {
      "color": "#91dfff"
    }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
    {
      "color": "#676767"
    }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
    {
      "color": "#e5e5e5"
    }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
    {
      "color": "#eeeeee"
    }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
    {
      "color": "#c9c9c9"
    }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [
    {
      "color": "#97dfff"
    }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
    {
      "color": "#9e9e9e"
    }
    ]
  }
  ];

  function initMap2(response){
    var uluru = {lat: parseFloat(response.latitude), lng: parseFloat(response.longitude)};
    var map = new google.maps.Map(document.getElementById('map'), {
      zoom: 18,
      center: uluru,
      styles: mapStyles,
      scrollwheel: false
    });


    var iconBase = '/images/';
    var icons = {
      clinic: {
        icon: iconBase + 'marker_1.svg'
      },
      hospital: {
        icon: iconBase + 'marker_2.svg'
      }
    };
    var markers;

    var infowindow = new google.maps.InfoWindow();

    var features = [
      {
        position: new google.maps.LatLng(parseFloat(response.latitude), parseFloat(response.longitude)),
        type: 'hospital',
        html: '<h4>' + response.facility_code + " " + response.facility_name + '</h4>' + '<p class="gray zero_bottom_padding">' + response.facility_address1 + " " + response.facility_address2 + '</p>' + '<p class="zero_bottom_padding">' + response.facility_phone_no + '</p>'
      }
    ];

    var markers;

    var infowindow = new google.maps.InfoWindow();

    features.forEach(function(feature) {
      var marker = new google.maps.Marker({
        position: feature.position,
        icon: icons[feature.type].icon,
        map: map
      });



      google.maps.event.addListener(marker, 'click', function () {
        infowindow.setContent(feature.html);
        infowindow.open(map, marker);
      });
    });

  }

  function initMap() {
    var uluru = {lat: 14.5593, lng: 121.0146};
    var map = new google.maps.Map(document.getElementById('map'), {
      zoom: 18,
      center: uluru,
      styles: mapStyles,
      scrollwheel: false
    });


    var iconBase = '/images/';
    var icons = {
      clinic: {
        icon: iconBase + 'marker_1.svg'
      },
      hospital: {
        icon: iconBase + 'marker_2.svg'
      }
    };
    var markers;

    var infowindow = new google.maps.InfoWindow();

    var features = [
      {
        position: new google.maps.LatLng(14.5593, 121.0146),
        type: 'hospital',
        html: '<h4>MAKATI MEDICAL CENTER</h4>'+'<p class="gray zero_bottom_padding">1234567 1234568 Makati City 1206 Metro Manila</p>'+'<p class="zero_bottom_padding">7656734</p>'+'<p class="gray">Affiliated Doctor/s</p>'
      }
  ];

    var markers;

    var infowindow = new google.maps.InfoWindow();

    features.forEach(function(feature) {
      var marker = new google.maps.Marker({
        position: feature.position,
        icon: icons[feature.type].icon,
        map: map
      });



      google.maps.event.addListener(marker, 'click', function () {
        infowindow.setContent(feature.html);
        infowindow.open(map, marker);
      });
    });
  }

  function initMapAllFacility(response){
      var map = new google.maps.Map(document.getElementById('map'), {
        zoom: 15,
        styles: mapStyles,
        scrollwheel: false
      });


      var iconBase = '/images/';
      var icons = {
        clinic: {
          icon: iconBase + 'marker_1.svg'
        },
        hospital: {
          icon: iconBase + 'marker_2.svg'
        }
      };

      var bounds = new google.maps.LatLngBounds();
      var features = [];
    for (var i=0;i<response.length;i++){
          var position =  new google.maps.LatLng(parseFloat(response[i].latitude), parseFloat(response[i].longitude));
          var type = 'hospital';
          var html = '<h4>' + response[i].facility_code + " " + response[i].facility_name + '</h4>' + '<p class="gray zero_bottom_padding">' + response[i].facility_address1 + " " + response[i].facility_address2 + '</p>' + '<p class="zero_bottom_padding">' + response[i].facility_phone_no + '</p>';

      var infowindow = new google.maps.InfoWindow();
      bounds.extend(position)

        var marker = new google.maps.Marker({
          position: position,
          icon: icons[type].icon,
          map: map
        });
        map.fitBounds(bounds);
        features.push([position, type, html, marker])

    }
    features.forEach(function(feature) {
        google.maps.event.addListener(feature[3], 'click', function () {
          infowindow.setContent(feature[2]);
          infowindow.open(map, feature[3]);
        });
    });
  }

google.maps.event.addDomListener(window, 'load', initMap);


