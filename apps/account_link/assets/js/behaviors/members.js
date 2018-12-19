const locale = $('#locale').val();

onmount('div[id="Member_Index"]', function() {
  const csrf = $('input[name="_csrf_token"]').val();
  $('#member_table').DataTable({
    "columns": [
      null,
      null,
      null,
      null,
      null,
      { className: "menued-rows__wrap" }
    ],
    "ajax": {
      "url": "/en/members/index/data",
      "headers": { "X-CSRF-TOKEN": csrf },
      "type": "get"
    },
    "processing": true,
    "serverSide": true,
    "deferRender": true,
    "drawCallback": function (){
      $('.dropdown').dropdown();
      $('.menued-rows__dropdown').click( function() {
        $(this).find(".container").toggle();
      });

      openModal('.modal-open-requestloa', '.ui.modal.requestloa')
      openModal('.modal-open-requestloa-member', '.ui.modal.requestloa-member')
      function openModal(trigger, modal) {
        $(modal).modal('attach events', trigger, 'show');
      }


  $('.modal-open-viewlog').click(function() {
    let member_id = $(this).attr('member_id')
    $('#member_logs_table').css("overflow-y", "scroll")
    $.ajax({
      url: `/${locale}/members/${member_id}/logs`,
      type: 'get',
      success: function(response) {
        // FOR MEMBER LOGS
        $("#member_logs_table tbody").html('')
        if (jQuery.isEmptyObject(response)) {
          $('#extend_logs').attr('style','')
          let no_log =
            `NO LOGS FOUND`
          $("#timeline").removeClass('feed timeline')
          $("#member_logs_table tbody").append(no_log)
        } else {
          let i=0
          for (let log of response) {
            let new_row =
              `<div class="ui feed">\
              <div class="event"> \
              <div class="label"> \
              <i class="blue circle icon"></i> \
              </div> \
              <div class="content"> \
              <div class="summary">\
              <p class="member_log_date">${log.inserted_at}</p>\
              </div>\
              <div class="extra text"> \
              ${log.message}\
              </div> \
              </div> \
              </div> </tr>
            `
            $("#timeline").addClass('feed timeline')
            $("#member_logs_table tbody").append(new_row)
            i++
              if(i>=5) {
                $('#extend_logs').attr('style','overflow:scroll;height:300px;overflow:auto')}
            else {$('#extend_logs').attr('style','')}
          }
        }
        $('p[class="member_log_date"]').each(function() {
          let date = $(this).html();
          $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
        })
      $('.ui.modal.view-log').modal('show')
        // END OF MEMBER LOGS

      }
    })
  })

  $('#submit_cancel')
  .form({
    on: blur,
    inline: true,
    fields: {
      'member[cancel_date]': {
        identifier: 'member[cancel_date]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Cancel Date'
          }
        ]
      },
      'member[cancel_reason]': {
        identifier: 'member[cancel_reason]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Cancel Reason'
          }
        ]
      }
    }
  });
  $('#submit_suspend')
  .form({
    on: blur,
    inline: true,
    fields: {
      'member[cancel_date]': {
        identifier: 'member[suspend_date]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Suspend Date'
          }
        ]
      },
      'member[cancel_reason]': {
        identifier: 'member[suspend_reason]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Suspend Reason'
          }
        ]
      }
    }
  });
  $('#submit_reactivate')
  .form({
    on: blur,
    inline: true,
    fields: {
      'member[cancel_date]': {
        identifier: 'member[reactivate_date]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Reactivate Date'
          }
        ]
      },
      'member[cancel_reason]': {
        identifier: 'member[reactivate_reason]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Reactivate Reason'
          }
        ]
      }
    }
  });
  $('#submit_cancel_retract')
  .form({
    on: blur,
    inline: true,
    fields: {
      'member[cancel_date]': {
        identifier: 'member[cancel_date]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Cancel Date'
          }
        ]
      },
      'member[cancel_reason]': {
        identifier: 'member[cancel_reason]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Cancel Reason'
          }
        ]
      }
    }
  });
  $('#submit_suspend_retract')
  .form({
    on: blur,
    inline: true,
    fields: {
      'member[cancel_date]': {
        identifier: 'member[suspend_date]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Suspend Date'
          }
        ]
      },
      'member[cancel_reason]': {
        identifier: 'member[suspend_reason]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Suspend Reason'
          }
        ]
      }
    }
  });
  $('#submit_reactivate_retract')
  .form({
    on: blur,
    inline: true,
    fields: {
      'member[cancel_date]': {
        identifier: 'member[reactivate_date]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Reactivate Date'
          }
        ]
      },
      'member[cancel_reason]': {
        identifier: 'member[reactivate_reason]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please Enter Reactivate Reason'
          }
        ]
      }
    }
  });

  let member_id
  let member_name
  let member_status
  let member_effect
  let member_expire

  $('.modal-open-actionConfirmation-cancel').click(function(){
    let member_cancel_date = $(this).attr('member_cancel_date')
    let member_cancel_reason = $(this).attr('member_cancel_reason')
    let member_cancel_remarks = $(this).attr('member_cancel_remarks')
    let member_suspend_date = new Date((new Date($(this).attr('member_suspend_date'))).getTime() + (1 * 24 * 60 * 60 * 1000))
    let member_reactivate_date = new Date((new Date($(this).attr('member_reactivate_date'))).getTime() + (1 * 24 * 60 * 60 * 1000))
    const today = new Date((new Date()).getTime() + (1 * 24 * 60 * 60 * 1000))
    member_name = $(this).attr('member_name')
    member_status = $(this).attr('member_status')
    member_effect = $(this).attr('member_effect_date')
    member_expire = $(this).attr('member_expire_date')
    member_id = $(this).attr('member_id')

    let account_suspend_date = $(this).attr('account_suspend_date')
    let account_cancel_date = $(this).attr('account_cancel_date')
    let before_member_expire = new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000))
    let min_date = ""
    let max_date = before_member_expire


    if (member_suspend_date != 'Invalid Date' && new Date(member_suspend_date) >= today) {
      min_date = member_suspend_date
    }
    else if (member_reactivate_date != 'Invalid Date' && new Date(member_reactivate_date) >= today) {
      min_date = member_reactivate_date
    }
    else {
      min_date = today
    }

    if (account_cancel_date) {
      if (new Date(account_cancel_date) <= new Date(member_expire)) {
        max_date = new Date(account_cancel_date)
      }
      else {
        max_date = before_member_expire
      }
    }
    else {
      max_date = before_member_expire
    }

     if (member_cancel_date == ''){
      $('#cancel_member_id').val(member_id)
      $('#cancel_member_name').val(member_name)
      $('#cancel_member_name').attr('disabled', 'disabled')
      $('#cancel_member_status').text(member_status)
      $('#cancel_member_effect').val(member_effect)
      $('#cancel_member_expire').val(member_expire)
      $('#cancel_member_effect').attr('disabled', 'disabled')
      $('#cancel_member_expire').attr('disabled', 'disabled')

      $('.ui.modal.action-confirmation-cancel').modal({
        closable: false,
        autofocus: false,
        observeChanges: true,
        onHide: function() {
          $('#close_update_cancel').attr('style', 'display: none;')
          $('#update_cancel').attr('style', 'display: none;')
          $('#close_cancel_edit').attr('style', 'display: block;')
          $('#edit_cancel').attr('style', 'display: block;')
        },
        onShow: function() {
          $('#cancelDate').calendar({
            type: 'date',
            startMode: 'day',
            minDate: new Date(min_date.getFullYear(), min_date.getMonth(), min_date.getDate()),
            maxDate: new Date(max_date.getFullYear(), max_date.getMonth(), max_date.getDate()),
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
                return year + '-' + month + '-' + day;
              }
            }
          })
        }
      }).modal('show')
    }
    else {
      $('#cancel_date').val(member_cancel_date)
      $('#cancel_reason').val(member_cancel_reason).change()
      $('#cancel_remark').val(member_cancel_remarks)
      $('#cancel_date').attr('disabled', 'disabled')
      $('.dropdown').addClass("disabled");
      $('#cancel_remark').attr('disabled', 'disabled')
      $('#retract_cancel_member_id').val(member_id)
      $('#retract_cancel_member_name').val(member_name)
      $('#retract_cancel_member_name').attr('disabled', 'disabled')
      $('#retract_cancel_member_status').text(member_status)
      $('#retract_cancel_member_effect').val(member_effect)
      $('#retract_cancel_member_expire').val(member_expire)
      $('#retract_cancel_member_effect').attr('disabled', 'disabled')
      $('#retract_cancel_member_expire').attr('disabled', 'disabled')

      $('.ui.modal.action-confirmation-cancel-retract').modal({
        closable: false,
        autofocus: false,
        observeChanges: true,
        onHide: function() {
          $('#close_update_cancel').attr('style', 'display: none;')
          $('#update_cancel').attr('style', 'display: none;')
          $('#close_cancel_edit').attr('style', 'display: block;')
          $('#edit_cancel').attr('style', 'display: block;')
        },
        onShow: function() {
          $('#retractcancelDate').calendar({
            type: 'date',
            startMode: 'day',
            minDate: new Date(min_date.getFullYear(), min_date.getMonth(), min_date.getDate()),
            maxDate: new Date(max_date.getFullYear(), max_date.getMonth(), max_date.getDate()),
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
                return year + '-' + month + '-' + day;
              }
            }
          })
        }
      }).modal('show')
    }
  });

  $('#close_cancel_member').click(function(){
    $('.ui.modal.action-confirmation-cancel').modal('hide');
  });

  $('#close_cancel').click(function(){
    $('.ui.modal.action-confirmation-cancel-retract').modal('hide');
  });

  $('#close_update_cancel').click(function(){
    $('.ui.modal.action-confirmation-cancel-retract').modal('hide');
  });

  $('#cancel_cancel').click(function(){
    swal({
      text: "Are you sure you want to retract movement?",
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="send icon"></i> Yes, retract movement',
      cancelButtonText: '<i class="remove icon"></i> No, dont retract movement',
      confirmButtonClass: 'ui small positive right floated button',
      cancelButtonClass: 'ui small negative floated button',
      buttonsStyling: false
    }).then(function () {
      $('#cancel_date').val('for_retract')
      $('#cancel_reason').val('Reason 1')
      $('#submit_cancel_retract').submit()
    })
  });

  $('#edit_cancel_member').click(function() {
    $('#close_update_cancel').attr('style', 'display: block;')
    $('#update_cancel').attr('style', 'display: block;')
    $('#close_cancel_edit').attr('style', 'display: none;')
    $('#edit_cancel').attr('style', 'display: none;')
    $('#cancel_date').removeAttr('disabled')
    $('.dropdown').removeClass('disabled')
    $('#cancel_remark').removeAttr('disabled')
  });

  $('.modal-open-actionConfirmation-suspend').click(function(){
    let member_suspend_date = $(this).attr('member_suspend_date')
    let member_suspend_reason = $(this).attr('member_suspend_reason')
    let member_suspend_remarks = $(this).attr('member_suspend_remarks')
    let member_cancel_date = new Date((new Date($(this).attr('member_cancel_date'))).getTime() - (1 * 24 * 60 * 60 * 1000))
    member_name = $(this).attr('member_name')
    member_status = $(this).attr('member_status')
    member_effect = $(this).attr('member_effect_date')
    member_expire = $(this).attr('member_expire_date')
    member_id = $(this).attr('member_id')

    const today = new Date((new Date()).getTime() + (1 * 24 * 60 * 60 * 1000))
    let account_suspend_date = $(this).attr('account_suspend_date')
    let account_cancel_date = $(this).attr('account_cancel_date')
    let before_member_expire = new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000))
    let max_date = ""

    if (member_cancel_date != 'Invalid Date') {
      if (new Date(member_cancel_date) <= before_member_expire) {
        max_date = member_cancel_date
      }
      else {
        max_date = before_member_expire
      }
    }
    else {
      if (account_suspend_date) {
        if (new Date(account_suspend_date) <= new Date(member_expire)) {
          max_date = new Date(account_suspend_date)
        }
        else {
          max_date = before_member_expire
        }
      }
      else {
        if (account_cancel_date) {
          if (new Date(account_cancel_date) <= new Date(member_expire)) {
            max_date = new Date(account_cancel_date)
          }
          else {
            max_date = before_member_expire
          }
        }
        else {
          max_date = before_member_expire
        }
      }
    }

    if (member_suspend_date == ''){
      $('#suspend_member_id').val(member_id)
      $('#suspend_member_name').val(member_name)
      $('#suspend_member_name').attr('disabled', 'disabled')
      $('#suspend_member_status').text(member_status)
      $('#suspend_member_effect').val(member_effect)
      $('#suspend_member_expire').val(member_expire)
      $('#suspend_member_effect').attr('disabled', 'disabled')
      $('#suspend_member_expire').attr('disabled', 'disabled')

      $('.ui.modal.action-confirmation-suspend').modal({
        closable: false,
        autofocus: false,
        observeChanges: true,
        onHide: function() {
          $('#close_update_suspend').attr('style', 'display: none;')
          $('#update_suspend').attr('style', 'display: none;')
          $('#close_suspend_edit').attr('style', 'display: block;')
          $('#edit_suspend').attr('style', 'display: block;')
        },
        onShow: function() {
          $('#suspendDate').calendar({
            type: 'date',
            startMode: 'day',
            minDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
            maxDate: new Date(max_date.getFullYear(), max_date.getMonth(), max_date.getDate()),
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
                return year + '-' + month + '-' + day;
              }
            }
          })
        }
      }).modal('show')
    }
    else {
      $('#suspend_date').val(member_suspend_date)
      $('#suspend_reason').val(member_suspend_reason).change()
      $('#suspend_remark').val(member_suspend_remarks)
      $('#suspend_date').attr('disabled', 'disabled')
      $('.dropdown').addClass("disabled")
      $('#suspend_remark').attr('disabled', 'disabled')
      $('#retract_suspend_member_id').val(member_id)
      $('#retract_suspend_member_name').val(member_name)
      $('#retract_suspend_member_name').attr('disabled', 'disabled')
      $('#retract_suspend_member_status').text(member_status)
      $('#retract_suspend_member_effect').val(member_effect)
      $('#retract_suspend_member_expire').val(member_expire)
      $('#retract_suspend_member_effect').attr('disabled', 'disabled')
      $('#retract_suspend_member_expire').attr('disabled', 'disabled')

      $('.ui.modal.action-confirmation-suspend-retract').modal({
        closable: false,
        autofocus: false,
        observeChanges: true,
        onHide: function() {
          $('#close_update_suspend').attr('style', 'display: none;')
          $('#update_suspend').attr('style', 'display: none;')
          $('#close_suspend_edit').attr('style', 'display: block;')
          $('#edit_suspend').attr('style', 'display: block;')
        },
        onShow: function() {
          $('#retractsuspendDate').calendar({
            type: 'date',
            startMode: 'day',
            minDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
            maxDate: new Date(max_date.getFullYear(), max_date.getMonth(), max_date.getDate()),
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
                return year + '-' + month + '-' + day;
              }
            }
          })
        }
      }).modal('show')
    }
  });

  $('#close_suspend_member').click(function(){
    $('.ui.modal.action-confirmation-suspend').modal('hide');
  });

  $('#close_suspend').click(function(){
    $('.ui.modal.action-confirmation-suspend-retract').modal('hide');
  });

  $('#close_update_suspend').click(function(){
    $('.ui.modal.action-confirmation-suspend-retract').modal('hide');
  });

  $('#cancel_suspend').click(function(){
    swal({
      text: "Are you sure you want to retract movement?",
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="send icon"></i> Yes, retract movement',
      cancelButtonText: '<i class="remove icon"></i> No, dont retract movement',
      confirmButtonClass: 'ui small positive right floated button',
      cancelButtonClass: 'ui small negative floated button',
      buttonsStyling: false
    }).then(function () {
      $('#suspend_date').val('for_retract')
      $('#suspend_reason').val('Reason 1')
      $('#submit_suspend_retract').submit()
    })
  });

  $('#edit_suspend_member').click(function() {
    $('#close_update_suspend').attr('style', 'display: block;')
    $('#update_suspend').attr('style', 'display: block;')
    $('#close_suspend_edit').attr('style', 'display: none;')
    $('#edit_suspend').attr('style', 'display: none;')
    $('#suspend_date').removeAttr('disabled')
    $('.dropdown').removeClass('disabled')
    $('#suspend_remark').removeAttr('disabled')
  });

  $('.modal-open-actionConfirmation-reactivate').click(function(){
    let member_reactivate_date = $(this).attr('member_reactivate_date')
    let member_reactivate_reason = $(this).attr('member_reactivate_reason')
    let member_reactivate_remarks = $(this).attr('member_reactivate_remarks')
    let member_cancel_date = new Date((new Date($(this).attr('member_cancel_date'))).getTime() - (1 * 24 * 60 * 60 * 1000))
    member_name = $(this).attr('member_name')
    member_status = $(this).attr('member_status')
    member_effect = $(this).attr('member_effect_date')
    member_expire = $(this).attr('member_expire_date')
    member_id = $(this).attr('member_id')
    const today = new Date((new Date()).getTime() + (1 * 24 * 60 * 60 * 1000))
    let account_suspend_date = $(this).attr('account_suspend_date')
    let account_cancel_date = $(this).attr('account_cancel_date')
    let before_member_expire = new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000))
    let max_date = ""

    if (member_cancel_date != 'Invalid Date') {
      if (new Date(member_cancel_date) <= before_member_expire) {
        max_date = member_cancel_date
      }
      else {
        max_date = before_member_expire
      }
    }
    else {
      if (account_suspend_date) {
        if (new Date(account_suspend_date) <= new Date(member_expire)) {
          max_date = new Date(account_suspend_date)
        }
        else {
          max_date = before_member_expire
        }
      }
      else {
        if (account_cancel_date) {
          if (new Date(account_cancel_date) <= new Date(member_expire)) {
            max_date = new Date(account_cancel_date)
          }
          else {
            max_date = before_member_expire
          }
        }
        else {
          max_date = before_member_expire
        }
      }
    }

    if (member_reactivate_date == ''){
      $('.ui.modal.action-confirmation-reactivate').modal('show');
      $('#reactivate_member_id').val(member_id)
      $('#reactivate_member_name').val(member_name)
      $('#reactivate_member_name').attr('disabled', 'disabled')
      $('#reactivate_member_status').text(member_status)
      $('#reactivate_member_effect').val(member_effect)
      $('#reactivate_member_expire').val(member_expire)
      $('#reactivate_member_effect').attr('disabled', 'disabled')
      $('#reactivate_member_expire').attr('disabled', 'disabled')

      $('.ui.modal.action-confirmation-reactivate').modal({
        closable: false,
        autofocus: false,
        observeChanges: true,
        onHide: function() {
          $('#close_update_reactivate').attr('style', 'display: none;')
          $('#update_reactivate').attr('style', 'display: none;')
          $('#close_reactivate_edit').attr('style', 'display: block;')
          $('#edit_reactivate').attr('style', 'display: block;')
        },
        onShow: function() {
          $('#reactivateDate').calendar({
            type: 'date',
            startMode: 'day',
            minDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
            maxDate: new Date(max_date.getFullYear(), max_date.getMonth(), max_date.getDate()),
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
                return year + '-' + month + '-' + day;
              }
            }
          })
        }
      }).modal('show')
    }
    else {
      $('#reactivate_date').val(member_reactivate_date)
      $('#reactivate_reason').val(member_reactivate_reason).change()
      $('#reactivate_remark').val(member_reactivate_remarks)
      $('#reactivate_date').attr('disabled', 'disabled')
      $('.dropdown').addClass("disabled");
      $('#reactivate_remark').attr('disabled', 'disabled')
      $('#retract_reactivate_member_id').val(member_id)
      $('#retract_reactivate_member_name').val(member_name)
      $('#retract_reactivate_member_name').attr('disabled', 'disabled')
      $('#retract_reactivate_member_status').text(member_status)
      $('#retract_reactivate_member_effect').val(member_effect)
      $('#retract_reactivate_member_expire').val(member_expire)
      $('#retract_reactivate_member_effect').attr('disabled', 'disabled')
      $('#retract_reactivate_member_expire').attr('disabled', 'disabled')

      $('.ui.modal.action-confirmation-reactivate-retract').modal({
        closable: false,
        autofocus: false,
        observeChanges: true,
        onHide: function() {
          $('#close_update_reactivate').attr('style', 'display: none;')
          $('#update_reactivate').attr('style', 'display: none;')
          $('#close_reactivate_edit').attr('style', 'display: block;')
          $('#edit_reactivate').attr('style', 'display: block;')
        },
        onShow: function() {
          $('#retractreactivateDate').calendar({
            type: 'date',
            startMode: 'day',
            minDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
            maxDate: new Date(max_date.getFullYear(), max_date.getMonth(), max_date.getDate()),
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
                return year + '-' + month + '-' + day;
              }
            }
          })
        }
      }).modal('show')
    }
  });

  $('#close_reactivate_member').click(function(){
    $('.ui.modal.action-confirmation-reactivate').modal('hide');
  });

  $('#close_reactivate').click(function(){
    $('.ui.modal.action-confirmation-reactivate-retract').modal('hide');
  });

  $('#close_update_reactivate').click(function(){
    $('.ui.modal.action-confirmation-reactivate-retract').modal('hide');
  });

  $('#cancel_reactivate').click(function(){
    swal({
      text: "Are you sure you want to retract movement?",
      type: 'question',
      showCancelButton: true,
      confirmButtonText: '<i class="send icon"></i> Yes, retract movement',
      cancelButtonText: '<i class="remove icon"></i> No, dont retract movement',
      confirmButtonClass: 'ui small positive right floated button',
      cancelButtonClass: 'ui small negative floated button',
      buttonsStyling: false
    }).then(function () {
      $('#reactivate_date').val('for_retract')
      $('#reactivate_reason').val('Reason 1')
      $('#submit_reactivate_retract').submit()
    })
  });

  $('#edit_reactivate_member').click(function() {
    $('#close_update_reactivate').attr('style', 'display: block;')
    $('#update_reactivate').attr('style', 'display: block;')
    $('#close_reactivate_edit').attr('style', 'display: none;')
    $('#edit_reactivate').attr('style', 'display: none;')
    $('#reactivate_date').removeAttr('disabled')
    $('.dropdown').removeClass('disabled')
    $('#reactivate_remark').removeAttr('disabled')
  });


    }
  })

  let table = $('#member_table').DataTable();

  //Export Member
  $('#export_member').click(function() {
    let validate = []
    for (let i=0;i<8;i++)
    {
      validate[i] = ''
    }
    if ($('#member_pending').is(":checked") == false) {
      validate[0] = 'Pending'
    }
    if ($('#member_active').is(":checked") == false) {
      validate[1] = 'Active'
    }
    if ($('#member_cancel').is(":checked") == false) {
      validate[2] = 'Cancelled'
    }
    if ($('#member_suspend').is(":checked") == false ) {
      validate[3] = 'Suspended'
    }
    if ($('#member_lapse').is(":checked") == false) {
      validate[4] = 'Lapsed'
    }
    if ($('#member_principal').is(":checked") == false) {
      validate[5] = 'Principal'
    }
    if ($('#member_dependent').is(":checked") == false) {
      validate[6] = 'Dependent'
    }
    if ($('#member_guardian').is(":checked") == false) {
      validate[7] = 'Guardian'
    }

    let search_result = table.rows({order:'current', search: 'applied'}).data();
    let search_value = $('.dataTables_filter input').val();

    if (search_result.length > 0) {
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/members/index/download`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        data: {member_param: { "search_value" : search_value.trim(), "validate" : validate}},
        dataType: 'json',
        success: function(response){
          let utc = new Date()
          let year = utc.getUTCFullYear()
          let month = utc.getUTCMonth()
          let day = utc.getUTCDay();
          let date = `${month}-${day}-${year}`
          let filename = 'Members_' + date + '.csv'
          // Download CSV file
          downloadCSV(response, filename);
        }
      });
    }
    else{
      alertify.error('</i>No Members to Download.<i id="notification_error" class="close icon">');
      alertify.defaults = {
        notifier:{
          delay:5,
          position:'top-right',
          closeButton: false
        }
      };
    }
  });

  // Event listener to the two range filtering inputs to redraw on input
  $('#member_suspend').on('change', function() {
    table.draw();
  });
  $('#member_active').on('change', function() {
    table.draw();
  });
  $('#member_lapse').on('change', function() {
    table.draw();
  });
  $('#member_cancel').on('change', function() {
    table.draw();
  });
  $('#member_pending').on('change', function() {
    table.draw();
  });
  $('#member_guardian').on('change', function() {
    table.draw();
  });
  $('#member_dependent').on('change', function() {
    table.draw();
  });
  $('#member_principal').on('change', function() {
    table.draw();
  });

  $.fn.dataTable.ext.search.push(function( settings, data, dataIndex ) {
    if ( $('#member_suspend').is(":checked") && $('#member_principal').is(":checked") == false  && $('#member_dependent').is(":checked") == false && $('#member_guardian').is(":checked") == false ){
      if (data[4].trim() == "Suspended"){
        return true;
      }
    }
    if ( $('#member_active').is(":checked") && $('#member_principal').is(":checked") == false  && $('#member_dependent').is(":checked") == false && $('#member_guardian').is(":checked") == false ){
      if (data[4].trim() == "Active"){
        return true;
      }
    }
    if ( $('#member_cancel').is(":checked") && $('#member_principal').is(":checked") == false  && $('#member_dependent').is(":checked") == false && $('#member_guardian').is(":checked") == false ){
      if (data[4].trim() == "Cancelled"){
       return true;
      }
    }
    if ( $('#member_pending').is(":checked") && $('#member_principal').is(":checked") == false  && $('#member_dependent').is(":checked") == false && $('#member_guardian').is(":checked") == false ){
      if (data[4].trim() == "Pending"){
        return true;
      }
    }
    if ( $('#member_lapse').is(":checked") && $('#member_principal').is(":checked") == false  && $('#member_dependent').is(":checked") == false && $('#member_guardian').is(":checked") == false ){
      if (data[4].trim() == "Lapsed"){
        return true;
      }
    }
    if ( $('#member_guardian').is(":checked") && $('#member_active').is(":checked") == false  && $('#member_cancel').is(":checked") == false && $('#member_suspend').is(":checked") == false && $('#member_pending').is(":checked") == false && $('#member_lapse').is(":checked") == false){
      if (data[3].trim() == "Guardian") {
        return true;
      }
    }
    if ( $('#member_principal').is(":checked") && $('#member_active').is(":checked") == false  && $('#member_cancel').is(":checked") == false && $('#member_suspend').is(":checked") == false && $('#member_pending').is(":checked") == false && $('#member_lapse').is(":checked") == false){
      if (data[3].trim() == "Principal"){
        return true;
          }
      }
    if ( $('#member_dependent').is(":checked") && $('#member_active').is(":checked") == false  && $('#member_cancel').is(":checked") == false && $('#member_suspend').is(":checked") == false && $('#member_pending').is(":checked") == false && $('#member_lapse').is(":checked") == false){
      if (data[3].trim() == "Dependent"){
        return true;
      }
    }
    if ( $('#member_suspend').is(":checked") && $('#member_principal').is(":checked")){
      if (data[4].trim() == "Suspended" && data[3].trim() == "Principal"){
        return true;
      }
    }
    if ( $('#member_suspend').is(":checked") && $('#member_dependent').is(":checked")){
      if (data[4].trim() == "Suspended" && data[3].trim() == "Dependent"){
        return true;
      }
    }
    if ( $('#member_suspend').is(":checked") && $('#member_guardian').is(":checked")){
      if (data[4].trim() == "Suspended" && data[3].trim() == "Guardian"){
        return true;
      }
    }
    if ( $('#member_pending').is(":checked") && $('#member_principal').is(":checked")){
      if (data[4].trim() == "Pending" && data[3].trim() == "Principal"){
        return true;
      }
    }
    if ( $('#member_pending').is(":checked") && $('#member_dependent').is(":checked")){
      if (data[4].trim() == "Pending" && data[3].trim() == "Dependent"){
        return true;
      }
    }
    if ( $('#member_pending').is(":checked") && $('#member_guardian').is(":checked")){
      if (data[4].trim() == "Pending" && data[3].trim() == "Guardian"){
        return true;
      }
    }
    if ( $('#member_active').is(":checked") && $('#member_principal').is(":checked")){
      if (data[4].trim() == "Active" && data[3].trim() == "Principal"){
        return true;
      }
    }
    if ( $('#member_active').is(":checked") && $('#member_dependent').is(":checked")){
      if (data[4].trim() == "Active" && data[3].trim() == "Dependent"){
        return true;
       }
    }
    if ( $('#member_active').is(":checked") && $('#member_guardian').is(":checked")){
      if (data[4].trim() == "Active" && data[3].trim() == "Guardian"){
        return true;
      }
    }
    if ( $('#member_cancel').is(":checked") && $('#member_principal').is(":checked")){
      if (data[4].trim() == "Cancelled" && data[3].trim() == "Principal"){
        return true;
      }
    }
    if ( $('#member_cancel').is(":checked") && $('#member_dependent').is(":checked")){
      if (data[4].trim() == "Cancelled" && data[3].trim() == "Dependent"){
        return true;
      }
    }
    if ( $('#member_cancel').is(":checked") && $('#member_guardian').is(":checked")){
      if (data[4].trim() == "Cancelled" && data[3].trim() == "Guardian"){
        return true;
      }
    }
    if ( $('#member_lapse').is(":checked") && $('#member_principal').is(":checked")){
      if (data[4].trim() == "Lapsed" && data[3].trim() == "Principal"){
        return true;
      }
    }
    if ( $('#member_lapse').is(":checked") && $('#member_dependent').is(":checked")){
      if (data[4].trim() == "Lapsed" && data[3].trim() == "Dependent"){
        return true;
      }
    }
    if ( $('#member_lapse').is(":checked") && $('#member_guardian').is(":checked")){
      if (data[4].trim() == "Lapsed" && data[3].trim() == "Guardian"){
        return true;
      }
    }

    if ( $('#member_dependent').is(":checked") == false  && $('#member_principal').is(":checked") == false && $('#member_guardian').is(":checked") == false && $('#member_suspend').is(":checked") == false && $('#member_pending').is(":checked") == false && $('#member_active').is(":checked") == false && $('#member_lapse').is(":checked") == false && $('#member_cancel').is(":checked") == false ){
      return true;
    }
  });

  $('.requestloa').modal({
    closable  : false,
    onHide : function(){
      $('#validate_member_cvv').removeClass('error')
      $('#validate_member_cvv').find('.prompt').remove()
      $('#validate_member_card_no').removeClass('error')
      $('#validate_member_card_no').find('.prompt').remove()
    }
  })
  $('.requestloa-member').modal({
    closable  : false,
    onHide : function(){
      $('#validate_fullname').removeClass('error')
      $('#validate_fullname').find('.prompt').remove()
      $('#validate_birthdate').removeClass('error')
      $('#validate_birthdate').find('.prompt').remove()
    }
  })

  $('.request_loa').on('click', function(){
    let member_id = $(this).attr('memberID')
    let member_card_no = $(this).attr('memberCardNo')
    let member_name = $(this).attr('memberName').toLowerCase().replace(/\s+/g, ' ').trim()
    let member_birthdate = $(this).attr('memberBirthDate')
    $('#member_card_id').val(member_id)
    $('#member_card_no').val(member_card_no)
    $('#member_info').attr('memberID', member_id)
    $('#member_info').attr('memberName', member_name)
    $('#member_info').attr('memberBirthDate', member_birthdate)

    $('#authenticate_card_button').click(function(){
      let card_no = ''
      let member_card_no = $('#member_card_no').val()
      $('#verify_member_card_no').find('.text-center.cardVerification').each(function(){
        card_no += $(this).val()
      })
      if (card_no.length < 16){
        $('#validate_member_card_no').removeClass('error')
        $('#validate_member_card_no').find('.prompt').remove()
        $('#validate_member_card_no').addClass('error')
        $('#validate_member_card_no').append(`<div class="ui basic red pointing prompt label transition visible">Please complete Card No</div>`)
      }
      if($('#validate_member_cvv').find('.text-center.cvvVerification').val().length < 3){
        $('#validate_member_cvv').removeClass('error')
        $('#validate_member_cvv').find('.prompt').remove()
        $('#validate_member_cvv').addClass('error')
        $('#validate_member_cvv').append(`<div class="ui basic red pointing prompt label transition visible">Please complete CVV</div>`)
      }
      if (card_no.length == 16 && $('#validate_member_cvv').find('.text-center.cvvVerification').val().length == 3){
        if (member_card_no == card_no){
          alert('verified')
        }
        else{
          window.location.href=`/${locale}/members?invalid_card=true`
        }
      }
    })
  });

  $('#verify_member_card_no').find('.text-center.cardVerification').change(function(){
    $('#validate_member_card_no').removeClass('error')
    $('#validate_member_card_no').find('.prompt').remove()
  })

  $('#validate_member_cvv').find('.text-center.cvvVerification').change(function(){
    $('#validate_member_cvv').removeClass('error')
    $('#validate_member_cvv').find('.prompt').remove()
  })

  $('#member_info').on('click', function(){
    let member_id = $(this).attr('memberID')
    let member_name = $(this).attr('memberName')
    let member_birthdate = $(this).attr('memberBirthDate')
    //$('input[name="member[member_info_id]"]').val(member_id)

    $('#authenticate_info_button').click(function(){
      if ($('#member_full_name').val() == ""){
        $('#validate_fullname').removeClass('error')
        $('#validate_fullname').find('.prompt').remove()
        $('#validate_fullname').addClass('error')
        $('#validate_fullname').append(`<div class="ui basic red pointing prompt label transition visible">Please enter fullname</div>`)
      }
      if ($('#member_birthdate').val() == ""){
        $('#validate_birthdate').removeClass('error')
        $('#validate_birthdate').find('.prompt').remove()
        $('#validate_birthdate').addClass('error')
        $('#validate_birthdate').append(`<div class="ui basic red pointing prompt label transition visible">Please enter birthdate</div>`)
      }
      if ($('#member_full_name').val() != "" && $('#member_birthdate').val() != ""){
        if ($('#member_full_name').val().toLowerCase().replace(/\s+/g, ' ').trim() == member_name && $('#member_birthdate').val() == member_birthdate){
          alert('verified')
        }
        else{
          window.location.href=`/${locale}/members?invalid_info=true`
        }
      }
    })
  });

  $('#member_full_name').change(function(){
    $('#validate_fullname').removeClass('error')
    $('#validate_fullname').find('.prompt').remove()
  })

  $('#member_birthdate').change(function(){
    $('#validate_birthdate').removeClass('error')
    $('#validate_birthdate').find('.prompt').remove()
  })

  const today = new Date();
  $('#birthdate').calendar({
    type: 'date',
    monthFirst: true,
    maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
        return year + '-' + month + '-' + day;
      }
    }
  });
});

function downloadCSV(csv, filename){
  var csvFile;
  var downloadLink;

  // CSV file
  csvFile = new Blob([csv], {type: "text/csv"});

  // Download link
  downloadLink = document.createElement("a");

  // File name
  downloadLink.download = filename;

  // Create a link to the file
  downloadLink.href = window.URL.createObjectURL(csvFile);

  // Hide download link
  downloadLink.style.display = "none";

  // Add the link to DOM
  document.body.appendChild(downloadLink);

  // Click download link
  downloadLink.click();
};
//End Export Member


onmount('input[id="invalid_info"]', function(){
  alertify.error('<i id="notification_error" class="close icon"></i><p>Invalid member details.</p>');
  alertify.defaults = {
    notifier:{
      delay:5,
      position:'top-right',
      closeButton: false
    }
  };
})

onmount('input[id="invalid_card"]', function(){
  alertify.error('<i id="notification_error" class="close icon"></i><p>The Card number or CVV you have entered is invalid</p>');
  alertify.defaults = {
    notifier:{
      delay:5,
      position:'top-right',
      closeButton: false
    }
  };
})

onmount('div[id="memberComment"]', function() {
 // for member comment
  $('.timefromnow').each(function() {
    let value = moment($(this).attr('timestamp')).fromNow()
    $(this).html(value)
  })

  setInterval(function(){
    $('.timefromnow').each(function() {
      let value = moment($(this).attr('timestamp')).fromNow()
      $(this).html(value)
    })
  }, 5000);

  $('a[name="comment_modal"]').on('click', function(){
    $('div[role="add-comment"]').modal('show');
  })

  $('#btnComment').on('click', function(e){
    let csrf = $('input[name="_csrf_token"]').val();
    let member_id = $('#member_id').val()
    let comment = $('#member_comment').val()
    let params = {comment: comment}


    if (comment == '') {

      $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
        $(this).remove();
      });

      $('#comment_text_area').addClass('error').append(`<div class="ui basic red pointing prompt label transition visible">Please enter comment</div>`)
    }
    else{
      $.ajax({
        url:`/en/members/${member_id}/add_comment`,
        headers: {"X-CSRF-TOKEN": csrf},
        data: {member_params: params},
        type: 'POST',
        success: function(response){
          let obj = JSON.parse(response)

          $('#commentContainer').prepend(`<div class="item">
                          <div class="mt-1 mb-1">${obj.comment}</div>
                          <i class="large github middle aligned icon"></i>
                          <div class="content">
                            <a class="header">${obj.created_by}</a>
                            <div class="description timefromnow" timestamp="${obj.inserted_at}">a few seconds ago</div>
                          </div>
                        </div>`)

          $('#member_comment').val('')
          $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
            $(this).remove();
          });
          $('#comment_text_area').removeClass('error')
          $('#message_count').text("0/250")
        },
        error: function(){
          alert("Erorr adding Batch comment!")
        }
      })
    }

  })

  $('#member_comment').on('keyup', function(){
    $('.ui.basic.red.pointing.prompt.label.transition.visible').each(function(){
      $(this).remove();
    });
    $('#comment_text_area').removeClass('error')

    let max_length = parseInt(250);

    $('#message_count').val(max_length + ' characters')
    let text_length = $(this).val().length;
    let text_remaining = max_length - text_length;
    $('#message_count').html(text_length + "/250")
  })
})

onmount('div[id="Members"]', function() {

  $('#modalProcedure')
    .modal({autofocus: false, observeChanges: true})
    .modal('attach events', '.add.button', 'show')

  $('#sortableProducts').sortable({
    appendTo: 'body',
    helper: 'clone',
    stop: function(event, ui){
      let counter = 1
      $('#memberProductsTbl > tbody  > tr').each(function(){
        $(this).children(':first').html(`<b>${counter}</b>`)
        counter++
      })
    }
  });

  var valArray = []
  $("input:checkbox").on('change', function () {
    var value = $(this).val()
    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value)
      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('input[name="member[account_product_ids_main]"]').val(valArray)
  });

  $('#product_select').on('change', function(){
    var valArray = [];

    if($(this).is(':checked')){
      $('input[name="member[account_product_id][]"]').each(function(){
        $(this).prop('checked', true)

        var value = $(this).val();
        if(this.checked) {
          valArray.push(value);
        } else {
          var index = valArray.indexOf(value);
          if (index >= 0) {
            valArray.splice( index, 1)
          }
        }
      })
    }else{
      $('input[name="member[account_product_id][]"]').each(function(){
        $(this).prop('checked', false)
      })
    }

    $('input[name="member[account_product_ids_main]"]').val(valArray)
  });

  let member_product_tier = []

  $('#productTierForm').on('submit', function(){
    $('#memberProductsTbl > tbody  > tr').each(function(){
      member_product_tier.push($(this).attr('mpID'))
    })
    $('#productTier').val(member_product_tier)
  });

  $('.delete_product').on('click', function(){
    let m_id = $(this).attr('memberID');
    let mp_id = $(this).attr('memberProductID');
    $('#product_removal_confirmation').modal('show');
    $('#confirmation_m_id').val(m_id);
    $('#confirmation_mp_id').val(mp_id);
  })

  $('.delete_invalid').on('click', function(){
    $('.ajs-message.ajs-error.ajs-visible').remove()
    alertify.error(`<i class="close icon"></i><p>Product was already used and this cannot be removed</p>`);
  })

  $('#confirmation_cancel_p').click(function(){
    $('#product_removal_confirmation').modal('hide');
  });

  $('#confirmation_submit_p').click(function(){
    let csrf = $('input[name="_csrf_token"]').val();
    let m_id = $('#confirmation_m_id').val();
    let mp_id = $('#confirmation_mp_id').val();

    $.ajax({
      url:`/${locale}/members/${m_id}/member_product/${mp_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        if(obj.valid == true){
          window.location.href = `/${locale}/members/${m_id}/show`
        } else {
          if(obj.coverage == "ACU"){
            alertify.error('<i class="close icon"></i>ACU Benefit has already been availed.')
          } else {
            alertify.error('<i class="close icon"></i>Member Plan has already been used.')
          }
        }
      },
      error: function(){
        alert('Error deleting product!')
      }
    });
  });
});

onmount('div[name="MemberGeneral"]', function () {
  $('.ui.dropdown.search.selection').dropdown({ fullTextSearch: true });
  const member_id = $('#memberID').val();
  const principal_id = $('#memberPrincipalID').val()
  const today = new Date();
  const account_group_id = $('input[name="member[account_group_id]"]').val()
  const account_group_code = $('input[name="member[account_code]"]').val()
  let employee_number_array = []
  let account_principals = []
  let hierarchy = []
  let single_dependent_hierarchy = []
  let single_parent_dependent_hierarchy = []
  let married_dependent_hierarchy = []
  let effective_date = ""
  let expiry_date = ""
  let dependents_to_skip = []
  let pwd_arr = []
  let senior_arr = []
  let csrf = $('input[name="_csrf_token"]').val()

  $.ajax({
    url:`/${locale}/account/${account_group_code}/get_account`,
    type: 'GET',
    success: function(response){
      // set dependent hierarchies of returned account
      single_dependent_hierarchy.length = 0
      single_parent_dependent_hierarchy.length = 0
      married_dependent_hierarchy.length = 0
      $.map(response.dependent_hierarchy, function(dependent_hierarchy, index) {
        if (dependent_hierarchy.hierarchy_type == "Single Employee") {
          single_dependent_hierarchy.push(dependent_hierarchy.dependent)
        }
        if (dependent_hierarchy.hierarchy_type == "Single Parent Employee") {
          single_parent_dependent_hierarchy.push(dependent_hierarchy.dependent)
        }
        if (dependent_hierarchy.hierarchy_type == "Married Employee") {
          married_dependent_hierarchy.push(dependent_hierarchy.dependent)
        }
      })

      let members = response.members

      // get employee numbers within the selected account
      employee_number_array.length = 0
      $.map(members, function(member, index) {
        if (member.employee_no != null && member.id != member_id){
          employee_number_array.push(member.employee_no)
        }
      })

      // get principal IDs within the account
      account_principals.length = 0
      $('#principalID').html('')
      $('#principalID').append('<option value="">Please select Principal ID</option>')

      $.each(members, function(index, member) {
        if ((member.type == "Principal" || member.type == "Guardian") && member.id != member_id && member.status == "Active") {
          account_principals.push(member)

          if (member.middle_name) {
            if (member.suffix) {
              $('#principalID').append(`<option value="${member.id}">${member.id} - ${member.first_name} ${member.middle_name} ${member.last_name} ${member.suffix}</option>`)
            }else {
              $('#principalID').append(`<option value="${member.id}">${member.id} - ${member.first_name} ${member.middle_name} ${member.last_name}</option>`)
            }
          }else {
            if (member.suffix) {
              $('#principalID').append(`<option value="${member.id}">${member.id} - ${member.first_name} ${member.last_name} ${member.suffix}</option>`)
            }else {
              $('#principalID').append(`<option value="${member.id}">${member.id} - ${member.first_name} ${member.last_name}</option>`)
            }
          }
        }
      })

      $('#principalID').dropdown('clear')
      $('#principalID').dropdown()
      $('#relationship').html('')
      $('#relationship').dropdown('clear')

      setTimeout(function () {
        $('#principalID').dropdown('set selected', $('#memberPrincipalID').val())
      }, 1)

      let accounts = response.account

      $.each(accounts, function(index, account){
        if (account.status == "Active"){
          effective_date = account.start_date
          expiry_date = account.end_date
        }
      })

      $('input[name="member[effectivity_date]"]').val(effective_date)
      $('input[name="member[expiry_date]"]').val(expiry_date)

      $('#effectiveDate').calendar({
        type: 'date',
        startMode: 'day',
        minDate: new Date(effective_date),
        maxDate: new Date(expiry_date),
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
            return year + '-' + month + '-' + day;
          }
        }
      })

      effective_date = new Date(effective_date)

      $('#expiryDate').calendar({
        type: 'date',
        startMode: 'day',
        startCalendar: $('#effectiveDate'),
        minDate: new Date(effective_date.getFullYear(), effective_date.getMonth(), effective_date.getDate() +  1),
        maxDate: new Date(expiry_date),
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
            return year + '-' + month + '-' + day;
          }
        }
      })

      expiry_date =  new Date(expiry_date)

      $('#dateHired').calendar({
        type: 'date',
        startMode: 'year',
        maxDate: new Date(expiry_date.getFullYear(), expiry_date.getMonth(), expiry_date.getDate()),
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
            return year + '-' + month + '-' + day;
          }
        }
      })
    }
  });

  $.fn.form.settings.rules.checkEmpNumber = function(param) {
    return employee_number_array.indexOf(param) == -1 ? true : false;
  };

  $.fn.form.settings.rules.philhealthChecker = function(param) {
    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmaked_value.length == "12") {
      return true
    } else {
      return false
    }
  };

  $.fn.form.settings.rules.tinChecker = function(param) {
    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmaked_value.length == "12") {
      return true
    } else {
      return false
    }
  };

  const checkSeniorId = () => {
    $.ajax({
      url:`/${locale}/members/senior_id/all`,
      headers: {"x-csrf-token": csrf},
      type: 'get',
      datatype: 'json',
      success: function(response){
        let obj = JSON.parse(response)
        senior_arr.push(obj)
        for(var i = senior_arr[0].length - 1; i >= 0; i--) {
          if(senior_arr[0][i] == $('#saved_senior_id').val()) {
            senior_arr[0].splice(i, 1);
          }
        }
      }
    });
  };
  checkSeniorId();

  const checkPwdId = () => {
    $.ajax({
      url:`/${locale}/members/pwd_id/all`,
      headers: {"x-csrf-token": csrf},
      type: 'get',
      datatype: 'json',
      success: function(response){
        let obj = JSON.parse(response)
        pwd_arr.push(obj)
        for(var i = pwd_arr[0].length - 1; i >= 0; i--) {
          if(pwd_arr[0][i] == $('#saved_pdw_id').val()) {
            pwd_arr[0].splice(i, 1);
          }
        }
      }
    });
  };

  checkPwdId();

  $.fn.form.settings.rules.checkIfSenior = function(param) {
    let birthdate = $('input[id="member_birthdate"]').val()
    birthdate = birthdate.split("-", 1)
    let today_date = new Date()
    let total_age = today_date.getFullYear() - parseInt(birthdate[0])
    if (birthdate == ""){
      return false
    }
    else if (total_age < 60){
      return false
    }
    else{
      return true
    }
  };

  $.fn.form.settings.rules.checkSeniorID = function(param) {
    // let copy = $('input[id="member_senior_id"]').val();
    // let position = $.inArray(copy, senior_arr[0]);
    // if ( ~position ) senior_arr[0].splice(position, 1);

    if(senior_arr[0].includes(param)){
      return false
    } else{
      return true
    }
  };

  $.fn.form.settings.rules.checkPWDID = function(param) {
    // let copy = $('input[id="member_pwd_id"]').val();
    // let position = $.inArray(copy, pwd_arr[0]);
    // if ( ~position ) pwd_arr[0].splice(position, 1);

    if(pwd_arr[0].includes(param)){
      return false
    } else{
      return true
    }
  };

  $('.ui.form')
  .form({
    inline: true,
    on: 'blur',
    fields: {
      'member[first_name]': {
        identifier: 'member[first_name]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter First Name'
        },
        {
          type   : 'maxLength[150]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/^[A-Za-z .,-]*$/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'member[middle_name]': {
        identifier  : 'member[middle_name]',
        optional    : 'true',
        rules: [{
          type   : 'maxLength[150]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/^[A-Za-z .,-]*$/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'member[last_name]': {
        identifier: 'member[last_name]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Last Name'
        },
        {
          type   : 'maxLength[150]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/^[A-Za-z .,-]*$/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'member[suffix]': {
        identifier  : 'member[suffix]',
        optional    : 'true',
        rules: [{
          type   : 'maxLength[10]',
          prompt : 'Please enter at most {ruleValue} characters'
        },
        {
          type   : 'regExp[/^[A-Za-z .,-]*$/]',
          prompt : 'Only letters and characters (.,-) are allowed'
        }]
      },
      'member[birthdate]': {
        identifier: 'member[birthdate]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Birthdate'
        }]
      },
      'member[civil_status]': {
        identifier: 'member[civil_status]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Civil Status'
        }]
      },
      'member[principal_id]': {
        identifier: 'member[principal_id]',
        rules: [{
          type: 'empty',
          prompt: 'Please select Principal ID'
        }]
      },
      'member[principal_product_id]': {
        identifier: 'member[principal_product_id]',
        rules: [{
          type: 'empty',
          prompt: `Please select Principal's Product`
        }]
      },
      'member[relationship]': {
        identifier: 'member[relationship]',
        rules: [{
          type: 'empty',
          prompt: 'Please select Relationship'
        }]
      },
      'member[effectivity_date]': {
        identifier: 'member[effectivity_date]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Effective Date'
        }]
      },
      'member[expiry_date]': {
        identifier: 'member[expiry_date]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Expiry Date'
        }]
      },
      'member[employee_no]': {
        identifier: 'member[employee_no]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Employee Number'
        },
        {
          type: 'checkEmpNumber[param]',
          prompt: 'Employee No. is already in used'
        }]
      },
      // 'member[date_hired]': {
      //   identifier: 'member[date_hired]',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter Date Hired'
      //   }]
      // },
      // 'member[regularization_date]': {
      //   identifier: 'member[regularization_date]',
      //   rules: [{
      //     type: 'empty',
      //     prompt: 'Please enter Regularization Date'
      //   }]
      // },
      'member[senior_id]': {
        identifier: 'member[senior_id]',
        rules: [{
          type: 'checkIfSenior[param]',
          prompt: 'Member must be 60 years old and above.'
        },
        {
          type: 'checkSeniorID[param]',
          prompt: 'Senior ID already exists'
        }]
      },
      'member[pwd_id]': {
        identifier: 'member[pwd_id]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter PWD ID'
        },
        {
          type: 'checkPWDID[param]',
          prompt: 'PWD ID already exists'
        }]
      },
      'member[philhealth]': {
        identifier: 'member[philhealth]',
        optional: true,
        rules: [
        // {
        //   type: 'empty',
        //   prompt: 'Please enter PhilHealth Number'
        // },
        {
          type: 'philhealthChecker[param]',
          prompt: 'PhilHealth Number must be 12 digits'
        }]
      },
      'member[tin]': {
        identifier: 'member[tin]',
        optional: true,
        rules: [{
          type: 'tinChecker[param]',
          prompt: 'TIN must be 12 digits'
        }]
      }
    },
    onSuccess: function(event, fields) {
      /*let valid = validate_skipping_hierarchy()
      if (valid == false) {
        event.preventDefault()
        }
        */
    }
  });

  $('input[name="member[type]"]').change(function() {
    $('select[name="member[relationship]"]').dropdown('clear')
    $('select[name="member[relationship]"]').val('')
    $('select[name="member[relationship]"]').find('option').remove()
    $('select[name="member[principal_product_id]"]').dropdown('clear')
    $('select[name="member[principal_product_id]"]').val('')
    $('select[name="member[principal_product_id]"]').find('option').remove()
    $('select[name="member[principal_id]"]').dropdown('clear')
    $('div').removeClass('error')
    $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()

    let val = $(this).val()

    if (val == "Principal") {
      disableDependentFields()
      enablePrincipalFields()
      enableCivilStatus()
    }else if (val == "Dependent") {
      enableDependentFields()
      disablePrincipalFields()
    } else if (val == "Guardian") {
      disableDependentFields()
      disablePrincipalFields()
      enableGuardianFields()
      enableCivilStatus()
    }
  });

  $('select[name="member[principal_id]"]').change(function() {
    if ($(this).val() != "") {
      let selected_principal = account_principals.find(principal => principal.id == $(this).val())
      //load principal_products
      let principal_product = selected_principal.products
      $('#principal_product').html('')
      $('#principal_product').dropdown('clear')
      $('#principal_product').append('<option value=""></option>')
      for (let i=0;i<principal_product.length;i++){
        $('#principal_product').append(`<option value="${principal_product[i].id}" waiver="${principal_product[i].hierarchy_waiver}" id="${i+1}">${principal_product[i].code} - ${principal_product[i].hierarchy_waiver}</option>`)
      }

      let spouse_count = dependent_count(selected_principal, "Spouse")
      let parent_count = dependent_count(selected_principal, "Parent")
      let sibling_count = dependent_count(selected_principal, "Sibling")
      let child_count = dependent_count(selected_principal, "Child")
      let current_tier = 0
      $('#member_gender_Male').attr('disabled', false)
      $('#member_gender_Female').attr('disabled', false)
      $('#skipContainer').html('')

      setTimeout(function () {
        $('#principal_product').dropdown('set selected', $('#memberPrincipalProductID').val())
      }, 1)

      /* if (selected_principal.civil_status == "Single") {
        hierarchy = single_dependent_hierarchy
      } else if (selected_principal.civil_status == "Single Parent") {
        hierarchy = single_parent_dependent_hierarchy
      } else if (selected_principal.civil_status == "Married") {
        hierarchy = married_dependent_hierarchy
      }

      for (let relationship of hierarchy) {
        if (relationship == "Spouse") {
          if (spouse_count > 0 ) {
            current_tier++
          }
        }
        if (relationship == "Parent") {
          if (parent_count > 0 ) {
            current_tier++
          }
        }
        if (relationship == "Child") {
          if (child_count > 0 ) {
            current_tier++
          }
        }
        if (relationship == "Sibling") {
          if (sibling_count > 0 ) {
            current_tier++
          }
        }
      }

      $('#relationship').html('')
      $('#relationship').dropdown('clear')
      $('#relationship').append('<option value="">Select Relationship</option>')
      for (var i = 0; i < hierarchy.length; i++) {
        if (i >= current_tier) {
          $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
        }
        else {
          if (hierarchy[i] == "Parent" && hierarchy.indexOf("Parent") == current_tier-1 && parent_count < 2) {
            $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
          }
          else if (hierarchy[i] == "Child" && hierarchy.indexOf("Child") == current_tier-1) {
            $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
          }
          else if (hierarchy[i] == "Sibling" && hierarchy.indexOf("Sibling") == current_tier-1) {
            $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}" >${hierarchy[i]}</option>`)
          }
          else {
            $('#relationship').append(`<option disabled="true" value="${hierarchy[i]}">${hierarchy[i]}</option>`)
          }
        }
      }
      $('#relationship').dropdown('refresh') */

      effective_date = selected_principal.effectivity_date
      expiry_date = selected_principal.expiry_date

      $('input[name="member[effectivity_date]"]').val(effective_date)
      $('input[name="member[expiry_date]"]').val(expiry_date)

      $('#effectiveDate').calendar({
        type: 'date',
        startMode: 'day',
        minDate: new Date(effective_date),
        maxDate: new Date(expiry_date),
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
            return year + '-' + month + '-' + day;
          }
        }
      })

      effective_date = new Date(effective_date)

      $('#expiryDate').calendar({
        type: 'date',
        startMode: 'day',
        startCalendar: $('#effectiveDate'),
        minDate: new Date(effective_date.getFullYear(), effective_date.getMonth(), effective_date.getDate() +  1),
        maxDate: new Date(expiry_date),
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
            return year + '-' + month + '-' + day;
          }
        }
      })

      expiry_date =  new Date(expiry_date)

      $('#dateHired').calendar({
        type: 'date',
        startMode: 'year',
        maxDate: new Date(expiry_date.getFullYear(), expiry_date.getMonth(), expiry_date.getDate()),
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
            return year + '-' + month + '-' + day;
          }
        }
      })

      setTimeout(function () {
        $('#relationship').dropdown('set selected', $('#memberRelationship').val())
        if (selected_principal.id == principal_id && $('#principal_product').find(':selected').attr('waiver') == 'Skip Allowed'){
          let relationship = $('select#relationship option:selected').attr('id')
          for (let a=1;a<relationship;a++){
            let val = $('select#relationship').find(`#${a}`).val()
            $('select#relationship').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).addClass('disabled')
          }
          for (let a=1;a<$('select#principal_product option').length;a++) {
            if (a-1 != relationship){
              let val = $('select#principal_product').find(`#${a}`).val()
              $('select#principal_product').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).addClass('disabled')
            }
          }
        }
      }, 1)

      $('#hierarchy_data tr').remove()

      for (let dependent of selected_principal.dependents) {
        if (dependent.id == member_id){
          for (let data of dependent.skipped_dependents){
            let name = ''
            if (data.suffix == null && data.middle_name != null) {
              name = data.first_name + ' ' + data.middle_name + ' ' + data.last_name
            }
            if (data.suffix != null && data.middle_name == null) {
              name = data.first_name + ' ' + data.last_name + ' ' + data.suffix
            }
            if (data.middle_name == null && data.suffix == null){
              name = data.first_name + ' ' + data.last_name
            }
            if (data.middle_name != null && data.suffix != null){
              name = data.first_name + ' ' + data.middle_name + ' ' + data.last_name + ' ' + data.suffix
            }
            let relationship_data = data.relationship
            let gender = data.gender
            let birthdate = data.birthdate
            let reason = data.reason
            let supporting_file = data.supporting_document
            let skipped_id = data.id
            let first_name = data.first_name
            let middle_name = data.middle_name
            if (middle_name == null){
              middle_name = ''
            }
            let last_name = data.last_name
            let suffix = data.suffix
            if (suffix == null){
              suffix = ''
            }

            let data_row = `<tr>
            <td id="table_relationship" class="relationship" skip_id="${skipped_id}" relationship="${relationship_data}" first_name="${first_name}" middle_name="${middle_name}" last_name="${last_name}" suffix="${suffix}" gender="${gender}" birthdate="${birthdate}" reason="${reason}" file_name="${supporting_file}" >${relationship_data}</td>
            <td id="table_name">${name}</td>
            <td id="table_gender">${gender}</td>
            <td id="table_birthdate">${birthdate}</td>
            <td id="table_reason">${reason}</td>
            <td id="table_filename">${supporting_file}</td>
            <td>
            <div class="ui icon top right floated pointing dropdown skipping_action">
            <i class="primary large ellipsis vertical icon"></i>
            <div class="left menu transition hidden">
            <div class="item edit_skip_icon">
            edit
            </div>
            <div class="item remove_skip_icon">
            remove
            </div>
            </div>
            </div>
            </td>
            </tr>`
            $('#hierarchy_data').append(data_row)
            $('.skipping_action').dropdown()
            $('.remove_skip_icon').on('click', function(){
              let this_class = $(this)
              swal({
                title: 'Remove Skipping Hierarchy?',
                text: "Deleting this skipping hierarchy will permanently remove it from the system.",
                type: 'question',
                width: '700px',
                showCancelButton: true,
                cancelButtonText: '<i class="remove icon"></i> No, Keep Skipping hierarchy',
                confirmButtonText: '<i class="trash icon"></i> Yes, Remove Skipping hierarchy',
                cancelButtonClass: 'ui button',
                confirmButtonClass: 'ui blue button',
                width: '700px',
                buttonsStyling: false
              }).then(function () {

                let relationship = this_class.closest('td').closest('tr').find('.relationship').html()
                if (dependents_to_skip.indexOf(relationship) == -1) {
                  dependents_to_skip.push(relationship)
                }
                this_class.closest('td').closest('tr').remove();
                //$('#addDependentSkip').removeClass('disabled')
                let relationship_table = []
                $('#hierarchy_table tbody tr').each(function(){
                  relationship_table.push($(this).find('#table_relationship').html())
                })
                if (relationship_table.length == 0){
                  let relationship_dropdown = $('select#relationship option:selected').attr('id')
                  for (let a=1;a<relationship_dropdown;a++){
                    let val = $('select#relationship').find(`#${a}`).val()
                    $('select#relationship').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).removeClass('disabled')
                  }
                  for (let a=1;a<$('select#principal_product option').length;a++) {
                    if (a-1 != relationship){
                      let val = $('select#principal_product').find(`#${a}`).val()
                      $('select#principal_product').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).removeClass('disabled')
                    }
                  }
                }
                if (dependents_to_skip.length != 0){
                  $('#addDependentSkip').removeClass('disabled')
                }
              })
            })

          $('.edit_skip_icon').on('click', function(){
            let this_class = $(this).closest('tr')
            let relationship_table = []
            $('#hierarchy_table tbody tr').each(function() {
              relationship_table.push($(this).find('#table_relationship').html())
            })
            let parent_count = 0
            let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
            for (let dependent of selected_principal.dependents) {
              if (dependent.relationship == "Parent" && dependent.status != "Disapprove"){
                parent_count += 1
              }
            }

            for (let i=0;i<relationship_table.length;i++) {
              if (relationship_table[i] == "Parent") {
                if (parent_count != 1) {
                  parent_count = parent_count + 1
                }
                else {
                  let in_array = $.inArray(relationship_table[i], dependents_to_skip)
                  if (in_array != '-1') {
                    dependents_to_skip.splice(in_array, 1);
                  }
                }
              }
              else {
                let in_array = $.inArray(relationship_table[i], dependents_to_skip)
                if (in_array != '-1') {
                  dependents_to_skip.splice(in_array, 1);
                }
              }
            }
            let relationship = $(this).closest('td').closest('tr').find('.relationship').html()
            if (dependents_to_skip.indexOf(relationship) == -1) {
              dependents_to_skip.push(relationship)
            }
            $('.skip_relationship').empty()

            let relationship_options = ``
            for (let relationship of dependents_to_skip) {
              relationship_options += `<option value="${relationship}">${relationship}</option>`
            }
            $('.skip_relationship').append(relationship_options);
            $('.edit_skipping_hierarchy').modal('show')
            $('input[name="edit_member_first_name"]').val($(this).closest('tr').find('#table_relationship').attr('first_name'))
            $('input[name="edit_member_middle_name"]').val($(this).closest('tr').find('#table_relationship').attr('middle_name'))
            $('input[name="edit_member_last_name"]').val($(this).closest('tr').find('#table_relationship').attr('last_name'))
            $('input[name="edit_member_suffix"]').val($(this).closest('tr').find('#table_relationship').attr('suffix'))
            $('input[name="edit_member_birthdate"]').val($(this).closest('tr').find('#table_relationship').attr('birthdate'))
            $('input[name="edit_member_supporting_document"]').val($(this).closest('tr').find('#table_relationship').attr('file_name'))
            $('input[name="edit_member_supporting_document"]').closest('.field').addClass('disabled')
            setTimeout(function () {
              $('.skip_dropdown').dropdown('set selected', relationship)
            }, 1)
            $('.skip_reason').dropdown('set selected', $(this).closest('tr').find('#table_relationship').attr('reason'))
            if ($(this).closest('tr').find('#table_relationship').attr('gender') == "Male"){
              $('input[name="edit_member_gender"][value="Male"]').prop('checked', true);
            }
            else{
              $('input[name="edit_member_gender"][value="Female"]').prop('checked', true);
            }
            let count_parent = 0
            let count_spouse = 0
            let selected_gender = $(this).closest('tr').find('#table_relationship').attr('gender')
            $('#hierarchy_table tbody tr').each(function() {
              if ($(this).find('#table_relationship').html() == 'Parent') {
                count_parent += 1
              }
              if ($(this).find('#table_relationship').html() == 'Spouse'){
                count_spouse += 1
              }
            })
            if (count_parent >= 2 && relationship == 'Parent'){
              $('#edit_skipped_gender_Male').attr('disabled', true)
              $('#edit_skipped_gender_Female').attr('disabled', true)
            }
            if (count_parent <= 1 && relationship == 'Parent'){
              $('#edit_skipped_gender_Male').attr('disabled', false)
              $('#edit_skipped_gender_Female').attr('disabled', false)
            }
            if (count_spouse >= 1 && relationship == 'Spouse'){
              if ($(this).closest('tr').find('#table_relationship').attr('gender') == "Male"){
                $('#edit_skipped_gender_Female').attr('disabled', true)
              }
              else{
                $('#edit_skipped_gender_Male').attr('disabled', true)
              }
            }
            if (relationship == 'Parent'){
              let principal_birthdate = new Date(selected_principal.birthdate)
              $('.skip-calendar').calendar({
                type: 'date',
                startMode: 'year',
                maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
                    return year + '-' + month + '-' + day;
                  }
                }
              })
            }
            if (relationship == 'Spouse'){
              $('.skip-calendar').calendar({
                type: 'date',
                startMode: 'year',
                maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
                    return year + '-' + month + '-' + day;
                  }
                }
              })
            }
            if (relationship == 'Child' || relationship == 'Sibling'){
              let principal_birthdate = new Date(selected_principal.birthdate)
              $('.skip-calendar').calendar({
                type: 'date',
                startMode: 'year',
                minDate: new Date(principal_birthdate.getFullYear() + 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
                maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
                    return year + '-' + month + '-' + day;
                  }
                }
              })
            }
            $('#edit-skip-item').unbind("click").click(function(){
              let edit_valid_text = edit_validate_text_inputs()
              let edit_valid_select = edit_validate_select_inputs()
              let edit_valid_file = edit_validate_file_inputs()
              let relationship = ''
              let name = ''
              let first_name = ''
              let middle_name = ''
              let last_name = ''
              let suffix = ''
              let gender = ''
              let birthdate = ''
              let reason = ''
              let supporting_file = ''
              relationship = $('.edit_select-validate-required').find('.skip_relationship option:selected').val()
              name = $('input[name="edit_member_first_name"]').val() + ' ' + $('input[name="edit_member_middle_name"]').val() + ' ' + $('input[name="edit_member_last_name"]').val() + ' ' + $('input[name="edit_member_suffix"]').val()
              first_name = $('input[name="edit_member_first_name"]').val()
              middle_name = $('input[name="edit_member_middle_name"]').val()
              last_name = $('input[name="edit_member_last_name"]').val()
              suffix = $('input[name="edit_member_suffix"]').val()
              gender = $('input[name="edit_member_gender"]:checked').val()
              birthdate = $('input[name="edit_member_birthdate"]').val()
              reason = $('.edit_select-validate-required').find('.skip_reason').find('select').val()
              if (edit_valid_text == true && edit_valid_select == true && edit_valid_file == true) {
                if ($('.edit_file-validate-required.disabled').find('input').attr('type') == "text"){
                  this_class.find('#table_relationship').attr('relationship', relationship)
                  this_class.find('#table_relationship').attr('first_name', first_name)
                  this_class.find('#table_relationship').attr('middle_name', middle_name)
                  this_class.find('#table_relationship').attr('last_name', last_name)
                  this_class.find('#table_relationship').attr('suffix', suffix)
                  this_class.find('#table_relationship').attr('gender', gender)
                  this_class.find('#table_relationship').attr('birthdate', birthdate)
                  this_class.find('#table_relationship').attr('reason', reason)

                  this_class.find('#table_relationship').text(relationship)
                  this_class.find('#table_name').text(name)
                  this_class.find('#table_gender').text(gender)
                  this_class.find('#table_birthdate').text(birthdate)
                  this_class.find('#table_reason').text(reason)
                }
                else{
                  supporting_file = $('input[name="edit_member_supporting_document"]').prop('files')[0];
                  let reader = new FileReader();
                  let base64 = ''
                  if (supporting_file != "") {
                    reader.readAsBinaryString(supporting_file);
                    reader.onload = function(readerEvt) {
                      let binaryString = readerEvt.target.result;
                      base64 = btoa(binaryString)
                      let data = ``
                      this_class.find('#table_relationship').attr('relationship', relationship)
                      this_class.find('#table_relationship').attr('first_name', first_name)
                      this_class.find('#table_relationship').attr('middle_name', middle_name)
                      this_class.find('#table_relationship').attr('last_name', last_name)
                      this_class.find('#table_relationship').attr('suffix', suffix)
                      this_class.find('#table_relationship').attr('gender', gender)
                      this_class.find('#table_relationship').attr('birthdate', birthdate)
                      this_class.find('#table_relationship').attr('reason', reason)
                      this_class.find('#table_relationship').attr('file_name', supporting_file.name)
                      this_class.find('#table_relationship').attr('extension', supporting_file.name.split('.').pop())
                      this_class.find('#table_relationship').attr('base64', base64)

                      this_class.find('#table_relationship').text(relationship)
                      this_class.find('#table_name').text(name)
                      this_class.find('#table_gender').text(gender)
                      this_class.find('#table_birthdate').text(birthdate)
                      this_class.find('#table_reason').text(reason)
                      this_class.find('#table_filename').text(supporting_file.name)
                    }
                  }
                }
                $('.edit_skipping_hierarchy').modal('hide')
              }
            })

            $('.edit_select-validate-required').find('.skip_relationship').change(function() {
              let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
              if ($(this).val() == "Spouse") {
                if (selected_principal.gender == "Male") {
                  $('#edit_skipped_gender_Female').attr('disabled', false)
                  $('#edit_skipped_gender_Female').prop('checked', true)
                  $('#edit_skipped_gender_Male').attr('disabled', true)
                } else {
                  $('#edit_skipped_gender_Male').attr('disabled', false)
                  $('#edit_skipped_gender_Male').prop('checked', true)
                  $('#edit_skipped_gender_Female').attr('disabled', true)
                }
                $('.skip-calendar').calendar({
                  type: 'date',
                  startMode: 'year',
                  maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
              }

              if ($(this).val() == 'Parent' && relationship != 'Parent' && count_parent == 1) {
                let parent_gender = ''
                $('#hierarchy_table tbody tr').each(function() {
                  if ($(this).find('#table_relationship').html() == 'Parent') {
                    parent_gender = $(this).find('#table_gender').html()
                    if (parent_gender == "Male") {
                      $('#edit_skipped_gender_Female').attr('disabled', false)
                      $('#edit_skipped_gender_Female').prop('checked', true)
                      $('#edit_skipped_gender_Male').attr('disabled', true)
                    } else {
                      $('#edit_skipped_gender_Male').attr('disabled', false)
                      $('#edit_skipped_gender_Male').prop('checked', true)
                      $('#edit_skipped_gender_Female').attr('disabled', true)
                    }
                  }
                })

                for (let dependent of selected_principal.dependents){
                  if (dependent.relationship == "Parent" && dependent.status != "Disapprove"){
                    if (dependent.gender == "Male"){
                      $('#edit_skipped_gender_Female').prop('checked', true)
                      $('#edit_skipped_gender_Male').attr('disabled', true)
                    }else
                      {
                        $('#edit_skipped_gender_Male').prop('checked', true)
                        $('#edit_skipped_gender_Female').attr('disabled', true)
                      }
                  }
                }
                let principal_birthdate = new Date(selected_principal.birthdate)
                $('.skip-calendar').calendar({
                  type: 'date',
                  startMode: 'year',
                  maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
              }
              if ($(this).val() == 'Parent' && relationship == 'Parent' && count_parent == 1) {
                if (selected_gender == "Male") {
                  $('#edit_skipped_gender_Male').prop('checked', true)
                  $('#edit_skipped_gender_Male').attr('disabled', false)
                  $('#edit_skipped_gender_Female').attr('disabled', false)
                }
                else{
                  $('#edit_skipped_gender_Female').prop('checked', true)
                  $('#edit_skipped_gender_Male').attr('disabled', false)
                  $('#edit_skipped_gender_Female').attr('disabled', false)
                }
                let principal_birthdate = new Date(selected_principal.birthdate)
                $('.skip-calendar').calendar({
                  type: 'date',
                  startMode: 'year',
                  maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
              }

              if ($(this).val() == 'Parent' && relationship == 'Parent' && count_parent == 2) {
                if (selected_gender == "Male") {
                  $('#edit_skipped_gender_Male').prop('checked', true)
                  $('#edit_skipped_gender_Male').attr('disabled', true)
                  $('#edit_skipped_gender_Female').attr('disabled', true)
                }
                else{
                  $('#edit_skipped_gender_Female').prop('checked', true)
                  $('#edit_skipped_gender_Female').attr('disabled', true)
                  $('#edit_skipped_gender_Male').attr('disabled', true)
                }
                let principal_birthdate = new Date(selected_principal.birthdate)
                $('.skip-calendar').calendar({
                  type: 'date',
                  startMode: 'year',
                  maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
              }

              if ($(this).val() == 'Child' || $(this).val() == 'Sibling'){
                $('#edit_skipped_gender_Male').attr('disabled', false)
                $('#edit_skipped_gender_Female').attr('disabled', false)
                $('#edit_skipped_gender_Male').prop('checked', true)
                let principal_birthdate = new Date(selected_principal.birthdate)
                $('.skip-calendar').calendar({
                  type: 'date',
                  startMode: 'year',
                  minDate: new Date(principal_birthdate.getFullYear() + 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
                  maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
              }
            });
          })

          $('#remove_file').click(function(){
            $('input[name="edit_member_supporting_document"]').closest('.field').removeClass('disabled')
            $('input[name="edit_member_supporting_document"]').attr('type', 'file')
            $('input[name="edit_member_supporting_document"]').attr('accept', '.pdf,.xls,.jpg,.csv,.doc,.docx,.xlsx,.png')
            $(this).attr('style', 'display: none;')
          })

          $('.edit_skipping_hierarchy').modal({
            closable  : false,
            onHide : function() {
              $('input[name="edit_member_first_name"]').val('')
              $('input[name="edit_member_middle_name"]').val('')
              $('input[name="edit_member_last_name"]').val('')
              $('input[name="edit_member_suffix"]').val('')
              $('input[name="edit_member_gender"][value="Male"]').prop('checked', true);
              $('input[name="edit_member_birthdate"]').val('')
              $('input[name="member_reason"]').val('')
              $('input[name="edit_member_supporting_document"]').attr('type', 'text')
              $('input[name="edit_member_supporting_document"]').attr('accept', '')
              $('input[name="edit_member_supporting_document"]').closest('.field').addClass('disabled')
              $('#edit_skipped_gender_Male').attr('disabled', false)
              $('#edit_skipped_gender_Female').attr('disabled', false)
              $('#remove_file').attr('style', 'height: 40px; margin-top: 20px; !important')
              $('.skip_relationship').val('')
              $('.select-validate-required').find('.text').html('');
            }
          })
          }
        }
      }
    }
  });

  $('select[name="member[principal_product_id]"]').change(function(){
if ($(this).val() != null) {
      let waiver = $('#principal_product').find(':selected').attr('waiver')
      if (waiver != 'Skip Allowed'){
        $('#divSkip').addClass('hide')
        $('#addDependentSkip').addClass('disabled')
      }
      let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
      let spouse_count = dependent_count(selected_principal, "Spouse")
      let parent_count = dependent_count(selected_principal, "Parent")
      let sibling_count = dependent_count(selected_principal, "Sibling")
      let child_count = dependent_count(selected_principal, "Child")
      let current_tier = 0

      if (selected_principal.civil_status == "Single") {
        hierarchy = single_dependent_hierarchy
      } else if (selected_principal.civil_status == "Single Parent") {
        hierarchy = single_parent_dependent_hierarchy
      } else if (selected_principal.civil_status == "Married") {
        hierarchy = married_dependent_hierarchy
      }

      for (let relationship of hierarchy) {
        if (relationship == "Spouse") {
          if (spouse_count > 0 ) {
            current_tier++
          }
        }
        if (relationship == "Parent") {
          if (parent_count > 0 ) {
            current_tier++
          }
        }
        if (relationship == "Child") {
          if (child_count > 0 ) {
            current_tier++
          }
        }
        if (relationship == "Sibling") {
          if (sibling_count > 0 ) {
            current_tier++
          }
        }
      }

      $('#relationship').html('')
      $('#relationship').dropdown('clear')
      $('#relationship').append('<option value="">Select Relationship</option>')
      for (var i = 0; i < hierarchy.length; i++) {
        if (i >= current_tier) {
          $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
        }
        else {
          if (hierarchy[i] == "Parent" && hierarchy.indexOf("Parent") == current_tier-1 && parent_count < 2) {
            $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
            }
          else if (hierarchy[i] == "Child" && hierarchy.indexOf("Child") == current_tier-1) {
            $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}">${hierarchy[i]}</option>`)
          }
          else if (hierarchy[i] == "Sibling" && hierarchy.indexOf("Sibling") == current_tier-1) {
            $('#relationship').append(`<option value="${hierarchy[i]}" id="${i+1}" >${hierarchy[i]}</option>`)
          }
          else {
          $('#relationship').append(`<option disabled="true" value="${hierarchy[i]}">${hierarchy[i]}</option>`)
          }
        }
      }
      $('#relationship').dropdown('refresh')
    }
  })

  $('select[name="member[relationship]"]').change(function() {
    if ($(this).val() != null) {
      let relationship = $(this).val()
      let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
      let principal_birthdate = new Date(selected_principal.birthdate)
      let principal_children = []
      let principal_parents = []
      let principal_siblings = []

      $('#member_gender_Male').attr('disabled', false)
      $('#member_gender_Female').attr('disabled', false)

      $.map(selected_principal.dependents, function(dependent, index) {
        if (dependent.relationship == "Child" && dependent.id != member_id) {
          principal_children.push(dependent)
        } else if (dependent.relationship == "Parent" && dependent.id != member_id) {
          principal_parents.push(dependent)
        } else if (dependent.relationship == "Sibling" && dependent.id != member_id) {
          principal_siblings.push(dependent)
        }
        else if (dependent.relationship == "Parent" && dependent.id != member_id) {
          principal_parents.push(dependent)
        }
      })

      // $('#skipContainer').html('')
      let waiver = $('#principal_product').find(':selected').attr('waiver')
      if (waiver == 'Skip Allowed' && check_if_skipping(selected_principal, relationship) == false) {
        $('#divSkip').removeClass('hide')
        $('#addDependentSkip').removeClass('disabled')
        $('#hierarchy_table').removeClass('hide')

        let relationship_table = []
        $('#hierarchy_table tbody tr').each(function() {
          relationship_table.push($(this).find('#table_relationship').html())
        })

        for (let dependent of selected_principal.dependents) {
          if (dependent.id == member_id) {
            if (dependent.skipped_dependents.length > 0 && relationship_table.length == dependent.skipped_dependents.length){
              $('#addDependentSkip').addClass('disabled')
            }
          }
        }

        setTimeout(function () {
          let relationship_table = []
          $('#hierarchy_table tbody tr').each(function() {
            relationship_table.push($(this).find('#table_relationship').html())
          })

          let parent_count = 0
          for (let dependent of selected_principal.dependents) {
            if (dependent.id != member_id && dependent.relationship == "Parent" && dependent.status != "Disapprove") {
              parent_count += 1
            }
          }

          for (let i=0;i<relationship_table.length;i++) {
            if (relationship_table[i] == "Parent") {
              if (parent_count != 1) {
                parent_count = parent_count + 1
              }
              else {
                let in_array = $.inArray(relationship_table[i], dependents_to_skip)
                if (in_array != '-1') {
                  dependents_to_skip.splice(in_array, 1);
                }
              }
            }
            else{
              let in_array = $.inArray(relationship_table[i], dependents_to_skip)
              if (in_array != '-1') {
                dependents_to_skip.splice(in_array, 1);
              }
            }
          }
          if (dependents_to_skip.length != 0) {
          }
        }, 1)
      } else {
        $('#divSkip').addClass('hide')
        $('#addDependentSkip').addClass('disabled')
      }
      $('select[name="member[civil_status]"]').closest('.dropdown').closest('.field').removeClass('error')
      $('select[name="member[civil_status]"]').closest('.dropdown').closest('.field').find('.prompt').remove()

      if (relationship == "Child" || relationship == "Sibling") {
        $('#member_civil_status').dropdown('set selected', 'Single')
        disableCivilStatus()

        let last_minor = ""
        if (relationship == "Child") {
          last_minor = principal_children[0]
        } else if (relationship == "Sibling") {
          last_minor = principal_siblings[0]
        }

        if (last_minor == null) {
          $('#birthdate').calendar({
            type: 'date',
            startMode: 'year',
            minDate: new Date(principal_birthdate.getFullYear() + 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
            maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
                return year + '-' + month + '-' + day;
              }
            }
          })
        } else {
          let last_minor_birthdate = new Date(last_minor.birthdate)
          last_minor_birthdate.setDate(last_minor_birthdate.getDate() + 1)
          $('#birthdate').calendar({
            type: 'date',
            startMode: 'year',
            minDate: new Date(last_minor_birthdate.getFullYear(), last_minor_birthdate.getMonth(), last_minor_birthdate.getDate()),
            maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
                return year + '-' + month + '-' + day;
              }
            }
          })
        }
      } else if (relationship == "Parent") {
        if (principal_parents.length != 0) {
          if (principal_parents[0].gender == "Male") {
            $('#member_gender_Female').prop('checked', true)
            $('#member_gender_Male').attr('disabled', true)
          }
          else {
            $('#member_gender_Male').prop('checked', true)
            $('#member_gender_Female').attr('disabled', true)
          }
        }

        // $('#member_civil_status').dropdown('set selected', 'Married')
        // disableCivilStatus()

        $('#birthdate').calendar({
          type: 'date',
          startMode: 'year',
          maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
              return year + '-' + month + '-' + day;
            }
          }
        })
      } else if (relationship == "Spouse") {
        if (selected_principal.gender == "Male") {
          $('#member_gender_Female').prop('checked', true)
          $('#member_gender_Male').attr('disabled', true)
        }
        else {
          $('#member_gender_Male').prop('checked', true)
          $('#member_gender_Female').attr('disabled', true)
        }

        $('#member_civil_status').dropdown('set selected', 'Married')
        disableCivilStatus()

        $('#birthdate').calendar({
          type: 'date',
          startMode: 'year',
          maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
              return year + '-' + month + '-' + day;
            }
          }
        })
      }
      else {
        $('#member_civil_status').dropdown('set selected', 'Single')
        disableCivilStatus()

        $('#birthdate').calendar({
          type: 'date',
          startMode: 'year',
          minDate: new Date(principal_birthdate.getFullYear() + 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
          maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
              return year + '-' + month + '-' + day;
            }
          }
        })
      }
    }
  });

  if ($('input[name="member[type]"]:checked').val() == "Principal") {
    disableDependentFields()
    enablePrincipalFields()
  }
  else if ($('input[name="member[type]"]:checked').val() == "Dependent") {
    enableDependentFields()
    disablePrincipalFields()
  }
  else if ($('input[name="member[type]"]:checked').val() == "Guardian") {
    disableDependentFields()
    disablePrincipalFields()
    enableGuardianFields()
  }

  $('input[name="member[is_regular]"]').change(function() {
    let val = $(this).val()
    if (val == "true") {
      $('input[name="member[regularization_date]"]').val('')
      $('input[name="member[regularization_date]"]').prop('disabled', true)
    }
    else {
      $('input[name="member[regularization_date]"]').prop('disabled', false)
    }
  });

  if ($('input[name="member[is_regular]"]:checked').val() == "true") {
    $('input[name="member[regularization_date]"]').val('')
    $('input[name="member[regularization_date]"]').prop('disabled', true)
  }

  if ($('input[name="member[senior]"]:checked').val() == "true"){
    $('input[name="member[senior_id]"]').prop('disabled', false)
    $('div[id="upload_senior"]').removeClass("disabled")
  }
  else {
    $('input[name="member[senior_id]"]').prop('disabled', true)
    $('div[id="upload_senior"]').addClass("disabled")
    $('div[id="div_senior_id"]').find('.prompt').remove()
    $('div[id="div_senior_id"]').removeClass('error')
  }

  $('input[name="member[senior]"]').on('change', function() {
    if ($('input[name="member[senior]"]:checked').val() == "true"){
      $('input[name="member[senior_id]"]').prop('disabled', false)
      $('div[id="upload_senior"]').removeClass("disabled")
    }
    else {
      $('input[name="member[senior_id]"]').val('')
      // $('input[name="member[senior_id_copy]"]').val('')
      $('input[name="member[senior_id]"]').prop('disabled', true)
      $('div[id="upload_senior"]').addClass("disabled")
      $('div[id="div_senior_id"]').find('.prompt').remove()
      $('div[id="div_senior_id"]').removeClass('error')
      $('#text_senior').val('')
      $('#file_senior').val('')
    }
  });

  if ($('input[name="member[pwd]"]:checked').val() == "true"){
    $('input[name="member[pwd_id]"]').prop('disabled', false)
    $('div[id="upload_pwd"]').removeClass("disabled")
  }
  else {
    $('input[name="member[pwd_id]"]').prop('disabled', true)
    $('div[id="upload_pwd"]').addClass("disabled")
    $('div[id="div_pwd_id"]').find('.prompt').remove()
    $('div[id="div_pwd_id"]').removeClass('error')
  }

  $('input[name="member[pwd]"]').on('change', function() {
    if ($('input[name="member[pwd]"]:checked').val() == "true"){
      $('input[name="member[pwd_id]"]').prop('disabled', false)
      $('div[id="upload_pwd"]').removeClass("disabled")
    }
    else {
      $('input[name="member[pwd_id]"]').val('')
      // $('input[name="member[pwd_id_copy]"]').val('')
      $('input[name="member[pwd_id]"]').prop('disabled', true)
      $('div[id="upload_pwd"]').addClass("disabled")
      $('div[id="div_pwd_id"]').find('.prompt').remove()
      $('div[id="div_pwd_id"]').removeClass('error')
      $('#text_pwd').val('')
      $('#file_pwd').val('')
    }
  });

  $('input[name="member[philhealth_type]"]').change(function() {
    let val = $(this).val()
    if (val == "Not Covered") {
      $('input[name="member[philhealth]"]').val('')
      $('input[name="member[philhealth]"]').prop('disabled', true)
    }
    else {
      $('input[name="member[philhealth]"]').prop('disabled', false)
    }
  });

  if ($('input[name="member[philhealth_type]"]:checked').val() == "Not Covered") {
    $('input[name="member[philhealth]"]').prop('disabled', true)
    $('input[name="member[philhealth]"]').val('')
  }
  else {
    $('input[name="member[philhealth]"]').prop('disabled', false)
  }

  $('#expiryDate').change(function() {
    let val = $('input[name="member[expiry_date]"]').val()
    let expiry_date =  new Date(val)

    $('#dateHired').calendar({
      type: 'date',
      startMode: 'year',
      maxDate: new Date(expiry_date.getFullYear(), expiry_date.getMonth(), expiry_date.getDate()),
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
          return year + '-' + month + '-' + day;
        }
      }
    })
  });

  $('#addDependentSkip').click(function() {
    $('.add_skipping_hierarchy').modal('show');
    let relationship_table = []
    $('#hierarchy_table tbody tr').each(function() {
      relationship_table.push($(this).find('#table_relationship').html())
    })
    let parent_count = 0
    let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
    for (let dependent of selected_principal.dependents) {
      if (dependent.id != member_id && dependent.relationship == "Parent" && dependent.status != "Disapprove"){
        parent_count += 1
      }
    }

    for (let i=0;i<relationship_table.length;i++) {
      if (relationship_table[i] == "Parent") {
        if (parent_count != 1) {
          parent_count = parent_count + 1
        }
        else {
          let in_array = $.inArray(relationship_table[i], dependents_to_skip)
          if (in_array != '-1') {
            dependents_to_skip.splice(in_array, 1);
          }
        }
      }
      else {
        let in_array = $.inArray(relationship_table[i], dependents_to_skip)
        if (in_array != '-1') {
          dependents_to_skip.splice(in_array, 1);
        }
      }
    }
    $('.skip_relationship').empty()

    let relationship_options = ``
    for (let relationship of dependents_to_skip) {
      relationship_options += `<option value="${relationship}">${relationship}</option>`
    }

    $('.skip_relationship').append(relationship_options);
    /*if ($('.skip_relationship').val() == "Spouse") {
      if (selected_principal.gender == "Male") {
        $('#skipped_gender_Female').prop('checked', true)
        $('#skipped_gender_Male').attr('disabled', true)
      } else {
        $('#skipped_gender_Male').prop('checked', true)
        $('#skipped_gender_Female').attr('disabled', true)
      }
    }
    else{
      $('#skipped_gender_Male').removeAttr('disabled')
      $('#skipped_gender_Female').removeAttr('disabled')
      $('#skipped_gender_Male').prop('checked', true)
      }
    */

    $('.skip-calendar').calendar({
      type: 'date',
      startMode: 'year',
      maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
          return year + '-' + month + '-' + day;
        }
      }
    })

    $('.skip_dropdown').dropdown('restore defaults');
    $('#skip_reason').dropdown('restore defaults');

    //append_dependent_to_skip(skip_counter)
    //skip_counter++
  });

  $('body').on('click', '.remove-skip-item', function() {
    $(this).closest('.dependents-to-skip').remove()
  });

  $('body').on('keyup', '.validate-required', function() {
    $(this).find('.prompt').remove()
    $(this).removeClass('error')
  });

  $('body').on('change', '.select-validate-required', function() {
    $(this).find('.prompt').remove()
    $(this).removeClass('error')
  });

  $('body').on('change', '.file-validate-required', function() {
    $(this).find('.prompt').remove()
    $(this).removeClass('error')
  });

  $('body').on('keyup', '.edit_validate-required', function() {
    $(this).find('.prompt').remove()
    $(this).removeClass('error')
  });

  $('body').on('change', '.edit_select-validate-required', function() {
    $(this).find('.prompt').remove()
    $(this).removeClass('error')
  });

  $('body').on('change', '.edit_file-validate-required', function() {
    $(this).find('.prompt').remove()
    $(this).removeClass('error')
  });

  $('.add-skip-item').on('click', function(){
    let valid_text = validate_text_inputs()
    let valid_select = validate_select_inputs()
    let valid_file = validate_file_inputs()
    let relationship = ''
    let name = ''
    let first_name = ''
    let middle_name = ''
    let last_name = ''
    let suffix = ''
    let gender = ''
    let birthdate = ''
    let reason = ''
    let supporting_file = ''
    relationship = $('select.skip_relationship option:selected').val()
    name = $('input[name="member_first_name"]').val() + ' ' + $('input[name="member_middle_name"]').val() + ' ' + $('input[name="member_last_name"]').val() + ' ' + $('input[name="member_suffix"]').val()
    first_name = $('input[name="member_first_name"]').val()
    middle_name = $('input[name="member_middle_name"]').val()
    last_name = $('input[name="member_last_name"]').val()
    suffix = $('input[name="member_suffix"]').val()
    gender = $('input[name="member_gender"]:checked').val()
    birthdate = $('input[name="member_birthdate"]').val()
    reason = $('.select-validate-required').find('.skip_reason').find('select').val()
    supporting_file = $('input[name="member_supporting_document"]').prop('files')[0];
    let reader = new FileReader();
    let base64 = ''
    if (supporting_file != "") {
      reader.readAsBinaryString(supporting_file);
      reader.onload = function(readerEvt) {
        let binaryString = readerEvt.target.result;
        base64 = btoa(binaryString)
        let data = ``
        if (valid_text == true && valid_select == true && valid_file == true) {
          data = `<tr>
          <td id="table_relationship" class="relationship" relationship="${relationship}" first_name="${first_name}" middle_name="${middle_name}" last_name="${last_name}" suffix="${suffix}" gender="${gender}" birthdate="${birthdate}" reason="${reason}" file_name="${supporting_file.name}" extension="${supporting_file.name.split('.').pop()}" base64="${base64}" >${relationship}</td>
          <td id="table_name">${name}</td>
          <td id="table_gender">${gender}</td>
          <td id="table_birthdate">${birthdate}</td>
          <td id="table_reason">${reason}</td>
          <td id="table_filename">${supporting_file.name}</td>
          <td>
          <div class="ui icon top right floated pointing dropdown skipping_action">
          <i class="primary large ellipsis vertical icon"></i>
          <div class="left menu transition hidden">
          <div class="item edit_skip_icon">
          edit
          </div>
          <div class="item remove_skip_icon">
          remove
          </div>
          </div>
          </div>
          </td>
          </tr>`
          $('#hierarchy_data').append(data)
          $('.skipping_action').dropdown()
          $('.add_skipping_hierarchy').modal('hide')
          $('.remove_skip_icon').on('click', function(){
            let this_class = $(this)
            swal({
              title: 'Remove Skipping Hierarchy?',
              text: "Deleting this skipping hierarchy will permanently remove it from the system.",
              type: 'question',
              width: '700px',
              showCancelButton: true,
              cancelButtonText: '<i class="remove icon"></i> No, Keep Skipping hierarchy',
              confirmButtonText: '<i class="trash icon"></i> Yes, Remove Skipping hierarchy',
              cancelButtonClass: 'ui button',
              confirmButtonClass: 'ui blue button',
              width: '700px',
              buttonsStyling: false
            }).then(function () {
              let relationship = this_class.closest('td').closest('tr').find('.relationship').html()
              if (dependents_to_skip.indexOf(relationship) == -1) {
                dependents_to_skip.push(relationship)
              }
              this_class.closest('td').closest('tr').remove();

              let relationship_table = []
              setTimeout(function () {
                $('#hierarchy_table tbody tr').each(function() {
                  relationship_table.push($(this).find('#table_relationship').html())
                })
                if (relationship_table.length == 0 && $('#principal_product').find(':selected').attr('waiver') == 'Skip Allowed') {
                  let relationship_dropdown = $('select#relationship option:selected').attr('id')
                  for (let a=1;a<relationship_dropdown;a++) {
                    let val = $('select#relationship').find(`#${a}`).val()
                    $('select#relationship').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).removeClass('disabled')
                  }
                  for (let a=1;a<$('select#principal_product option').length;a++) {
                    if (a-1 != relationship){
                      let val = $('select#principal_product').find(`#${a}`).val()
                      $('select#principal_product').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).removeClass('disabled')
                    }
                  }
                }
                if (dependents_to_skip.length != 0) {
                  $('#addDependentSkip').removeClass('disabled')
                }
              }, 1)
              /*for (let i=0;i<relationship_table.length;i++){
                console.log(relationship_table[i])
                let in_array = $.inArray(relationship_table[i], dependents_to_skip)
                if (in_array != '-1'){
                  dependents_to_skip.splice(in_array, 1);
                }
                }
              */
              /* if (dependents_to_skip.length != 0){
                $('#addDependentSkip').removeClass('disabled')
                }
              */
            })
          })
          $('.edit_skip_icon').on('click', function(){
            let this_class = $(this).closest('tr')
            let relationship_table = []
            $('#hierarchy_table tbody tr').each(function() {
              relationship_table.push($(this).find('#table_relationship').html())
            })
            let parent_count = 0
            let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
            for (let dependent of selected_principal.dependents) {
              if (dependent.id != member_id && dependent.relationship == "Parent" && dependent.status != "Disapprove"){
                parent_count += 1
              }
            }

            for (let i=0;i<relationship_table.length;i++) {
              if (relationship_table[i] == "Parent") {
                if (parent_count != 1) {
                  parent_count = parent_count + 1
                }
                else {
                  let in_array = $.inArray(relationship_table[i], dependents_to_skip)
                  if (in_array != '-1') {
                    dependents_to_skip.splice(in_array, 1);
                  }
                }
              }
              else {
                let in_array = $.inArray(relationship_table[i], dependents_to_skip)
                if (in_array != '-1') {
                  dependents_to_skip.splice(in_array, 1);
                }
              }
            }
            let relationship = $(this).closest('td').closest('tr').find('.relationship').html()
            if (dependents_to_skip.indexOf(relationship) == -1) {
              dependents_to_skip.push(relationship)
            }
            $('.skip_relationship').empty()

            let relationship_options = ``
            for (let relationship of dependents_to_skip) {
              relationship_options += `<option value="${relationship}">${relationship}</option>`
            }
            $('.skip_relationship').append(relationship_options);
            $('.edit_skipping_hierarchy').modal('show')
            $('input[name="edit_member_first_name"]').val($(this).closest('tr').find('#table_relationship').attr('first_name'))
            $('input[name="edit_member_middle_name"]').val($(this).closest('tr').find('#table_relationship').attr('middle_name'))
            $('input[name="edit_member_last_name"]').val($(this).closest('tr').find('#table_relationship').attr('last_name'))
            $('input[name="edit_member_suffix"]').val($(this).closest('tr').find('#table_relationship').attr('suffix'))
            $('input[name="edit_member_birthdate"]').val($(this).closest('tr').find('#table_relationship').attr('birthdate'))
            $('input[name="edit_member_supporting_document"]').val($(this).closest('tr').find('#table_relationship').attr('file_name'))
            $('input[name="edit_member_supporting_document"]').closest('.field').addClass('disabled')
            setTimeout(function () {
              $('.skip_dropdown').dropdown('set selected', relationship)
            }, 1)
            $('.skip_reason').dropdown('set selected', $(this).closest('tr').find('#table_relationship').attr('reason'))
            if ($(this).closest('tr').find('#table_relationship').attr('gender') == "Male"){
              $('input[name="edit_member_gender"][value="Male"]').prop('checked', true);
            }
            else{
              $('input[name="edit_member_gender"][value="Female"]').prop('checked', true);
            }
            let count_parent = 0
            let count_spouse = 0
            let selected_gender = $(this).closest('tr').find('#table_relationship').attr('gender')
            $('#hierarchy_table tbody tr').each(function() {
              if ($(this).find('#table_relationship').html() == 'Parent') {
                count_parent += 1
              }
              if ($(this).find('#table_relationship').html() == 'Spouse'){
                count_spouse += 1
              }
            })
            if (count_parent >= 2 && relationship == 'Parent'){
              $('#edit_skipped_gender_Male').attr('disabled', true)
              $('#edit_skipped_gender_Female').attr('disabled', true)
            }
            if (count_parent <= 1 && relationship == 'Parent'){
              $('#edit_skipped_gender_Male').attr('disabled', false)
              $('#edit_skipped_gender_Female').attr('disabled', false)
            }
            if (count_spouse >= 1 && relationship == 'Spouse'){
              if ($(this).closest('tr').find('#table_relationship').attr('gender') == "Male"){
                $('#edit_skipped_gender_Female').attr('disabled', true)
              }
              else{
                $('#edit_skipped_gender_Male').attr('disabled', true)
              }
            }
            $('#edit-skip-item').unbind("click").click(function(){
              let edit_valid_text = edit_validate_text_inputs()
              let edit_valid_select = edit_validate_select_inputs()
              let edit_valid_file = edit_validate_file_inputs()
              let relationship = ''
              let name = ''
              let first_name = ''
              let middle_name = ''
              let last_name = ''
              let suffix = ''
              let gender = ''
              let birthdate = ''
              let reason = ''
              let supporting_file = ''
              relationship = $('.edit_select-validate-required').find('.skip_relationship option:selected').val()
              name = $('input[name="edit_member_first_name"]').val() + ' ' + $('input[name="edit_member_middle_name"]').val() + ' ' + $('input[name="edit_member_last_name"]').val() + ' ' + $('input[name="edit_member_suffix"]').val()
              first_name = $('input[name="edit_member_first_name"]').val()
              middle_name = $('input[name="edit_member_middle_name"]').val()
              last_name = $('input[name="edit_member_last_name"]').val()
              suffix = $('input[name="edit_member_suffix"]').val()
              gender = $('input[name="edit_member_gender"]:checked').val()
              birthdate = $('input[name="edit_member_birthdate"]').val()
              reason = $('.edit_select-validate-required').find('.skip_reason').find('select').val()
              if (edit_valid_text == true && edit_valid_select == true && edit_valid_file == true) {
                if ($('.edit_file-validate-required.disabled').find('input').attr('type') == "text"){
                  this_class.find('#table_relationship').attr('relationship', relationship)
                  this_class.find('#table_relationship').attr('first_name', first_name)
                  this_class.find('#table_relationship').attr('middle_name', middle_name)
                  this_class.find('#table_relationship').attr('last_name', last_name)
                  this_class.find('#table_relationship').attr('suffix', suffix)
                  this_class.find('#table_relationship').attr('gender', gender)
                  this_class.find('#table_relationship').attr('birthdate', birthdate)
                  this_class.find('#table_relationship').attr('reason', reason)

                  this_class.find('#table_relationship').text(relationship)
                  this_class.find('#table_name').text(name)
                  this_class.find('#table_gender').text(gender)
                  this_class.find('#table_birthdate').text(birthdate)
                  this_class.find('#table_reason').text(reason)
                }
                else{
                  supporting_file = $('input[name="edit_member_supporting_document"]').prop('files')[0];
                  let reader = new FileReader();
                  let base64 = ''
                  if (supporting_file != "") {
                    reader.readAsBinaryString(supporting_file);
                    reader.onload = function(readerEvt) {
                      let binaryString = readerEvt.target.result;
                      base64 = btoa(binaryString)
                      let data = ``
                      this_class.find('#table_relationship').attr('relationship', relationship)
                      this_class.find('#table_relationship').attr('first_name', first_name)
                      this_class.find('#table_relationship').attr('middle_name', middle_name)
                      this_class.find('#table_relationship').attr('last_name', last_name)
                      this_class.find('#table_relationship').attr('suffix', suffix)
                      this_class.find('#table_relationship').attr('gender', gender)
                      this_class.find('#table_relationship').attr('birthdate', birthdate)
                      this_class.find('#table_relationship').attr('reason', reason)
                      this_class.find('#table_relationship').attr('file_name', supporting_file.name)
                      this_class.find('#table_relationship').attr('extension', supporting_file.name.split('.').pop())
                      this_class.find('#table_relationship').attr('base64', base64)

                      this_class.find('#table_relationship').text(relationship)
                      this_class.find('#table_name').text(name)
                      this_class.find('#table_gender').text(gender)
                      this_class.find('#table_birthdate').text(birthdate)
                      this_class.find('#table_reason').text(reason)
                      this_class.find('#table_filename').text(supporting_file.name)
                    }
                  }
                }
                $('.edit_skipping_hierarchy').modal('hide')
              }
            })

            $('.edit_select-validate-required').find('.skip_relationship').change(function() {
              let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
              if ($(this).val() == "Spouse") {
                if (selected_principal.gender == "Male") {
                  $('#edit_skipped_gender_Female').attr('disabled', false)
                  $('#edit_skipped_gender_Female').prop('checked', true)
                  $('#edit_skipped_gender_Male').attr('disabled', true)
                } else {
                  $('#edit_skipped_gender_Male').attr('disabled', false)
                  $('#edit_skipped_gender_Male').prop('checked', true)
                  $('#edit_skipped_gender_Female').attr('disabled', true)
                }
                $('.skip-calendar').calendar({
                  type: 'date',
                  startMode: 'year',
                  maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
              }

              if ($(this).val() == 'Parent' && relationship != 'Parent' && count_parent == 1) {
                let parent_gender = ''
                $('#hierarchy_table tbody tr').each(function() {
                  if ($(this).find('#table_relationship').html() == 'Parent') {
                    parent_gender = $(this).find('#table_gender').html()
                    if (parent_gender == "Male") {
                      $('#edit_skipped_gender_Female').attr('disabled', false)
                      $('#edit_skipped_gender_Female').prop('checked', true)
                      $('#edit_skipped_gender_Male').attr('disabled', true)
                    } else {
                      $('#edit_skipped_gender_Male').attr('disabled', false)
                      $('#edit_skipped_gender_Male').prop('checked', true)
                      $('#edit_skipped_gender_Female').attr('disabled', true)
                    }
                  }
                })

                for (let dependent of selected_principal.dependents){
                  if (dependent.relationship == "Parent" && dependent.status != "Disapprove"){
                    if (dependent.gender == "Male"){
                      $('#edit_skipped_gender_Female').prop('checked', true)
                      $('#edit_skipped_gender_Male').attr('disabled', true)
                    }else
                      {
                        $('#edit_skipped_gender_Male').prop('checked', true)
                        $('#edit_skipped_gender_Female').attr('disabled', true)
                      }
                  }
                }
                let principal_birthdate = new Date(selected_principal.birthdate)
                $('.skip-calendar').calendar({
                  type: 'date',
                  startMode: 'year',
                  maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
              }
              if ($(this).val() == 'Parent' && relationship == 'Parent' && count_parent == 1) {
                if (selected_gender == "Male") {
                  $('#edit_skipped_gender_Male').prop('checked', true)
                  $('#edit_skipped_gender_Male').attr('disabled', false)
                  $('#edit_skipped_gender_Female').attr('disabled', false)
                }
                else{
                  $('#edit_skipped_gender_Female').prop('checked', true)
                  $('#edit_skipped_gender_Male').attr('disabled', false)
                  $('#edit_skipped_gender_Female').attr('disabled', false)
                }
                let principal_birthdate = new Date(selected_principal.birthdate)
                $('.skip-calendar').calendar({
                  type: 'date',
                  startMode: 'year',
                  maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
              }

              if ($(this).val() == 'Parent' && relationship == 'Parent' && count_parent == 2) {
                if (selected_gender == "Male") {
                  $('#edit_skipped_gender_Male').prop('checked', true)
                  $('#edit_skipped_gender_Male').attr('disabled', true)
                  $('#edit_skipped_gender_Female').attr('disabled', true)
                }
                else{
                  $('#edit_skipped_gender_Female').prop('checked', true)
                  $('#edit_skipped_gender_Female').attr('disabled', true)
                  $('#edit_skipped_gender_Male').attr('disabled', true)
                }
                let principal_birthdate = new Date(selected_principal.birthdate)
                $('.skip-calendar').calendar({
                  type: 'date',
                  startMode: 'year',
                  maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
              }

              if ($(this).val() == 'Child' || $(this).val() == 'Sibling'){
                $('#edit_skipped_gender_Male').attr('disabled', false)
                $('#edit_skipped_gender_Female').attr('disabled', false)
                $('#edit_skipped_gender_Male').prop('checked', true)
                let principal_birthdate = new Date(selected_principal.birthdate)
                $('.skip-calendar').calendar({
                  type: 'date',
                  startMode: 'year',
                  minDate: new Date(principal_birthdate.getFullYear() + 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
                  maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
                      return year + '-' + month + '-' + day;
                    }
                  }
                })
              }
            });
          })

          $('#remove_file').click(function(){
            $('input[name="edit_member_supporting_document"]').closest('.field').removeClass('disabled')
            $('input[name="edit_member_supporting_document"]').attr('type', 'file')
            $('input[name="edit_member_supporting_document"]').attr('accept', '.pdf,.xls,.jpg,.csv,.doc,.docx,.xlsx,.png')
            $(this).attr('style', 'display: none;')
          })

          $('.edit_skipping_hierarchy').modal({
            closable  : false,
            onHide : function() {
              $('input[name="edit_member_first_name"]').val('')
              $('input[name="edit_member_middle_name"]').val('')
              $('input[name="edit_member_last_name"]').val('')
              $('input[name="edit_member_suffix"]').val('')
              $('input[name="edit_member_gender"][value="Male"]').prop('checked', true);
              $('input[name="edit_member_birthdate"]').val('')
              $('input[name="member_reason"]').val('')
              $('input[name="edit_member_supporting_document"]').attr('type', 'text')
              $('input[name="edit_member_supporting_document"]').attr('accept', '')
              $('input[name="edit_member_supporting_document"]').closest('.field').addClass('disabled')
              $('#edit_skipped_gender_Male').attr('disabled', false)
              $('#edit_skipped_gender_Female').attr('disabled', false)
              $('#remove_file').attr('style', 'height: 40px; margin-top: 20px; !important')
              $('.skip_relationship').val('')
              $('.select-validate-required').find('.text').html('');
            }
          })
          /* let relationship_table = []
          setTimeout(function () {
            $('#hierarchy_table tbody tr').each(function(){
              relationship_table.push($(this).find('#table_relationship').html())
            })
          }, 1)
          console.log(relationship_table.length)
          for (let i=0;i<relationship_table.length;i++){
            let in_array = $.inArray(relationship_table[i], dependents_to_skip)
            if (in_array != '-1'){
              dependents_to_skip.splice(in_array, 1);
            }
          }
          if (dependents_to_skip.length == 0){
            $('#addDependentSkip').addClass('disabled')
          }
          */
        }
      }
    };
  });

  $('.add_skipping_hierarchy').modal({
    closable  : false,
    onHide : function() {
      $('select.skip_relationship').val('')
      $('input[name="member_first_name"]').val('')
      $('input[name="member_middle_name"]').val('')
      $('input[name="member_last_name"]').val('')
      $('input[name="member_suffix"]').val('')
      $('input[name="member_gender"][value="Male"]').prop('checked', true);
      $('input[name="member_birthdate"]').val('')
      $('input[name="member_reason"]').val('')
      $('input[name="member_supporting_document"]').val('');
      $('.skip_relationship').val('')
      $('#skipped_gender_Male').removeAttr('disabled')
      $('#skipped_gender_Female').removeAttr('disabled')
      $('.select-validate-required').find('.text').html('');
      let relationship = $('select#relationship option:selected').attr('id')
      let relationship_table = []
      $('#hierarchy_table tbody tr').each(function() {
        relationship_table.push($(this).find('#table_relationship').html())
      })
      let parent_count = 0
      let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
      for (let dependent of selected_principal.dependents) {
        if (dependent.id != member_id && dependent.relationship == "Parent" && dependent.status != "Disapprove"){
          parent_count += 1
        }
      }

      for (let i=0;i<relationship_table.length;i++) {
        if (relationship_table[i] == "Parent") {
          if (parent_count != 1) {
            parent_count = parent_count + 1
          }
          else {
            let in_array = $.inArray(relationship_table[i], dependents_to_skip)
            if (in_array != '-1') {
              dependents_to_skip.splice(in_array, 1);
            }
          }
        }
        else {
          let in_array = $.inArray(relationship_table[i], dependents_to_skip)
          if (in_array != '-1') {
            dependents_to_skip.splice(in_array, 1);
          }
        }
      }
      if (dependents_to_skip.length == 0) {
       $('#addDependentSkip').addClass('disabled')
      }
      if (relationship_table.length > 0) {
        for (let a=1;a<relationship;a++) {
          let val = $('select#relationship').find(`#${a}`).val()
          $('select#relationship').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).addClass('disabled')
        }
      }
      if ($('select#principal_product option').length > 0) {
        for (let a=1;a<$('select#principal_product option').length;a++) {
          if (a-1 != relationship){
            let val = $('select#principal_product').find(`#${a}`).val()
            $('select#principal_product').closest('.ui.dropdown').find('.menu').find(`div[data-value="${val}"]`).addClass('disabled')
          }
        }
      }
    }
  });

  $('.skip_relationship').change(function() {
    $('#skipped_gender_Male').attr('disabled', false)
    $('#skipped_gender_Female').attr('disabled', false)
    $('#skipped_gender_Male').prop('checked', true)

    let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
    if ($(this).val() == "Spouse") {
      if (selected_principal.gender == "Male") {
        $('#skipped_gender_Female').prop('checked', true)
        $('#skipped_gender_Male').attr('disabled', true)
      } else {
        $('#skipped_gender_Male').prop('checked', true)
        $('#skipped_gender_Female').attr('disabled', true)
      }
      $('.skip-calendar').calendar({
        type: 'date',
        startMode: 'year',
        maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
            return year + '-' + month + '-' + day;
          }
        }
      })
    }

    if ($(this).val() == "Parent") {
      let parent_gender = ''
      $('#hierarchy_table tbody tr').each(function() {
        if ($(this).find('#table_relationship').html() == 'Parent') {
          parent_gender = $(this).find('#table_gender').html()
          if (parent_gender == "Male") {
            $('#skipped_gender_Female').prop('checked', true)
            $('#skipped_gender_Male').attr('disabled', true)
          } else {
            $('#skipped_gender_Male').prop('checked', true)
            $('#skipped_gender_Female').attr('disabled', true)
          }
        }
      })

      for (let dependent of selected_principal.dependents){
        if (dependent.id != member_id && dependent.relationship == "Parent" && dependent.status != "Disapprove"){
          if (dependent.gender == "Male"){
            $('#skipped_gender_Female').prop('checked', true)
            $('#skipped_gender_Male').attr('disabled', true)
          }else
            {
              $('#skipped_gender_Male').prop('checked', true)
              $('#skipped_gender_Female').attr('disabled', true)
            }
        }
      }

      let principal_birthdate = new Date(selected_principal.birthdate)
      $('.skip-calendar').calendar({
        type: 'date',
        startMode: 'year',
        maxDate: new Date(principal_birthdate.getFullYear() - 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
            return year + '-' + month + '-' + day;
          }
        }
      })
    }

    if ($(this).val() == "Child" || $(this).val() == "Sibling") {
      let principal_birthdate = new Date(selected_principal.birthdate)
      $('.skip-calendar').calendar({
        type: 'date',
        startMode: 'year',
        minDate: new Date(principal_birthdate.getFullYear() + 1, principal_birthdate.getMonth(), principal_birthdate.getDate()),
        maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
            return year + '-' + month + '-' + day;
          }
        }
      })
    }
  });

  $('.cancel-skip').click(function(){
    $('.add_skipping_hierarchy').modal('hide')
  });



  $('#submitGeneral').on('click', function() {
    let waiver = $('#principal_product').find(':selected').attr('waiver')
    if ($('input[name="member[type]"]:checked').val() == "Dependent" && $('#principalID').val() != "" && $('#relationship').val() != "" && waiver != ''){
      let checker = validate_hierarchy_skipping(waiver)
      if (checker == true) {
        $('#memberForm').submit()
      }
    }
    else {
      $('#memberForm').submit()
    }
  });

  // Functions
  function enableDependentFields() {
    $('#principalID').prop('disabled', false)
    $('#principalID').closest('div.dropdown').removeClass('disabled')
    $('#relationship').prop('disabled', false)
    $('#relationship').closest('div.dropdown').removeClass('disabled')
    $('#principal_product').prop('disabled', false)
    $('#principal_product').closest('div.dropdown').removeClass('disabled')

    $('.depFields').attr('style', 'display: block')
  };

  function disableDependentFields() {
    $('#principalID').prop('disabled', true)
    $('#principalID').closest('div.dropdown').addClass('disabled')
    $('#relationship').prop('disabled', true)
    $('#relationship').closest('div.dropdown').addClass('disabled')
    $('#principal_product').prop('disabled', true)
    $('#principal_product').closest('div.dropdown').addClass('disabled')

    $('.depFields').attr('style', 'display: none')
  };

  function enablePrincipalFields() {
    $('#employeeNo').prop('disabled', false)
    $('#employeeNo').removeClass('disabled')
    $('#hiredDate').prop('disabled', false)
    $('#hiredDate').removeClass('disabled')
    $('input[name="member[is_regular]"]').attr('disabled', false)
    $('#regDate').prop('disabled', false)
    $('#regDate').removeClass('disabled')

    $('#empNoField').attr('style', 'display: block')
    $('#hiredField').attr('style', 'display: block')
    $('#prinFields').attr('style', 'display: block')
  }

  function disablePrincipalFields() {
    $('#employeeNo').prop('disabled', true)
    $('#employeeNo').addClass('disabled')
    $('#hiredDate').prop('disabled', true)
    $('#hiredDate').addClass('disabled')
    $('input[name="member[is_regular]"]').attr('disabled', true)
    $('#regDate').prop('disabled', true)
    $('#regDate').addClass('disabled')

    $('#empNoField').attr('style', 'display: none')
    $('#hiredField').attr('style', 'display: none')
    $('#prinFields').attr('style', 'display: none')
  }

  function enableGuardianFields() {
    $('#employeeNo').prop('disabled', false)
    $('#employeeNo').removeClass('disabled')

    $('#empNoField').attr('style', 'display: block')
  }

  function disableCivilStatus() {
    $('#member_civil_status').prop('disabled', true)
    $('#member_civil_status').closest('div.dropdown').addClass('disabled')
  }

  function enableCivilStatus() {
    $('#member_civil_status').dropdown('clear')
    $('#member_civil_status').val('')
    $('#member_civil_status').prop('disabled', false)
    $('#member_civil_status').closest('div.dropdown').removeClass('disabled')
  }

  function dependent_count(principal, type) {
    let count = 0
    for (let dependent of principal.dependents) {
      // TEMPO
      if (dependent.id != $('#memberID').val() && dependent.status != "Disapprove") {
        if (dependent.relationship == type) {
          count++
        }
        for (let skipped_dependent of dependent.skipped_dependents) {
          if (skipped_dependent.relationship == type) {
            count++
          }
        }
      }
    }
    return count
  };

  function validate_hierarchy_skipping(waiver) {
    let principal_id = $('select[name="member[principal_id]"]').val()
    let relationship = $('select[name="member[relationship]"]').val()
    let selected_principal = account_principals.find(principal => principal.id == principal_id)
    let spouse_count = dependent_count(selected_principal, "Spouse")
    let child_count = dependent_count(selected_principal, "Child")
    let parent_count = dependent_count(selected_principal, "Parent")
    let sibling_count = dependent_count(selected_principal, "Sibling")
    dependents_to_skip.length = 0
    let hello = hierarchy.indexOf(relationship) - 1

    while (hello >= 0) {
      dependents_to_skip.push(hierarchy[hello])
      hello--
    }

    if (spouse_count != 0) {
      let index = dependents_to_skip.indexOf("Spouse")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (child_count != 0) {
      let index = dependents_to_skip.indexOf("Child")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (parent_count != 0) {
      let index = dependents_to_skip.indexOf("Parent")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (sibling_count != 0) {
      let index = dependents_to_skip.indexOf("Sibling")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    let skip_parent = 0
    let skip_spouse = 0
    let skip_child = 0
    let skip_sibling = 0

    $('.skip_relationship_data').each(function() {
      let hello = $(this).html()
      if (hello == "Parent") {skip_parent++}
      if (hello == "Spouse") {skip_spouse++}
      if (hello == "Child") {skip_child++}
      if (hello == "Sibling") {skip_sibling++}
    })

    if (dependents_to_skip.includes("Parent") && skip_parent > 0) {
      dependents_to_skip.splice(dependents_to_skip.indexOf("Parent"), 1)
    }
    if (dependents_to_skip.includes("Spouse") && skip_spouse > 0) {
      dependents_to_skip.splice(dependents_to_skip.indexOf("Spouse"), 1)
    }
    if (dependents_to_skip.includes("Child") && skip_child > 0) {
      dependents_to_skip.splice(dependents_to_skip.indexOf("Child"), 1)
    }
    if (dependents_to_skip.includes("Sibling") && skip_sibling > 0) {
      dependents_to_skip.splice(dependents_to_skip.indexOf("Sibling"), 1)
    }

    let relationship_table = []
    $('#hierarchy_table tbody tr').each(function() {
      relationship_table.push($(this).find('#table_relationship').html())
    })

    let parent_count_skip = 0
    for (let dependent of selected_principal.dependents) {
      if (dependent.id != member_id && dependent.relationship == "Parent" && dependent.status != "Disapprove") {
        parent_count_skip += 1
      }
    }

    for (let i=0;i<relationship_table.length;i++) {
      if (relationship_table[i] == "Parent") {
        if (parent_count_skip != 1) {
          parent_count_skip = parent_count_skip + 1
        }
        else {
          let in_array = $.inArray(relationship_table[i], dependents_to_skip)
          if (in_array != '-1'){
            dependents_to_skip.splice(in_array, 1);
          }
        }
      }
      else {
        let in_array = $.inArray(relationship_table[i], dependents_to_skip)
        if (in_array != '-1'){
          dependents_to_skip.splice(in_array, 1);
        }
      }
    }
    if (waiver == 'Waive'){
      return true
    }
    else if (waiver == 'Enforce' || waiver == 'null'){
      if (dependents_to_skip.length == 0)
        {
          return true
        }else{
          swal({
            title: 'The relationship you selected is not allowed',
            html: `Enforce hierarchy is setup in selected principal’s product, please follow the hierarchy of dependents to proceed with the enrollment`,
            type: 'warning',
            width: '700px',
            confirmButtonText: '<i class="check icon"></i> Ok',
            confirmButtonClass: 'ui button',
            buttonsStyling: false,
            reverseButtons: true,
            allowOutsideClick: false
          }).catch(swal.noop)
          return false
        }
    }
    else if (waiver == 'Skip Allowed' && dependents_to_skip.length == 0) {
      // console.log($('input[name="member[type]"]').val())
      // if (relationship == 'Spouse' && selected_principal.gender == $('sele')) {
      // }
      // if (input_checker) {
      //   return false
      // }
      // else {
      //   return false
      // }
      let data = []
      $('#hierarchy_table tbody tr').each(function() {
        data.push($(this).find('.relationship').attr('relationship'))
        data.push($(this).find('.relationship').attr('first_name'))
        data.push($(this).find('.relationship').attr('middle_name'))
        data.push($(this).find('.relationship').attr('last_name'))
        data.push($(this).find('.relationship').attr('suffix'))
        data.push($(this).find('.relationship').attr('gender'))
        data.push($(this).find('.relationship').attr('birthdate'))
        data.push($(this).find('.relationship').attr('reason'))
        data.push($(this).find('.relationship').attr('file_name'))
        data.push($(this).find('.relationship').attr('extension'))
        data.push($(this).find('.relationship').attr('base64'))
        if (data.pop() == undefined) {
          data.push($(this).find('.relationship').attr('skip_id'))
        }
        else {
          data.push($(this).find('.relationship').attr('base64'))
        }
      })
      $('#skipping_hierarchy_data_value').val(data)
      return true
    }
    else {
      let error_message = dependents_to_skip.join('<br>')
      let relationship_table = []

      check_if_skipping(selected_principal, relationship)

      $('#hierarchy_table tbody tr').each(function() {
        relationship_table.push($(this).find('#table_relationship').html())
      })

      let parent_count = 0
      for (let dependent of selected_principal.dependents) {
        if (dependent.relationship == "Parent" && dependent.status != "Disapprove") {
          parent_count += 1
        }
      }

      for (let i=0;i<relationship_table.length;i++) {
        if (relationship_table[i] == "Parent") {
          if (parent_count != 1) {
            parent_count = parent_count + 1
          }
          else {
            let in_array = $.inArray(relationship_table[i], dependents_to_skip)
            if (in_array != '-1') {
              dependents_to_skip.splice(in_array, 1);
            }
          }
        }
        else {
          let in_array = $.inArray(relationship_table[i], dependents_to_skip)
          if (in_array != '-1') {
            dependents_to_skip.splice(in_array, 1);
          }
        }
      }

      swal({
        title: 'The relationship you entered is not allowed',
        html: `The relationship you entered skips the following hierarchy of dependent/s: <br> ${error_message}`,
        type: 'warning',
        confirmButtonText: '<i class="check icon"></i> Ok',
        confirmButtonClass: 'ui button',
        buttonsStyling: false,
        reverseButtons: true,
        allowOutsideClick: false
      }).catch(swal.noop)
      return false
    }
  };

  function check_if_skipping(principal, relationship) {
    dependents_to_skip.length = 0
    let spouse_count = dependent_count(principal, "Spouse")
    let parent_count = dependent_count(principal, "Parent")
    let sibling_count = dependent_count(principal, "Sibling")
    let child_count = dependent_count(principal, "Child")
    let hello = hierarchy.indexOf(relationship) - 1

    while (hello >= 0) {
      dependents_to_skip.push(hierarchy[hello])
      hello--
    }

    if (spouse_count != 0) {
      let index = dependents_to_skip.indexOf("Spouse")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (child_count != 0) {
      let index = dependents_to_skip.indexOf("Child")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (parent_count != 0) {
      let index = dependents_to_skip.indexOf("Parent")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (sibling_count != 0) {
      let index = dependents_to_skip.indexOf("Sibling")
      if (index != -1){
        dependents_to_skip.splice(index, 1)
      }
    }

    if (dependents_to_skip.length == 0) {
      return true
    } else {
      return false
    }
  };

  function validate_text_inputs() {
    let valid = true
    $('.validate-required').each(function(){
      $(this).removeClass('error')
      $(this).find('.prompt').remove()
      let field = $(this).find('input').val()
      if (field == "") {
        let field_name = $(this).find('label').html()
        $(this).addClass('error')
        $(this).append(`<div class="ui basic red pointing prompt label transition visible">Please enter ${field_name}</div>`)
        valid = false
      }
    })
    return valid
  };

  function validate_select_inputs() {
    let valid = true
    $('.select-validate-required').each(function(){
      $(this).removeClass('error')
      $(this).find('.prompt').remove()
      let field = $(this).find('.dropdown').find('select').val()
      if (field == "" || field == null) {
        let field_name = $(this).find('label').html()
        $(this).addClass('error')
        $(this).append(`<div class="ui basic red pointing prompt label transition visible">Please enter ${field_name}</div>`)
        valid = false
      }
    })
    return valid
  };

  function validate_file_inputs() {
    let valid = true
    $('.file-validate-required').each(function(){
      $(this).removeClass('error')
      $(this).find('.prompt').remove()
      let field = $(this).find('input').val()
      if (field == "") {
        let field_name = $(this).find('label').html()
        $(this).addClass('error')
        $(this).append(`<div class="ui basic red pointing prompt label transition visible">Please Choose a File</div>`)
        valid = false
      }else
        {
          let file_extensions = "pdf,xls,jpg,csv,doc,docx,xlsx,png"
          let this_extension = $(this).find('input[name="member_supporting_document"]').prop('files')[0].name.split('.').pop()
          if (file_extensions.indexOf(this_extension) == -1) {
            $(this).addClass('error')
            $(this).append(`<div class="ui basic red pointing prompt label transition visible">Invalid File type. Valid file type are in .xls, .xlsx, .csv, .docx, .png, .jpg, .jpeg, and .pdf  format</div>`)
          valid = false
          }
        }
    })
    return valid
  };

  function edit_validate_text_inputs() {
    let valid = true
    $('.edit_validate-required').each(function(){
      $(this).removeClass('error')
      $(this).find('.prompt').remove()
      let field = $(this).find('input').val()
      if (field == "") {
        let field_name = $(this).find('label').html()
        $(this).addClass('error')
        $(this).append(`<div class="ui basic red pointing prompt label transition visible">Please enter ${field_name}</div>`)
        valid = false
      }
    })
    return valid
  };

  function edit_validate_select_inputs() {
    let valid = true
    $('.edit_select-validate-required').each(function(){
      $(this).removeClass('error')
      $(this).find('.prompt').remove()
      let field = $(this).find('.dropdown').find('select').val()
      if (field == "" || field == null) {
        let field_name = $(this).find('label').html()
        $(this).addClass('error')
        $(this).append(`<div class="ui basic red pointing prompt label transition visible">Please enter ${field_name}</div>`)
        valid = false
      }
    })
    return valid
  };

  function edit_validate_file_inputs() {
    let valid = true
    $('.edit_file-validate-required').each(function(){
      $(this).removeClass('error')
      $(this).find('.prompt').remove()
      let field = $(this).find('input').val()
      if (field == "") {
        let field_name = $(this).find('label').html()
        $(this).addClass('error')
        $(this).append(`<div class="ui basic red pointing prompt label transition visible">Please Choose a File</div>`)
        valid = false
      }else
        {
          let file_extensions = "pdf,xls,jpg,csv,doc,docx,xlsx,png"
          if ($(this).find('input[name="edit_member_supporting_document"]').attr('type') != 'text'){
            let this_extension = $(this).find('input[name="edit_member_supporting_document"]').prop('files')[0].name.split('.').pop()
            if (file_extensions.indexOf(this_extension) == -1) {
              $(this).addClass('error')
              $(this).append(`<div class="ui basic red pointing prompt label transition visible">Invalid File type. Valid file type are in .xls, .xlsx, .csv, .docx, .png, .jpg, .jpeg, and .pdf  format</div>`)
              valid = false
            }
          }
        }
    })
    return valid
  };

  function append_dependent_to_skip(count) {
    let relationship_options = ''
    for (let relationship of dependents_to_skip) {
      relationship_options += `<option value="${relationship}">${relationship}</option>`
    }
    let new_row = `\
      <div class="dependents-to-skip">\
        <div class="two fields">\
          <div class="field select-validate-required">\
            <label for="member_relationship">Relationship</label>\
            <div class="ui dropdown selection" tabindex="0">\
              <select name="member[dependent_skip][${count}][relationship]" class="skip_relationship">\
                <option value="">Select Relationship</option>\
                ${relationship_options}\
              </select>\
              <i class="dropdown icon"></i>\
              <div class="default text">Select Relationship</div>\
              <div class="menu" tabindex="-1"></div>\
            </div>\
          </div>\
          <div class="field validate-required">\
            <label for="">First Name</label>\
            <input class="person name" name="member[dependent_skip][${count}][first_name]" type="text">\
          </div>\
        </div>\
        <div class="two fields">\
          <div class="field">\
            <label>Middle Name</label>\
            <input class="person name" name="member[dependent_skip][${count}][middle_name]" type="text">\
          </div>\
          <div class="field validate-required">\
            <label>Last Name</label>\
            <input class="person name" name="member[dependent_skip][${count}][last_name]" type="text">\
          </div>\
        </div>\
        <div class="two fields">\
          <div class="field">\
            <div class="two fields">\
              <div class="field">\
                <label>Suffix</label>\
                <input name="member[dependent_skip][${count}][suffix]" type="text">\
              </div>\
              <div class="field">\
                <div class="field">\
                  <label>Gender</label>\
                </div>\
                <div class="inline fields">\
                  <div class="field">\
                    <div class="ui radio checkbox">\
                      <input checked="" name="member[dependent_skip][${count}][gender]" type="radio" value="Male" tabindex="0" class="hidden">\
                      <label>Male</label>\
                    </div>\
                  </div>\
                  <div class="field">\
                    <div class="ui radio checkbox">\
                      <input name="member[dependent_skip][${count}][gender]" type="radio" value="Female" tabindex="0" class="hidden">\
                      <label>Female</label>\
                    </div>\
                  </div>\
                </div>\
              </div>\
            </div>\
          </div>\
          <div class="field validate-required">\
            <label>Birthdate</label>\
            <div class="skip-calendar ui calendar">\
              <div class="ui input right icon">\
                <i class="calendar icon"></i>\
                <input name="member[dependent_skip][${count}][birthdate]" placeholder="YYYY-MM-DD" type="text">\
              </div>\
            </div>\
          </div>\
        </div>\
        <div class="two fields">\
          <div class="field validate-required">\
            <label>Reason</label>\
            <input class="person name" name="member[dependent_skip][${count}][reason]" type="text">\
          </div>\
          <div class="field file-validate-required">\
            <label>Supporting Document</label>\
            <input name="member[dependent_skip][${count}][supporting_document]" type="file">\
          </div>\
        </div>\
        <button type="button" class="ui button remove-skip-item">Remove</button>\
      </div>\
    `
    $('#skipContainer').append(new_row)
    $('.skip_relationship').dropdown()
    $('.ui .checkbox').checkbox()

    $('.skip-calendar').calendar({
      type: 'date',
      startMode: 'year',
      maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
          return year + '-' + month + '-' + day;
        }
      }
    })
  };

  // Dates
  $('#birthdate').calendar({
    type: 'date',
    startMode: 'year',
    maxDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
        return year + '-' + month + '-' + day;
      }
    },
    onChange: function(date, text, mode) {
      if (text) {
        let age = Math.floor(moment().diff(text, 'years', true))
        document.getElementById('age').value = age
      }
      else {
        document.getElementById('age').value = ""
      }
    }
  });

  $('#regularizationDate').calendar({
    type: 'date',
    startMode: 'year',
    startCalendar: $('#dateHired'),
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
        return year + '-' + month + '-' + day;
      }
    }
  });
});

onmount('div[name="MemberProducts"]', function () {

  $('#modal_products')
    .modal({autofocus: false, observeChanges: true})
    .modal('attach events', '.add.button', 'show')

  $('#sortableProducts').sortable({
    appendTo: 'body',
    helper: 'clone',
    stop: function(event, ui){
      let counter = 1
      $('#memberProductsTbl > tbody  > tr').each(function(){
        $(this).children(':first').html(`<b>${counter}</b>`)
        counter++
      })
    }
  });

  let member_product_tier = []

  $('#productTierForm').on('submit', function(){
    $('#memberProductsTbl > tbody  > tr').each(function(){
      member_product_tier.push($(this).attr('mpID'))
    })
    $('#productTier').val(member_product_tier)
  });

  let valArray = []

  $("input:checkbox.selection").on('change', function () {
    var value = $(this).val()
    if(this.checked) {
      valArray.push(value)
    } else {
      var index = valArray.indexOf(value)
      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('input[name="member[account_product_ids_main]"]').val(valArray)
  });

  $('#product_select').on('change', function(){
    var table = $('#productsModalTable').DataTable()
    var rows = table.rows({ 'search': 'applied' }).nodes();

    if ($(this).is(':checked')) {
      $('input[type="checkbox"]', rows).each(function() {
        var value = $(this).val()
        var eligible = $(this).attr('eligible')
        if (eligible == "true") {
          if (this.checked) {
            valArray.push(value)
          } else {
            var index = valArray.indexOf(value);

            if (index >= 0) {
              valArray.splice(index, 1)
            }
            valArray.push(value)
          }
          $(this).prop('checked', true)
        }
      })

    } else {
      valArray.length = 0
      $('input[type="checkbox"]').each(function() {
        $(this).prop('checked', false)
      })
    }
    $('input[name="member[account_product_ids_main]"]').val(valArray)
  });

  $('.delete_product').on('click', function(){
    let m_id = $(this).attr('memberID');
    let mp_id = $(this).attr('memberProductID');
    $('#product_removal_confirmation').modal('show');
    $('#confirmation_m_id').val(m_id);
    $('#confirmation_mp_id').val(mp_id);
  });

  $('#confirmation_submit_p').click(function(){
    let csrf = $('input[name="_csrf_token"]').val();
    let m_id = $('#confirmation_m_id').val();
    let mp_id = $('#confirmation_mp_id').val();

    $.ajax({
      url:`/${locale}/members/${m_id}/member_product/${mp_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.href = `/${locale}/members/${m_id}/setup?step=2&delete=success`
        //location.reload()
      },
      error: function(){
        alert('Error deleting product!')
      }
    })
  });
});

onmount('input[id="deleteMemberProductSuccess"]', function() {
  alertify.success(`<i class="close icon"></i><p>Successfully deleted product/s</p>`);
});

onmount('div[name="MemberContacts"]', function() {
  const valid_mobile_prefix = ["905", "906", "907", "908", "909", "910", "912", "915", "916", "917", "918", "919", "920", "921", "922", "923", "926", "927", "928", "929", "930", "932", "933", "935", "936", "937", "938", "939", "942", "943", "947", "948", "949", "973", "974", "979", "989", "996", "997", "999", "977", "978", "945", "955", "956", "994", "976", "975", "995", "817", "940", "946", "950", "992", "813", "911", "913", "914", "981", "998", "951", "970", "934", "941", "944", "925", "924", "931"];

  $.fn.form.settings.rules.mobileChecker = function(param) {
    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmaked_value.length == "10") {
      return true
    } else {
      return false
    }
  };

  $.fn.form.settings.rules.mobilePrefixChecker = function(param) {
    return valid_mobile_prefix.indexOf(param.substring(0, 3)) == -1 ? false : true
  };

  $.fn.form.settings.rules.telephoneChecker = function(param) {
    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmaked_value.length == "7") {
      return true
    } else {
      return false
    }
  };

   $.fn.form.settings.rules.postalChecker = function(param) {
    let unmaked_value = param.replace(/-/g, '').replace(/_/g, '')
    if (unmaked_value.length == "4") {
      return true
    } else {
      return false
    }
  };

  // if ($('#member_type').val() == "Dependent"){
    $('.ui.form')
    .form({
    inline: true,
      on: 'blur',
      fields: {
        'member[email]': {
          identifier: 'member[email]',
          optional: true,
          rules: [{
            type: 'email',
            prompt: 'Please enter a valid email'
          }]
        },
        'member[email2]': {
          identifier: 'member[email2]',
          optional: true,
          rules: [{
            type: 'email',
            prompt: 'Please enter a valid email'
          }]
        },
        'member[mobile]': {
          identifier: 'member[mobile]',
          optional: true,
          rules: [{
            type   : 'mobileChecker[param]',
            prompt : 'Mobile Phone 1 must be 10 digits'
          },
          {
            type: 'mobilePrefixChecker[param]',
            prompt: 'Invalid Mobile Phone 1 prefix'
          }]
        },
        'member[mobile2]': {
          identifier: 'member[mobile2]',
          optional: true,
          rules: [{
            type   : 'mobileChecker[param]',
            prompt : 'Mobile Phone 2 must be 10 digits'
          },
          {
            type: 'mobilePrefixChecker[param]',
            prompt: 'Invalid Mobile Phone 2 prefix'
          }]
        },
        'member[telephone]': {
          identifier: 'member[telephone]',
          optional: true,
          rules: [{
            type: 'telephoneChecker[param]',
            prompt: 'Telephone must be 7 digits'
          }]
        },
        'member[fax]': {
          identifier: 'member[fax]',
          optional: true,
          rules: [{
            type: 'telephoneChecker[param]',
            prompt: 'Fax must be 7 digits'
          }]
        },
        'member[postal]': {
          identifier: 'member[postal]',
          optional: true,
          rules: [{
            type: 'postalChecker[param]',
            prompt: 'Postal must be 4 digits'
          }]
        }
      }
    })
  // }

  // if ($('#member_type').val() == "Principal"){
  //   $('.ui.form')
  //   .form({
  //   inline: true,
  //     on: 'blur',
  //     fields: {
  //       'member[email]': {
  //         identifier: 'member[email]',
  //         rules: [{
  //           type: 'empty',
  //           prompt: 'Please enter Email Address'
  //         },
  //         {
  //           type: 'email',
  //           prompt: 'Please enter a valid email'
  //         }]
  //       },
  //       'member[email2]': {
  //         identifier: 'member[email2]',
  //         optional: true,
  //         rules: [{
  //           type: 'email',
  //           prompt: 'Please enter a valid email'
  //         }]
  //       },
  //       'member[mobile]': {
  //         identifier: 'member[mobile]',
  //         rules: [{
  //           type: 'empty',
  //           prompt: 'Please enter Mobile Phone'
  //         },
  //         {
  //           type   : 'mobileChecker[param]',
  //           prompt : 'Mobile Phone 1 must be 11 digits'
  //         },
  //         {
  //           type: 'mobilePrefixChecker[param]',
  //           prompt: 'Invalid Mobile Phone 1 prefix'
  //         }]
  //       },
  //       'member[mobile2]': {
  //         identifier: 'member[mobile2]',
  //         optional: true,
  //         rules: [{
  //           type   : 'mobileChecker[param]',
  //           prompt : 'Mobile Phone 2 must be 11 digits'
  //         },
  //         {
  //           type: 'mobilePrefixChecker[param]',
  //           prompt: 'Invalid Mobile Phone 2 prefix'
  //         }]
  //       },
  //       'member[telephone]': {
  //         identifier: 'member[telephone]',
  //         optional: true,
  //         rules: [{
  //           type: 'telephoneChecker[param]',
  //           prompt: 'Telephone must be 7 digits'
  //         }]
  //       },
  //       'member[fax]': {
  //         identifier: 'member[fax]',
  //         optional: true,
  //         rules: [{
  //           type: 'telephoneChecker[param]',
  //           prompt: 'Fax must be 7 digits'
  //         }]
  //       },
  //       'member[postal]': {
  //         identifier: 'member[postal]',
  //         optional: true,
  //         rules: [{
  //           type: 'postalChecker[param]',
  //           prompt: 'Postal must be 4 digits'
  //         }]
  //       }
  //     }
  //   })
  // }
});

onmount('div[name="MemberSummary"]', function() {
  $('div[role="success"]', function(){
    $('#enroll_success')
      .modal('setting', 'closable', false)
      .modal('show')
  });
});

//Batch Upload
onmount('div[id="member_batch_upload"]', function() {

  $('.item.active').attr('class', 'item')
  $('#batch_processing').attr('class', 'item active')

  $('.modal-open-actionConfirmation-file-upload').click(function(){
    $('.action-confirmation-upload-file').modal('show')
  })

  $('#batch_enrollment_template').click(function(){
    let csv = `Employee No,Member Type,Relationship,Effective Date,Expiry Date,First Name,Middle Name / Initial,Last Name,Suffix,Gender,Civil Status,Birthdate,Mobile No,Email,Date Hired,Regularization Date,Address,City,Product Code,For Card Issuance,Tin No,Philhealth,Philhealth No,Remarks\n(Required) Employee No. of the Principal or Guardian,(Required) Member type of member: Principal Dependent Guardian,(Required for dependents) Spouse Child Parent Sibling,(Required) Date must be in mm/dd/yyyy format,(Required) Date must be in mm/dd/yyyy format,"(Required) Must be containing 150 characters consist of letters and dot (.) comma (,) and hyphen (-)","(Optional) Must be containing 150 characters consist of letters and dot (.) comma (,) and hyphen (-)","(Required) Must be containing 150 characters consist of letters and dot (.) comma (,) and hyphen (-)","(Optional) Must be containing 10 characters consist of letters and dot (.) comma (,) and hyphen (-)",(Required) Male or Female,(Required) Status: Single Single Parent Married Widow / Widower Annulled Separated,(Required) Date must be in mm/dd/yyyy format,(Optional) Must be 11 digits only. Format must be 09********,"(Optional) Must contain alphanumeric characters with special characters dot (.)  hypen (-), at (@) and underscore(_)",(Optional) Date must be in mm/dd/yyyy format,(Optional) Date must be in mm/dd/yyyy format,(Optional) Address of the member,(Optional) City Address of the member,(Required) Product code of the product of the member,(Required) Yes No,(Optional) Must be containing twelve(12) numeric characters only,(Required) Required to file Optional to file Not Covered,(Optional) Must be containing twelve(12) numeric characters only,(Optional) Must be containing 250 alphanumeric and special characters only.`

    let filename = 'Member_Corporate_Template.csv'
    // Download CSV file
    downloadCSV(csv, filename);
  })
  $('#batch_cancellation_template').click(function(){
    let csv = []
    let template = "Member ID,Cancellation Date,Reason"
    csv.push(template)
    let filename = 'Member_Cancellation_Template.csv'
    // Download CSV file
    downloadCSV(csv, filename);
  })
  $('#batch_suspension_template').click(function(){
    let csv = []
    let template = "Member ID,Suspension Date,Reason"
    csv.push(template)
    let filename = 'Member_Suspension_Template.csv'
    // Download CSV file
    downloadCSV(csv, filename);
  })
  $('#batch_reactivation_template').click(function(){
    let csv = []
    let template = "Member ID,Reactivation Date,Reason"
    csv.push(template)
    let filename = 'Member_Reactivation_Template.csv'
    // Download CSV file
    downloadCSV(csv, filename);
  })

  let table = $('#member_batch_table').DataTable();

  $('#suspension_type').on('change', function() {
    table.draw();
  } );
  $('#reactivation_type').on('change', function() {
    table.draw();
  } );
  $('#cancellation_type').on('change', function() {
    table.draw();
  } );

  $('#enrollment_type').on('change', function() {
    table.draw();
  } );

  $.fn.dataTable.ext.search.push(
    function( settings, data, dataIndex ) {
      if ( $('#enrollment_type').is(":checked") )
        {
          if (data[2] == "Corporate")
            {
              return true;
            }
        }
      if ( $('#suspension_type').is(":checked") )
        {
          if (data[2] == "Suspension")
            {
              return true;
            }
        }
      if ( $('#cancellation_type').is(":checked") )
        {
          if (data[2] == "Cancellation")
            {
              return true;
            }
        }
      if ( $('#reactivation_type').is(":checked") )
        {
          if (data[2] == "Reactivation")
            {
              return true;
            }
        }

        if ( $('#reactivation_type').is(":checked") == false && $('#enrollment_type').is(":checked") ==false  && $('#cancellation_type').is(":checked") == false && $('#suspension_type').is(":checked") == false ){
          return true;
        }
    })

    $('#file_upload').on('change', function(event){
      let pdffile = event.target.files[0];
      if (pdffile != undefined){
        if((pdffile.name).indexOf('.csv') >= 0){
          if(pdffile.size <= 8000000){
          }
          else{
            $(this).val('')
            alert_error_size()
          }
        }
        else{
          $(this).val('')
          alert_error_file()
        }
      }
      else{
        $(this).val('')
      }
    })

    function alert_error_file(){
      alertify.error('Invalid file format. Please upload CSV file only.<i id="notification_error" class="close icon"></i>');
      alertify.defaults = {
        notifier:{
          delay:5,
          position:'top-right',
          closeButton: false
        }
      };
    }

    function alert_error_size(){
      alertify.error('Invalid file upload you reach maximum size<i id="notification_error" class="close icon"></i>');
      alertify.defaults = {
        notifier:{
          delay:8,
          position:'top-right',
          closeButton: false
        }
      };
    }

    $('#member_batch_table').on('click','.download_failed_button', function(){
      let upload_type = $(this).attr('upload_type')
      let logs_id = $(this).attr('member_upload_logs_id')
      let file_name = $(this).attr('file_name')
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/members/${logs_id}/failed/${upload_type}/member_batch_download`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        dataType: 'json',
        success: function(response){
          let filename = `${file_name}_Failed.csv`
          downloadCSV(response, filename);
        }
      });
    })

    $('#member_batch_table').on('click','.download_success_button', function(){
      let upload_type = $(this).attr('upload_type')
      let logs_id = $(this).attr('member_upload_logs_id')
      let file_name = $(this).attr('file_name')
      const csrf2 = $('input[name="_csrf_token"]').val();
      $.ajax({
        url:`/${locale}/members/${logs_id}/success/${upload_type}/member_batch_download`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        dataType: 'json',
        success: function(response){
          let filename = `${file_name}_Success.csv`
          downloadCSV(response, filename);
        }
      });
    })

    $('#import_member').form({
      on: blur,
      inline: true,
      fields: {
        'member[file]': {
          identifier: 'member[file]',
          rules: [{
            type  : 'empty',
            prompt: 'Please Choose File.'
          }
          ]
        },
        'member[upload_type]': {
          identifier: 'member[upload_type]',
          rules: [{
            type  : 'empty',
            prompt: 'Please Choose Upload Type.'
          }
          ]
        }
      }
    });

  $('td[class="date_transform"]').each(function(){
    let date = $(this).html();
    let udate = new Date(date);
  });
});

onmount('#original_facility' ,function(){
  setTimeout(function() {
    let facility_id = $('#original_facility').val()
    if(facility_id != "") {
      $(`#photo_${facility_id}`).trigger('click');
    }
  }, 2e3);
});
