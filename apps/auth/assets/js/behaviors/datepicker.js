onmount('div[id="dateFormPicker"]', function () {

	$('#example1').calendar();
	$('#example2').calendar({
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
	});
	$('#example3').calendar({
	  type: 'time'
	});

  let currentDate = new Date()
  let tomorrowsDate = currentDate.setDate(currentDate.getDate() + 1)
  let futureDate = currentDate.setDate(currentDate.getDate() + 2)
  let cur_end_date = $('input[id="account_cur_end_date"]').val();

  if (cur_end_date != '' && cur_end_date != null) {
    tomorrowsDate = moment(cur_end_date).add(1, 'day').calendar();
  }

	$('#account_start_date').calendar({
	  type: 'date',
    minDate: new Date(tomorrowsDate),
    onChange: function (start_date, text, mode) {
      let start = new Date(start_date)
      let end_date = start.setDate(start.getDate() + 1)
      end_date = new Date(end_date)
      $('input[name="hidden-date"]').val(end_date)
      let start_date1 = start_date.setDate(start_date.getDate() -1)
      let new_end_date = moment(start_date1).add(1, 'year').calendar()
      new_end_date = moment(new_end_date).format("YYYY-MM-DD")
      $('input[name="account[end_date]"]').val(new_end_date)
      $('input[name="account[start_date]"]').val(moment(start_date.setDate(start_date.getDate() + 1)).format("YYYY-MM-DD"))

      $('#account_end_date').calendar({
        type: 'date',
        minDate: new Date(end_date),
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
            return year + '-' + month + '-' + day;
        }
    }
  });

  let edit_end = $('input[name="account[end_date]"]').val()
  let edit_start = $('input[name="account[start_date]"]').val()
  let min_date, startDate, newStartDate;

  if (new Date() > new Date(edit_start)){
    min_date = currentDate
  }else if (new Date() < new Date(edit_start)) {
    edit_start = new Date(edit_start)
    startDate = edit_start.setDate(edit_start.getDate() + 1)
    min_date = moment(startDate).format("YYYY-MM-DD")
  }else{
    edit_start = new Date(edit_start)
    startDate = edit_start.setDate(edit_start.getDate() + 1)
    min_date = moment(startDate).format("YYYY-MM-DD")
  }

  $('#account_edit_end_date').calendar({
    type: 'date',
    minDate: new Date(min_date),
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

  $('#account_edit_start_date').calendar({
    type: 'date',
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

  $('#rangestart').calendar({
	  type: 'date',
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
	});

	$('#rangeend').calendar({
	  type: 'date',
    startCalendar: $('#rangestart'),
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
	});

  $('#example4').calendar({
	  startMode: 'year'
	});
	$('#example5').calendar();
	$('#example6').calendar({
	  ampm: false,
	  type: 'time'
	});
	$('#example7').calendar({
	  type: 'month'
	});
	$('#example8').calendar({
	  type: 'year'
	});
	$('#example9').calendar();
	$('#example10').calendar({
	  on: 'hover'
	});
	var today = new Date();
	$('#example11').calendar({
	  minDate: new Date(today.getFullYear(), today.getMonth(), today.getDate() - 5),
	  maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate() + 5)
	});
	$('#example12').calendar({
	  monthFirst: false
	});
	$('div[id="example13"]').calendar({
	  monthFirst: false,
    type: 'date',
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
	});
	$('#example14').calendar({
	  inline: true
	});
	$('#example15').calendar();

  $('#birthdate').calendar({
	  type: 'date',
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
  });
});
