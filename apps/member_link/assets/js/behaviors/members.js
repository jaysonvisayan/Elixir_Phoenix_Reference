onmount('div[id="Member_Index"]', function() {
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
    if (member_cancel_date == ''){
      $('#cancel_member_id').val(member_id)
      $('#cancel_member_name').val(member_name)
      $('#cancel_member_name').attr('disabled', 'disabled')
      $('#cancel_member_status').text(member_status)
      $('#cancel_member_effect').val(member_effect)
      $('#cancel_member_expire').val(member_expire)
      $('#cancel_member_effect').attr('disabled', 'disabled')
      $('#cancel_member_expire').attr('disabled', 'disabled')
      let expiry_date = new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000))
      if (new Date(member_suspend_date) != 'Invalid Date' && new Date(member_suspend_date) >= today){
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
              minDate: new Date(member_suspend_date.getFullYear(), member_suspend_date.getMonth(), member_suspend_date.getDate()),
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
        }).modal('show')
      }
      else if (new Date(member_reactivate_date) != 'Invalid Date' && new Date(member_reactivate_date) >= today){
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
              minDate: new Date(member_reactivate_date.getFullYear(), member_reactivate_date.getMonth(), member_reactivate_date.getDate()),
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
        }).modal('show')
      }
      else{
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
              minDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
        }).modal('show')
      }
    }
    else{
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
      let expiry_date = new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000))
      if (new Date(member_suspend_date) != 'Invalid Date' && new Date(member_suspend_date) >= today){
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
              minDate: new Date(member_suspend_date.getFullYear(), member_suspend_date.getMonth(), member_suspend_date.getDate()),
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
        }).modal('show')
      }
      else if (new Date(member_reactivate_date) != 'Invalid Date' && new Date(member_reactivate_date) >= today){
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
              minDate: new Date(member_reactivate_date.getFullYear(), member_reactivate_date.getMonth(), member_reactivate_date.getDate()),
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
        }).modal('show')
      }
      else{
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
              minDate: new Date(today.getFullYear(), today.getMonth(), today.getDate()),
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
        }).modal('show')
      }
    }
  });

  $('#close_cancel_member').click(function(){
    $('.ui.modal.action-confirmation-cancel').modal('hide');
  })

  $('#close_cancel').click(function(){
    $('.ui.modal.action-confirmation-cancel-retract').modal('hide');
  })

  $('#close_update_cancel').click(function(){
    $('.ui.modal.action-confirmation-cancel-retract').modal('hide');
  })



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
  })

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
    if (member_suspend_date == ''){
      $('#suspend_member_id').val(member_id)
      $('#suspend_member_name').val(member_name)
      $('#suspend_member_name').attr('disabled', 'disabled')
      $('#suspend_member_status').text(member_status)
      $('#suspend_member_effect').val(member_effect)
      $('#suspend_member_expire').val(member_expire)
      $('#suspend_member_effect').attr('disabled', 'disabled')
      $('#suspend_member_expire').attr('disabled', 'disabled')
      if (member_cancel_date != 'Invalid Date' && (new Date(member_cancel_date)) <= new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000)))
        {
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
                maxDate: new Date(member_cancel_date.getFullYear(), member_cancel_date.getMonth(), member_cancel_date.getDate()),
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
        else{
          let expiry_date = new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000))
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
          }).modal('show')
        }
    }
    else{
      $('.ui.modal.action-confirmation-suspend-retract').modal('show');
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
      if (member_cancel_date != 'Invalid Date' && (new Date(member_cancel_date)) <= new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000)))
        {
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
                maxDate: new Date(member_cancel_date.getFullYear(), member_cancel_date.getMonth(), member_cancel_date.getDate()),
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
        else{
          let expiry_date = new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000))
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
          }).modal('show')
        }
    }
  });

  $('#close_suspend_member').click(function(){
    $('.ui.modal.action-confirmation-suspend').modal('hide');
  })

  $('#close_suspend').click(function(){
    $('.ui.modal.action-confirmation-suspend-retract').modal('hide');
  })

  $('#close_update_suspend').click(function(){
    $('.ui.modal.action-confirmation-suspend-retract').modal('hide');
  })

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
   })

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
      if (member_cancel_date != 'Invalid Date' && (new Date(member_cancel_date)) <= new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000)))
        {
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
                maxDate: new Date(member_cancel_date.getFullYear(), member_cancel_date.getMonth(), member_cancel_date.getDate()),
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
        else{
          let expiry_date = new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000))
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
          }).modal('show')
        }
    }
    else{
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
      if (member_cancel_date != 'Invalid Date' && (new Date(member_cancel_date)) <= new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000)))
        {
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
                maxDate: new Date(member_cancel_date.getFullYear(), member_cancel_date.getMonth(), member_cancel_date.getDate()),
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
        else{
          let expiry_date = new Date((new Date(member_expire)).getTime() - (1 * 24 * 60 * 60 * 1000))
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
          }).modal('show')
        }
    }
  });

  $('#close_reactivate_member').click(function(){
    $('.ui.modal.action-confirmation-reactivate').modal('hide');
  })

  $('#close_reactivate').click(function(){
    $('.ui.modal.action-confirmation-reactivate-retract').modal('hide');
  })

  $('#close_update_reactivate').click(function(){
    $('.ui.modal.action-confirmation-reactivate-retract').modal('hide');
  })

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
  })

  $('#edit_reactivate_member').click(function() {
    $('#close_update_reactivate').attr('style', 'display: block;')
    $('#update_reactivate').attr('style', 'display: block;')
    $('#close_reactivate_edit').attr('style', 'display: none;')
    $('#edit_reactivate').attr('style', 'display: none;')
    $('#reactivate_date').removeAttr('disabled')
    $('.dropdown').removeClass('disabled')
    $('#reactivate_remark').removeAttr('disabled')
  });

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
          url:`/members/index/download`,
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
    else
      {
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
    } );
    $('#member_active').on('change', function() {
      table.draw();
    } );
    $('#member_lapse').on('change', function() {
            table.draw();
    } );

    $('#member_cancel').on('change', function() {
            table.draw();
    } );
    $('#member_pending').on('change', function() {
            table.draw();
    } );

    $('#member_guardian').on('change', function() {
            table.draw();
    } );
    $('#member_dependent').on('change', function() {
            table.draw();
    } );

    $('#member_principal').on('change', function() {
            table.draw();
    } );

    $.fn.dataTable.ext.search.push(
      function( settings, data, dataIndex ) {
        if ( $('#member_suspend').is(":checked") && $('#member_principal').is(":checked") == false  && $('#member_dependent').is(":checked") == false && $('#member_guardian').is(":checked") == false )
          {
            if (data[5] == "Suspended")
            {
              return true;
            }
        }
        if ( $('#member_active').is(":checked") && $('#member_principal').is(":checked") == false  && $('#member_dependent').is(":checked") == false && $('#member_guardian').is(":checked") == false )
        {
          if (data[5] == "Active")
            {
              return true;
            }
        }
        if ( $('#member_cancel').is(":checked") && $('#member_principal').is(":checked") == false  && $('#member_dependent').is(":checked") == false && $('#member_guardian').is(":checked") == false )
        {
          if (data[5] == "Cancelled")
            {
              return true;
            }
        }
        if ( $('#member_pending').is(":checked") && $('#member_principal').is(":checked") == false  && $('#member_dependent').is(":checked") == false && $('#member_guardian').is(":checked") == false )
        {
          if (data[5] == "Pending")
            {
              return true;
            }
        }
        if ( $('#member_lapse').is(":checked") && $('#member_principal').is(":checked") == false  && $('#member_dependent').is(":checked") == false && $('#member_guardian').is(":checked") == false )
        {
          if (data[5] == "Lapsed")
            {
              return true;
            }
        }
        if ( $('#member_guardian').is(":checked") && $('#member_active').is(":checked") == false  && $('#member_cancel').is(":checked") == false && $('#member_suspend').is(":checked") == false && $('#member_pending').is(":checked") == false && $('#member_lapse').is(":checked") == false)
        {
          if (data[4] == "Guardian")
            {
              return true;
            }
        }
        if ( $('#member_principal').is(":checked") && $('#member_active').is(":checked") == false  && $('#member_cancel').is(":checked") == false && $('#member_suspend').is(":checked") == false && $('#member_pending').is(":checked") == false && $('#member_lapse').is(":checked") == false)
        {
          if (data[4] == "Principal")
            {
              return true;
            }
        }
        if ( $('#member_dependent').is(":checked") && $('#member_active').is(":checked") == false  && $('#member_cancel').is(":checked") == false && $('#member_suspend').is(":checked") == false && $('#member_pending').is(":checked") == false && $('#member_lapse').is(":checked") == false)
        {
          if (data[4] == "Dependent")
            {
              return true;
            }
        }
        if ( $('#member_suspend').is(":checked") && $('#member_principal').is(":checked"))
        {
          if (data[5] == "Suspended" && data[4] == "Principal")
            {
              return true;
            }
        }
        if ( $('#member_suspend').is(":checked") && $('#member_dependent').is(":checked"))
        {
          if (data[5] == "Suspended" && data[4] == "Dependent")
            {
              return true;
            }
        }
        if ( $('#member_suspend').is(":checked") && $('#member_guardian').is(":checked"))
        {
          if (data[5] == "Suspended" && data[4] == "Guardian")
            {
              return true;
            }
        }
        if ( $('#member_pending').is(":checked") && $('#member_principal').is(":checked"))
        {
          if (data[5] == "Pending" && data[4] == "Principal")
            {
              return true;
            }
        }
        if ( $('#member_pending').is(":checked") && $('#member_dependent').is(":checked"))
        {
          if (data[5] == "Pending" && data[4] == "Dependent")
            {
              return true;
            }
        }
        if ( $('#member_pending').is(":checked") && $('#member_guardian').is(":checked"))
        {
          if (data[5] == "Pending" && data[4] == "Guardian")
            {
              return true;
            }
        }
        if ( $('#member_active').is(":checked") && $('#member_principal').is(":checked"))
        {
          if (data[5] == "Active" && data[4] == "Principal")
            {
              return true;
            }
        }
        if ( $('#member_active').is(":checked") && $('#member_dependent').is(":checked"))
          {
          if (data[5] == "Active" && data[4] == "Dependent")
            {
              return true;
            }
        }
        if ( $('#member_active').is(":checked") && $('#member_guardian').is(":checked"))
        {
          if (data[5] == "Active" && data[4] == "Guardian")
            {
              return true;
            }
        }
        if ( $('#member_cancel').is(":checked") && $('#member_principal').is(":checked"))
        {
          if (data[5] == "Cancelled" && data[4] == "Principal")
            {
              return true;
            }
        }
        if ( $('#member_cancel').is(":checked") && $('#member_dependent').is(":checked"))
        {
          if (data[5] == "Cancelled" && data[4] == "Dependent")
            {
              return true;
            }
        }
        if ( $('#member_cancel').is(":checked") && $('#member_guardian').is(":checked"))
        {
          if (data[5] == "Cancelled" && data[4] == "Guardian")
            {
              return true;
            }
        }
        if ( $('#member_lapse').is(":checked") && $('#member_principal').is(":checked"))
        {
          if (data[5] == "Lapsed" && data[4] == "Principal")
            {
              return true;
            }
        }
        if ( $('#member_lapse').is(":checked") && $('#member_dependent').is(":checked"))
        {
          if (data[5] == "Lapsed" && data[4] == "Dependent")
            {
              return true;
            }
        }
        if ( $('#member_lapse').is(":checked") && $('#member_guardian').is(":checked"))
        {
          if (data[5] == "Lapsed" && data[4] == "Guardian")
            {
              return true;
            }
        }

        if ( $('#member_dependent').is(":checked") == false  && $('#member_principal').is(":checked") == false && $('#member_guardian').is(":checked") == false && $('#member_suspend').is(":checked") == false && $('#member_pending').is(":checked") == false && $('#member_active').is(":checked") == false && $('#member_lapse').is(":checked") == false && $('#member_cancel').is(":checked") == false ){
              return true;
        }


      });
})

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

onmount('div[id="Members"]', function() {
  $('#modalProcedure').modal({autofocus: false, observeChanges: true}).modal('attach events', '.add.button', 'show')

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

  $('.delete_product').on('click', function(){
    let m_id = $(this).attr('memberID');
    let mp_id = $(this).attr('memberProductID');
    $('#product_removal_confirmation').modal('show');
    $('#confirmation_m_id').val(m_id);
    $('#confirmation_mp_id').val(mp_id);
  })

  $('#confirmation_cancel_p').click(function(){
    $('#product_removal_confirmation').modal('hide');
  });

  $('#confirmation_submit_p').click(function(){
    let csrf = $('input[name="_csrf_token"]').val();
    let m_id = $('#confirmation_m_id').val();
    let mp_id = $('#confirmation_mp_id').val();

    $.ajax({
      url:`/members/${m_id}/member_product/${mp_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        window.location.href = `/members/${m_id}/show`
      },
      error: function(){
        alert('Error deleting product!')
      }
    });
  });
});

onmount('div[name="MemberGeneral"]', function () {
  const member_id = $('#memberID').val();
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

  $.ajax({
    url:`/account/${account_group_code}/get_account`,
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
        if (member.type == "Principal" && member.id != member_id) {
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

      $('#expiryDate').calendar({
        type: 'date',
        startMode: 'day',
        startCalendar: $('#effectiveDate'),
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
          prompt: 'Employee number is already used within the account'
        }]
      },
      'member[date_hired]': {
        identifier: 'member[date_hired]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Date Hired'
        }]
      },
      'member[regularization_date]': {
        identifier: 'member[regularization_date]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Regularization Date'
        }]
      },
      'member[philhealth]': {
        identifier: 'member[philhealth]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter PhilHealth Number'
        }]
      }
    },
    onSuccess: function(event, fields) {
      let valid = validate_skipping_hierarchy()
      if (valid == false) {
        event.preventDefault()
      }
    }
  });

  $('input[name="member[type]"]').change(function() {
    $('select[name="member[relationship]"]').dropdown('clear')
    $('select[name="member[relationship]"]').val('')
    $('select[name="member[principal_id]"]').dropdown('clear')
    $('div').removeClass('error')
    $('.ui.basic.red.pointing.prompt.label.transition.visible').remove()

    let val = $(this).val()

    if (val == "Principal") {
      disableDependentFields()
      enablePrincipalFields()
    }else if (val == "Dependent") {
      enableDependentFields()
      disablePrincipalFields()
    } else if (val == "Guardian") {
      disableDependentFields()
      disablePrincipalFields()
      enableGuardianFields()
    }
  });

  $('select[name="member[principal_id]"]').change(function() {
    if ($(this).val() != null) {
      let selected_principal = account_principals.find(principal => principal.id == $(this).val())
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
          $('#relationship').append(`<option value="${hierarchy[i]}">${hierarchy[i]}</option>`)
        }
        else {
          if (hierarchy[i] == "Parent" && hierarchy.indexOf("Parent") == current_tier-1 && parent_count < 2) {
            $('#relationship').append(`<option value="${hierarchy[i]}">${hierarchy[i]}</option>`)
          }
          else if (hierarchy[i] == "Child" && hierarchy.indexOf("Child") == current_tier-1) {
            $('#relationship').append(`<option value="${hierarchy[i]}">${hierarchy[i]}</option>`)
          }
          else if (hierarchy[i] == "Sibling" && hierarchy.indexOf("Sibling") == current_tier-1) {
            $('#relationship').append(`<option value="${hierarchy[i]}">${hierarchy[i]}</option>`)
          }
          else {
            $('#relationship').append(`<option disabled="true" value="${hierarchy[i]}">${hierarchy[i]}</option>`)
          }
        }
      }

      $('#relationship').dropdown('refresh')

      setTimeout(function () {
        $('#relationship').dropdown('set selected', $('#memberRelationship').val())
      }, 1)

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

      $('#expiryDate').calendar({
        type: 'date',
        startMode: 'day',
        startCalendar: $('#effectiveDate'),
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

  $('select[name="member[relationship]"]').change(function() {
    if ($(this).val() != null) {
      let relationship = $(this).val()
      let selected_principal = account_principals.find(principal => principal.id == $('#principalID').val())
      let principal_birthdate = new Date(selected_principal.birthdate)
      let principal_children = []

      $.map(selected_principal.dependents, function(dependent, index) {
        if (dependent.relationship == "Child") {
          principal_children.push(dependent)
        }
      })

      if (check_if_skipping(selected_principal, relationship)) {
        $('#addDependentSkip').addClass('disabled')
      } else {
        $('#addDependentSkip').removeClass('disabled')
      }

      if ($(this).val() == "Child") {
        let last_child = principal_children.slice(-1)[0]
        if (last_child == null) {
          $('#birthdate').calendar({
            type: 'date',
            startMode: 'year',
            minDate: new Date(principal_birthdate.getFullYear(), principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
        } else{
          let last_child_birthdate = new Date(last_child.birthdate)
          $('#birthdate').calendar({
            type: 'date',
            startMode: 'year',
            minDate: new Date(last_child_birthdate.getFullYear(), last_child_birthdate.getMonth(), last_child_birthdate.getDate()),
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
      } else if ($(this).val() == "Parent") {
        $('#birthdate').calendar({
          type: 'date',
          startMode: 'year',
          maxDate: new Date(principal_birthdate.getFullYear(), principal_birthdate.getMonth(), principal_birthdate.getDate()),
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
      } else if ($(this).val() == "Spouse") {
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
      } else {
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
    }
  });

  if ($('input[name="member[type]"]:checked').val() == "Principal") {
    disableDependentFields()
    enablePrincipalFields()
  } else if ($('input[name="member[type]"]:checked').val() == "Dependent") {
    enableDependentFields()
    disablePrincipalFields()
  } else if ($('input[name="member[type]"]:checked').val() == "Guardian") {
    disableDependentFields()
    disablePrincipalFields()
    enableGuardianFields()
  }

  $('input[name="member[is_regular]"]').change(function() {
    let val = $(this).val()
    if (val == "true") {
      $('input[name="member[regularization_date]"]').val('')
      $('input[name="member[regularization_date]"]').prop('disabled', true)
    } else {
      $('input[name="member[regularization_date]"]').prop('disabled', false)
    }
  });

  $('input[name="member[philhealth_type]"]').change(function() {
    let val = $(this).val()
    if (val == "Not Covered") {
      $('input[name="member[philhealth]"]').val('')
      $('input[name="member[philhealth]"]').prop('disabled', true)
    } else {
      $('input[name="member[philhealth]"]').prop('disabled', false)
    }
  });

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

  $('#modal_skipping')
    .modal({autofocus: false, observeChanges: true})
    .modal('attach events', '.add.button', 'show')

  // Functions
  function enableDependentFields(){
    $('#principalID').prop('disabled', false)
    $('#principalID').closest('div.dropdown').removeClass('disabled')
    $('#relationship').prop('disabled', false)
    $('#relationship').closest('div.dropdown').removeClass('disabled')
  };

  function disableDependentFields(){
    $('#principalID').prop('disabled', true)
    $('#principalID').closest('div.dropdown').addClass('disabled')
    $('#relationship').prop('disabled', true)
    $('#relationship').closest('div.dropdown').addClass('disabled')
  };

  function enablePrincipalFields() {
    $('#employeeNo').prop('disabled', false)
    $('#employeeNo').removeClass('disabled')
    $('#hiredDate').prop('disabled', false)
    $('#hiredDate').removeClass('disabled')
    $('input[name="member[is_regular]"]').attr('disabled', false)
    $('#regDate').prop('disabled', false)
    $('#regDate').removeClass('disabled')
  }

  function disablePrincipalFields() {
    $('#employeeNo').prop('disabled', true)
    $('#employeeNo').addClass('disabled')
    $('#hiredDate').prop('disabled', true)
    $('#hiredDate').addClass('disabled')
    $('input[name="member[is_regular]"]').attr('disabled', true)
    $('#regDate').prop('disabled', true)
    $('#regDate').addClass('disabled')
  }

  function enableGuardianFields() {
    $('#employeeNo').prop('disabled', false)
    $('#employeeNo').removeClass('disabled')
  }

  function dependent_count(principal, type) {
    let count = 0
    for (let dependent of principal.dependents) {
      // TEMPO
      if (dependent.id != $('#memberID').val()) {
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

  function validate_skipping_hierarchy() {
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

    $('.skip_relationship').each(function() {
      let hello = $(this).val()
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

    // let input_checker = true

    // if (validate_text_inputs() == false) {
    //   input_checker = false
    // }

    // if (validate_select_inputs() == false) {
    //   input_checker = false
    // }

    // if (validate_file_inputs() == false) {
    //   input_checker = false
    // }

    if (dependents_to_skip.length == 0) {
      // console.log($('input[name="member[type]"]').val())
      // if (relationship == 'Spouse' && selected_principal.gender == $('sele')) {
      // }
      // if (input_checker) {
      //   return false
      // }
      // else {
      //   return false
      // }
      return true
    } else {
      let error_message = dependents_to_skip.join('<br>')
      swal({
        title: 'The relationship you entered is not allowed',
        html: 'The relationship you entered skips the following hierarchy of dependent/s:<br><b>'
              + `${error_message}` + '</b>',
        type: 'warning',
        width: '',
        confirmButtonText: '<i class="check icon"></i> Ok',
        confirmButtonClass: 'ui button',
        buttonsStyling: false,
        reverseButtons: true,
        allowOutsideClick: false
      }).catch(swal.noop)
      return false
    }
  };

  function check_if_skipping(principal, relationship){
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

  let valArray = []

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
  });

  $('#confirmation_submit_p').click(function(){
    let csrf = $('input[name="_csrf_token"]').val();
    let m_id = $('#confirmation_m_id').val();
    let mp_id = $('#confirmation_mp_id').val();

    $.ajax({
      url:`/members/${m_id}/member_product/${mp_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        let obj = JSON.parse(response)
        location.reload()
      },
      error: function(){
        alert('Error deleting product!')
      }
    })
  });
});

onmount('div[name="MemberContacts"]', function() {
  $('.ui.form')
  .form({
    inline: true,
    fields: {
      'member[email]': {
        identifier: 'member[email]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter Email Address'
          },
          {
            type: 'email',
            prompt: 'Please enter a valid email'
          }
        ]
      },
      'member[email2]': {
        identifier: 'member[email2]',
        optional: true,
        rules: [
          {
            type: 'email',
            prompt: 'Please enter a valid email'
          }
        ]
      },
      'member[mobile]': {
        identifier: 'member[mobile]',
        rules: [{
          type: 'empty',
          prompt: 'Please enter Mobile Phone'
        }]
      }
    }
  })
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

  $('#download_template').click(function(){
    if ($('#template_type').find(":selected").val() == "Enrollment"){
      let csv = []
      let template = "Account Code,Employee No,Member Type,Relationship,Effective Date,Expiry Date,First Name,Middle Name,Last Name,Suffix,Gender,Civil Status,Birthdate,Mobile,Email,Date Hired,Regularization Date,Address,City,Product Code,For Card Issuance,Tin No,Philhealth,Philhealth No"
      csv.push(template)
      let filename = 'Member_Enrollment_Template.csv'
      // Download CSV file
      downloadCSV(csv, filename);
    }
    else if ($('#template_type').find(":selected").val() == "Suspension"){
      let csv = []
      let template = "Member Name,Member ID,Employee No,Card No,Suspension Date,Reason"
      csv.push(template)
      let filename = 'Member_Suspension_Template.csv'
      // Download CSV file
      downloadCSV(csv, filename);
    }
    else if ($('#template_type').find(":selected").val() == "Cancellation"){
      let csv = []
      let template = "Member Name,Member ID,Employee No,Card No,Cancellation Date,Reason"
      csv.push(template)
      let filename = 'Member_Cancelled_Template.csv'
      // Download CSV file
      downloadCSV(csv, filename);
    }
    else if ($('#template_type').find(":selected").val() == "Reactivation"){
      let csv = []
      let template = "Member Name,Member ID,Employee No,Card No,Reactivation Date,Reason"
      csv.push(template)
      let filename = 'Member_Reactivation_Template.csv'
      // Download CSV file
      downloadCSV(csv, filename);
    }
    else
      {
        alertify.error('Please Select Template Type.<i id="notification_error" class="close icon"></i>');
        alertify.defaults = {
          notifier:{
            delay:5,
            position:'top-right',
            closeButton: false
          }
        };
      }
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
          if (data[2] == "Enrollment")
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
        url:`/members/${logs_id}/failed/${upload_type}/member_batch_download`,
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
        url:`/members/${logs_id}/success/${upload_type}/member_batch_download`,
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

