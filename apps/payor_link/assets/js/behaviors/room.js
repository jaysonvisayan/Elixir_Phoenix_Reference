onmount('div[id="room_new"]', function() {


    $('#room_hierarchy').keypress(function(e) {
        if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) {
            return false;
        }
    });

    $('input[id="room_code"]').on('keyup', function(evt) {
        $(this).val(function(_, val) {
            return val.toUpperCase();
        });
    });


    /* CAPITALIZE FIRST LETTER OF CLUSTER NAME IN EVERY WORD*/
    $.fn.capitalize = function() {
        $.each(this, function() {
            this.value = this.value.replace(/\b[a-z]/gi, function($0) {
                return $0.toUpperCase();
            });
            this.value = this.value.replace(/@([a-z])([^.]*\.[a-z])/gi, function($0, $1) {
                console.info(arguments);
                return '@' + $0.toUpperCase() + $1.toLowerCase();
            });
        });
    }

    $('input[id="room_type"]').keypress(function() {
        $(this).capitalize();
    }).capitalize();

    let csrf = $('input[name="_csrf_token"]').val();
    let room_code = $('input[name="room[code]"]').attr("value")
    let room_type = $('input[name="room[type]"]').attr("value")

    $.ajax({
        url: `/get_all_room_code_and_type`,
        headers: {
            "X-CSRF-TOKEN": csrf
        },
        type: 'get',
        success: function(response) {
            let data = JSON.parse(response)
            let array = $.map(data, function(value, index) {
                return [value.code]
            });

            let array2 = $.map(data, function(value, index) {
                return [value.type.toLowerCase()]
            });


            if (room_code != undefined) {
                array.splice($.inArray(room_code, array), 1)
            }

            if (room_type != undefined) {
                array2.splice($.inArray(room_type, array2), 1)
            }

            $.fn.form.settings.rules.checkRoomCode = function(param) {
                return array.indexOf(param) == -1 ? true : false
            }

            $.fn.form.settings.rules.checkRoomType = function(param) {
              return array2.indexOf(param.toLowerCase()) == -1 ? true : false
            }


            $('.ui.form')
                .form({
                    on: blur,
                    inline: true,
                    fields: {
                        'room[code]': {
                            identifier: 'room[code]',
                            rules: [{
                                    type: 'empty',
                                    prompt: 'Room Code is required'
                                },
                                {
                                    type: 'checkRoomCode[param]',
                                    prompt: 'Room Code already exist!'
                                }
                            ]
                        },
                        'room[type]': {
                            identifier: 'room[type]',
                            rules: [{
                                    type: 'empty',
                                    prompt: 'Room Type is required'
                                },
                                {
                                    type: 'checkRoomType[param]',
                                    prompt: 'Room Type already exist!'
                                }

                            ]
                        },
                        'room[hierarchy]': {
                            identifierier: 'room[hierarchy]',
                            rules: [{
                                type: 'empty',
                                prompt: 'Room Hierarchy is required'
                            }]
                        },
                        'room[ruv_rate]': {
                            identifierier: 'room[ruv_rate]',
                            rules: [{
                                type: 'empty',
                                prompt: 'RUV Rate is required'
                            }]
                        }
                    },
                    onSuccess: function(event) {
                        if ($('#checker').val() == "") {
                            event.preventDefault()
                            swal({
                                title: 'Do you really want to create this room?',
                                html: "<br><div class='ui grid container'><div class='eight wide computer column'><b>Room Code</b></div>" +
                                    "<div class='eight wide computer column'>" + $('#room_code').val() + "</div>" + "</div>" +
                                    "<div class='ui grid container'><div class='eight wide computer column'><b>Room Type</b></div>" +
                                    "<div class='eight wide computer column'>" + $('#room_type').val() + "</div>" + "</div>" +
                                    "<div class='ui grid container'><div class='eight wide computer column'><b>Room Hierarchy</b></div>" +
                                    "<div class='eight wide computer column'>" + $('#room_hierarchy').val() + "</div>" + "</div>" +
                                    "<div class='ui grid container'><div class='eight wide computer column'><b>RUV Rate</b></div>" +
                                    "<div class='eight wide computer column'>" + $('#room_ruv_rate').val() + "</div>" + "</div><br><br>",
                                type: 'warning',
                                showCancelButton: true,
                                confirmButtonText: '<i class="check icon"></i> Yes',
                                cancelButtonText: '<i class="remove icon"></i> No',
                                confirmButtonClass: 'ui blue button',
                                cancelButtonClass: 'ui button',
                                buttonsStyling: false,
                                reverseButtons: true,
                                width: '850px'
                            }).then(function() {
                                $('#checker').val('true')
                                $('#room_form').submit()
                            }).catch(swal.noop)
                        }
                    }
                });
        },
        error: function() {}
    })

});

onmount('div[id="edit_room_modal"]', function() {

    $(this).modal({
            closable: false,
            onHide: function() {
                $('#room_div').removeClass("eight column row")
                $('#room_div').addClass("hidden")
                $('#facilities_room').removeClass("hidden")
                $('#facilities_room').addClass("column")
                $('#facilities_room_less').removeClass("column")
                $('#facilities_room_less').addClass("hidden")
            }
        })
        .modal('attach events', '.edit_room', 'show')

    $(".edit_room").click(function() {
        let room_id = $(this).attr('rid')
        let room_code = $(this).closest('tr').find('a[field="room_code"]').html()
        let room_type = $(this).closest('tr').find('td[field="room_type"]').html()
        let room_hierarchy = $(this).closest('tr').find('td[field="room_hierarchy"]').html()
        let room_ruv_rate = $(this).closest('tr').find('td[field="room_ruv_rate"]').html()
        let room_edit = document.getElementById('rooms_edit');
        if ((room_type == "OP") || (room_type == "ER"))
        {
          $('#rooms_edit').addClass("disabled")
        }
        else
        {
          $('#rooms_edit').removeClass("disabled")
        }
        $('input[field="room_id"]').val(room_id)
        $('#room_code').text(room_code)
        $('#room_type').text(room_type)
        $('#room_hierarchy').text(room_hierarchy)
        $('#room_ruv_rate').text(room_ruv_rate)



        room_edit.href = "rooms/" + room_id + "/update"

        $.ajax({
            url: `/rooms/${room_id}/logs`,
            type: 'GET',
            success: function(response) {
                $("#room_logs_table tbody").html('')
                if (jQuery.isEmptyObject(response.room_logs)) {
                    let no_log =
                        `NO LOGS FOUND`
                    $("#timeline").removeClass('feed timeline')
                    $("#room_logs_table tbody").append(no_log)
                } else {
                    for (let rlogs of response.room_logs) {
                        let new_row =
                            `<div class="ui feed"> \
             <div class="event"> \
             <div class="label"> \
             <i class="blue circle icon"></i> \
             </div> \
              <div class="content"> \
              <div class="summary"> \
             <p class="room_log_date">${rlogs.inserted_at}</p>\
             </div> \
             <div class="extra text"> \
             ${rlogs.message}\
             </div> \
             </div> \
             </div> \
             </div> \
             </tr>`
                        $("#timeline").addClass('feed timeline')
                        $("#room_logs_table tbody").append(new_row)
                    }
                }
                $('p[class="room_log_date"]').each(function() {
                    let date = $(this).html();
                    $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
                })
            }
        })

        $.ajax({
            url: `/rooms/${room_id}/get_a_room`,
            type: 'GET',
            success: function(response) {
                let obj = JSON.parse(response)

                let facility_room = obj.facility_room_rates
                $("#room_facilities_table tbody").html('')
                if (jQuery.isEmptyObject(facility_room)) {
                    let no_facility =
                        `<tr>\
            <td colspan="7" class="center aligned">NO FACILITIES FOUND</td>\
          </tr>`
                    $("#room_facilities_table tbody").append(no_facility)
                } else {
                    for (let room of facility_room) {
                        let new_row =
                            `<tr>\
                <td>${room.facility.name}</td>\
                <td>${room.facility.code}</td>\
                <td>${room.facility_room_type}</td>\
                <td>${room.facility_room_rate}</td>\
            </tr>`
                        $("#room_facilities_table tbody").append(new_row)
                    }
                }
            }
        })

    })

    $('#facilities_room').click(function() {
        $('#room_div').removeClass("hidden")
        $('#room_div').addClass("eight column row")
        $('#facilities_room_less').removeClass("hidden")
        $('#facilities_room_less').addClass("column")
        $(this).removeClass("column")
        $(this).addClass("hidden")

    })

    $('#facilities_room_less').click(function() {
        $('#room_div').removeClass("eight column row")
        $('#room_div').addClass("hidden")
        $('#facilities_room').removeClass("hidden")
        $('#facilities_room').addClass("column")
        $(this).removeClass("column")
        $(this).addClass("hidden")

    })

});



onmount('div[id="validates"]', function() {

    const csrf = $('input[name="_csrf_token"]').val();
    const room_type = $('input[name="room[type]"]').attr("value")

    $.ajax({
        url: `/get_all_room_type`,
        headers: {
            "X-CSRF-TOKEN": csrf
        },
        type: 'get',
        success: function(response) {
            const data = JSON.parse(response)
            const array = $.map(data, function(value, index) {
                return [value.type.toLowerCase()]
            });

            if (room_type != undefined) {
                array.splice($.inArray(room_type, array), 1)
            }

            $.fn.form.settings.rules.checkRoomType = function(param) {
                return array.indexOf(param.toLowerCase()) == -1 ? true : false
            }


            $('.ui.form')
                .form({
                    on: blur,
                    inline: true,
                    fields: {
                        'room[code]': {
                            identifier: 'room[code]',
                            rules: [{
                                    type: 'empty',
                                    prompt: 'Room Code is required'
                                },
                                {
                                    type: 'checkRoomCode[param]',
                                    prompt: 'Room Code already exist!'
                                }
                            ]
                        },
                        'room[type]': {
                            identifier: 'room[type]',
                            rules: [{
                                    type: 'empty',
                                    prompt: 'Room Type is required'
                                },
                                {
                                    type: 'checkRoomType[param]',
                                    prompt: 'Room Type already exist!'
                                }

                            ]
                        },
                        'room[hierarchy]': {
                            identifierier: 'room[hierarchy]',
                            rules: [{
                                type: 'empty',
                                prompt: 'Room Hierarchy is required'
                            }]
                        },
                        'room[ruv_rate]': {
                            identifierier: 'room[ruv_rate]',
                            rules: [{
                                type: 'empty',
                                prompt: 'RUV Rate is required'
                            }]
                        }
                    },
                    onSuccess: function(event) {
                        if ($('#checker').val() == "") {
                            event.preventDefault()
                            swal({
                                title: 'Do you really want to update this room?',
                                html: "<br><div class='ui grid container'><div class='eight wide computer column'><b>Room Code</b></div>" +
                                    "<div class='eight wide computer column'>" + $('#room_code').val() + "</div>" + "</div>" +
                                    "<div class='ui grid container'><div class='eight wide computer column'><b>Room Type</b></div>" +
                                    "<div class='eight wide computer column'>" + $('#room_type').val() + "</div>" + "</div>" +
                                    "<div class='ui grid container'><div class='eight wide computer column'><b>Room Hierarchy</b></div>" +
                                    "<div class='eight wide computer column'>" + $('#room_hierarchy').val() + "</div>" + "</div>" +
                                    "<div class='ui grid container'><div class='eight wide computer column'><b>RUV Rate</b></div>" +
                                    "<div class='eight wide computer column'>" + $('#room_ruv_rate').val() + "</div>" + "</div><br><br>",
                                type: 'warning',
                                showCancelButton: true,
                                confirmButtonText: '<i class="check icon"></i> Yes',
                                cancelButtonText: '<i class="remove icon"></i> No',
                                confirmButtonClass: 'ui blue button',
                                cancelButtonClass: 'ui button',
                                buttonsStyling: false,
                                reverseButtons: true,
                                width: '850px'
                            }).then(function() {
                                $('#checker').val('true')
                                $('#edit_room_form').submit()
                            }).catch(swal.noop)
                        }
                    }
                });
        },
        error: function() {}
    })
})


onmount('div[id="RoomLogsModal"]', function() {

    $(this).modal({
            closable: false,
            onDeny: function() {
                $('#room_div').removeClass("eight column row")
                $('#room_div').addClass("hidden")
                $('#facilities_room').removeClass("hidden")
                $('#facilities_room').addClass("column")
                $('#facilities_room_less').removeClass("column")
                $('#facilities_room_less').addClass("hidden")
            }
        })
        .modal('attach events', '#room_logs', 'show')

})
