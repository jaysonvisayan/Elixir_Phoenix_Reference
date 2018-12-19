onmount('div[role="manage-ruv"]', function(){
  if ($('input[name="ruv[effectivity_date]"]').val() != ''){
    let effectivity_date = moment($('input[name="ruv[effectivity_date]"]').val()).format("MM/DD/YYYY");
    $('#ruv_display_effectivity_date').val(effectivity_date);
  }

  let currentLocaleData = moment(moment.localeData()).format("MM/DD/YYYY");

  $('#effectivity_date').calendar({
    type: 'date',
    minDate: new Date(moment(currentLocaleData).add(1, 'days')),
    onChange: function (date, text, mode) {
      let effectivity_date = moment(date).format("YYYY-MM-DD");
      $('input[name="ruv[effectivity_date]"]').val(effectivity_date);
    },
    formatter: {
      date: function (date, settings) {
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
        return month + '/' + day + '/' + year;
      }
    }
  });

  $.fn.form.settings.rules.RUVCodeExists = function(param) {
    if ($('#ruv_codes').val() == "" || $('#ruv_codes').val() == null){
      return true;
    } else {
      var ruv_codes = JSON.parse($('#ruv_codes').val());
      if (jQuery.inArray(param, ruv_codes) < 0) {
        return true;
      } else {
        return false;
      }
    }
  }

  $.fn.form.settings.rules.validValue = function(param) {
    if (param == '') {
      return true;
    } else {
      if ($('input[name="ruv[type]"]:checked').val() == "Unit") {
        return ((Math.floor(param)).toString() == param) ? true : false;
      } else {
        let last = param.substring(param.length -1, param.length);

        if((Math.floor(param)).toString() == param) {
          return true;
        } else {
          return (param.toString().split(".")[1].length == 2) ? true : false;
        }
      }
    }
  }

  $.fn.form.settings.rules.futureDate = function(param) {
    if (param == '') {
      return true;
    } else {
      if (moment(currentLocaleData).diff(param, 'days') >= 0){
        return false;
      } else {
        return true;
      }
    }
  }

  $('#formValidate').form({
    inline: true,
    fields: {
      'ruv[code]': {
        identifier: 'ruv[code]',
        rules:
        [
          {
            type   : 'empty',
            prompt : 'Please enter RUV code'
          },
          {
            type   : 'RUVCodeExists[param]',
            prompt : 'RUV Code already exists'
          }
        ]
      },
      'ruv[description]': {
        identifier: 'ruv[description]',
        rules:
        [
          {
            type   : 'empty',
            prompt : 'Please enter RUV description'
          }
        ]
      },
      'ruv[type]': {
        identifier: 'ruv[type]',
        rules:
        [
          {
            type   : 'empty',
            prompt : 'Please enter RUV type'
          }
        ]
      },
      'ruv[display_effectivity_date]': {
        identifier: 'ruv[display_effectivity_date]',
        rules:
        [
          {
            type   : 'empty',
            prompt : 'Please enter effectivity date'
          },
          {
            type   : 'futureDate[param]',
            prompt : 'Effectivity date must be future dated'
          }
        ]
      },
      'ruv[value]': {
        identifier: 'ruv[value]',
        rules:
        [
          {
            type   : 'empty',
            prompt : 'Please enter value'
          },
          {
            type   : 'validValue[param]',
            prompt : 'Invalid value'
          },
        ]
      },
    }
  });

  var value = document.getElementById("ruv_value");

  if (value != null) {
    value.addEventListener("keypress", function(e) {
    // prevent: "e", "=", ",", "-", "."
      let list;
      if ($('input[name="ruv[type]"]:checked').val() == "Unit") {
        list = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
      } else {
        list = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "."]
      }

      if (list.includes(String.fromCharCode(e.which))) {
      } else {
        e.preventDefault();
      }
    });
  }

  $('input[name="ruv[type]"]').on('change', function(){
    $('#ruv_value').val('');
  });
});

onmount('div[role="ruv-index"]', function(){
  $('.show-ruv-details').click(function() {
    $('div[role="show-details"]').modal('show');

    let ruv_id = $(this).attr('ruvId');
    let code = $(this).closest('tr').find('td[field="code"]').text().trim();
    let description = $(this).closest('tr').find('td[field="description"]').text().trim();
    let type = $(this).closest('tr').find('td[field="type"]').text().trim();
    let value = $(this).closest('tr').find('td[field="value"]').text().trim();
    let effectivity_date = $(this).closest('tr').find('td[field="effectivity_date"]').text().trim();
    let facility_ruvs = $(this).closest('tr').find('input[field="facility_ruvs"]').val().trim();
    let benefit_ruvs = $(this).closest('tr').find('input[field="benefit_ruvs"]').val().trim();
    let case_rates = $(this).closest('tr').find('input[field="case_rates"]').val().trim();

    $('label[id="code"]').text(code);
    $('label[id="description"]').text(description);
    $('label[id="type"]').text(type);
    $('label[id="value"]').text(value);
    $('label[id="effectivity_date"]').text(effectivity_date);
    $('input[id="ruv_id"]').val(ruv_id);
    $('input[id="benefit_ruvs"]').val(benefit_ruvs);
    $('input[id="facility_ruvs"]').val(facility_ruvs);
    $('a[id="edit_ruv"]').attr('href', '/ruvs/' + ruv_id + '/edit');

    if (facility_ruvs > 0 || benefit_ruvs > 0 || case_rates > 0) {
      $('div[role="delete-ruv"]').addClass('disabled');
    } else {
      $('div[role="delete-ruv"]').removeClass('disabled');
    }
  });
});

onmount('div[role="ruv-logs"]', function(){
  $('a[id="ruv_logs"]').click(function() {
    var ruv_id = $('input[id="ruv_id"]').val();

    $.ajax({
      url: `/ruvs/${ruv_id}/logs`,
      type: 'get',
      success: function(response) {
        // var data = JSON.parse(response);
        let data = response
        $('div[role="ruv-logs"]').modal('show');
        $('#ruv_logs_table').html('');
        if(jQuery.isEmptyObject(data)){
          var no_log = 'NO LOGS FOUND'
          $("#ruv_logs_table").removeClass('feed timeline')
          $('#ruv_logs_table').append(no_log);
        }  else {
          $("#ruv_logs_table").addClass('feed timeline');
          for(let i=0; i < data.length; i++) {
            var new_row = '<div class="ui feed"><div class="event">' +
                          '<div class="label"><i class="blue circle icon"></i></div>' +
                          '<div class="scrolling content">' +
                          '<div class="summary"><p>' + moment(data[i].inserted_at).format('MMMM Do YYYY, h:mm a') + '</p></div>' +
                          '<div class="extra text">' + data[i].message + '</div>' +
                          '</div>' +
                          '</div></div>';
          $('#ruv_logs_table').append(new_row);
          }
        }
      }
    });
  });
});

onmount('div[role="delete-ruv"]', function(){
  $('div[role="delete-ruv"]').on('click', function(){
    swal({
      title: 'Remove RUV?',
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Remove RUV',
      cancelButtonText: '<i class="remove icon"></i> No, Remove RUV',
      confirmButtonClass: 'ui positive button',
      cancelButtonClass: 'ui negative button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false

    }).then(function() {
      let ruv_id = $('input[id="ruv_id"]').val();
      window.location = '/ruvs/' + ruv_id + '/delete';
    }).catch(swal.noop)
  });
});
