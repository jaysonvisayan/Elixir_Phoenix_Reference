const locale = $('#locale').val();

onmount('.single_peme', function () {
  $('.active-peme').addClass('active')
})

onmount('#peme_tab', function () {
  $('.step').click(function(){
    let link = $(this).attr('link')
    if($(this).hasClass('link')) {
      window.location.replace(link)
    }
  })
})

onmount('div[id="request_loa"]', function () {
  let csrf = $('input[name="_csrf_token"]').val();
  $.ajax({
    url:`/${locale}/peme/single/load_packages`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let obj = JSON.parse(response);
      for (let pckg of obj) {
        let new_row = `<option value="${pckg.id}">${pckg.display}</option>`
        $('#package_dd').append(new_row)
      }
      $('.dropdown.selection').dropdown('refresh');
    }
  });

  $('#pemedate').calendar({
    type: 'date',
    endCalendar: $('#rangeend'),
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
        return year + '-' + month + '-' + day;
      }
    }
  })

  $('#package_dd').change(function(){
    let val = $('.ui.fluid.dropdown.selection').dropdown('get value')
    if(val != null) {
      let csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/peme/single/${val}/load_package`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        success: function(response){
          $('#facility_name').text(response.package_facility)
          $('#package_name').text(response.name)
          $('#procedure_record').text(response.package_payor_procedure)
          $('.package-list').css('display', 'block')
          $('.peme-general-info').css('display', 'block')
        }
      })
    }
  })

  $('#singlePemeForm')
  .form({
    inline : true,
    on     : 'blur',
    fields: {
      'peme_loa[peme_date]': {
        identifier: 'peme_loa[peme_date]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please select a PEME Date.'
          }
        ]
      },
      'peme_loa[package_id]': {
        identifier: 'peme_loa[package_id]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please select a package.'
          }
        ]
      }
    }
  })

})

onmount('div[id="general"]', function () {

	$('#birthdate').calendar({
	  type: 'date',
	  endCalendar: $('#rangeend'),
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
            return year + '-' + month + '-' + day;
        }
    }
	})

	$('#effectivitydate').calendar({
	  type: 'date',
	  endCalendar: $('#rangeend'),
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
            return year + '-' + month + '-' + day;
        }
    }
	})

	$('#expirydate').calendar({
	  type: 'date',
	  endCalendar: $('#rangeend'),
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
            return year + '-' + month + '-' + day;
        }
    }
	})

  $('#singlePemeForm')
  .form({
    inline : true,
    on     : 'blur',
    fields: {
      'member[first_name]': {
        identifier: 'member[first_name]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a first name.'
          }
        ]
      },
      'member[middle_name]': {
        identifier: 'member[middle_name]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a middle name.'
          }
        ]
      },
      'member[last_name]': {
        identifier: 'member[last_name]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a last name.'
          }
        ]
      },
      'member[birthdate]': {
        identifier: 'member[birthdate]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a birthdate.'
          }
        ]
      },
      'member[gender]': {
        identifier: 'member[gender]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a gender.'
          }
        ]
      },
      'member[gender]': {
        identifier: 'member[gender]',
        rules: [
          {
            type   : 'checked',
            prompt : 'Please enter a gender.'
          }
        ]
      },
      'member[civil_status]': {
        identifier: 'member[civil_status]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a civil status.'
          }
        ]
      },
      'member[effectivity_date]': {
        identifier: 'member[effectivity_date]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a effectivity date.'
          }
        ]
      },
      'member[expiry_date]': {
        identifier: 'member[expiry_date]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a expiry date.'
          }
        ]
      }
    }
  })

})

onmount('div[id="contact"]', function () {
  $('#singlePemeForm')
  .form({
    inline : true,
    on     : 'blur',
    fields: {
      'member[email]': {
        identifier: 'member[email]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter an email.'
          }
        ]
      },
      'member[mobile]': {
        identifier: 'member[mobile]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter a mobile.'
          }
        ]
      }
    }
  })
})
