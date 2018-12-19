function myFunction() {
    alert("I am an alert box!");
}

onmount('div[role="address-form"]', function(e) {
    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src = "https://maps.googleapis.com/maps/api/js?key=AIzaSyB-FlYg_DB4v-UcHCH2XxX6MWy0qSF-9C4&callback=initMap";
    script.setAttribute = ("async", "async");
    script.setAttribute = ("defer", "defer");
    document.body.appendChild(script);
    var map, geocoder, marker, latitude, longitude, bounds, loc;
    var image = "/images/marker.svg";
    window.initMap = function() {
        map = new google.maps.Map(document.getElementById('map'), {
            center: { lat: 14.599512, lng: 120.984222 },
            zoom: 20
        });
        geocoder = new google.maps.Geocoder();
        if ($('#account_longitude').val() != '') {
            setMarker($('#account_longitude').val() * 1, $('#account_latitude').val() * 1);
        } else {
            marker = new google.maps.Marker({
                position: { lat: 14.599512, lng: 120.984222 },
                map: map,
                draggable: true,
                icon: image
            });
            google.maps.event.addListener(marker, 'dragend', function(evt) {
                $('#account_longitude').val(evt.latLng.lng());
                $('#account_latitude').val(evt.latLng.lat());
                setAddress($('#account_longitude').val() * 1, $('#account_latitude').val() * 1);
            });
        }
    }

    $('.ui.segment').on('mouseenter', function(e) {
        var address = $('#account_line_2').val() + " " + $('#account_city').val() + " " + $('#account_province').val()
        geoCodeAddress(address, 15)

    });

    $('.key-up-address').keyup(function(e) {
        var address = $('#account_line_2').val() + " " + $('#account_city').val() + " " + $('#account_province').val()
        geoCodeAddress(address, 15)
    });

    $('.key-up-haddress').keyup(function(e) {
        var address = $('#account_line_2_v2').val() + " " + $('#account_city_v2').val() + " " + $('#account_province_v2').val()
        geoCodeAddress(address, 15)
    });

    const geoCodeAddress = (address, zoom) => {
        return new Promise(function(resolve, reject) {
            geocoder.geocode({ 'address': address }, function(results, status) {
                if (status == google.maps.GeocoderStatus.OK) {
                    latitude = results[0].geometry.location.lat();
                    longitude = results[0].geometry.location.lng();
                    map = new google.maps.Map(document.getElementById('map'), {
                        zoom: zoom,
                        center: { lat: latitude, lng: longitude }
                    });
                    setMarker(longitude, latitude);
                }
            });
        });
    }
    const setMarker = (longitude, latitude) => {
        bounds = new google.maps.LatLngBounds();
        marker = new google.maps.Marker({
            position: { lat: latitude, lng: longitude },
            map: map,
            draggable: true,
            icon: image
        });
        loc = new google.maps.LatLng(marker.position.lat(), marker.position.lng());
        bounds.extend(loc);
        $('#account_longitude').val(longitude);
        $('#account_latitude').val(latitude);
        google.maps.event.addListener(marker, 'dragend', function(evt) {
            $('#account_longitude').val(evt.latLng.lng());
            $('#account_latitude').val(evt.latLng.lat());
            setAddress($('#account_longitude').val() * 1, $('#account_latitude').val() * 1);
        });
        map.setCenter(marker.position);
        marker.setMap(map);
        map.fitBounds(bounds);
    }
    const setAddress = (longitude, latitude) => {
        var latlng = new google.maps.LatLng(latitude, longitude);
        geocoder = new google.maps.Geocoder();
        geocoder.geocode({ 'latLng': latlng }, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                var componentForm = {
                    route: 'long_name',
                    political: 'long_name',
                    sublocality: 'long_name',
                    locality: 'long_name',
                    administrative_area_level_1: 'short_name',
                    postal_code: 'short_name'
                };
                var AccountForm = {
                    route: 'account_line_2',
                    political: 'account_city',
                    sublocality: 'account_province',
                    locality: 'account_city',
                    administrative_area_level_1: 'account_region',
                    postal_code: 'account_postal_code'
                };
                resetAddress();
                for (var i = 0; i < results[0].address_components.length; i++) {
                    var addressType = results[0].address_components[i].types[0];
                    if (componentForm[addressType]) {
                        var val = results[0].address_components[i][componentForm[addressType]];
                        var val2 = document.getElementById(AccountForm[addressType]).value;
                        var val3 = val2 + ' ' + val;
                        document.getElementById(AccountForm[addressType]).value = $.trim(val3);
                        //if (addressType == "administrative_area_level_1") {
                        if (results[0].address_components[4].long_name == "Philippines") {
                            document.getElementById('account_province').value = $.trim(results[0].address_components[2].long_name);
                        } else {
                            document.getElementById('account_province').value = $.trim(results[0].address_components[4].long_name);
                        }

                        document.getElementById('account_line_1').value = $.trim(
                            results[0].address_components[0].short_name
                        );
                        document.getElementById('account_line_2').value = $.trim(
                            results[0].address_components[0].short_name
                        );
                        document.getElementById('account_country').value = $.trim(
                            "Philippines"
                        );
                        // }
                    }
                }
                $('div').removeClass('error')
                $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
            }
        });
    }
    const resetAddress = () => {
        $('#account_line_2').val('');
        $('#account_region').val('');
        $('#account_province').val('');
        $('#account_city').val('');
        $('#account_postal_code').val('');
    }
});

// facility address map start
onmount('div[role="address-form-facility"]', function(e) {

  function get_location_group(region){
    const csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/facilities/${region}/get_lg_by_region`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let location_group = JSON.parse(response);

        $('.ui.label.transition.visible').remove();
        if(location_group.length > 0){

          let options = '<option value="">Location Group</option>';
          let items = '';

          for(let i=0; i < location_group.length; i++){
            options =
              options +
              '<option value="' +
              location_group[i].id +
              '">' + location_group[i].name +
              '</option>';

            items =
              items +
              '<div class="item" data-value="' +
              location_group[i].id +
              '">' + location_group[i].name +
              '</div>';
          }

          $('select[id="facility_location_group_ids"]').html(options);
          $('div[id="drpTitle"]').html('Location Group');
          $('div[id="drpTitle"]').attr('class', 'default text');
          $('div[id="drpItem"]').html(items);

        }else{
          let options = '<option value="">No Location Group Found</option>';

          $('select[id="facility_location_group_ids"]').html(options);
          $('div[id="drpTitle"]').html('No Location Group');
          $('div[id="drpTitle"]').attr('class', 'default text');
          $('div[id="drpItem"]').html('');

          alertify.error('<i class="close icon"></i>No location group created for this region. Please create location group.')
        }

      }
    });

  }

  $('input[name="facility[region]"]').blur(function() {
    get_location_group($('input[name="facility[region]"]').val());
  });

  var script = document.createElement("script");
  script.type = "text/javascript";
  script.src = "https://maps.googleapis.com/maps/api/js?key=AIzaSyB-FlYg_DB4v-UcHCH2XxX6MWy0qSF-9C4&callback=initMap";
  script.setAttribute = ("async", "async");
  script.setAttribute = ("defer", "defer");
  document.body.appendChild(script);
  var map,geocoder, marker, latitude, longitude, bounds, loc;
  window.initMap = function() {
    if($('div[id="map-edit"]').length == 0){
      map = new google.maps.Map(document.getElementById('map'), {
        center: {lat: 14.599512, lng: 120.984222},
        zoom: 20
      });
    }else{
      map = new google.maps.Map(document.getElementById('map-edit'), {
        center: {lat: 14.599512, lng: 120.984222},
        zoom: 20
      });
    }

    geocoder = new google.maps.Geocoder();

    if($('#facility_longitude').val() != '') {
      setMarker($('#facility_longitude').val() * 1, $('#facility_latitude').val() * 1);
    } else {

      if($('div[id="map-edit"]').length == 0){
        marker = new google.maps.Marker({
          position: {lat: 14.599512, lng: 120.984222},
          map: map,
          draggable: true
        });
      }else{
        marker = new google.maps.Marker({
          position: {lat: 14.599512, lng: 120.984222},
          map: map,
          draggable: false
        });
      }

      google.maps.event.addListener(marker, 'dragend', function(evt){
        $('div[role="map_details"]').form('clear');
        $('#facility_longitude').val(evt.latLng.lng());
        $('#facility_latitude').val(evt.latLng.lat());
        setAddress($('#facility_longitude').val() * 1, $('#facility_latitude').val() * 1);
      });
    }

  }

  $('.key-up-address').keyup(function (e) {
    var address = $('#facility_line_1').val() + " " + $('#facility_line_2').val() + " " + $('#facility_city').val() + " " + $('#facility_province').val() + " " + $('#facility_country').val();
    geoCodeAddress(address, 15);
  });

  const geoCodeAddress = (address, zoom) => {
    return new Promise(function(resolve,reject) {
      geocoder.geocode( { 'address': address}, function(results, status) {
        if (status == google.maps.GeocoderStatus.OK) {
          latitude = results[0].geometry.location.lat();
          longitude = results[0].geometry.location.lng();
          map = new google.maps.Map(document.getElementById('map'), {
            zoom: zoom,
            center: {lat: latitude, lng: longitude}
          });
          setMarker(longitude, latitude);
        }
      });
    });
  }

  const setMarker = (longitude, latitude) => {
    bounds  = new google.maps.LatLngBounds();

    if($('div[id="map-edit"]').length == 0){
      marker = new google.maps.Marker({
        position: {lat: latitude, lng: longitude},
        map: map,
        draggable: true
      });
    }else{
      marker = new google.maps.Marker({
        position: {lat: latitude, lng: longitude},
        map: map,
        draggable: false
      });
    }

    loc = new google.maps.LatLng(marker.position.lat(),marker.position.lng());
    bounds.extend(loc);
    $('#facility_longitude').val(longitude);
    $('#facility_latitude').val(latitude);

    google.maps.event.addListener(marker, 'dragend', function(evt){
      $('div[role="map_details"]').form('clear');
      $('#facility_longitude').val(evt.latLng.lng());
      $('#facility_latitude').val(evt.latLng.lat());
      setAddress($('#facility_longitude').val() * 1, $('#facility_latitude').val() * 1);
    });

    map.setCenter(marker.position);
    marker.setMap(map);
    map.fitBounds(bounds);
  }

  const setAddress = (longitude, latitude) => {
    var latlng = new google.maps.LatLng(latitude, longitude);
    geocoder = new google.maps.Geocoder();
    geocoder.geocode({ 'latLng': latlng }, function (results, status) {
      if (status == google.maps.GeocoderStatus.OK) {
        var componentForm = {
          street_number: 'long_name',
          route: 'long_name',
          political: 'long_name',
          locality: 'long_name',
          administrative_area_level_1: 'long_name',
          country: 'long_name',
          postal_code: 'short_name',
        };
        var FacilityForm = {
          street_number: 'facility_line_1',
          route: 'facility_line_1',
          political: 'facility_line_2',
          locality: 'facility_city',
          administrative_area_level_1: 'facility_province',
          country: 'facility_country',
          postal_code: 'facility_postal_code',
        };
        resetAddress();
        for (var i = 0; i < results[0].address_components.length; i++) {
          var addressType = results[0].address_components[i].types[0];
          if (componentForm[addressType]) {
            var val = results[0].address_components[i][componentForm[addressType]];
            var val2 = document.getElementById(FacilityForm[addressType]).value;
            var val3 = val2 + ' ' + val;
            document.getElementById(FacilityForm[addressType]).value = $.trim(val3);
            if (addressType == "administrative_area_level_1"){
              let region = $.trim(results[0].address_components[i].short_name)

              document.getElementById('facility_region').value = region;

              get_location_group(region);
            }
          }
        }
      }
    });
  }

  const resetAddress = () => {
    $('#facility_line_1').val('');
    $('#facility_line_2').val('');
    $('#facility_city').val('');
    $('#facility_region').val('');
    $('#facility_province').val('');
    $('#facility_country').val('');
    $('#facility_postal_code').val('');
  }
});
//facility address map end

// Member Map
onmount('div[role="address-member-form"]', function(e) {
    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src = "https://maps.googleapis.com/maps/api/js?key=AIzaSyB-FlYg_DB4v-UcHCH2XxX6MWy0qSF-9C4&callback=initMap";
    script.setAttribute = ("async", "async");
    script.setAttribute = ("defer", "defer");
    document.body.appendChild(script);
    var map, geocoder, marker, latitude, longitude, bounds, loc;
    var image = "/images/marker.svg";
    window.initMap = function() {
        map = new google.maps.Map(document.getElementById('map'), {
            center: { lat: 14.599512, lng: 120.984222 },
            zoom: 20
        });
        geocoder = new google.maps.Geocoder();
        if ($('#member_longitude').val() != '') {
            setMarker($('#member_longitude').val() * 1, $('#member_latitude').val() * 1);
        } else {
            marker = new google.maps.Marker({
                position: { lat: 14.599512, lng: 120.984222 },
                map: map,
                draggable: true,
                icon: image
            });
            google.maps.event.addListener(marker, 'dragend', function(evt) {
                $('#member_longitude').val(evt.latLng.lng());
                $('#member_latitude').val(evt.latLng.lat());
                setAddress($('#member_longitude').val() * 1, $('#member_latitude').val() * 1);
            });
        }
    }

    $('.ui.segment').on('mouseenter', function(e) {
        var address = $('#member_street_name').val() + " " + $('#member_city').val() + " " +
            $('#member_province').val()
        geoCodeAddress(address, 15)
    });

    $('.key-up-address').keyup(function(e) {
        var address = $('#member_street_name').val() + " " + $('#member_city').val() + " " +
            $('#member_province').val()
        geoCodeAddress(address, 15)
    });

    const geoCodeAddress = (address, zoom) => {
        return new Promise(function(resolve, reject) {
            geocoder.geocode({ 'address': address }, function(results, status) {
                if (status == google.maps.GeocoderStatus.OK) {
                    latitude = results[0].geometry.location.lat();
                    longitude = results[0].geometry.location.lng();
                    map = new google.maps.Map(document.getElementById('map'), {
                        zoom: zoom,
                        center: { lat: latitude, lng: longitude }
                    });
                    setMarker(longitude, latitude);
                }
            });
        });
    }
    const setMarker = (longitude, latitude) => {
        bounds = new google.maps.LatLngBounds();
        marker = new google.maps.Marker({
            position: { lat: latitude, lng: longitude },
            map: map,
            draggable: true,
            icon: image
        });
        loc = new google.maps.LatLng(marker.position.lat(), marker.position.lng());
        bounds.extend(loc);
        $('#member_longitude').val(longitude);
        $('#member_latitude').val(latitude);
        google.maps.event.addListener(marker, 'dragend', function(evt) {
            $('#member_longitude').val(evt.latLng.lng());
            $('#member_latitude').val(evt.latLng.lat());
            setAddress($('#member_longitude').val() * 1, $('#member_latitude').val() * 1);
        });
        map.setCenter(marker.position);
        marker.setMap(map);
        map.fitBounds(bounds);
    }
    const setAddress = (longitude, latitude) => {
        var latlng = new google.maps.LatLng(latitude, longitude);
        geocoder = new google.maps.Geocoder();
        geocoder.geocode({ 'latLng': latlng }, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                var componentForm = {
                    route: 'long_name',
                    political: 'long_name',
                    sublocality: 'long_name',
                    locality: 'long_name',
                    administrative_area_level_1: 'short_name',
                    postal_code: 'short_name'
                };
                var AccountForm = {
                    route: 'member_street_name',
                    political: 'member_city',
                    sublocality: 'member_province',
                    locality: 'member_city',
                    administrative_area_level_1: 'member_region',
                    postal_code: 'member_postal'
                };
                resetAddress();
                for (var i = 0; i < results[0].address_components.length; i++) {
                    var addressType = results[0].address_components[i].types[0];
                    if (componentForm[addressType]) {
                        var val = results[0].address_components[i][componentForm[addressType]];
                        var val2 = document.getElementById(AccountForm[addressType]).value;
                        var val3 = val2 + ' ' + val;
                        document.getElementById(AccountForm[addressType]).value = $.trim(val3);
                        //if (addressType == "administrative_area_level_1") {
                        if (results[0].address_components[4].long_name == "Philippines") {
                            document.getElementById('member_province').value = $.trim(results[0].address_components[2].long_name);
                        } else {
                            document.getElementById('member_province').value = $.trim(results[0].address_components[4].long_name);
                        }

                        document.getElementById('member_street_name').value = $.trim(
                            results[0].address_components[0].short_name
                        );
                        document.getElementById('member_country').value = $.trim(
                            "Philippines"
                        );
                        // }
                    }
                }
                $('div').removeClass('error')
                $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()
            }
        });
    }
    const resetAddress = () => {
        $('#member_street_name').val('');
        $('#member_region').val('');
        $('#member_province').val('');
        $('#member_city').val('');
        $('#member_postal').val('');
    }
});

//Map Display Only
onmount('div[role="map-display"]', function(e) {
    var latitude = parseFloat($('#latitude').val());
    var longitude = parseFloat($('#longitude').val());

    if(latitude != '' && longitude != '' && !isNaN(latitude) && !isNaN(longitude)){

    var script = document.createElement("script");
    script.type = "text/javascript";
    script.src = "https://maps.googleapis.com/maps/api/js?key=AIzaSyB-FlYg_DB4v-UcHCH2XxX6MWy0qSF-9C4&callback=initMap";
    script.setAttribute = ("async", "async");
    script.setAttribute = ("defer", "defer");
    document.body.appendChild(script);
    var map, marker;
    var image = "/images/marker.svg";
    window.initMap = function() {
        map = new google.maps.Map(document.getElementById('map'), {
            center: { lat: latitude, lng: longitude },
            zoom: 20,
            size: new google.maps.Size(200, 200)
        });
        marker = new google.maps.Marker({
            position: { lat: latitude, lng: longitude },
            map: map,
            draggable: false,
            icon: image
        });
    }

  }
});
