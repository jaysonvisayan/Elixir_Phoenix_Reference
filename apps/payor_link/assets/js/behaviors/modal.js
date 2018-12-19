onmount('div[id="sizesModal"]', function(){
  $('#miniModal').on('click', function(){
    $('.mini.modal').modal('show');
  });
  $('#tinyModal').on('click', function(){
    $('.tiny.modal').modal('show');
  });
  $('#smallModal').on('click', function(){
    $('.ui.small.modal')
  .modal({
    closable  : false,
    onDeny    : function(){
      window.alert('Wait not yet!');
      return false;
    },
    onApprove : function() {
      window.alert('Approved!');
    }
  })
  .modal('show')
;
  });
  $('#largeModal').on('click', function(){
    $('.large.modal').modal('show');
  });
});

onmount('.modal', function(){
  $('tr').removeAttr("style")

  $('div[id="pop_modal_renew"]').on('click', function(){
    $('#modal_renew').modal('show')
  })

  $('button[name="modal_contact"]').on('click', function(){
    $('div[role="add"]').form('reset');
    $('div[role="add"]').modal('show');
    $('div[role="add-contact"]').form('reset');
    $('div[role="add-contact"]').modal('show');
    $('p[role="append-telephone"]').empty();
    $('p[role="append-mobile"]').empty();
    $('p[role="append-fax"]').empty();
    $('p[role="append-email"]').empty();
    $('div[id="example13"]').calendar();
    $('div[id="example13"]').calendar({
      monthFirst: false,
      type: 'date',
      maxDate: new Date(),
      formatter: {
        date: function (date, settings) {
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

    const check_tel = (tel) => {
      if(tel == ""){
        $('div[role="add"]').find('a[add="telephone"]').addClass("disabled")
      }else{
        $('div[role="add"]').find('a[add="telephone"]').removeClass("disabled")
      }
    }

    const check_mob = (mob) => {
      if(mob == ""){
        $('div[role="add"]').find('a[add="mobile"]').addClass("disabled")
      }else{
        $('div[role="add"]').find('a[add="mobile"]').removeClass("disabled")
      }
    }

    const check_fax = (fax) => {
      if(fax == ""){
        $('div[role="add"]').find('a[add="fax"]').addClass("disabled")
      }else{
        $('div[role="add"]').find('a[add="fax"]').removeClass("disabled")
      }
    }

    let mob = $('div[role="add"]').find('input[name="account[mobile][]"]').val()
    check_mob(mob)

    let tel = $('div[role="add"]').find('input[name="account[telephone][]"]').val()
    check_tel(tel)

    let fax = $('div[role="add"]').find('input[name="account[fax][]"]').val()
    check_fax(fax)

    $('div[role="add"]').find('input[name="account[telephone][]"]').on('keyup', function(){
      let tel = $(this).val()
      check_tel(tel)
    })

    $('div[role="add"]').find('input[name="account[mobile][]"]').on('keyup', function(){
      let mob = $(this).val()
      check_mob(mob)
    })

    $('div[role="add"]').find('input[name="account[fax][]"]').on('keyup', function(){
      let fax = $(this).val()
      check_fax(fax)
    })

  });

  //Account > Show > Product > Custom
  var valArray = []
  $("input:checkbox").each(function () {
    var value = $(this).val();

    if(this.checked) {
      valArray.push(value);
    } else {
      var index = valArray.indexOf(value);

      if (index >= 0) {
        valArray.splice( index, 1)
      }
    }
    $('div[id="account_product_custom"]').find('input[name="account_product[product_ids]"]').val(valArray);
  });

  let valArray2 = []

  $("input:checkbox").on('change', function () {
    var value = $(this).val();

    if(this.checked) {
      valArray2.push(value);
    } else {
      var index = valArray2.indexOf(value);

      if (index >= 0) {
        valArray2.splice( index, 1)
      }
    }

    $('div[id="account_product_custom"]').find('input[name="account_product[product_ids]"]').val(valArray2);
  });

  $('div[name="modal_product_custom"]').on('click', function(){
    $('div[id="account_product_custom"]')
      .modal({
        autofocus: false
      })
      .modal('show');

    $('tr[role="row"]').removeAttr("style")
    $('.modals').on('mouseover', function(){
      $('tr[role="row"]').removeAttr("style")
    })
  })
  //Account > Show > Product > Standard


  const onlyUnique = (value, index, self) => {
    return self.indexOf(value) === index;
  }

  //Cluster Page Modal


// Suspend account in Cluster
  $('div[name="modal_suspension"]').on('click', function(){

    $('div[role="suspend_account"]').modal('show');
    var sd = new Date();
    var suspend_minDate = sd.getFullYear() + "/" + (sd.getMonth()+1) + "/" + (sd.getDate()+1);
    var temp_maxDate = "";


    if($(this).attr('CancelDate') == ""){
      temp_maxDate = $(this).attr('EndDate');
    }
    else{
      temp_maxDate = $(this).attr('CancelDate');
    }

    // previous day before the CANCEL DATE or ENDDATE
    var suspend_maxDate = new Date(temp_maxDate);
    var dayOfMonth = suspend_maxDate.getDate();
    suspend_maxDate.setDate(dayOfMonth - 1);

    $('#suspend_date_picker').calendar({
      type: 'date',
      monthFirst: false,
      endCalendar: $('#suspend_date_picker'),
      minDate: new Date(suspend_minDate),
      maxDate: new Date(suspend_maxDate),
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

    const cluster_id_suspend = $(this).attr('clusterID');
    const account_id_suspend = $(this).attr('accountID');
    const account_group_id_suspend = $(this).attr('AccountGroupID');
    const csrf_suspend = $('input[name="_csrf_token"]').val();
    const stats = $(this).attr('statusID');

  $.ajax({
  url:`/clusters/${cluster_id_suspend}/accounts/${account_id_suspend}/get_all_group_accounts`,
      headers: {"X-CSRF-TOKEN": csrf_suspend},
      type: 'get',
      success: function(response){
      let data3 = JSON.parse(response)

     // $('#modal_suspend').find('input[name="_csrf_token"]').val(csrf_suspend)

      $('#modal_suspend').find('#account_code_name').val(data3.account_group.code + '/' + data3.account_group.name)
      $('#modal_suspend').find('#account_start_date').val(data3.start_date)
      $('#modal_suspend').find('#account_end_date').val(data3.end_date)
      $('#modal_suspend').find('#account_status').text(data3.status)
      $('#modal_suspend').find('#cluster_status').val("Active")
      $('#modal_suspend').find('#cluster_account_id').val(account_id_suspend)
      $('#modal_suspend').find('#cluster_cluster_id').val(cluster_id_suspend)
      $('#modal_suspend').find('#cluster_account_group_id').val(account_group_id_suspend)
      },
      error: function(){
       window.location.href=`/clusters/${cluster_id_suspend}/accounts/${account_id_suspend}/get_all_group_accounts`;
      }
    });
  });



      // Submit button
      $('#btn_suspend_account_in_cluster').on('click', function(){
        const c_suspend_date = $('#modal_suspend').find('input[name="cluster[suspend_date]"]').val()
        const c_suspend_reason = $("#cluster_suspend_reason").find( "option:selected" ).prop("value");
        const c_suspend_account_name = $('#modal_suspend').find('#account_code_name').val()

        if(c_suspend_date == "" || c_suspend_reason == "")
        {
          $('#suspend').form({
          on: blur,
          inline: true,
          fields: {
            'cluster[suspend_date]': {
              identifier: 'cluster[suspend_date]',
              rules: [{
                type  : 'empty',
                prompt: 'Please enter suspension date'
              },
              ]
            },
            'cluster[suspend_reason]': {
              identifier: 'cluster[suspend_reason]',
              rules: [{
                type  : 'empty',
                prompt: 'Please enter suspension reason'
              },
              ]
            },
          }
          })
          $('#suspend').submit()
          e.preventDefault()
        }
        else
        {
          swal({
          title: 'Suspend Account',
          text: `Suspending this account (${c_suspend_account_name}) will temporarily remove all funtions on ${c_suspend_date}?`,
          type: 'question',
          showCancelButton: true,
          cancelButtonText: '<i class="remove icon"></i> No, keep account',
          confirmButtonText: '<i class="check icon"></i> Yes, suspend account',
          cancelButtonClass: 'ui negative button',
          confirmButtonClass: 'ui positive button',
          reverseButtons: true,
          buttonsStyling: false
          }).then(function () {
                    $('#suspend').submit()
                  })
        }
      })
      // End of Submit button
  // End of Suspend account in Cluster



  // Renew account in Cluster
  $('div[name="modal_renew"]').on('click', function(){

    $('div[role="cluster"]').modal('show');

    // Declarations
    let renew_start_date = $(this).attr('RenewStartDate');
    let renew_expiry_date = $(this).attr('RenewExpiryDate');

    let cluster_id = $(this).attr('clusterID');
    let account_id = $(this).attr('accountID');
    let account_group_id = $(this).attr('AccountGroupID');
    let status_account = $(this).attr('AccountStatus');
    let csrf2 = $('input[name="_csrf_token"]').val();
    var renewtoday = new Date();
    var renew_split_text = renew_expiry_date.split('-');

    let currentDate = new Date()
    let tomorrowsDate = currentDate.setDate(currentDate.getDate() + 1)
    let futureDate = currentDate.setDate(currentDate.getDate() + 2)
    let cur_end_date =  $('div[id="Renew"]').find('input[name="cluster[end_date]"]').val()

    if (cur_end_date != '' && cur_end_date != null) {
      tomorrowsDate = moment(cur_end_date).add(1, 'day').calendar();
    }

    if (status_account == "Active")
    {
      let _min_date_day = parseInt(renew_split_text[2]) + 1
      $('div[id="Renew"]').find('#rangestart').calendar({
        type: 'date',
        minDate: new Date(renew_split_text[0], renew_split_text[1] -1, _min_date_day),
        onChange: function (start_date, text, mode) {
          let start = new Date(start_date)
          let end_date = start.setDate(start.getDate() + 1)
          end_date = new Date(end_date)
          let start_date1 = start_date.setDate(start_date.getDate() -1)
          let new_end_date = moment(start_date1).add(1, 'year').calendar()
          new_end_date = moment(new_end_date).format("YYYY-MM-DD")
           $('div[id="Renew"]').find('input[name="cluster[end_date]"]').val(new_end_date)
           $('div[id="Renew"]').find('input[name="cluster[start_date]"]').val(moment(start_date.setDate(start_date.getDate() + 1)).format("YYYY-MM-DD"))

          $('div[id="Renew"]').find('#rangeend').calendar({
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
    }
    else
    {
       $('div[id="Renew"]').find('#rangestart').calendar({
        type: 'date',
        minDate: new Date(tomorrowsDate),
        onChange: function (start_date, text, mode) {
          let start = new Date(start_date)
          let end_date = start.setDate(start.getDate() + 1)
          end_date = new Date(end_date)
          let start_date1 = start_date.setDate(start_date.getDate() -1)
          let new_end_date = moment(start_date1).add(1, 'year').calendar()
          new_end_date = moment(new_end_date).format("YYYY-MM-DD")
           $('div[id="Renew"]').find('input[name="cluster[end_date]"]').val(new_end_date)
           $('div[id="Renew"]').find('input[name="cluster[start_date]"]').val(moment(start_date.setDate(start_date.getDate() + 1)).format("YYYY-MM-DD"))

          $('div[id="Renew"]').find('#rangeend').calendar({
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
    }

    $.ajax({

      url:`/clusters/${cluster_id}/accounts/${account_id}/get_all_group_accounts`,
      headers: {"X-CSRF-TOKEN": csrf2},
      type: 'get',
      success: function(response){
      let data2 = JSON.parse(response)

      $('div[id="Renew"]').find('#account_code_name').val(data2.account_group.code + '/' + data2.account_group.name)
       $('div[id="Renew"]').find('#account_start_date').val(data2.start_date)
      $('div[id="Renew"]').find('#account_end_date').val(data2.end_date)
      $('div[id="Renew"]').find('#account_status').text(data2.status)
      $('div[id="Renew"]').find('#cluster_status').val("Active")
      $('div[id="Renew"]').find('#cluster_account_id').val(account_id)
      $('div[id="Renew"]').find('#cluster_cluster_id').val(cluster_id)
      $('div[id="Renew"]').find('#cluster_account_group_id').val(account_group_id)
      },
      error: function(){
        window.location.href=`/clusters/${cluster_id}/accounts/${account_id}/get_all_group_accounts`;
      }
    })
  });

  $('#renew_account').on('click', function(e)
  {
    let effective_date = $('#Renew').find('input[name="cluster[start_date]"]').val()
    let expiry_date = $('#Renew').find('input[name="cluster[end_date]"]').val()
    let account_code_name = $('#Renew').find('#account_code_name').val()

    if(effective_date == "" || expiry_date == "")
    {
      $('#Renew')
      .form({
        on: blur,
        inline: true,
        fields: {
          'cluster[start_date]': {
            identifier: 'cluster[start_date]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter effectivity date.'
            }
            ]
          },
          'cluster[end_date]': {
            identifier: 'cluster[end_date]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter expiry date.'

            }
            ]
          }
        }
      })
      $('#renewal_account').submit()
      e.preventDefault()
    }
    else
    {
      swal({
      title: 'Renew Account?',
      type: 'question',
      showCancelButton: true,
      cancelButtonText: '<i class="remove icon"></i> No, Keep Account',
      confirmButtonText: '<i class="check icon"></i> Yes, Renew Account',
      cancelButtonClass: 'ui negative button',
      confirmButtonClass: 'ui positive button',
      reverseButtons: true,
      buttonsStyling: false
      }).then(function ()
      {
        $('#renewal_account').submit()
      })
    }

  })
  // End of Renew account in Cluster

  // Extend account in Cluster
  $('div[name="modal_extend_account_cluster"]').on('click', function(){
    $('div[role="extend"]').form('clear');
    $('div[id="message"]').remove();
    $('div[role="extend"]').modal('show');

    const cluster_id_extend = $(this).attr('clusterID');
    const account_id_extend = $(this).attr('accountID');
    const status_extend = $(this).attr('statusID');
    const csrf_extend = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/clusters/${cluster_id_extend}/accounts/${account_id_extend}/get_all_group_accounts`,
      headers: {"X-CSRF-TOKEN": csrf_extend},
      type: 'get',
      success: function(response){
      let data_extend = JSON.parse(response)
      $('#modal_extend').find('#account_code_name').val(data_extend.account_group.code + '/' + data_extend.account_group.name)
      $('#modal_extend').find('#account_start_date').val(data_extend.start_date)
      $('#modal_extend').find('#account_end_date').val(data_extend.end_date)
      $('#modal_extend').find('#account_status').text(data_extend.status)
      $('#modal_extend').find('#cluster_status').val("Active")
      $('#modal_extend').find('#cluster_account_id').val(account_id_extend)
      $('#modal_extend').find('#cluster_cluster_id').val(cluster_id_extend)
      $('#modal_extend').find('input[name="_csrf_token"]').val(csrf_extend)
      },
      error: function(){
        window.location.href=`/clusters/${cluster_id_extend}/accounts/${account_id_extend}/get_all_group_accounts`;
      }
    });

    //DatePicker
    $('#modal_extend').find('#new_end_date').calendar({
      type: 'date',
      monthFirst: false,
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

    //Validations
    $('#modal_extend').find('#extend_button').on('click', function(){
      const new_end_date = $('#modal_extend').find('input[name="cluster[end_date]"]').val();
      const old_end_date = $('#modal_extend').find('#account_end_date').val();

      $('#modal_extend').find('div[id="message"]').remove();

      $('#modal_extend').find('#cluster_end_date').on('click', function(){
        if($(this).find('input').val() != ""){
          $('#expiry_date').removeClass('error')
          $('div[id="message"]').remove()
        }
      });

      const error = '<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div> <ul class="list">'

      if(new_end_date == "")
      {
        $('p[role="append"]').append(error + '<li>New Expiry Date is Required.</li> </ul> </div>')
        $('#expiry_date').addClass('error')
      }
      else if(new_end_date <= old_end_date)
      {
        $('p[role="append"]').append(error + '<li>New expiry date must not be prior or same with the Current Expiry date.</li> </ul> </div>')
        $('#expiry_date').addClass('error')
      }
      else if(status_extend != "Active")
      {
        $('p[role="append"]').append(error + '<li>Account Status should be Active.</li> </ul> </div>')
      }
      else
      {
        swal({
          title: 'Extend Account?',
          type: 'question',
          showCancelButton: true,
          cancelButtonText: '<i class="remove icon"></i> No, keep account',
          confirmButtonText: '<i class="check icon"></i> Yes, extend account',
          cancelButtonClass: 'ui negative button',
          confirmButtonClass: 'ui positive button',
          reverseButtons: true,
          buttonsStyling: false
        }).then(function () {
          $('#extend_form').submit()
        }, function (dismiss) {
          if (dismiss === 'cancel') {
            $('#modal_extend').modal('hide')
          }
        })
      }
    });
  });

  // End of Extend account in Cluster

  // End of Cluster Page Modal

  //Account Page - Extend Account Modal
  $('div[name="modal_extend_account"]').on('click', function(){

    $('div[role="extend_account"]').modal('show');
    // Declarations
    let extend_account_id = $(this).attr('ExtendAccountID');
    let extend_account_group_id = $(this).attr('ExtendAccountGroupID');
    let extend_account_group_name = $(this).attr('ExtendAccountName');
    let extend_account_group_code = $(this).attr('ExtendAccountCode');
    let extend_account_end_date = $(this).attr('ExtendAccountEndDate');
    let extend_account_status = $(this).attr('ExtendAccountStatus');

    let csrfextend_account = $('input[name="_csrf_token"]').val();
    var today = new Date();
    var split_text = extend_account_end_date.split('-');

    //Form Validation
    $('#modal_extend_account')
    .form({
      inline : true,
      on     : 'blur',
      fields: {
        'account[end_date]': {
          identifier: 'account[end_date]',
          rules: [
            {
              type   : 'empty',
              prompt : 'Please enter new expiry date'
            }
          ]
        }
      }
    });

    // Status Checker
    if(extend_account_status != "Active"){
      $('button[id="extend_account"]').attr('disabled', 'disabled')
    }

    // Datepicker
    let extended_date = parseInt(split_text[2])+1
    $('div[id="expirydatepicker"]').calendar({
      monthFirst: false,
      type: 'date',
      minDate: new Date(split_text[0], split_text[1] - 1, extended_date),
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
    // End of Datepicker

    $.ajax({

      url:`/api/v1/accounts/${extend_account_id}/get_an_account`,
      headers: {"X-CSRF-TOKEN": csrfextend_account},
      type: 'get',
      success: function(response){
        let extend_account_data = JSON.parse(response)

        $('#extend').find('#account_account_group_id').val(extend_account_group_id)
        $('#extend').find('input[name="account[account_id]"]').val(extend_account_id)
      },
      error: function(){
        window.location.href=`/accounts/${extend_account_id}`;
      }
    })

    $('#extend_account').on('click', function(){
      const extend_end_date = $('input[name="account[end_date]"]').val()
      $('div[id="message"]').remove()

      $('#account_end_date').on('click', function(){
        if($(this).find('input').val() != ""){
         $('#date_end').removeClass('error')
         $('div[id="message"]').remove()
        }
      })

      if(extend_end_date == "")
      {
         $('p[role="append"]').append('<div id="message" class="ui negative message"><ul class="list"> <li>Please enter new expiry date.</li> </ul> </div>')
         $('#date_end').addClass('error')
      }
      else
      {
      swal({
        title: 'Extend Account?',
        type: 'question',
        showCancelButton: true,
        cancelButtonText: '<i class="remove icon"></i> No, keep account',
        confirmButtonText: '<i class="check icon"></i> Yes, extend account',
        cancelButtonClass: 'ui negative button',
        confirmButtonClass: 'ui positive button',
        reverseButtons: true,
        buttonsStyling: false
      }).then(function () {
        $('#extend').submit()

      })
      }
    })
    $('input[name="account[end_date]"]').on('click', function(){
      $('p[role="append"]').remove()
    })
  });

  //End of Account Page - Extend Account Modal

  // Account Page - Suspend Account Modal
  $('div[name="modal_suspend_account"]').on('click', function(){

    $('div[role="suspend_account_in_account"]').modal('show');
    var spd = new Date();
    var suspend_minDate = spd.getFullYear() + "/" + (spd.getMonth()+1) + "/" + (spd.getDate()+1);
    var temp_maxDate = "";


    if($(this).attr('SuspendAccountCancelDate') == ""){
      temp_maxDate = $(this).attr('SuspendAccountEndDate');
    }
    else{
      temp_maxDate = $(this).attr('SuspendAccountCancelDate');
    }

    // previous day before the CANCEL DATE or ENDDATE
    var suspend_maxDate = new Date(temp_maxDate);
    var dayOfMonth = suspend_maxDate.getDate();
    suspend_maxDate.setDate(dayOfMonth - 1);

    // Date Picker
    $('#modal_suspend_in_account').find('#account_suspend_date_picker').calendar({
      type: 'date',
      monthFirst: false,
      endCalendar: $('#account_suspend_date_picker'),
      minDate: new Date(suspend_minDate),
      maxDate: new Date(suspend_maxDate),
      formatter: {
        date: function (date, settings) {
          if (!date) return '';

          var suspend_day = date.getDate() + '';
          if (suspend_day.length < 2) {
              suspend_day = '0' + suspend_day;
          }

          var suspend_month = (date.getMonth() + 1) + '';
          if (suspend_month.length < 2) {
              suspend_month = '0' + suspend_month;
          }

          var suspend_year = date.getFullYear();
          return suspend_year + '-' + suspend_month + '-' + suspend_day;
        }
      }
    });
    // End of Date Picker

    const suspend_account_id = $(this).attr('SuspendAccountID');
    const suspend_account_group_id = $(this).attr('SuspendAccountGroupID');
    const suspend_account_group_name = $(this).attr('SuspendAccountName');
    const suspend_account_group_code = $(this).attr('SuspendAccountCode');
    const suspend_account_end_date = $(this).attr('SuspendAccountEndDate');
    const csrfsuspend_account = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/api/v1/accounts/${suspend_account_id}/get_an_account`,
      headers: {"X-CSRF-TOKEN": csrfsuspend_account},
      type: 'get',
      success: function(response){
        let suspend_data = JSON.parse(response)
        $('#modal_suspend_in_account').find('#account_code_name').val(suspend_data.account_group.code + '/' + suspend_data.account_group.name)
        $('#modal_suspend_in_account').find('#account_start_date').val(suspend_data.start_date)
        $('#modal_suspend_in_account').find('#account_end_date').val(suspend_data.end_date)
        $('#modal_suspend_in_account').find('#account_status_text').text(suspend_data.status)
        $('#modal_suspend_in_account').find('#account_status').val("Active")
        $('#modal_suspend_in_account').find('#account_account_id').val(suspend_account_id)
        $('#modal_suspend_in_account').find('#account_account_group_id').val(suspend_account_group_id)
      },
      error: function(){
        window.location.href=`/accounts/${suspend_account_id}`;
      }
    })
  });


  // Submit button
  $('#suspend_account').on('click', function(){
    const a_suspend_date = $('#modal_suspend_in_account').find('input[name="account[suspend_date]"]').val()
    const a_suspend_reason = $("#account_suspend_reason").find( "option:selected" ).prop("value");
    const a_suspend_account_name = $('#modal_suspend_in_account').find('#account_code_name').val()

    if(a_suspend_date == "" || a_suspend_reason == "")
    {
     $('#suspend').form({
        on: blur,
        inline: true,
        fields: {
          'account[suspend_date]': {
            identifier: 'account[suspend_date]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter suspension date'
            },
            ]
          },
          'account[suspend_reason]': {
            identifier: 'account[suspend_reason]',
            rules: [{
              type  : 'empty',
              prompt: 'Please enter suspension reason'
            },
            ]
          },
        }
      })
      $('#suspend').submit()
      e.preventDefault()
    }
    else
    {
      swal({
      title: 'Suspend Account?',
      text: `Account ${a_suspend_account_name} will be suspended on ${a_suspend_date}?`,
      type: 'question',
      showCancelButton: true,
      cancelButtonText: '<i class="remove icon"></i> No, keep account',
      confirmButtonText: '<i class="check icon"></i> Yes, suspend account',
      cancelButtonClass: 'ui negative button',
      confirmButtonClass: 'ui positive button',
      reverseButtons: true,
      buttonsStyling: false
      }).then(function ()
      {
        $('#suspend').submit()
      })
    }

  })
  // End of Submit button

  // End of Account Page - Suspend Modal


  // Account Page - Reactivate Modal
  $('div[name="modal_reactivate_account"]').on('click', function(){
    $('div[role="reactivate_account_in_account"]').form('reset');
    $('div[role="reactivate_account_in_account"]').modal('show');
    var rd = new Date();
    var reactivate_minDate = rd.getFullYear() + "/" + (rd.getMonth()+1) + "/" + (rd.getDate()+1);
    var temp_reactivate_maxDate = "";

    if($(this).attr('ReactivateAccountCancelDate') == ""){
      temp_reactivate_maxDate = $(this).attr('ReactivateAccountEndDate');

    }
    else{
      temp_reactivate_maxDate = $(this).attr('ReactivateAccountCancelDate');
    }

    // previous day before the CANCEL DATE or ENDDATE
    var reactivate_maxDate = new Date(temp_reactivate_maxDate);
    var dayOfMonth = reactivate_maxDate.getDate();
    reactivate_maxDate.setDate(dayOfMonth - 1);

    let reactivate_account_start_date = $(this).attr('ReactivateAccountStartDate');
    let r_a_s_d = new Date(reactivate_account_start_date)

    if(rd.getTime() >= r_a_s_d.getTime()){
      let tomorrowsDate = rd.setDate(rd.getDate() + 1)
      reactivate_account_start_date = new Date(tomorrowsDate)
    }

    // Date Picker
    $('#modal_reactivate_in_account').find('#account_reactivate_date_picker').calendar({
      type: 'date',
      monthFirst: false,
      endCalendar: $('#account_reactivate_date_picker'),
      minDate: new Date(reactivate_account_start_date),
      maxDate: new Date(temp_reactivate_maxDate),
      formatter: {
        date: function (date, settings) {
          if (!date) return '';

          var reactivate_day = date.getDate() + '';
          if (reactivate_day.length < 2) {
              reactivate_day = '0' + reactivate_day;
          }

          var reactivate_month = (date.getMonth() + 1) + '';
          if (reactivate_month.length < 2) {
              reactivate_month = '0' + reactivate_month;
          }

          var reactivate_year = date.getFullYear();
          return reactivate_year + '-' + reactivate_month + '-' + reactivate_day;
        }
      }
    });
    // End of Date Picker

    const reactivate_account_end_date = $(this).attr('ReactivateAccountEndDate');
    const reactivate_account_id = $(this).attr('ReactivateAccountID');
    const reactivate_account_group_id = $(this).attr('ReactivateAccountGroupID');
    const reactivate_account_group_name = $(this).attr('ReactivateAccountName');
    const reactivate_account_group_code = $(this).attr('ReactivateAccountCode');
    const csrfreactivate_account = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/api/v1/accounts/${reactivate_account_id}/get_an_account`,
      headers: {"X-CSRF-TOKEN": csrfreactivate_account},
      type: 'get',
      success: function(response){
        let reactivate_data = JSON.parse(response)
        $('#modal_reactivate_in_account').find('#account_code_name').val(reactivate_data.account_group.code + '/' + reactivate_data.account_group.name)
        $('#modal_reactivate_in_account').find('#account_start_date').val(reactivate_data.start_date)
        $('#modal_reactivate_in_account').find('#account_end_date').val(reactivate_data.end_date)
        $('#modal_reactivate_in_account').find('#account_status_text').text(reactivate_data.status)
        $('#modal_reactivate_in_account').find('#account_status').val("Suspended")
        $('#modal_reactivate_in_account').find('#account_account_id').val(reactivate_account_id)
        $('#modal_reactivate_in_account').find('#account_account_group_id').val(reactivate_account_group_id)
      },
      error: function(){
       // window.location.href=`/accounts/${reactivate_account_id}`;
        window.location.href=`/api/v1/accounts/${reactivate_account_id}/get_an_account`;
      }
    })
  });

  // Submit Button
        $('#reactivate_account').on('click', function(e){

        const ac_reactivate_date = $('#modal_reactivate_in_account').find('input[name="account[reactivate_date]"]').val()
        const remarks = $('#modal_reactivate_in_account').find('input[name="account[reactivate_remarks]"]').val()
        const ac_reactivate_account_name = $('#modal_reactivate_in_account').find('#account_code_name').val()
        //console.log(ac_reactivate_account_name)
        //         console.log(ac_reactivate_date)
        $('div[id="message_reactivate"]').remove()

        $('#account_reactivate_date').on('click', function(){
          if($(this).find('input').val() != ""){
          $('#reactivate_date').removeClass('error')
          $('div[id="message_reactivate"]').remove()
          }
        })

      const swal_reactivate = (val) => {
        let title, text, cancel, confirm_text

        if (val == "Account"){
          title = 'Submit Account Reactivation'
          text = `Account ${ac_reactivate_account_name} will be reactivate on ${ac_reactivate_date}?`
          cancel = '<i class="remove icon"></i> No'
          confirm_text =  '<i class="check icon"></i> Yes'
        }else{
          title = 'Reactivate'
          text = ''
          cancel = '<i class="remove icon"></i> No, keep account'
          confirm_text =  '<i class="check icon"></i> Yes, reactivate account'
        }

        swal({
          title: title,
          text: text,
          type: 'question',
          showCancelButton: true,
          cancelButtonText: cancel,
          confirmButtonText: confirm_text,
          cancelButtonClass: 'ui negative button',
          confirmButtonClass: 'ui positive button',
          reverseButtons: true,
          buttonsStyling: false
        }).then(function ()
        {
          $('#reactivate').submit()
        })
      }


       if ($(this).attr("role") == "Account"){
        if(ac_reactivate_date == ""){
          $('#reactivate').form({
            on: blur,
            inline: true,
            fields: {
              'account[reactivate_date]': {
                identifier: 'account[reactivate_date]',
                rules: [{
                  type  : 'empty',
                  prompt: 'Please enter Reactivation date'
                },
                ]
              },
            }
          })
          $('#reactivate').submit()
          e.preventDefault()
        }else{
           swal_reactivate("Account")
        }
       } else {
        if(ac_reactivate_date == ""){
          $('#reactivate').form({
            on: blur,
            inline: true,
            fields: {
              'account[reactivate_date]': {
                identifier: 'account[reactivate_date]',
                rules: [{
                  type  : 'empty',
                  prompt: 'Please enter Reactivation date'
                },
                ]
              },
            }
          })
          $('#reactivate').submit()
          e.preventDefault()
        }else{
           swal_reactivate("Cluster")
        }
       }

      })
  // End of Submit Button



  // End of Account Page - Reactivate Modal


  $('div[name="edit_modal_acc_product"]').on('click', function(){
    const account_id = $(this).attr('accountID');
    const account_product_id = $(this).attr('AccountProductID');
    const csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/accounts/${account_product_id}/get_account_product`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        const data =  JSON.parse(response)

        $('#account_product_name').val(data.name)
        $('#account_product_account_product_id').val(account_product_id)
        $('#account_product_description').val(data.description)
        $('#account_product_limit_amount').val(data.limit_amount)
        $('#account_product_type').val(data.type).change();
        $('input[name="account_product[limit_applicability]"][value="' + data.limit_applicability + '"]').prop('checked', true);
        $('input[name="account_product[limit_type]"][value="' + data.limit_type + '"]').prop('checked', true);
        $('input[name="account_product[status]"][value="' + data.status + '"]').prop('checked', true);
        $('input[name="account_product[standard_product]"][value="' + data.standard_product + '"]').prop('checked', true);
        $('div[id="edit_account_product"]').modal('show');
      },
      error: function(){
        window.location.href=`/accounts/${account_id}/edit?step=5`;
      }
    })

  });

  $('button[name="modal_schedule"]').on('click', function(){
    $('div[role="add-schedule"]').form('reset');
    $('div[role="add-schedule"]').modal('show');
  });
});

onmount('div[role="edit"]', function(){
   const to_string_date = (date) => {
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

  $('a[name="edit_modal_contact"]').on('click', function(){
    $('div[role="edit"]').form('reset');
    $('div[role="edit"]').modal('show');
    $('div[id="example13"]').calendar();
    $('div[id="example13"]').calendar({
      monthFirst: false,
      type: 'date',
      maxDate: new Date(),
      formatter: {
        date: function (date, settings) {
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

    $('p[error="select"]').hide();
    $('p[error="number"]').hide();
    $('div[role="edit-form-telephone"]').remove(); // remove div
    $('div[role="edit-form-mobile"]').remove(); // remove div
    $('div[role="edit-form-fax"]').remove(); // remove div
    $('input[indexT="0"]').val("");
    $('input[indexM="0"]').val("");
    $('input[indexF="0"]').val("");

    let account_id = $(this).attr('accountID');
    let contact_id = $(this).attr('contactID');
    let csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/accounts/${contact_id}/get_contact`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let data = JSON.parse(response);
        let selector = 'div[role="edit"]';
        $(selector).find('#account_contact_id').val(contact_id);
        $(selector).find('.ui.dropdown.selection select').val(data.type).change();
        $(selector).find('#account_last_name').val(data.last_name);
        $(selector).find('#account_department').val(data.department);
        $(selector).find('#account_designation').val(data.designation);
        $(selector).find('#account_email').val(data.email);
        $(selector).find('#account_ctc').val(data.ctc);
        $(selector).find('#account_ctc_place_issued').val(data.ctc_place_issued);
        $(selector).find('#account_passport_no').val(data.passport_no);
        $(selector).find('#account_passport_place_issued').val(data.passport_place_issued);

        if(data.ctc_date_issued == null || data.ctc_date_issued == ""){
          let ctc_date = data.ctc_date_issued
        } else {
          let ctc_date = new Date(data.ctc_date_issued)
          ctc_date = to_string_date(ctc_date)
          $(selector).find('#account_ctc_date_issued').val(ctc_date);
        }

        if(data.passport_date_issued == null || data.passport_date_issued == ""){
          let passport_date = data.passport_date_issued
        } else {
          let  passport_date = new Date(data.passport_date_issued)
          passport_date = to_string_date(passport_date)
          $(selector).find('#account_passport_date_issued').val(passport_date);
        }

        //contact number
        for(let i=0; i < data.phones.length; i++){
          if(data.phones[i].type == "telephone"){

            if($('input[indexT="0"]').val() == ""){
              $(selector).find('input[indexT="0"]').val(data.phones[i].number).change();
              $(selector).find('input[indexTCC="0"]').val(data.phones[i].country_code).change();
              $(selector).find('input[indexTAC="0"]').val(data.phones[i].area_code).change();
              $(selector).find('input[indexTL="0"]').val(data.phones[i].local).change();
            }else{
              let telephone = data.phones[i].number
              let country = data.phones[i].country_code
              let area = data.phones[i].area_code
              let local = data.phones[i].local
              let telHtml = $('div[role="edit-telephone"]').html();
              let tel = `<div class="fields" role="edit-form-telephone" id="edit-tel" telindex="${i}">${telHtml}</div>`

              added_fields(i, telephone, tel, "telephone", "tel", country, area, local)
            }
          }
          if(data.phones[i].type == "mobile"){
            if($('input[indexM="0"]').val() == ""){
              $(selector).find('input[indexM="0"]').val(data.phones[i].number).change();
              $(selector).find('input[indexMCC="0"]').val(data.phones[i].country_code).change();
            }else{
              let mobile = data.phones[i].number
              let country = data.phones[i].country_code
              let area = data.phones[i].area_code
              let local = data.phones[i].local
              let mobHtml = $('div[role="edit-mobile"]').html();
              let mob = `<div class="fields" role="edit-form-mobile" id="edit-mob" mobindex="${i}">${mobHtml}</div>`

              added_fields(i, mobile, mob, "mobile", "mob", country, area, local)
            }
          }
          if(data.phones[i].type == "fax"){
            if($('input[indexF="0"]').val() == ""){
              $(selector).find('input[indexF="0"]').val(data.phones[i].number);
              $(selector).find('input[indexFCC="0"]').val(data.phones[i].country_code).change();
              $(selector).find('input[indexFAC="0"]').val(data.phones[i].area_code).change();
              $(selector).find('input[indexFL="0"]').val(data.phones[i].local).change();
            }else{
              let fax_val = data.phones[i].number;
              let country = data.phones[i].country_code
              let area = data.phones[i].area_code
              let local = data.phones[i].local
              let faxHtml = $('div[role="edit-fax"]').html();
              let fax = `<div class="fields" role="edit-form-fax" id="edit-fax" faxindex="${i}">${faxHtml}</div>`

              added_fields(i, fax_val, fax, "fax", "fax", country, area, local)
            }
          }
        }

        const check_tel = (tel) => {
          if(tel == ""){
            $(selector).find('a[add="editTelephone"]').addClass("disabled")
          }else{
            $(selector).find('a[add="editTelephone"]').removeClass("disabled")
          }
        }

        const check_mob = (mob) => {
          if(mob == ""){
            $(selector).find('a[add="editMobile"]').addClass("disabled")
          }else{
            $(selector).find('a[add="editMobile"]').removeClass("disabled")
          }
        }

        const check_fax = (fax) => {
          if(fax == ""){
            $(selector).find('a[add="editFax"]').addClass("disabled")
          }else{
            $(selector).find('a[add="editFax"]').removeClass("disabled")
          }
        }

        let mob = $(selector).find('input[name="account[mobile][]"]').val()
        check_mob(mob)

        let tel = $(selector).find('input[name="account[telephone][]"]').val()
        check_tel(tel)

        let fax = $(selector).find('input[name="account[fax][]"]').val()
        check_fax(fax)

        $(selector).find('input[name="account[telephone][]"]').on('keyup', function(){
          let tel = $(this).val()
          check_tel(tel)
        })

        $(selector).find('input[name="account[mobile][]"]').on('keyup', function(){
          let mob = $(this).val()
          check_mob(mob)
        })

        $(selector).find('input[name="account[fax][]"]').on('keyup', function(){
          let fax = $(this).val()
          check_fax(fax)
        })

      },
      error: function() {
        window.location.href=`/accounts/${account_id}/setup?step=3`;
      },
    });
  });

  $('a[add="editTelephone"]').on('click', function(){
    telephone();
    $('div[role="edit-form-telephone"]').on('click', 'a[remove="tel"]', function(e) {
      $(this).closest('div[role="edit-form-telephone"]').remove();
    });
  });

  $('a[add="editMobile"]').on('click', function(){
    mobile();
    $('div[role="edit-form-mobile"]').on('click', 'a[remove="mob"]', function(e) {
      $(this).closest('div[role="edit-form-mobile"]').remove();
    });
  });

  $('a[add="editFax"]').on('click', function(){
    fax();
    $('div[role="edit-form-fax"]').on('click', 'a[remove="fax"]', function(e) {
      $(this).closest('div[role="edit-form-fax"]').remove();
    });
  });

  let telephone = () => {
    let telHtml = $('div[role="form-telephone"]').html();
    let tel = `<div class="fields" role="edit-form-telephone" id="edit-tele">${telHtml}</div>`

    $('p[edit="append-telephone"]').append(tel);
    $('div[id="edit-tele"]').find('a').removeAttr("add");
    $('div[id="edit-tele"]').find('a').removeAttr("class");
    $('div[id="edit-tele"]').find('a').attr("remove", "tel");
    $('div[id="edit-tele"]').find('a').attr("class", "ui icon red button");
    $('div[id="edit-tele"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="edit-tele"]').find('label').remove();

    let Inputmask = require('inputmask');
    let phone = new Inputmask("999-9999", { "clearIncomplete": true})

    let area_local = new Inputmask("numeric", {
      allowMinus:false,
      rightAlign: false
    });
    area_local.mask($('.area_and_local'));
    phone.mask($('.phone'));

    number_input()
    validate_length()
  }

  let mobile = () => {
    let mobc = parseInt($('p[edit="append-mobile"]').attr('mobc')) + 1
    let edit_mob = "edit_mob" + mobc

    let mobHtml = $('div[role="form-mobile"]').html();
    let mob = `<div class="fields" role="edit-form-mobile" id="${edit_mob}">${mobHtml}</div>`

    $('p[edit="append-mobile"]').append(mob);
    $('p[edit="append-mobile"]').attr("mobc", mobc)
    $(`div[id="${edit_mob}"]`).find('a').removeAttr("add");
    $(`div[id="${edit_mob}"]`).find('a').removeAttr("class");
    $(`div[id="${edit_mob}"]`).find('a').attr("remove", "mob");
    $(`div[id="${edit_mob}"]`).find('a').attr("class", "ui icon red button");
    $(`div[id="${edit_mob}"]`).find('a').html(`<i class="icon trash"></i>`);
    $(`div[id="${edit_mob}"]`).find('label').remove();

    let Inputmask = require('inputmask');
    let im = new Inputmask("\\999-999-9999", { "clearIncomplete": true});
    im.mask($(`div[id="${edit_mob}"]`).find('.mobile'));

    number_input()
    validate_length()
  }

  let fax = () => {
    let faxHtml = $('div[role="form-fax"]').html();
    let fax = `<div class="fields" role="edit-form-fax" id="edit-fax">${faxHtml}</div>`

    $('p[edit="append-fax"]').append(fax);
    $('div[id="edit-fax"]').find('a').removeAttr("add");
    $('div[id="edit-fax"]').find('a').removeAttr("class");
    $('div[id="edit-fax"]').find('a').attr("remove", "fax");
    $('div[id="edit-fax"]').find('a').attr("class", "ui icon red button");
    $('div[id="edit-fax"]').find('a').html(`<i class="icon trash"></i>`);
    $('div[id="edit-fax"]').find('label').remove();

    let Inputmask = require('inputmask');
    let phone = new Inputmask("999-9999", { "clearIncomplete": true})

    let area_local = new Inputmask("numeric", {
      allowMinus:false,
      rightAlign: false
    });
    area_local.mask($('.area_and_local'));
    phone.mask($('.phone'));

    number_input()
    validate_length()
  }

  let added_fields = (i, val, html, type, remove, country, area, local) => {
    let div_selector = 'div['+ remove +'index="'+ i +'"]';

    $('p[edit="append-'+ type +'"]').append(html);
    // $(div_selector).find('input').attr("index_no", i);
    // $(div_selector).find('input[index_no="'+ i +'"]').val(val);
    if (type == "telephone") {
      $(div_selector).find('input[indexT="0"]').val(val);
      $(div_selector).find('input[indexTCC="0"]').val(country);
      $(div_selector).find('input[indexTAC="0"]').val(area);
      $(div_selector).find('input[indexTL="0"]').val(local);
    }
    else if (type == "mobile") {
      $(div_selector).find('input[indexM="0"]').val(val);
      $(div_selector).find('input[indexMCC="0"]').val(country);
    }
    else if (type == "fax") {
      $(div_selector).find('input[indexF="0"]').val(val);
      $(div_selector).find('input[indexFCC="0"]').val(country);
      $(div_selector).find('input[indexFAC="0"]').val(area);
      $(div_selector).find('input[indexFL="0"]').val(local);
    }
    $(div_selector).find('a').removeAttr("add");
    $(div_selector).find('a').removeAttr("class");
    $(div_selector).find('a').attr("remove", remove);
    $(div_selector).find('a').attr("class", "ui icon red button");
    $(div_selector).find('a').html(`<i class="icon trash"></i>`);
    $(div_selector).find('label').remove();

    $('div[role="edit-form-'+ type + '"]').on('click', 'a[remove="'+ remove +'"]', function(e) {
      $(this).closest('div[role="edit-form-'+ type + '"]').remove();
    });

    let Inputmask = require('inputmask');
    let im = new Inputmask("\\999-999-9999", { "clearIncomplete": true});
    let phone = new Inputmask("999-9999", { "clearIncomplete": true})
    im.mask($(div_selector).find('.mobile'));

    let area_local = new Inputmask("numeric", {
      allowMinus:false,
      rightAlign: false
    });
    area_local.mask($('.area_and_local'));
    phone.mask($('.phone'));

    number_input()
    validate_length()
  }

  let validate_length = () => {
    $('input[id="contact"]').on('focusout', function(){
      $(this).each(function(){
        if ($(this).val().length >= $(this).attr("minlength")) {
          $(this).next('p[role="validate"]').hide();
        }
      })
    });
  }

  let number_input = () => {
    $('input[type="number"]').on('keypress', function(evt){
      let theEvent = evt || window.event;
      let key = theEvent.keyCode || theEvent.which;
      key = String.fromCharCode( key );
      let regex = /[a-zA-Z``~<>^'{}[\]\\;':",./?!@#$%&*()_+=-]|\./;
      let min = $(this).attr("minlength")

      if( regex.test(key) ) {
        theEvent.returnValue = false;
        if(theEvent.preventDefault) theEvent.preventDefault();
      }else{
        if($(this).val().length >= $(this).attr("maxlength")){
          $(this).next('p[role="validate"]').hide();
          $(this).on('keyup', function(evt){
            if(evt.keyCode == 8){
              $(this).next('p[role="validate"]').show();
            }
          })
          return false;
        }else if( min > $(this).val().length){
          $(this).next('p[role="validate"]').show();
          $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
        }
        else{
          $(this).next('p[role="validate"]').hide();
          $(this).val($(this).val().charAt(0).toUpperCase() + $(this).val().slice(1))
        }
      }
    })
  }

});


// Cancel account in Cluster
  $('div[name="modal_cancel"]').on('click', function(){

    $('div[role="cancel_account"]').modal('show');

    const cluster_id_cancel = $(this).attr('clusterID');
    const cluster_date_suspend = $(this).attr('SuspendDate')
    const account_id_cancel = $(this).attr('AccountID');
    const csrf_cancel = $('input[name="_csrf_token"]').val();
    const status = $(this).attr('statusID');

  $.ajax({
  url:`/clusters/${cluster_id_cancel}/accounts/${account_id_cancel}/get_all_group_accounts`,
      headers: {"X-CSRF-TOKEN": csrf_cancel},
      type: 'get',
      success: function(response){
      let data4 = JSON.parse(response)

      $('#cancel').find('#account_code').val(data4.account_group.code)
      $('#cancel').find('#account_name').val(data4.account_group.name)
      $('#cancel').find('#account_start_date').val(data4.start_date)
      $('#cancel').find('#account_end_date').val(data4.end_date)
      $('#cancel').find('#account_status').text(data4.status)
      $('#cancel').find('#cluster_status').val("Cancelled")
      $('#cancel').find('#cluster_account_id').val(account_id_cancel)
      $('#cancel').find('#cluster_cluster_id').val(cluster_id_cancel)

      let currentDate = new Date()
      let endDate = new Date(data4.end_date)
      let suspendDate = new Date(cluster_date_suspend)
      if (suspendDate == "Invalid Date") {
        currentDate = currentDate.setDate(currentDate.getDate() + 1)
      } else {
        currentDate = suspendDate.setDate(suspendDate.getDate() + 1)
      }
      endDate = endDate.setDate(endDate.getDate() - 1)

      $('div[id="cancelDatePicker"]').calendar({
        monthFirst: false,
        type: 'date',
        minDate: new Date(currentDate),
        maxDate: new Date(endDate),
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
      error: function(){
       window.location.href=`/clusters/${cluster_id_cancel}/accounts/${account_group_id_cancel}/${account_id_cancel}/get_all_group_accounts`;
      }
    });
  });
      // Submit button
      $('#btn_cancel_account_in_cluster').on('click', function(){

        $('#cancel_form')
        .form({
          inline : true,
          fields: {
            'cluster[cancel_reason]': {
              identifier: 'cluster[cancel_reason]',
              rules: [
                {
                  type   : 'empty',
                  prompt : 'Please enter reason'
                }
              ]
            },
            'cluster[cancel_date]': {
              identifier: 'cluster[cancel_date]',
              rules: [
                {
                  type   : 'empty',
                  prompt : 'Please enter cancellation date'
                }
              ]
            }
          }
        })

        if(($('#cancel_date').val() != "") && ($('#cancel_reason').val() != "")){
          let cancellation_date = new Date($('#cancel_date').val())
          let cancelDate = moment(cancellation_date).format('MMMM DD, YYYY')
          swal({
            title: 'Cancel Account?',
            text: `Canceling this account will permanently remove all functions on ${cancelDate}`,
            type: 'warning',
            showCancelButton: true,
            cancelButtonText: '<i class="remove icon"></i> No, keep account',
            confirmButtonText: '<i class="check icon"></i> Yes, cancel account',
            cancelButtonClass: 'ui negative button',
            confirmButtonClass: 'ui positive button',
            reverseButtons: true,
            buttonsStyling: false
          }).then(function ()
            {
              if($('#cancel_remarks').val() == ""){
                $('#cancel_remarks').val("None")
              }
              $('#cancel_form').submit()
            })
        }
        else{
          addValidationErrors()
        }

        function addValidationErrors() {
          if(($('#cancel_reason').val() == "")){
            $('#cancel_form').form('add prompt', 'cluster[cancel_reason]', 'Please enter reason for cancellation')
          }
          if(($('#cancel_date').val() == "")){
            $('#cancel_form').form('add prompt', 'cluster[cancel_date]', 'Please enter cancellation date')
          }
        }
      })
  // End of Cancel account in Cluster

//Cancel Account in Account Page
onmount('div[id="modal_cancel_account"]', function () {
  $(this).modal('attach events', '#modal_cancel_button', 'show');
  $('#confirm_cancel_modal').modal('attach events', '#confirm_cancel_account', 'show');

  let start_date = new Date($('b[role="account_effectivity"]').html())
  let min_date = start_date.setDate(start_date.getDate() + 1)
  let end_date = new Date($('b[role="account_expiry"]').html())
  let max_date = end_date.setDate(end_date.getDate())

  // Datepicker
  $('div[id="cancelDatePicker"]').calendar({
    onthFirst: false,
    type: 'date',
    minDate: new Date(min_date),
    maxDate: new Date(max_date),
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
  // End of Datepicker

  $('#modal_cancel_account')
  .form({
    inline : true,
    fields: {
      'cancel_account[cancel_reason]': {
        identifier: 'cancel_account[cancel_reason]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please select reason for cancellation'
          }
        ]
      },
      'cancel_account[cancel_date]': {
        identifier: 'cancel_account[cancel_date]',
        rules: [
          {
            type   : 'empty',
            prompt : 'Please enter cancellation date'
          }
        ]
      }
    }
  })

  $('#confirm_cancel_account').on('click', function()
  {
    if(($('#cancel_account_cancel_reason').val() != "") && ($('#cancel_account_cancel_date').val() != ""))
    {
      let cancellation_date = $('#cancel_account_cancel_date').val()
      swal({
        title: 'Cancel Account?',
        text: `Canceling this account will permanently remove all functions on ${cancellation_date}`,
        type: 'warning',
        showCancelButton: true,
        cancelButtonText: '<i class="remove icon"></i> No, keep account',
        confirmButtonText: '<i class="check icon"></i> Yes, cancel account',
        cancelButtonClass: 'ui negative button',
        confirmButtonClass: 'ui positive button',
        reverseButtons: true,
        buttonsStyling: false
      }).then(function () {
        $('#form_cancel_account').submit()
      })
    }
    else
    {
      addValidationErrors()
    }
  })

  function addValidationErrors() {
    if(($('#cancel_account_cancel_reason').val() == "")){
      $('#modal_cancel_account').form('add prompt', 'cancel_account[cancel_reason]', 'Please select reason for cancellation')
    }

    if(($('#cancel_account_cancel_date').val() == "")){
      $('#modal_cancel_account').form('add prompt', 'cancel_account[cancel_date]', 'Please enter cancellation date')
    }
  }

});

// Account > Financial > Approval Modal
onmount('div[role="financial"]', function(){
  $('a[name="approver"]').on('click', function(e){
    $('div[role="add-approval"]').modal('show')

    const account_group_id = $(this).attr('accountGroupID');
    const csrf = $('input[name="_csrf_token"]').val();

    $.ajax({
      url:`/accounts/${account_group_id}/on_click_update`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'post',
      data: {params: $('#financial').serializeArray().reduce(function(m,o){ m[o.name] = o.value; return m;}, {})},
      success: function(response){
      },
      error: function(){
      }
    })

    clearForm()
    e.preventDefault()
  })

  const clearForm = () => {
    $('div[role="add-approval"]').find(':input').not(':button, :submit, :reset, :hidden, :checkbox, :radio').val('');
    $('div[role="add-approval"]').find(':checkbox, :radio').prop('checked', false);
  }
})

onmount('div[id="facility_procedure"]', function(){

  $('#remove_procedure').on('click', function(){
    let f_id = $(this).attr('facility_id')
    let fpp_id = $(this).attr('fpp_id')
		swal({
		  title: 'Remove Procedure',
		  text: "Are you sure you want to remove this Procedure?",
		  type: 'question',
		  showCancelButton: true,
		  confirmButtonText: '<i class="send icon"></i> Remove',
		  cancelButtonText: '<i class="remove icon"></i> Cancel',
		  confirmButtonClass: 'ui blue button',
		  cancelButtonClass: 'ui button',
		  buttonsStyling: false
    }).then(function () {
      window.location.replace(`/facilities/${f_id}/remove_procedure/${fpp_id}`);
		})
 })


  let fpp_id = $('#fpp_code_name').attr('fpp_id')
  if (fpp_id == undefined || fpp_id == "")
    {}
  else
    {
     const csrf2 = $('input[name="_csrf_token"]').val();

         $.ajax({
        url:`/get_facility_payor_procedure/${fpp_id}`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'get',
        success: function(response){
          let data = response

          $('.room_procedure').each(function(){
            let room_rate_id = $(this).attr('room_rate_id')
            for (let fppr of data.facility_payor_procedure_rooms)
              {
                if (room_rate_id == fppr.facility_room_rate.id)
                  {
                    $(this).find('#room_amount').val(fppr.amount)
                    if (fppr.discount == 0){
                      $(this).find('#discount_percent').val('')
                    }else
                      {
                        $(this).find('#discount_percent').val(fppr.discount)
                      }
                    $(this).find('#start_date').val(fppr.start_date)
                  }
              }

        })
       }
         })
    }

  function alert_error_amount(){
    alertify.error('<i id="notification_error" class="close icon"></i><p>Please Enter Amount</p>');
    alertify.defaults = {
        notifier:{
            delay:5,
            position:'top-right',
            closeButton: false
        }
    };
  }

  function alert_error_discount(){
    alertify.error('<i id="notification_error" class="close icon"></i><p>Discount must only be 1-100</p>');
    alertify.defaults = {
        notifier:{
            delay:5,
            position:'top-right',
            closeButton: false
        }
    };
  }

  function alert_error_date(){
    alertify.error('<i id="notification_error" class="close icon"></i><p>Please Enter Effective Date</p>');
    alertify.defaults = {
        notifier:{
            delay:5,
            position:'top-right',
            closeButton: false
        }
    };
  }

  function alert_error_validate(){
    alertify.error('<i id="notification_error" class="close icon"></i><p>At least one room with the <br> following details must be filled out: <br> *Amount *Effective Date</p>');
    alertify.defaults = {
        notifier:{
            delay:5,
            position:'top-right',
            closeButton: false
        }
    };
  }
    let utc = new Date()
    let date = moment(utc)
    date = date.format("YYYY/MM/DD")
   $('.ui.calendar').calendar({
      type: 'date',
      minDate: new Date(date),
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

  /*
  let count= 1
  $('#room_procedure_button').on('click', function(){
    let dropdown_id = '#fields_append'
    dropdown_id = dropdown_id + (count - 1)
    if ($('#room_procedure_fields').find('#room_code_type').val() == "" || $(dropdown_id).find('#room_code_type').val() == "" || $('#room_procedure_fields').find('#room_amount').val() == "" || $('#room_procedure_fields').find('#discount_percent') ==  "" || $('#room_procedure_fields').find('#start_date').val() == "" || $(dropdown_id).find('#room_code_type').val() == "" || $(dropdown_id).find('#room_amount').val() == "" || $(dropdown_id).find('#discount_percent').val() == "" || $(dropdown_id).find('#start_date').val() == "" )
      {
      }
      else
        {
    dropdown_id = '#fields_append' + count
    let data_append = $('#fields_append').html()
    $('#room_procedure_fields').append(`<div class="ui grid" id="fields_append${count}" style="margin-bottom: -30px;">${data_append}</div>`)
    $(`#fields_append${count}`).find('#room_procedure_button_remove').attr('remove_count',`fields_append${count}`)
    $(dropdown_id).find('.ui.dropdown').dropdown();
    im.mask($(dropdown_id).find('#discount_percent'));
    $(dropdown_id).find('.ui.calendar').calendar({
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

    count = count + 1
        }
  $('button[role="remove-procedure"]').on('click', function(){
    let remove_count = $(this).attr('remove_count')
    $(`div[id="${remove_count}"]`).remove()
  });
  })
  */

  $('#add-procedure').on('click', function(){
    let room_params = []
    let validate = false
    let error_amount = false
    let error_date = false
    let error_discount = false
    $('.room_procedure').each(function(){
      let room_rate_id = $(this).attr('room_rate_id')
      let room_amount = $(this).find('#room_amount').val()
      let room_discount = $(this).find('#discount_percent').val()
      let room_start_date = $(this).find('#start_date').val()
      if (room_amount != "" || room_start_date != "")
        {
          validate = true
        }
      if (room_amount == "" && room_start_date != "")
        {
          error_amount = true
        }
      if (room_amount != "" && room_start_date == "")
        {
          error_date = true
        }
      if (room_discount != "" && room_discount > 100)
          {
            error_discount = true
          }
      if (room_amount == "" && room_start_date == "" && room_discount != "" && room_discount <= 100)
        {
          error_amount = true
          error_date = true
        }
        else
          {
            let string = `${room_rate_id},${room_amount},${room_discount},${room_start_date}`
            room_params.push(string)
          }
    })

      if (error_amount == true)
        {
          alert_error_amount()
        }
      if (error_date == true)
        {
          alert_error_date()
        }
      if (error_discount == true)
        {
          alert_error_discount()
        }
      if (validate == true && error_amount == false && error_date == false && error_discount == false)
        {
          $('#room_params').val(room_params)
          $('#addProcedure').submit();
        }
        else
          {
            if (validate == false)
              {
            alert_error_validate()
              }
          }


      /*
    let room_params = []
    let checker = false
    let room_id = $('#room_procedure_fields').find('.ui.dropdown').find(":selected").val()
      for (let a=1;a<count;a++){
        let dropdown_id_validate = '#fields_append' + a
        if (room_id == $(dropdown_id_validate).find('.ui.dropdown').find(":selected").val()){
          checker = true
        }
      }
    let room_amount = $('#room_procedure_fields').find('#room_amount').val()
    let room_discount = $('#room_procedure_fields').find('#discount_percent').val()
    let room_start_date = $('#room_procedure_fields').find('#start_date').val()
    let string = ''
      if (room_amount == '' || room_discount == '' || room_amount == '' || room_start_date == '' || room_amount == undefined || room_discount == undefined || room_amount == undefined || room_start_date == undefined){
      }
      else
        {
      string = `${room_id},${room_amount},${room_discount},${room_start_date}`
      room_params.push(string)
        }

    for (let i=1;i<count;i++)
    {
      let dropdown_id = '#fields_append' + i
      let room_id = $(dropdown_id).find('.ui.dropdown').find(":selected").val()
      for (let a=1;a<count;a++){
        let dropdown_id_validate = '#fields_append' + a
        if (i == a) {
        }
        else
          {
            if (room_id == $(dropdown_id_validate).find('.ui.dropdown').find(":selected").val()){
          checker = true
        }
          }
      }
      let room_amount = $(dropdown_id).find('#room_amount').val()
      let room_discount = $(dropdown_id).find('#discount_percent').val()
      let room_start_date = $(dropdown_id).find('#start_date').val()
      let string = ''
      if (room_amount == '' || room_discount == '' || room_amount == '' || room_start_date == '' || room_amount == undefined || room_discount == undefined || room_amount == undefined || room_start_date == undefined){
      }
      else
        {
      string = `${room_id},${room_amount},${room_discount},${room_start_date}`
      room_params.push(string)
      }


    }
    $('#room_params').val(room_params)
    if (checker == false){
      $('#addProcedure').submit();
    }else
    {
      alert_error_room()
      }
      */
  })
    let csrf = $('input[name="_csrf_token"]').val();
    let facility_id = $('#add-procedure').attr("facilityid")

    $.ajax({
      url:`/get_all_fpp_id_and_code/${facility_id}`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        const data = JSON.parse(response)
        let code = $('#updateProcedure').find('input[name="facility_procedure[code]"]').attr("dummy-val")

        let arrayCode = $.map(data, function(value, index) {
          return [value.code];
        });

        if(code != undefined){
          arrayCode.splice($.inArray(code, arrayCode),1)
        }

        $.fn.form.settings.rules.checkCode = function(param) {
          return arrayCode.indexOf(param) == -1 ? true : false;
        }
        $('#facility_procedure').form({
          on: 'blur',
          inline: true,
          fields: {
            'facility_procedure[payor_procedure_id]': {
              identifier: 'facility_procedure[payor_procedure_id]',
              rules: [{
                type   : 'empty',
                prompt : 'Please enter Payor CPT Code/Name'
              }]
            },
            'facility_procedure[code]': {
              identifier: 'facility_procedure[code]',
              rules: [{
                type   : 'empty',
                prompt : 'Please enter Facility Cpt Code'
              },
              { type   : 'checkCode[param]',
                prompt : 'This Facility Cpt Code is already taken!'
              }]
            },
            'facility_procedure[name]': {
              identifier: 'facility_procedure[name]',
              rules: [{
                type   : 'empty',
                prompt : 'Please enter Facility Cpt Name'
              }]
            }
          }
        })
      }
})
  });
  onmount('div[id="facility_procedure_index"]', function(){

  $('#no_room').on('click', function(){
    alertify.error('<i id="notification_error" class="close icon"></i><p>Please Add Rooms Before Adding Procedure</p>');
    alertify.defaults = {
        notifier:{
            delay:5,
            position:'top-right',
            closeButton: false
        }
    };
   })

  let Inputmask = require('inputmask');
  let im = new Inputmask("numeric", {
    max: 100,
    rightAlign: false
  });


  im.mask('#facility_procedure_discount');
  let copy_link = ''

  $('.linkFProcedure').on('click', function(){
  let facility_id = $(this).attr("facilityID")
    $('#view_facility_procedure').modal('show')
    clearForm()
    let utc = new Date()
    let date = moment(utc)
    date = date.format("YYYY/MM/DD")
    $('div[id="rangestart"]').calendar();
    $('div[id="rangestart"]').calendar({
      type: 'date',
      minDate: new Date(date),
      focusDate: 'focusDate',
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

    const facility_payor_procedure_id = $(this).attr('facilityProcedureID');
    const cpt_code = $(this).attr('cptCode')
    const cpt_name = $(this).attr('cptName')

    let fp_link = ''
    if (copy_link == ''){
      fp_link = $('#update_facility_procedure_room').attr('href')
      copy_link = fp_link
    }
    else
      {
        fp_link = copy_link
      }
    $('#update_facility_procedure_room').attr('href',fp_link + `/facilities_procedure/${facility_payor_procedure_id}/edit_procedure`)
     const csrf = $('input[name="_csrf_token"]').val();

         $.ajax({
        url:`/get_facility_payor_procedure/${facility_payor_procedure_id}`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'get',
        success: function(response){
          const data = response
          const selector = $('div[id="update_facility_procedure"]')
          let fppr = data.facility_payor_procedure_rooms
          $('#payor_cpt_code').text(cpt_code+ '/' +cpt_name)
          $('#facility_cpt_code').text(data.code)
          $('#facility_cpt_name').text(data.name)
          let dataSet = []
          for (let fppr of fppr){
              let data_array = []
              data_array.push(fppr.facility_room_rate.rooms.code)
              data_array.push(fppr.amount)
              data_array.push(fppr.discount)
              data_array.push(fppr.start_date)
              dataSet.push(data_array)
          }
            /* for (let fpp of fpp) {
               let new_row =
               `<tr>\
               <td>${fpp.facility.code}</td>\
               <td>${fpp.facility.name}</td>\
               <td>${obj.code}</td>\
               <td>${obj.description}</td>\
               </tr>`
               $("#procedure_facility_table tbody").append(new_row)

               }
               */
            $('#facility_procedure_table').DataTable( {
              destroy: true,
              data: dataSet,
              columns: [
                { title: "Room Code" },
                { title: "Amount" },
                { title: "Discount(%)" },
                { title: "Effective Date" }
              ]
            } );

          let procedure_room = fppr

          /* $('#facility_procedure_id').val(facility_payor_procedure_id)
          $('#code_type').attr('disabled','disabled')
          let count  = (data.facility_payor_procedure_rooms).length
          $('#code_type').val(cpt_code+ '/' +cpt_name)
          $('#code_type').attr('disabled','disabled')
          selector.find('#facility_procedure_code').val(data.code)
          selector.find('#facility_procedure_code').attr("dummy-val", data.code)
          selector.find('#facility_procedure_code').attr('disabled','disabled')
          selector.find('#facility_procedure_name').val(data.name)
          $('#room_code_type').val(room_code+ '/' +room_type)
          $('#room_code_type').attr('disabled','disabled')
          selector.find('#facility_procedure_facility_payor_procedure_room_id').val(facility_payor_procedure_room_id)
          selector.find('#facility_procedure_amount').val(amount)
          selector.find('#facility_procedure_discount').val(discount)
          selector.find('#facility_procedure_start_date').val(start_date)

*/
          $.ajax({
            url:`/get_all_fpp_id_and_code/${facility_id}`,
            headers: {"X-CSRF-TOKEN": csrf},
            type: 'get',
            success: function(response){
              const data = JSON.parse(response)
              let id = $('#updateProcedure').find('select[name="facility_procedure[payor_procedure_id]"]').attr("dummy-val")
              let code = $('#updateProcedure').find('input[name="facility_procedure[code]"]').attr("dummy-val")

              let room_rate_ids = $.map(procedure_room, function(value, index) {
                return [value.facility_room_rate.id];
              });
                room_rate_ids = jQuery.grep(room_rate_ids, function(value) {
                  return value != room_rate_id;
                });

              let arrayCode = $.map(data, function(value, index) {
                return [value.code];
              });

              let arrayID = $.map(data, function(value, index) {
                return [value.payor_procedure_id];
              });

              if(id != undefined){
                arrayID.splice($.inArray(id, arrayID),1)
              }

              $.fn.form.settings.rules.checkID = function(param) {
                return arrayID.indexOf(param) == -1 ? true : false;
              }

              if(code != undefined){
                arrayCode.splice($.inArray(code, arrayCode),1)
              }

              $.fn.form.settings.rules.checkCode = function(param) {
                return arrayCode.indexOf(param) == -1 ? true : false;
              }

              $.fn.form.settings.rules.checkRoomRateID = function(param) {
                return room_rate_ids.indexOf(param) == -1 ? true : false;
              }
              $('#updateProcedure').form({
                on: 'blur',
                inline: true,
                fields: {
                  'facility_procedure[payor_procedure_id]': {
                    identifier: 'facility_procedure[payor_procedure_id]',
                    rules: [{
                      type   : 'empty',
                      prompt : 'Please enter Payor CPT Code/Name'
                    },
                    { type   : 'checkID[param]',
                      prompt : 'This procedure is already taken!'
                    }]
                  },
                  'facility_procedure[code]': {
                    identifier: 'facility_procedure[code]',
                    rules: [{
                      type   : 'empty',
                      prompt : 'Please enter Facility Cpt Code'
                    },
                    { type   : 'checkCode[param]',
                      prompt : 'This Facility Cpt Code is already taken!'
                    }]
                  },
                  'facility_procedure[name]': {
                    identifier: 'facility_procedure[name]',
                    rules: [{
                      type   : 'empty',
                      prompt : 'Please enter Facility Cpt Name'
                    }]
                  },
                  'facility_procedure[amount]': {
                    identifier: 'facility_procedure[amount]',
                    rules: [{
                      type   : 'empty',
                      prompt : 'Please enter Amount'
                    }]
                  },
                  'facility_procedure[start_date]': {
                    identifier: 'facility_procedure[start_date]',
                    rules: [{
                      type   : 'empty',
                      prompt : 'Please enter Effective date'
                    }]
                  }
                }

              })

            },
            error: function(response){
            }
          })
        },
        error: function(){
        }
      })

  })

  const clearForm = () => {
    $('div[id="facility_procedure"]').find(':input').not(':button, :submit, :reset, :hidden, :checkbox, :radio').val('');
    $('div[id="facility_procedure"]').find(':checkbox, :radio').prop('checked', false);
  }
})

//Practitioner Schedule
onmount('div[role="modal-add-schedule"]', function(){
  let tr = $('div[role="modal-add-schedule"]').find('tbody > tr')
  $('button[id="add_sched"]').prop('disabled', true)

  tr.each(function(){
    if($(this).find('input[type="checkbox"]').is(':checked')){
      $('button[id="add_sched"]').prop('disabled', false)
    }

    if($(this).find('input[type="checkbox"]').is(':checked')){
      $(this).find('input[type="text"]').prop("disabled", false)
    }else{
      $(this).find('input[type="text"]').prop("disabled", true)
    }
  })

    $('div[role="modal-add-schedule"]').modal({
    autofocus: false,
    observeChanges: true
    }).modal('attach events', '#button_add_sched', 'show');

    $('button[name="add-schedule"]').on('click', function(){
    $('div[role="modal-add-schedule"]').form('reset');
    $('p[role="append-telephone"]').empty();
    $('p[role="append-mobile"]').empty();
    $('p[role="append-fax"]').empty();
    $('.time').calendar({
      ampm: false,
      type: 'time'
    });

    $('div[role="modal-add-schedule"]').on('mouseover', function(){
      let tr = $(this).find('tbody > tr').find('input[type="text"]')
      let no_val = []

      tr.each(function(){
        const inputs = $(this).val() == ""
        if(inputs){
          no_val.push(inputs)
        }else{
          no_val.push(inputs)
        }
      })
      no_val = no_val.every(is_all_true)

      if(no_val){
        $('button[id="add_sched"]').prop('disabled', true)
      }else{
        $('button[id="add_sched"]').prop('disabled', false)
      }
    })

    $('tbody > tr').on('mouseover', function(){
      let tr = $(this)
      tr.find('input[type="text"]').prop("disabled", false)

      tr.on('mouseout', function(){
        let no_val = []
        tr.find('input[type="text"]').each(function(){
          const inputs = $(this).val() == ""
          if(inputs){
            no_val.push(inputs)
          }else{
            no_val.push(inputs)
          }
        })

        no_val = no_val.every(is_all_true)

        if(no_val){
          tr.find('input[type="text"]').prop("disabled", true)
        }
      })

      $(this).find('div').removeClass('error')
      $(this).find('div[class="ui basic red pointing prompt label transition visible"]').remove()
    })

    const is_all_true = (element, index, array) => {
      return element == true
    }

    function toDate(dStr,format) {
      var now = new Date();
      if (format == "hh:mm") {
        now.setHours(dStr.substr(0,dStr.indexOf(":")));
        now.setMinutes(dStr.substr(dStr.indexOf(":")+1));
        now.setSeconds(0);
        return now;
      } else {
        return "Invalid Format";
      }
    }

    $.fn.form.settings.rules.validTimeToMon = function(param) {
      if (param == '' || $('input[name="practitioner_account[time_from][Monday]"]').val() == '') {
        return true;
      } else {
        if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_account[time_from][Monday]"]').val(), "hh:mm")) {
          return true;
        } else {
          return false;
        }
      }
    }

    $.fn.form.settings.rules.validTimeToTue = function(param) {
      if (param == '' || $('input[name="practitioner_account[time_from][Tuesday]"]').val() == '') {
        return true;
      } else {
        if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_account[time_from][Tuesday]"]').val(), "hh:mm")) {
          return true;
        } else {
          return false;
        }
      }
    }

    $.fn.form.settings.rules.validTimeToWed = function(param) {
      if (param == '' || $('input[name="practitioner_account[time_from][Wednesday]"]').val() == '') {
        return true;
      } else {
        if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_account[time_from][Wednesday]"]').val(), "hh:mm")) {
          return true;
        } else {
          return false;
        }
      }
    }

    $.fn.form.settings.rules.validTimeToThu = function(param) {
      if (param == '' || $('input[name="practitioner_account[time_from][Thursday]"]').val() == '') {
        return true;
      } else {
        if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_account[time_from][Thursday]"]').val(), "hh:mm")) {
          return true;
        } else {
          return false;
        }
      }
    }

    $.fn.form.settings.rules.validTimeToFri = function(param) {
      if (param == '' || $('input[name="practitioner_account[time_from][Friday]"]').val() == '') {
        return true;
      } else {
        if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_account[time_from][Friday]"]').val(), "hh:mm")) {
          return true;
        } else {
          return false;
        }
      }
    }

    $.fn.form.settings.rules.validTimeToSat = function(param) {
      if (param == '' || $('input[name="practitioner_account[time_from][Saturday]"]').val() == '') {
        return true;
      } else {
        if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_account[time_from][Saturday]"]').val(), "hh:mm")) {
          return true;
        } else {
          return false;
        }
      }
    }

    $.fn.form.settings.rules.validTimeToSun = function(param) {
      if (param == '' || $('input[name="practitioner_account[time_from][Sunday]"]').val() == '') {
        return true;
      } else {
        if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_account[time_from][Sunday]"]').val(), "hh:mm")) {
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
        'practitioner_account[room][Monday]': {
          identifier: 'practitioner_account[room][Monday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter a Room'
          }
          ]
        },
        'practitioner_account[time_from][Monday]': {
          identifier: 'practitioner_account[time_from][Monday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time From'
          }
          ]
        },
        'practitioner_account[time_to][Monday]': {
          identifier: 'practitioner_account[time_to][Monday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time To'
            },
            {
              type  : 'validTimeToMon',
              prompt: 'Time To must be greater than Time From'
            },
          ]
        },
        'practitioner_account[room][Tuesday]': {
          identifier: 'practitioner_account[room][Tuesday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter a Room'
          }
          ]
        },
        'practitioner_account[time_from][Tuesday]': {
          identifier: 'practitioner_account[time_from][Tuesday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time From'
          }
          ]
        },
        'practitioner_account[time_to][Tuesday]': {
          identifier: 'practitioner_account[time_to][Tuesday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time To'
            },
            {
              type  : 'validTimeToTue',
              prompt: 'Time To must be greater than Time From'
            },
          ]
        },
        'practitioner_account[room][Wednesday]': {
          identifier: 'practitioner_account[room][Wednesday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter a Room'
          }
          ]
        },
        'practitioner_account[time_from][Wednesday]': {
          identifier: 'practitioner_account[time_from][Wednesday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time From'
          }
          ]
        },
        'practitioner_account[time_to][Wednesday]': {
          identifier: 'practitioner_account[time_to][Wednesday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time To'
            },
            {
              type  : 'validTimeToWed',
              prompt: 'Time To must be greater than Time From'
            },
          ]
        },
        'practitioner_account[room][Thursday]': {
          identifier: 'practitioner_account[room][Thursday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter a Room'
          }
          ]
        },
        'practitioner_account[time_from][Thursday]': {
          identifier: 'practitioner_account[time_from][Thursday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time From'
          }
          ]
        },
        'practitioner_account[time_to][Thursday]': {
          identifier: 'practitioner_account[time_to][Thursday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time To'
            },
            {
              type  : 'validTimeToThu',
              prompt: 'Time To must be greater than Time From'
            },
          ]
        },
        'practitioner_account[room][Friday]': {
          identifier: 'practitioner_account[room][Friday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter a Room'
          }
          ]
        },
        'practitioner_account[time_from][Friday]': {
          identifier: 'practitioner_account[time_from][Friday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time From'
          }
          ]
        },
        'practitioner_account[time_to][Friday]': {
          identifier: 'practitioner_account[time_to][Friday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time To'
          },
            {
              type  : 'validTimeToFri',
              prompt: 'Time To must be greater than Time From'
            },
          ]
        },
        'practitioner_account[room][Saturday]': {
          identifier: 'practitioner_account[room][Saturday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter a Room'
          }
          ]
        },
        'practitioner_account[time_from][Saturday]': {
          identifier: 'practitioner_account[time_from][Saturday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time From'
          }
          ]
        },
        'practitioner_account[time_to][Saturday]': {
          identifier: 'practitioner_account[time_to][Saturday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time To'
          },
            {
              type  : 'validTimeToSat',
              prompt: 'Time To must be greater than Time From'
            },
          ]
        },
        'practitioner_account[room][Sunday]': {
          identifier: 'practitioner_account[room][Sunday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter a Room'
          }
          ]
        },
        'practitioner_account[time_from][Sunday]': {
          identifier: 'practitioner_account[time_from][Sunday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time From'
          }
          ]
        },
        'practitioner_account[time_to][Sunday]': {
          identifier: 'practitioner_account[time_to][Sunday]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time To'
          },
            {
              type  : 'validTimeToSun',
              prompt: 'Time To must be greater than Time From'
            },
          ]
        }
      }
    });
  })
})

onmount('div[role="modal-edit-schedule"]', function(){
  $('div[role="modal-edit-schedule"]').modal({
    autofocus: false,
    observeChanges: true
  }).modal('attach events', 'a[id="button_edit_sched"]', 'show');

  let tr = $('div[role="modal-edit-schedule"]').find('tbody > tr')
  $('button[id="edit_sched"]').prop('disabled', true)

  tr.each(function(){
    if($(this).find('input[type="checkbox"]').is(':checked')){
      $('button[id="edit_sched"]').prop('disabled', false)
    }

    if($(this).find('input[type="checkbox"]').is(':checked')){
      $(this).find('input[type="text"]').prop("disabled", false)
    }else{
      $(this).find('input[type="text"]').prop("disabled", true)
    }
  })


  $('a[name="edit-schedule"]').click(function(){
    $('div[role="modal-edit-schedule"]').form('reset');
    $('.time').calendar({
      ampm: false,
      type: 'time'
    });

    $('div[name="scheduleForm"]').find('tbody > tr').click(function(){
      let tr = $(this)
      let schedule_id = tr.attr("schedule_id")
      let sched_day = tr.find('td[role="day"]').html()
      let sched_room = tr.find('td[role="room"]').text()
      let sched_time_from = tr.find('td[role="time_from"]').text()
      let sched_time_to = tr.find('td[role="time_to"]').text()

      let modal_row = $('div[role="modal-edit-schedule"]').find('tbody > tr')
      modal_row.find('div[role="day"]').text(sched_day)
      modal_row.find('input[name="practitioner_account[day]"]').val(sched_day)
      modal_row.find('input[name="practitioner_account[room]"]').val(sched_room)
      modal_row.find('input[name="practitioner_account[time_from]"]').val(sched_time_from)
      modal_row.find('input[name="practitioner_account[time_to]"]').val(sched_time_to)
      modal_row.find('input[name="practitioner_account[schedule_id]"]').val(schedule_id)
    })

    $('div[role="modal-edit-schedule"]').on('mouseover', function(){
      let tr = $(this).find('tbody > tr').find('input[type="text"]')
      let no_val = []

      tr.each(function(){
        const inputs = $(this).val() == ""
        if(inputs){
          no_val.push(inputs)
        }else{
          no_val.push(inputs)
        }
      })
      no_val = no_val.every(is_all_true)

      if(no_val){
        $('button[id="edit_sched"]').prop('disabled', true)
      }else{
        $('button[id="edit_sched"]').prop('disabled', false)
      }
    })

    $('tbody > tr').on('mouseover', function(){
      let tr = $(this)
      tr.find('input[type="text"]').prop("disabled", false)

      tr.on('mouseout', function(){
        let no_val = []
        tr.find('input[type="text"]').each(function(){
          const inputs = $(this).val() == ""
          if(inputs){
            no_val.push(inputs)
          }else{
            no_val.push(inputs)
          }
        })

        no_val = no_val.every(is_all_true)

        if(no_val){
          tr.find('input[type="text"]').prop("disabled", true)
        }
      })

      $(this).find('div').removeClass('error')
      $(this).find('div[class="ui basic red pointing prompt label transition visible"]').remove()
    })

    const is_all_true = (element, index, array) => {
      return element == true
    }

    function toDate(dStr,format) {
      var now = new Date();
      if (format == "hh:mm") {
        now.setHours(dStr.substr(0,dStr.indexOf(":")));
        now.setMinutes(dStr.substr(dStr.indexOf(":")+1));
        now.setSeconds(0);
        return now;
      } else {
        return "Invalid Format";
      }
    }

    $.fn.form.settings.rules.validTimeTo = function(param) {
      if (param == '' || $('input[name="practitioner_account[time_from]"]').val() == '') {
        return true;
      } else {
        if (toDate(param, "hh:mm") > toDate($('input[name="practitioner_account[time_from]"]').val(), "hh:mm")) {
          return true;
        } else {
          return false;
        }
      }
    }

    $('#formScheduleValidateEdit').form({
      on: blur,
      inline: true,
      fields: {
        'practitioner_account[room]': {
          identifier: 'practitioner_account[room]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter a Room'
          }
          ]
        },
        'practitioner_account[time_from]': {
          identifier: 'practitioner_account[time_from]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time From'
          }
          ]
        },
        'practitioner_account[time_to]': {
          identifier: 'practitioner_account[time_to]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Time To'
          },
            {
              type  : 'validTimeTo',
              prompt: 'Time To must be greater than Time From'
            },
          ]
        }
      }
    });
  }) // onclick
})
