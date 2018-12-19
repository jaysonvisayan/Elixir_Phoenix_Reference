onmount('div[name="pf-formValidate"]', function() {
    let validMobileNos = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994", "976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

    $.fn.form.settings.rules.checkMobilePrefix = function(param) {
        return validMobileNos.indexOf(param.substring(1, 4)) == -1 ? false : true;
    }

    $.fn.form.settings.rules.validDateFormat = function(param) {
        if (param == '') {
            return true;
        } else {
            return moment(param, 'MM-DD-YYYY').isValid();
        }
    }

    $.fn.form.settings.rules.validateFixedFee = function(param) {
        if ($('input[name="practitioner_facility[coordinator]"]:checked').val() == "true") {
            if ($('input[name="practitioner_facility[fixed]"]:checked').val() == "true") {
                if ($('#practitioner_facility_fixed_fee').val() == '') {
                    return false;
                } else {
                    return true;
                }
            } else {
                return true;
            }
        } else {
            return true;
        }
    }

    $.fn.form.settings.rules.validateCoordinatorFee = function(param) {
        if ($('input[name="practitioner_facility[coordinator]"]:checked').val() == "true") {
            if ($('#practitioner_facility_coordinator_fee').val() == '') {
                return false;
            } else {
                return true;
            }
        } else {
            return true;
        }
    }

    $.fn.form.settings.rules.validateDecimal = function(param) {
        if (param == '') {
            return true;
        } else {
            var dec = parseFloat(param);
            return !(isNaN(dec));
        }
    }

    $('#formStep1PractitionerFacility').form({
        on: 'blur',
        inline: true,
        fields: {
            'practitioner_facility[types][]': {
                identifier: 'practitioner_facility[types][]',
                rules: [{
                    type: 'checked',
                    prompt: 'Please select at least one practitioner type'
                }]
            },
            'practitioner_facility[facility_id]': {
                identifier: 'practitioner_facility[facility_id]',
                rules: [{
                    type: 'empty',
                    prompt: 'Please select facility'
                }]
            },
            'practitioner_facility[pstatus_id]': {
                identifier: 'practitioner_facility[pstatus_id]',
                rules: [{
                    type: 'empty',
                    prompt: 'Please select status'
                }]
            },
            'practitioner_facility[affiliation_date]': {
                identifier: 'practitioner_facility[affiliation_date]',
                depends: 'practitioner_facility[disaffiliation_date]',
                rules: [{
                        type: 'empty',
                        prompt: 'Please enter affliation date'
                    }
                   ]
            },
            'practitioner_facility[disaffiliation_date]': {
                identifier: 'practitioner_facility[disaffiliation_date]',
                depends: 'practitioner_facility[affiliation_date]',
                rules: [{
                        type: 'empty',
                        prompt: 'Please enter disaffliation date'
                    }
                ]
            },
        }
    });

    $('#formStep3PractitionerFacility').submit(() => {
      let result = true
      $('.cf_specialization').each(function(){
        if($(this).val() == "" || $(this).val() == "0.00") {
          result = false
          let container = $(this).closest('.field')
          container.addClass('error')
          container.find('.cf_error').removeClass('hidden')
          container.find('.cf_error').addClass('visible')
          container.find('.cf_error').text('Please enter consultation fee.')
        } else {
          let val_str = $(this).val().replace(/,/g , "")
          let value = parseFloat(val_str)
          if(value >= parseFloat("5000")){
            result = false
            let container = $(this).closest('.field')
            container.addClass('error')
            container.find('.cf_error').removeClass('hidden')
            container.find('.cf_error').addClass('visible')
            container.find('.cf_error').text('Maximum consultation fee is up to 5,000 only.')
          }
        }
      })
      return result
    })

    $('.cf_specialization').on('keydown', function(){
      let container = $(this).closest('.field')
      container.removeClass('error')
      container.find('.cf_error').addClass('hidden')
      container.find('.cf_error').removeClass('visible')
    })

    $('.cf_specialization').on('click', function(){
      if($(this).val() == "") {
        $(this).val('.00')
        $(this).focus();
        $(this).get(0).setSelectionRange(0,0);
      }
    })

    $('#formStep3PractitionerFacility').form({
        on: 'blur',
        inline: true,
        fields: {
            'practitioner_facility[fixed_fee]': {
                identifier: 'practitioner_facility[fixed_fee]',
                rules: [{
                        type: 'validateFixedFee[param]',
                        prompt: 'Please enter fixed fee'
                    },
                    {
                        type: 'number',
                        prompt: 'Fixed Fee must be numeric'
                    }
                ]
            },
            'practitioner_facility[coordinator_fee]': {
                identifier: 'practitioner_facility[coordinator_fee]',
                rules: [{
                        type: 'validateCoordinatorFee[param]',
                        prompt: 'Please enter coordinator fee'
                    },
                    {
                        type: 'number',
                        prompt: 'Coordinator Fee must be numeric'
                    }
                ]
            },
            'practitioner_facility[cp_clearance_rate]': {
                identifier: 'practitioner_facility[cp_clearance_rate]',
                rules: [{
                    type: 'number',
                    prompt: 'CP clearance rate must be numeric'
                }]
            },
        }
    });

    var im = new Inputmask("decimal", {
      radixPoint: ".",
      groupSeparator: ",",
      digits: 2,
      autoGroup: true,
      rightAlign: false,
      oncleared: function () { self.Value(''); }
    });
    im.mask($('.cf_specialization'));
});

onmount('.practitioner_cf_table', function() {
  var im = new Inputmask("decimal", {
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    rightAlign: false,
    oncleared: function () { self.Value(''); }
  });
  im.mask($('.cf_specialization'));
})

onmount('div[role="pf-datepicker"]', function() {
    $('#practitioner_facility_affiliation_date').val(moment($('input[name="practitioner_facility[hidden_ad]"]').val()).format("MM-DD-YYYY"));
    $('#practitioner_facility_disaffiliation_date').val(moment($('input[name="practitioner_facility[hidden_dd]"]').val()).format("MM-DD-YYYY"));

    $('#pf_affiliation_date').calendar({
        type: 'date',
        onChange: function(start_date, text, mode) {
            start_date = moment(start_date).add(1, 'year').calendar()
            start_date = moment(start_date).format("MM-DD-YYYY")
            $('input[name="practitioner_facility[disaffiliation_date]"]').val(start_date)
            $('#pf_disaffiliation_date').calendar("set date", start_date);
        },
        formatter: {
            date: function(date, settings) {
              var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
              ];
              var day = date.getDate();
              var monthIndex = date.getMonth();
              var year = date.getFullYear();

              return monthNames[monthIndex] + ' ' + day + ', ' + year;
            }
        }
    });

    $('#pf_disaffiliation_date').calendar({
        type: 'date',
        startCalendar: $('#pf_affiliation_date'),
        formatter: {
            date: function(date, settings) {
              var monthNames = [
                "Jan", "Feb", "Mar",
                "Apr", "May", "Jun", "Jul",
                "Aug", "Sep", "Oct",
                "Nov", "Dec"
              ];
              var day = date.getDate();
              var monthIndex = date.getMonth();
              var year = date.getFullYear();

              return monthNames[monthIndex] + ' ' + day + ', ' + year;
            }
        }
    });

});

onmount('div[role="add-pf-schedule"]', function() {
    let tr = $('div[role="add-pf-schedule"]').find('tbody > tr')
    $('button[id="add_sched"]').prop('disabled', true)

    $('div[role="add-pf-schedule"]').modal({
        autofocus: false,
        observeChanges: true
    }).modal('attach events', '#button_add_sched', 'show');

    $('button[name="add-schedule"]').on('click', function() {
        $('div[role="add-pf-schedule"]').form('reset');

        $('.time_from').calendar({
            ampm: false,
            type: 'time',
            // endCalendar: $('.time_to')
        });

        $('.time_to').calendar({
            ampm: false,
            type: 'time',
            // startCalendar: $('.time_from')
        });

        $('div[role="add-pf-schedule"]').on('mouseover', function() {
            let tr = $(this).find('tbody > tr').find('input[type="text"]')
            let no_val = []

            tr.each(function() {
                const inputs = $(this).val() == ""
                if (inputs) {
                    no_val.push(inputs)
                } else {
                    no_val.push(inputs)
                }
            })
            no_val = no_val.every(is_all_true)

            if (no_val) {
                $('button[id="add_sched"]').prop('disabled', true)
            } else {
                $('button[id="add_sched"]').prop('disabled', false)
            }
        })

        $('tbody > tr').on('mouseover', function() {
            let tr = $(this)
            tr.find('input[type="text"]').prop("disabled", false)
        })

        const is_all_true = (element, index, array) => {
            return element == true
        }

        $.fn.form.settings.rules.emptyRoomMon = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[time_from][Monday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Monday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyRoomTue = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[time_from][Tuesday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Tuesday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyRoomWed = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[time_from][Wednesday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Wednesday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyRoomThu = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[time_from][Thursday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Thursday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyRoomFri = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[time_from][Friday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Friday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyRoomSat = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[time_from][Saturday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Saturday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyRoomSun = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[time_from][Sunday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Sunday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeFromMon = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Monday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Monday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeFromTue = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Tuesday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Tuesday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeFromWed = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Wednesday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Wednesday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeFromThu = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Thursday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Thursday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeFromFri = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Friday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Friday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeFromSat = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Saturday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Saturday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeFromSun = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Sunday]"]').val() == '' && $('input[name="practitioner_facility[time_to][Sunday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeToMon = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Monday]"]').val() == '' && $('input[name="practitioner_facility[time_from][Monday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeToTue = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Tuesday]"]').val() == '' && $('input[name="practitioner_facility[time_from][Tuesday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeToWed = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Wednesday]"]').val() == '' && $('input[name="practitioner_facility[time_from][Wednesday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeToThu = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Thursday]"]').val() == '' && $('input[name="practitioner_facility[time_from][Thursday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeToFri = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Friday]"]').val() == '' && $('input[name="practitioner_facility[time_from][Friday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeToSat = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Saturday]"]').val() == '' && $('input[name="practitioner_facility[time_from][Saturday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        $.fn.form.settings.rules.emptyTimeToSun = function(param) {
            if (param == '') {
                if ($('input[name="practitioner_facility[room][Sunday]"]').val() == '' && $('input[name="practitioner_facility[time_from][Sunday]"]').val() == '') {
                    return true;
                } else {
                    return false;
                }
            } else {
                return true;
            }
        }

        function toDate(dStr, format) {
            var now = new Date();
            if (format == "hh:mm") {
                now.setHours(dStr.substr(0, dStr.indexOf(":")));
                now.setMinutes(dStr.substr(dStr.indexOf(":") + 1));
                now.setSeconds(0);
                return now;
            } else {
                return "Invalid Format";
            }
        }

        $.fn.form.settings.rules.validTimeToMon = function(param) {
            if (param == '' || $('input[name="practitioner_facility[time_from][Monday]"]').val() == '') {
                return true;
            } else {
                if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_facility[time_from][Monday]"]').val(), "hh:mm")) {
                    return true;
                } else {
                    return false;
                }
            }
        }

        $.fn.form.settings.rules.validTimeToTue = function(param) {
            if (param == '' || $('input[name="practitioner_facility[time_from][Tuesday]"]').val() == '') {
                return true;
            } else {
                if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_facility[time_from][Tuesday]"]').val(), "hh:mm")) {
                    return true;
                } else {
                    return false;
                }
            }
        }

        $.fn.form.settings.rules.validTimeToWed = function(param) {
            if (param == '' || $('input[name="practitioner_facility[time_from][Wednesday]"]').val() == '') {
                return true;
            } else {
                if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_facility[time_from][Wednesday]"]').val(), "hh:mm")) {
                    return true;
                } else {
                    return false;
                }
            }
        }

        $.fn.form.settings.rules.validTimeToThu = function(param) {
            if (param == '' || $('input[name="practitioner_facility[time_from][Thursday]"]').val() == '') {
                return true;
            } else {
                if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_facility[time_from][Thursday]"]').val(), "hh:mm")) {
                    return true;
                } else {
                    return false;
                }
            }
        }

        $.fn.form.settings.rules.validTimeToFri = function(param) {
            if (param == '' || $('input[name="practitioner_facility[time_from][Friday]"]').val() == '') {
                return true;
            } else {
                if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_facility[time_from][Friday]"]').val(), "hh:mm")) {
                    return true;
                } else {
                    return false;
                }
            }
        }

        $.fn.form.settings.rules.validTimeToSat = function(param) {
            if (param == '' || $('input[name="practitioner_facility[time_from][Saturday]"]').val() == '') {
                return true;
            } else {
                if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_facility[time_from][Saturday]"]').val(), "hh:mm")) {
                    return true;
                } else {
                    return false;
                }
            }
        }

        $.fn.form.settings.rules.validTimeToSun = function(param) {
            if (param == '' || $('input[name="practitioner_facility[time_from][Sunday]"]').val() == '') {
                return true;
            } else {
                if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_facility[time_from][Sunday]"]').val(), "hh:mm")) {
                    return true;
                } else {
                    return false;
                }
            }
        }

        $('#formScheduleValidate').form({
            on: blur,
            inline: true,
            fields: {
                'practitioner_facility[room][Monday]': {
                    identifier: 'practitioner_facility[room][Monday]',
                    rules: [{
                        type: 'emptyRoomMon',
                        prompt: 'Please enter Room'
                    }, ]
                },
                'practitioner_facility[time_from][Monday]': {
                    identifier: 'practitioner_facility[time_from][Monday]',
                    rules: [{
                        type: 'emptyTimeFromMon',
                        prompt: 'Please enter Time From'
                    }, ]
                },
                'practitioner_facility[time_to][Monday]': {
                    identifier: 'practitioner_facility[time_to][Monday]',
                    rules: [{
                            type: 'emptyTimeToMon',
                            prompt: 'Please enter Time To'
                        },
                        {
                            type: 'validTimeToMon',
                            prompt: 'Time To must be greater than Time From'
                        },
                    ]
                },
                'practitioner_facility[room][Tuesday]': {
                    identifier: 'practitioner_facility[room][Tuesday]',
                    rules: [{
                        type: 'emptyRoomTue',
                        prompt: 'Please enter Room'
                    }, ]
                },
                'practitioner_facility[time_from][Tuesday]': {
                    identifier: 'practitioner_facility[time_from][Tuesday]',
                    rules: [{
                        type: 'emptyTimeFromTue',
                        prompt: 'Please enter Time From'
                    }]
                },
                'practitioner_facility[time_to][Tuesday]': {
                    identifier: 'practitioner_facility[time_to][Tuesday]',
                    rules: [{
                            type: 'emptyTimeToTue',
                            prompt: 'Please enter Time To'
                        },
                        {
                            type: 'validTimeToTue',
                            prompt: 'Time To must be greater than Time From'
                        },
                    ]
                },
                'practitioner_facility[room][Wednesday]': {
                    identifier: 'practitioner_facility[room][Wednesday]',
                    rules: [{
                        type: 'emptyRoomWed',
                        prompt: 'Please enter Room'
                    }, ]
                },
                'practitioner_facility[time_from][Wednesday]': {
                    identifier: 'practitioner_facility[time_from][Wednesday]',
                    rules: [{
                        type: 'emptyTimeFromWed',
                        prompt: 'Please enter Time From'
                    }]
                },
                'practitioner_facility[time_to][Wednesday]': {
                    identifier: 'practitioner_facility[time_to][Wednesday]',
                    rules: [{
                            type: 'emptyTimeToWed',
                            prompt: 'Please enter Time To'
                        },
                        {
                            type: 'validTimeToWed',
                            prompt: 'Time To must be greater than Time From'
                        },
                    ]
                },
                'practitioner_facility[room][Thursday]': {
                    identifier: 'practitioner_facility[room][Thursday]',
                    rules: [{
                        type: 'emptyRoomThu',
                        prompt: 'Please enter Room'
                    }, ]
                },
                'practitioner_facility[time_from][Thursday]': {
                    identifier: 'practitioner_facility[time_from][Thursday]',
                    rules: [{
                        type: 'emptyTimeFromThu',
                        prompt: 'Please enter Time From'
                    }]
                },
                'practitioner_facility[time_to][Thursday]': {
                    identifier: 'practitioner_facility[time_to][Thursday]',
                    rules: [{
                            type: 'emptyTimeToThu',
                            prompt: 'Please enter Time To'
                        },
                        {
                            type: 'validTimeToThu',
                            prompt: 'Time To must be greater than Time From'
                        },
                    ]
                },
                'practitioner_facility[room][Friday]': {
                    identifier: 'practitioner_facility[room][Friday]',
                    rules: [{
                        type: 'emptyRoomFri',
                        prompt: 'Please enter Room'
                    }, ]
                },
                'practitioner_facility[time_from][Friday]': {
                    identifier: 'practitioner_facility[time_from][Friday]',
                    rules: [{
                        type: 'emptyTimeFromFri',
                        prompt: 'Please enter Time From'
                    }]
                },
                'practitioner_facility[time_to][Friday]': {
                    identifier: 'practitioner_facility[time_to][Friday]',
                    rules: [{
                            type: 'emptyTimeToFri',
                            prompt: 'Please enter Time To'
                        },
                        {
                            type: 'validTimeToFri',
                            prompt: 'Time To must be greater than Time From'
                        },
                    ]
                },
                'practitioner_facility[room][Saturday]': {
                    identifier: 'practitioner_facility[room][Saturday]',
                    rules: [{
                        type: 'emptyRoomSat',
                        prompt: 'Please enter Room'
                    }, ]
                },
                'practitioner_facility[time_from][Saturday]': {
                    identifier: 'practitioner_facility[time_from][Saturday]',
                    rules: [{
                        type: 'emptyTimeFromSat',
                        prompt: 'Please enter Time From'
                    }]
                },
                'practitioner_facility[time_to][Saturday]': {
                    identifier: 'practitioner_facility[time_to][Saturday]',
                    rules: [{
                            type: 'emptyTimeToSat',
                            prompt: 'Please enter Time To'
                        },
                        {
                            type: 'validTimeToSat',
                            prompt: 'Time To must be greater than Time From'
                        },
                    ]
                },
                'practitioner_facility[room][Sunday]': {
                    identifier: 'practitioner_facility[room][Sunday]',
                    rules: [{
                        type: 'emptyRoomSun',
                        prompt: 'Please enter Room'
                    }, ]
                },
                'practitioner_facility[time_from][Sunday]': {
                    identifier: 'practitioner_facility[time_from][Sunday]',
                    rules: [{
                        type: 'emptyTimeFromSun',
                        prompt: 'Please enter Time From'
                    }]
                },
                'practitioner_facility[time_to][Sunday]': {
                    identifier: 'practitioner_facility[time_to][Sunday]',
                    rules: [{
                            type: 'emptyTimeToSun',
                            prompt: 'Please enter Time To'
                        },
                        {
                            type: 'validTimeToSun',
                            prompt: 'Time To must be greater than Time From'
                        },
                    ]
                }
            }
        });
    });

});

onmount('div[role="edit-pf-schedule"]', function() {
    if ($('a[id="button_edit_sched"]').length != 0) {
        $('div[role="edit-pf-schedule"]').modal({
            autofocus: false,
            observeChanges: true
        }).modal('attach events', 'a[id="button_edit_sched"]', 'show');

        let tr = $('div[role="edit-pf-schedule"]').find('tbody > tr')
        $('button[id="edit_sched"]').prop('disabled', true)

        $('a[name="edit-schedule"]').click(function() {
            $('div[role="modal-edit-schedule"]').form('reset');

            $('div[name="scheduleForm"]').find('tbody > tr').click(function() {
                let tr = $(this)
                let schedule_id = tr.attr("schedule_id")
                let sched_day = tr.find('td[role="day"]').html()
                let sched_room = tr.find('td[role="room"]').text()
                let sched_time_from = tr.find('td[role="time_from"]').text()
                let sched_time_to = tr.find('td[role="time_to"]').text()

                let modal_row = $('div[role="edit-pf-schedule"]').find('tbody > tr')
                modal_row.find('div[role="day"]').text(sched_day)
                modal_row.find('input[name="practitioner_facility[day]"]').val(sched_day)
                modal_row.find('input[name="practitioner_facility[room]"]').val(sched_room)
                modal_row.find('input[name="practitioner_facility[time_from]"]').val(sched_time_from)
                modal_row.find('input[name="practitioner_facility[time_to]"]').val(sched_time_to)
                modal_row.find('input[name="practitioner_facility[schedule_id]"]').val(schedule_id)

                $('#edit_time_from').calendar({
                    ampm: false,
                    type: 'time',
                    endCalendar: $('#edit_time_to')
                });

                $('#edit_time_to').calendar({
                    ampm: false,
                    type: 'time',
                    startCalendar: $('#edit_time_from')
                });

                $('#edit_time_from').calendar("set date", sched_time_from);
                $('#edit_time_to').calendar("set date", sched_time_to);
            });

            $('div[role="edit-pf-schedule"]').on('mouseover', function() {
                let tr = $(this).find('tbody > tr').find('input[type="text"]')
                let no_val = []

                tr.each(function() {
                    const inputs = $(this).val() == ""
                    if (inputs) {
                        no_val.push(inputs)
                    } else {
                        no_val.push(inputs)
                    }
                })
                no_val = no_val.every(is_all_true)

                if (no_val) {
                    $('button[id="edit_sched"]').prop('disabled', true)
                } else {
                    $('button[id="edit_sched"]').prop('disabled', false)
                }
            })

            $('tbody > tr').on('mouseover', function() {
                let tr = $(this)
                tr.find('input[type="text"]').prop("disabled", false)
            })

            const is_all_true = (element, index, array) => {
                return element == true
            }

            $('#formScheduleValidateEdit').form({
                on: blur,
                inline: true,
                fields: {
                    'practitioner_facility[room]': {
                        identifier: 'practitioner_facility[room]',
                        rules: [{
                            type: 'empty',
                            prompt: 'Please enter Room'
                        }]
                    },
                    'practitioner_facility[time_from]': {
                        identifier: 'practitioner_facility[time_from]',
                        rules: [{
                            type: 'empty',
                            prompt: 'Please enter Time From'
                        }]
                    },
                    'practitioner_facility[time_to]': {
                        identifier: 'practitioner_facility[time_to]',
                        rules: [{
                            type: 'empty',
                            prompt: 'Please enter Time To'
                        }]
                    }
                }
            });
        });
    }
});


onmount('div[name="pf-contact"]', function() {
    function addTelephone() {
        let telHtml = $('div[role="form-telephone"]').html();
        let tel = `<div class="two fields" role="form-telephone" id="append-tel">${telHtml}</div>`
        $('p[role="append-telephone"]').append(tel);

        $('div[id="append-tel"]').find('a').removeAttr("add");
        $('div[id="append-tel"]').find('input').removeAttr("value");
        $('div[id="append-tel"]').find('a').attr("remove", "tel");
        $('div[id="append-tel"]').find('a').attr("class", "ui icon basic button");
        $('div[id="append-tel"]').find('a').html(`<i class="trash icon"></i>`);
        $('div[id="append-tel"]').find('label').remove();

        $('div[role="form-telephone"]').on('click', 'a[remove="tel"]', function(e) {
            $(this).closest('div[role="form-telephone"]').remove();
        });

        var Inputmask = require('inputmask');
        var phone = new Inputmask("999-99-99", { "clearIncomplete": true })
        phone.mask($('.phone'));
    }

    function addFax() {
        let faxHtml = $('div[role="form-fax"]').html();
        let fax = `<div class="two fields" role="form-fax" id="append-fax">${faxHtml}</div>`

        $('p[role="append-fax"]').append(fax);
        $('div[id="append-fax"]').find('a').removeAttr("add");
        $('div[id="append-fax"]').find('input').removeAttr("value");
        $('div[id="append-fax"]').find('a').attr("remove", "fax");
        $('div[id="append-fax"]').find('a').attr("class", "ui icon basic button");
        $('div[id="append-fax"]').find('a').html(`<i class="trash icon"></i>`);
        $('div[id="append-fax"]').find('label').remove();

        $('div[role="form-fax"]').on('click', 'a[remove="fax"]', function(e) {
            $(this).closest('div[role="form-fax"]').remove();
        });

        var Inputmask = require('inputmask');
        var phone = new Inputmask("999-99-99", { "clearIncomplete": true })
        phone.mask($('.phone'));
    }

    function addMobile() {
        let mobHtml = $('div[role="form-mobile"]').html();
        let mob = `<div class="two fields" role="form-mobile" id="append-mob">${mobHtml}</div>`

        $('p[role="append-mobile"]').append(mob);
        $('div[id="append-mob"]').find('a').removeAttr("add");
        $('div[id="append-mob"]').find('input').removeAttr("value");
        $('div[id="append-mob"]').find('a').attr("remove", "mobile");
        $('div[id="append-mob"]').find('a').attr("class", "ui icon basic button");
        $('div[id="append-mob"]').find('a').html(`<i class="trash icon"></i>`);
        $('div[id="append-mob"]').find('label').remove();

        $('div[role="form-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
            $(this).closest('div[role="form-mobile"]').remove();
        });

        var Inputmask = require('inputmask');
        var im = new Inputmask("0\\999-999-99-99", { "clearIncomplete": true });
        im.mask($('.mobile'));
    }

    function addEmail() {
        let emailHtml = $('div[role="form-email"]').html();
        let email = `<div class="two fields" role="form-email" id="append-email">${emailHtml}</div>`

        $('p[role="append-email"]').append(email);
        $('div[id="append-email"]').find('a').removeAttr("add");
        $('div[id="append-email"]').find('input').removeAttr("value");
        $('div[id="append-email"]').find('a').attr("remove", "email");
        $('div[id="append-email"]').find('a').attr("class", "ui icon basic button");
        $('div[id="append-email"]').find('a').html(`<i class="trash icon"></i>`);
        $('div[id="append-email"]').find('label').remove();

        $('div[role="form-email"]').on('click', 'a[remove="email"]', function(e) {
            $(this).closest('div[role="form-email"]').remove();
        });
    }

    $('a[add="telephone"]').on('click', function() {
        addTelephone();
    });

    $('div[role="form-telephone"]').on('click', 'a[remove="tel"]', function(e) {
        $(this).closest('div[role="form-telephone"]').remove();
    });

    $('a[add="fax"]').on('click', function() {
        addFax();
    });

    $('div[role="form-fax"]').on('click', 'a[remove="fax"]', function(e) {
        $(this).closest('div[role="form-fax"]').remove();
    });

    $('a[add="mobile"]').on('click', function() {
        addMobile();
    });

    $('div[role="form-mobile"]').on('click', 'a[remove="mobile"]', function(e) {
        $(this).closest('div[role="form-mobile"]').remove();
    });

    $('a[add="email"]').on('click', function() {
        addEmail();
    });

    $('div[role="form-email"]').on('click', 'a[remove="email"]', function(e) {
        $(this).closest('div[role="form-email"]').remove();
    });
});

onmount('form[role="add_practitioner_facility_rate"]', function() {
    $('input[name="practitioner_facility[fixed]"]').on('change', function() {
        $('div[id="formStep3PractitionerFacility"]').find('.error').removeClass('error').find('.prompt').remove();

        if ($('input[name="practitioner_facility[fixed]"]:checked').val() == "false") {
            $('#practitioner_facility_fixed_fee').prop('disabled', true);
            $('#practitioner_facility_fixed_fee').val('');
            $('#facility_room').show();
        } else {
            $('#practitioner_facility_fixed_fee').prop('disabled', false);
            $('#facility_room').hide();
        }
    });

    $('input[name="practitioner_facility[coordinator]"]').on('change', function() {
        $('div[id="formStep3PractitionerFacility"]').find('.error').removeClass('error').find('.prompt').remove();

        if ($('input[name="practitioner_facility[coordinator]"]:checked').val() == "true") {
            $('#lblPf_coordinator_fee').html('<b>Coordinator Fee</b>');
            $('#practitioner_facility_fixed_true').prop('disabled', false);
            $('#practitioner_facility_fixed_true').prop('checked', true);
            $('#practitioner_facility_fixed_fee').prop('disabled', false);
            $('#facility_room').hide();
        } else {
            $('#lblPf_coordinator_fee').html('<b>Coordinator Fee <i>(optional)</i></b>');
            $('#practitioner_facility_fixed_true').prop('disabled', true);
            $('#practitioner_facility_fixed_false').prop('checked', true);
            $('#practitioner_facility_fixed_fee').prop('disabled', true);
            $('#practitioner_facility_fixed_fee').val('');
            $('#facility_room').show();
        }
    });
});

onmount('div[role="print_pf"]', function() {
    $('div[role="print_pf').click(function() {
        let pf_id = $(this).attr('pfID')
        window.open(`/practitioners/${pf_id}/pf/print_summary`, '_blank')
    });
});


onmount('div[role="delete-pf"]', function() {
    $('div[role="delete-pf"]').on('click', function() {
        swal({
            title: 'Delete Affiliation?',
            type: 'question',
            showCancelButton: true,
            confirmButtonText: '<i class="check icon"></i> Yes, Delete Affiliation',
            cancelButtonText: '<i class="remove icon"></i> No, Keep Affiliation',
            confirmButtonClass: 'ui positive button',
            cancelButtonClass: 'ui negative button',
            buttonsStyling: false,
            reverseButtons: true,
            allowOutsideClick: false

        }).then(function() {
            let pf_id = $('div[role="delete-pf"]').attr('pfId')
            window.location = '/practitioners/' + pf_id + '/pf/delete';
        })
    });
});

// onmount('div[role="cancel_button_pf"]', function(){
//   $('div[role="cancel_button_pf"]').on('click', function(){
//     swal({
//       title: 'Discard Changes?',
//       type: 'question',
//       text: 'If you go back now, your changes will be discarded.',
//       showCancelButton: true,
//       confirmButtonText: '<i class="check icon"></i> Yes, Discard Changes',
//       cancelButtonText: '<i class="remove icon"></i> No, Keep Changes',
//       confirmButtonClass: 'ui positive button',
//       cancelButtonClass: 'ui negative button',
//       buttonsStyling: false,
//       reverseButtons: true,
//       allowOutsideClick: false

//     }).then(function() {
//       let id = $('div[role="cancel_button_pf"]').attr('practitionerId')
//       window.location.href = '/practitioners/' + id;
//     })
//   });
// });
