onmount('.article', function () {
	let dateTime = function() {
	    let date = new Date;
	    let year = date.getFullYear();
	    let month = date.getMonth();
	    let months = new Array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
	    let d = date.getDate();
	    let day = date.getDay();
	    let days = new Array('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
	    let h = date.getHours();
	    // if(h<10)
	    // {
	    //         h = "0"+h;
	    // }
	    let m = date.getMinutes();
	    // if(m<10)
	    // {
	    //         m = "0"+m;
	    // }
	    let s = date.getSeconds();
	    // if(s<10)
	    // {
	    //         s = "0"+s;
	    // }

	    // Standard Time Conversion
	    let ampm = h >= 12 ? 'PM' : 'AM';
	    h = h % 12;
	    h = h ? h : 12;


	    // add a zero in front of numbers<10
	    h = checkTime(h);
	    m = checkTime(m);
	    s = checkTime(s);

	    let result = '' + days[day] + ', ' + months[month] + ' ' + d + ', ' + year + ' ' + h + ':' + m + ':' + s + " " + ampm;
	    document.getElementById('datetime').innerHTML = result;
	    setTimeout(function() {
	        dateTime()
	    }, 1000);

	    return true;
	}

	var checkTime = function(i) {
	    if (i < 10) {
	        i = "0" + i;
	    }
	    return i;
	};


	dateTime();
});

onmount('div[name="formConsultation"]', function () {
  //alert("hello");
	let dateTime = function() {
	    let date = new Date;
	    let year = date.getFullYear();
	    let month = date.getMonth();
	    let months = new Array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
	    let d = date.getDate();
	    let day = date.getDay();
	    let days = new Array('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
	    let h = date.getHours();
	    // if(h<10)
	    // {
	    //         h = "0"+h;
	    // }
	    let m = date.getMinutes();
	    // if(m<10)
	    // {
	    //         m = "0"+m;
	    // }
	    let s = date.getSeconds();
	    // if(s<10)
	    // {
	    //         s = "0"+s;
	    // }

	    // Standard Time Conversion
	    let ampm = h >= 12 ? 'PM' : 'AM';
	    h = h % 12;
	    h = h ? h : 12;

	    // add a zero in front of numbers<10
	    h = checkTime(h);
	    m = checkTime(m);
	    s = checkTime(s);

	    let result = months[month] + ' ' + d + ', ' + year + ' ' + h + ':' + m + ':' + s + " " + ampm;
      document.getElementById('date_created').innerHTML = result;

      let result_valid = months[month] + ' ' + (d + 2) + ', ' + year;
      document.getElementById('valid_until').innerHTML = result_valid;

      setTimeout(function() {
	        dateTime()
	    }, 1000);

	    return true;
	}

	var checkTime = function(i) {
	    if (i < 10) {
	        i = "0" + i;
	    }
	    return i;
	};

  dateTime();

  let birth_date = $('#birth_date').text();
  let age = Math.floor(moment().diff(birth_date, 'years', true));
  $('#age').text(age);
});
