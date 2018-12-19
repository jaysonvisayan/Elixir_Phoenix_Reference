onmount('div[id="evoucherLogin"]', function () {

  $('#evoucherLoginForm')
  .form({
    inline: true,
    fields: {
      evoucher_number: {
        identifier: 'evoucher_number',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Evoucher'
        }]
      },
      effectivity_date: {
        identifier: 'company_name',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Company Name'
        }]
      }
    }
  })

});

onmount('div[id="evoucherMemberDetails"]', function () {

	const today = new Date()
	const valid_mobile_prefix = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994", "976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"]
	const m_min_age = $('#maleAge').attr('min')
	const m_max_age = $('#maleAge').attr('max')
	const f_min_age = $('#femaleAge').attr('min')
	const f_max_age = $('#femaleAge').attr('max')
  const mobiles = JSON.parse($('input[id="mobiles"]').val())

  $('#member_gender_Male').change(function(){
    let male = $('#maleGender').val()
    if ( male == "false" )
     {
       alertify.error('<i id="notification_error" class="close icon" style="float:right"></i><p style="text-align:left">You are not allowed to avail the package in the e-voucher reason: Gender is not eligible</p>');
       $('#member_gender_Male').attr('checked',false);
     }
  });

  $('#member_gender_Female').change(function(){
    let female = $('#femaleGender').val()
    if ( female == "false" )
    {
       alertify.error('<i id="notification_error" class="close icon" style="float:right"></i><p style="text-align:left">You are not allowed to avail the package in the e-voucher reason: Gender is not eligible</p>');
       $('#member_gender_Female').attr('checked',false);
    }
  });

  $.fn.form.settings.rules.mobileChecker = function(param) {
    let unmasked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmasked_value.length == 11) {
      return true
    } else {
      return false
    }
  }

  $.fn.form.settings.rules.mobilePrefixChecker = function(param) {
  	return valid_mobile_prefix.indexOf(param.substring(1, 4)) == -1 ? false : true
  }

  $.fn.form.settings.rules.ageChecker = function(param) {
  	if (param == "") {
  		return true
  	} else { 
  		let gender = $('input[name="member[gender]"]:checked').val()
  		let age = moment().diff(param, 'years')
  		let min_age = 0
  		let max_age = 0
  		if (gender == "Male") {
  			min_age = m_min_age
  			max_age = m_max_age
  		} else {
  			min_age = f_min_age
  			max_age = f_max_age
  		}
  		if (max_age == "" && min_age == "") {
  			return false
  		} else {
	  		if (age >= min_age && age <= max_age) {
	  			return true
	  		} else {
	  			return false
	  		}
  		}
  	}
  }

  $.fn.form.settings.rules.checkMobile = function(param) {
    let unmasked_value = param.replace(/-/g, '').replace(/_/g, '')
    return mobiles.indexOf(unmasked_value.slice(1)) == -1 ? true : false;
  }

  let Inputmask = require('inputmask')
  let im = new Inputmask("0\\999-999-9999", {
    "clearIncomplete": false,
  })
  im.mask($('.mobile'))

  $('#birthdate').calendar({
    type: 'date',
    startMode: 'year',
    maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
    onChange: function (start_date, text, mode) {
      let birthdate = text.split("-", 1)
      let today_date = new Date()
      let total_age = today_date.getFullYear() - parseInt(birthdate[0])
      if (total_age > 60){
        $('#member_senior_true').prop('checked', true)
        $('#member_senior_false').attr('disabled', true)
        $('#member_senior_true').attr('disabled', false)
      } else if (total_age < 60) {
        $('#member_senior_false').prop('checked', true)
        $('#member_senior_true').attr('disabled', true)
        $('#member_senior_false').attr('disabled', false)
      }

      if ($('input[name="member[senior]"]:checked').val() == "true"){
        $('input[name="member[senior_id]"]').prop('disabled', false)
        $('div[id="senior_upload"]').removeClass("disabled")
      }
      else {
        $('input[name="member[senior_id]"]').prop('disabled', true)
        $('div[id="senior_upload"]').addClass("disabled")
      }
    },
    formatter: {
      date: function(date, settings) {
        if (!date) return '';
        var day = date.getDate() + '';
        if (day.length < 2) {
          day = '0' + day;
        }
        var month = (date.getMonth() + 1) + '';
        if (month.length < 2) {
          month = '0' + month;
        }
        var year = date.getFullYear();
        return month + '-' + day + '-' + year;
      }
    }
  })

  $('.person.name').on('keypress', function(evt){
    let theEvent = evt || window.event;
    let key = theEvent.keyCode || theEvent.which;
    key = String.fromCharCode( key );
    let regex = /[a-zA-Z,. -]/;

    if($(this).val().length <= 1 && evt.keyCode == 32 || regex.test(key) == false){
      return false;
    }else{
      $(this).on('focusout', function(evt){
        $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
      })
    }
  })

  $('#upload_secondary').click(function() {
    $('#secondary_id').click()
  });

  $('#upload_primary').click(function() {
    $('#primary_id').click()
  });

  $('#primary_id').change(function(){
    let file = event.target.files[0];
    var fileName = file.name;

    if (file.size < 5000000)
    {
      var ispic = checkfiletype(fileName);
      if (ispic)
      {
        $('#capture_primary').hide()
        $('.upload_txt_primary').text(file.name + " ")
        $('#remove_primary').show();
      }
      else if (!ispic)
      {
        $(this).val('')
        $('.upload_txt_primary').text('Upload Primary ID ')
        alertify.error('<i id="notification_error" class="close icon" style="float:right"></i><p style="text-align:left">Acceptable file types are jpg, jpeg and png only</p>');
      }
    }
    else
    {
      $(this).val('')
      $('.upload_txt_primary').text('Upload Primary ID ')
      alertify.error('<i id="notification_error" class="close icon" style="float:right"></i><p style="text-align:left">Maximum file size is 5 MB</p>')
    }
  });

  $('#remove_primary').click(function(){
    $('#primary_id').val(null);
    $('.upload_txt_primary').text('Upload Primary ID ')
    $('#capture_primary').show()
    $(this).hide();
    if( $('input[name="member[is_edit]"]').val() == "true" ) {
      $('#delete-primary-id').submit()
    }
  });

  $('#remove_secondary').click(function(){
    $('#secondary_id').val(null);
    $('.upload_txt_secondary').text('Upload Secondary ID ')
    $('#capture_secondary').show()
    $(this).hide();
    if( $('input[name="member[is_edit]"]').val() == "true" ) {
      $('#delete-secondary-id').submit()
    }
  });

  $('#secondary_id').change(function(){
    let file = event.target.files[0];
    var fileName = file.name;

    if (file.size < 5000000)
    {
      var ispic = checkfiletype(fileName);
      if (ispic)
      {
        $('#capture_secondary').hide()
        $('.upload_txt_secondary').text(file.name + " ")
        $('#remove_secondary').show();
      }
      else if (!ispic)
      {
        $(this).val('')
        $('.upload_txt').text('Upload Secondary ID ')
        alertify.error('<i id="notification_error" class="close icon" style="float:right"></i><p style="text-align:left">Acceptable file types are jpg, jpeg and png only</p>');
      }
    }
    else
    {
      $(this).val('')
      $('.upload_txt').text('Upload Secondary ID ')
      alertify.error('<i id="notification_error" class="close icon" style="float:right"></i><p style="text-align:left">Maximum file size is 5 MB</p>');
    }
  });
  
  function checkfiletype (fileName)
  {
    var ext = "";
    var i = fileName.lastIndexOf('.');
    if (i > 0) {
        ext = fileName.substring(i+1);
    }
    switch (ext.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    return true;
    }
  };

  $('#evoucherMemberDetailsForm')
  .form({
    inline: true,
    fields: {
      first_name: {
        identifier: 'first_name',
        rules: [{
          type: 'empty',
          prompt: 'Please enter First name'
        }]
      },
      last_name: {
        identifier: 'last_name',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Last name'
        }]
      },
      civil_status: {
        identifier: 'civil_status',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Civil Status'
        }]
      },
      birthdate: {
        identifier: 'birthdate',
        rules: [
        	{
          	type: 'empty',
          	prompt: 'Please enter Birthdate'
        	},
        	{
        		type: 'ageChecker[param]',
        		prompt: 'You are not allowed to avail the package in the e-voucher reason: Age is not eligible'
        	}
        ]
      },
      mobile: {
        identifier: 'mobile',
        rules: [
        	{
        		type: 'empty',
        		prompt: 'Please enter Mobile number'
        	},
          {
            type: 'mobileChecker[param]',
            prompt: 'Please enter a valid mobile number'
          },
          {
            type: 'mobilePrefixChecker[param]',
            prompt: 'Invalid Mobile number prefix'
          },
          {
            type: 'checkMobile[param]',
            prompt: 'Mobile number already exists'
          }
        ]
      },
      email: {
        identifier: 'email',
        optional: true,
        rules: [
        	{
        		type: 'email',
        		prompt: 'Please enter a valid email'
        	}
        ]
      },
      'member[gender]': {
        identifier: 'member[gender]',
        rules: [
          {
            type   : 'checked',
            prompt : 'Please select an option'
          }
        ]
      }
      // primary_id: {
      //   identifier: 'primary_id',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please upload primary id'
      //   }]
      // }
    }
  })
  $('.dropdown').dropdown()

  let pic = $('#member_primary_id_data').val();

  if(pic == "") {
  $('#evoucherMemberDetailsForm')
  .form({
    inline: true,
    fields: {
      first_name: {
        identifier: 'first_name',
        rules: [{
          type: 'empty',
          prompt: 'Please enter First name'
        }]
      },
      last_name: {
        identifier: 'last_name',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Last name'
        }]
      },
      civil_status: {
        identifier: 'civil_status',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Civil Status'
        }]
      },
      birthdate: {
        identifier: 'birthdate',
        rules: [
        	{
          	type: 'empty',
          	prompt: 'Please enter Birthdate'
        	},
        	{
        		type: 'ageChecker[param]',
        		prompt: 'You are not allowed to avail the package in the e-voucher reason: Age is not eligible'
        	}
        ]
      },
      mobile: {
        identifier: 'mobile',
        rules: [
        	{
        		type: 'empty',
        		prompt: 'Please enter Mobile number'
        	},
          {
            type: 'mobileChecker[param]',
            prompt: 'Please enter a valid mobile number'
          },
          {
            type: 'mobilePrefixChecker[param]',
            prompt: 'Invalid Mobile number prefix'
          },
          {
            type: 'checkMobile[param]',
            prompt: 'Mobile number already exists'
          }
        ]
      },
      email: {
        identifier: 'email',
        optional: true,
        rules: [
        	{
        		type: 'email',
        		prompt: 'Please enter a valid email'
        	}
        ]
      },
      'member[gender]': {
        identifier: 'member[gender]',
        rules: [
          {
            type   : 'checked',
            prompt : 'Please select an option'
          }
        ]
      }
      // primary_id: {
      //   identifier: 'primary_id',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please upload Primary ID'
      //   }]
      // }
    }
  })
  $('.dropdown').dropdown()
  }

  // PRIMARY CAPTURE PHOTO

  $('#capture_primary').on('click', function(){
    let data;
    $('#modal_facial_capture')
    .modal({ autofocus: false, closable: false, observeChanges: true })
    .modal("show");
    var video;
    var webcamStream;
    var video = document.getElementById('video');
    var canvas = document.getElementById('canvas');
    var photo = document.getElementById('primary-photo-cam');
    var track;

    function clearphoto() {
      var context = canvas.getContext('2d');
      context.fillStyle = "#FFF";
      context.fillRect(0, 0, canvas.width, canvas.height);

      var data = canvas.toDataURL('image/png');
      photo.setAttribute('src', data);
    }

    navigator.mediaDevices.getUserMedia({ video: true, audio: false })
      .then(function(stream) {
          video.srcObject = stream;
          track = stream.getTracks()[0];
          video.play();
      })
      .catch(function(err) {
          console.log("An error occurred! " + err);
    });

    // TAKE PHOTO
    $('#take_image').on('click', function() {
      var context = canvas.getContext('2d');
      canvas.width = 320;
      canvas.height = 240;
      context.drawImage(video, 0, 0, 320, 240);

      data = canvas.toDataURL('image/png');
      $('p[role="append_new_capture"]').empty()

    })

    // SAVE PHOTO
    $('#submit_capture').on('click', function(e) {
      $('#photo').attr('src', data);
      $('#primary-photo-cam').val(data)
      $('#photo-web-cam').val(data)

      if($('#photo-web-cam').val() == ""){
        let error = '<div id="message" class="ui negative message"><ul class="list">'
        $('div[id="message"]').remove()
        $('p[role="append_new_capture"]').append(error + '<li>Please take a photo.</li> </ul> </div>')
        e.preventDefault()
      } else {
        track.stop();
        clearphoto();
        $('#upload_primary').hide()
        $('#remove_primary_capture').show();
        $('.upload_txt_primary_capture').text('evoucher_primary_id.png ')
        $('#photo-web-cam').val("")
        $('#modal_facial_capture').modal("hide");
      }
    })

    $('.close.icon').on('click', function() {
      track.stop();
      clearphoto();
    })

    $('#remove_primary_capture').on('click', function() {
      $('#primary-photo-cam').val("")
      $('#primary_id').val(null);
      $('.upload_txt_primary_capture').text('Capture Photo ')
      $('.upload_txt_primary').text('Upload Primary ID ')
      $('#capture_primary').show()
      $('#upload_primary').show()
      $(this).hide();
    })
  })

  // SECONDARY CAPTURE PHOTO

  $('#capture_secondary').on('click', function(){
    let data;

    $('#modal_facial_capture2')
    .modal({ autofocus: false, closable: false, observeChanges: true })
    .modal("show");
    var video;
    var webcamStream;
    var video = document.getElementById('video2');
    var canvas = document.getElementById('canvas2');
    var photo = document.getElementById('secondary-photo-cam');
    var track;

    function clearphoto() {
      var context = canvas.getContext('2d');
      context.fillStyle = "#FFF";
      context.fillRect(0, 0, canvas.width, canvas.height);

      var data = canvas.toDataURL('image/png');
      photo.setAttribute('src', data);
    }

    navigator.mediaDevices.getUserMedia({ video: true, audio: false })
      .then(function(stream) {
          video.srcObject = stream;
          track = stream.getTracks()[0];
          video.play();
      })
      .catch(function(err) {
          console.log("An error occurred! " + err);
    });

    // TAKE PHOTO
    $('#take_image2').on('click', function() {
      var context = canvas.getContext('2d');
      canvas.width = 320;
      canvas.height = 240;
      context.drawImage(video, 0, 0, 320, 240);

      data = canvas.toDataURL('image/png');
      $('p[role="append_new_capture2"]').empty()

    })

    // SAVE PHOTO
    $('#submit_capture2').on('click', function(e) {
      $('#photo2').attr('src', data);
      $('#secondary-photo-cam').val(data)
      $('#photo-web-cam2').val(data)

      if($('#photo-web-cam2').val() == ""){
        let error = '<div id="message" class="ui negative message"><ul class="list">'
        $('div[id="message"]').remove()
        $('p[role="append_new_capture2"]').append(error + '<li>Please take a photo.</li> </ul> </div>')
        e.preventDefault()
      } else {
        track.stop();
        clearphoto();
        $('#upload_secondary').hide()
        $('#remove_secondary_capture').show();
        $('.upload_txt_secondary_capture').text('evoucher_secondary_id.png ')
        $('#photo-web-cam2').val("")
        $('#modal_facial_capture2').modal("hide");
      }
    })

    $('.close.icon').on('click', function() {
      track.stop();
      clearphoto();
    })

    $('#remove_secondary_capture').on('click', function() {
      $('#secondary-photo-cam').val("")
      $('#secondary_id').val(null);
      $('.upload_txt_secondary_capture').text('Capture Photo ')
      $('.upload_txt_secondary').text('Upload Secondary ID ')
      $('#capture_secondary').show()
      $('#upload_secondary').show()
      $(this).hide();
    })
  })
});

onmount('div[id="evoucherSelectFacility"]', function () {
  var script = document.createElement("script")
  script.type = "text/javascript"
  script.src = "https://maps.googleapis.com/maps/api/js?key=AIzaSyB-FlYg_DB4v-UcHCH2XxX6MWy0qSF-9C4&callback=initMap"
  script.setAttribute = ("async", "async")
  script.setAttribute = ("defer", "defer")
  var facilities = JSON.parse($('input[id="facilities"]').val());
  var map, marker
  document.body.appendChild(script)

  window.initMap = function() {
    map = new google.maps.Map(document.getElementById('map'), {
      center: {lat: 14.599512, lng: 120.984222},
      zoom: 20,
      size: new google.maps.Size(200, 200)
    });
  }

  $('.ui.search').search({
    source: facilities,
    showNoResults: true,
    maxResults: 10,
    searchFields: ['title'],
    onSelect: function(result, response) {
      $('input[name="peme[facility_id]"]').val(result.id)
      $(`#${result.id}`).closest('.card').find('.content').find('.description').css('color', '#0086CA')

      map = new google.maps.Map(document.getElementById('map'), {
        center: {lat: 14.599512, lng: 120.984222},
        zoom: 15,
        size: new google.maps.Size(200, 200)
      })

      var bounds = new google.maps.LatLngBounds()

      if (result != null){
        var position = new google.maps.LatLng(parseFloat(result.latitude), parseFloat(result.longitude))
        bounds.extend(position)

        marker = new google.maps.Marker({
          position: position,
          map: map,
          clickable: true,
          title: result.code
        })

        map.fitBounds(bounds);

        var address = result.line_1 + ' ' +
                      result.line_2 + ' ' +
                      result.city + ' ' +
                      result.province + ' ' +
                      result.region + ' ' +
                      result.country + ','  +
                      result.postal_code

        $('#facility_code').html(result.code);
        $('#facility_name').html(result.name);
        $('#facility_type').html(result.type);
        $('#facility_category').html(result.category);
        $('#facility_address').html(address);
        $('#facility_contact_number').html(result.phone_no);
        $('input[name="authorization[facility_id]"]').val(result.id);
        $('input[name="authorization[facility_code]"]').val(result.code);
      }
    },
    minCharacters: 0
  })

  $('.facility-card').on('click', function(){
    $('.description').removeAttr('style')
    $(this).closest('.card').find('.content').find('.description').css('color', '#0086CA')

    let long = $(this).attr('long')
    let lat = $(this).attr('lat')
    let code = $(this).attr('code')
    let id = $(this).attr('facilityID')

    $('input[name="peme[facility_id]"]').val(id)

    map = new google.maps.Map(document.getElementById('map'), {
      center: {lat: 14.599512, lng: 120.984222},
      zoom: 20,
      size: new google.maps.Size(200, 200)
    })

    var bounds = new google.maps.LatLngBounds()

    var position = new google.maps.LatLng(parseFloat(lat), parseFloat(long))
    bounds.extend(position)

    marker = new google.maps.Marker({
      position: position,
      map: map,
      clickable: true,
      title: code
    })

    map.fitBounds(bounds)

  })

  $('#selectFacilityForm').submit(function(e) {
    if ($('input[name="peme[facility_id]"]').val() == "") {
      e.preventDefault()
      alertify.error('<i class="close icon"></i>Please select a facility')
    } else {
      return true
    }
  })

});

onmount('.evoucher-pdf', function () {
  let pmID = $(this).attr('pmID')
  $.ajax({
    url:`/en/evoucher/${pmID}/render`,
    type: 'get',
    success: function(response){
      $('.evoucher-pdf').html(response.html)
    }
  })
  let qrcode = $('#evoucherQR').val()
  $('#qrContainer').qrcode({
        width: 180,
        height: 180,
        text: qrcode
  })
  let canvas = $('#qrContainer').find('canvas')[0].toDataURL()
  $('#qrBase').val(canvas)
});

onmount('div[id="evoucherReprint"]', function () {

  let Inputmask = require('inputmask')
  let im = new Inputmask("0\\999-999-9999", {
    "clearIncomplete": false,
  })
  im.mask($('.mobile-mask'))

  $('#evoucherReprintForm')
  .form({
    inline: true,
    fields: {
      evoucher_number: {
        identifier: 'mobile',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Mobile number'
        }]
      },
      effectivity_date: {
        identifier: 'company_name',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Company Name'
        }]
      }
    }
  })

});

onmount('#original_facility' ,function(){
  setTimeout(function() {
    let facility_id = $('#original_facility').val()
    if(facility_id != "") {
      $(`#photo_${facility_id}`).trigger('click');
    }
  }, 2e3);
});