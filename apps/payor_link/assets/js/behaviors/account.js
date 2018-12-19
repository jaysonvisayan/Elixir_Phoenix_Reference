onmount('div[id="AccountLogsModal"]', function(){

  $(this).modal('attach events', '#account_logs', 'show')

  $('p[class="account_log_date"]').each(function(){
    let date = $(this).html();
    $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
	})

  $('div[class="extra text"]').each(function(){
    let parser = new DOMParser;
    let dom = parser.parseFromString($(this).text(), 'text/html')
    $(this).text(dom.body.textContent);
  })

  // $('div[class="extra text"]').each(function(){
  //   var $this = $(this);
  //   var t = $this.text();
  //   $this.html(t.replace('&lt','<').replace('&gt', '>'));
  // })

});

$('font[class="practitioner_time"]').each(function(){
    let time = $(this).html()
    $(this).html(moment(time, 'HH:mm:ss').format('h:mm a'));
  })


onmount('div[name="AccountValidation"]', function(){
  $('.print-account').click(function() {
    let account_id = $(this).attr('accountID')
    window.open(`/accounts/${account_id}/print_account`, '_blank')
  });
  setInterval(loadTier, 50)

  function loadTier(){
    let r_height = $('.right_column').css('height')
    $('.left_column').css('height', r_height)
  }
});

onmount('div[name="AccountSearch"]', function(){
  $('#account_download_button').on('click', function(){
    var rows = document.querySelectorAll("tbody tr");
    var row = rows[0].querySelectorAll("td");

    if ((row[0].innerText == "No Records Found!") || (row[0].innerText == "No Matching Records Found!")){
        alert("No Records Found to Download");
    }
    else{
      var account_codes = [];

      for (var r = 0; r < rows.length; r++){
        var col = rows[r].querySelectorAll("td");
        account_codes.push(col[0].innerText);
      }

      const csrf = $('a[data-to="/sign_out"]').attr('data-csrf');

      $.ajax({
        url: `/accounts/index/download`,
        headers: {"X-CSRF-TOKEN": csrf},
        type: 'post',
        data: {params: account_codes},
        dataType: 'json',
        success: function(response){
          let obj = JSON.parse(response)
          let csv = []
          let title = "Account Code,Account Name,Segment,Industry,Funding Arrangement,Cluster,Effective Date,Expiry Date,Status,Version,Created By,Date Created"

          csv.push(title)

          let string = ""
          for (let i = 0; i < obj.length; i++){
            let cluster = ""
            let cluster_code = obj[i]["cluster_code"]
            let cluster_name = obj[i]["cluster_name"]
            if (cluster_code == null || cluster_code == ""){
              cluster = "N/A"
            }
            else{
              cluster = cluster_code + ' - ' + cluster_name
            }

            let date_created = obj[i]["date_created"]
            date_created = new Date(date_created).toJSON().slice(0,10).replace(/-/g,'-')

            string = '"' + obj[i]["code"] + '","' + obj[i]["name"] + '","' + obj[i]["segment"] + '","' + obj[i]["industry"] + '","' + obj[i]["funding"] + '","' + cluster + '","' + obj[i]["start_date"] + '","' + obj[i]["end_date"] + '","' + obj[i]["status"] + '","' + obj[i]["version"] + '","' + obj[i]["created_by"] + '","' + date_created + '"'

            csv.push(string)
            // string = ''
          }

          let utc = new Date().toJSON().slice(0,10).replace(/-/g,'_');
          let filename = 'Accounts_' + utc + '.csv'

          //Generate and Download CSV File
          downloadCSV(csv.join("\n"), filename)
        },
        error: function(xhr, status, error) {
          alert('error');
        }
      });
    }
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
});

onmount('div[name="AccountProduct"]', function(){
  $('.right_column').each(function(index, value){
    let index_count = index + 1
    let height = $(this).css('height')

    $('.left_container').append(`\
      <div class="sixteen wide tablet sixteen wide computer column left_column left-container-style">\
        <h3> Tier ${index_count}</h3>\
      </div>`)
  })

  let r_height = $('.right_column').css('height')
  $('.left_column').css('height', r_height)

  let container_width = $(this).width()
  let ap_width = container_width.toString() + 'px'

  recountProductTierRanking()
  checkAPData()

  $('#sortable_product').sortable({
    appendTo: 'body',
    helper: 'clone',
    placeholder: 'highlight-placeholder',
    start: function(event, ui){
      // recountProductTierRanking()
      ui.item.addClass('card-border')
    },
    stop: function(event, ui){
      ui.item.removeClass('card-border')
      recountProductTierRanking()
      checkAPData()
    },
    drag: function(event,ui){
      ui.helper.offset(ui.position)
    }
  }).disableSelection()

  function recountProductTierRanking() {
    let product_tier = ""
    let account_product_ids = $('#sortable_product').find('.account_product_id')
    account_product_ids.each(function(index, value){
      let index_count = index + 1
      let item_value = $(this).val()
      if(product_tier != ''){
        product_tier = product_tier + ',' + index_count + '_' + item_value
      } else {
        product_tier = index_count + '_' + item_value
      }
    })
    $('.product_tier_ranking').val(product_tier)
  }

  function checkAPData() {
    //$('#ap_warning').hide()
    let generated_value = $('#ap_checker_generated').val()
    let db_value = $('#ap_checker').text()

    if(generated_value == undefined) {
      $('#ap_warning').hide()
    }
    else
    {
     if(generated_value != db_value){
      $('#ap_warning').show()
     } else {
      $('#ap_warning').hide()
     }
    }
  }
});

onmount('div[id="ahoed_container"]', function(){
  function loopHierarchyItems(items){
    let hierarchy_type = "";
    items.each(function(index, value){
      let index_count = index + 1
      let item_value = $(this).text();
      if(hierarchy_type != ''){
        hierarchy_type = hierarchy_type + ',' + index_count + '-' + item_value
      } else {
        hierarchy_type = index_count + '-' + item_value
      }
    });
    return hierarchy_type
  }

  function refreshHierarchyData(){
    let me_order = loopHierarchyItems($('#me_sortable').find('span'));
    let se_order = loopHierarchyItems($('#se_sortable').find('span'));
    let spe_order = loopHierarchyItems($('#spe_sortable').find('span'));

    $('input[name="product[married_employee]"]').val(me_order);
    $('input[name="product[single_employee]"]').val(se_order);
    $('input[name="product[single_parent_employee]"]').val(spe_order);
  }

  function checkHierarchy(){
    let me_order = $('input[name="product[married_employee]"]').val();
    let se_order = $('input[name="product[single_employee]"]').val();
    let spe_order = $('input[name="product[single_parent_employee]"]').val();

    if(me_order == ''){
      me_order = '1-Spouse,2-Child,3-Parent,4-Sibling'
    }
    if(se_order == '') {
      se_order = '1-Parent,2-Sibling'
    }
    if(spe_order == '') {
      spe_order = '1-Parent,2-Child,3-Sibling'
    }

    checkHierarchyArray(me_order, '#me_sortable', 'me')
    checkHierarchyArray(se_order, '#se_sortable', 'se')
    checkHierarchyArray(spe_order, '#spe_sortable', 'spe')
    refreshHierarchyData()
  }

  function checkHierarchyArray(dependent, container, type){
    let count = 0;
    if(dependent != ''){
      let dependent_array = dependent.split(",")
      for(let i = 1; i <= dependent_array.length; i++){
        $.each(dependent_array, function(index,value){
          let item_array = value.split("-")
          let item_index = item_array[0]
          let item_value = item_array[1]
          let container_dd;

          if(i == item_index){
            let new_item = `\
              <div class="ui large fluid black basic label">\
              <span class="left floated">${item_value}</span>\
              <a class="right floated circular ui icon negative mini button delete_sortable" dependent="${item_value}" category="${type}">\
              <i class="icon minus"></i>\
              </a>\
              </div>\
              `

            switch(type){
              case 'me':
                container_dd = $('#me_dd');
              break;
              case 'se':
                container_dd = $('#se_dd');
              break;
              case 'spe':
                container_dd = $('#spe_dd');
              break;
            }

            let dropdowns = container_dd.find('div')
            $.each(dropdowns, function(){
              if($(this).attr('dependent') == item_value){
                $(this).remove()
              }
            });

            $(container).append(new_item)
          }
        })
      }
    }
  }

  checkHierarchy()

  $('#me_sortable').sortable({
    appendTo: 'body',
    helper: 'clone',
    start: function(event, ui){
      $("#me_validation").addClass('hidden');
    },
    stop: function(event, ui){
      refreshHierarchyData()
    },
    drag: function(event,ui){
      ui.helper.offset(ui.position);
    }
  });

  $('#se_sortable').sortable({
    appendTo: 'body',
    helper: 'clone',
    start: function(event, ui){
      $("#se_validation").addClass('hidden');
    },
    stop: function(event, ui){
      refreshHierarchyData()
    },
    drag: function(event,ui){
      ui.helper.offset(ui.position);
    }
  });

  $('#spe_sortable').sortable({
    appendTo: 'body',
    helper: 'clone',
    start: function(event, ui){
      $("#spe_validation").addClass('hidden');
    },
    stop: function(event, ui){
      refreshHierarchyData()
    },
    drag: function(event,ui){
      ui.helper.offset(ui.position);
    }
  });

  $('div[id="ahoed_container').on('click', '.delete_sortable',function(){
    let dependent = $(this).attr('dependent')
    let category = $(this).attr('category')
    let container;
    let checker;

    switch(category){
      case 'me':
        container = $('#me_dd');
        checker = $('#me_sortable').find('div').length;
        break;
      case 'se':
        container = $('#se_dd');
        checker = $('#se_sortable').find('div').length;
        break;
      case 'spe':
        container = $('#spe_dd');
        checker = $('#spe_sortable').find('div').length;
        break;
    }

    if(checker == 1){
      $("#" + category + "_validation").removeClass('hidden');
    } else {
      let new_item = `\
        <div href="#" class="item clickable-row append_sortable" dependent="${dependent}" category="${category}" >\
        ${dependent}\
        </div>\
        `
      container.append(new_item)

      $(this).closest('div').remove()
      refreshHierarchyData()
    }

  })

  $('div[id="ahoed_container').on('click', '.append_sortable',function(){
    let dependent = $(this).attr('dependent')
    let category = $(this).attr('category')

    let container;
    switch(category){
      case 'me':
        container = $('#me_sortable');
        break;
      case 'se':
        container = $('#se_sortable');
        break;
      case 'spe':
        container = $('#spe_sortable');
        break;
    }
    let new_item = `\
      <div class="ui large fluid black basic label">\
      <span class="left floated">${dependent}</span>\
      <a class="right floated circular ui icon negative mini button delete_sortable" dependent="${dependent}" category="${category}">\
      <i class="icon minus"></i>\
      </a>\
      </div>\
    `
    container.append(new_item)
    $("#" + category + "_validation").addClass('hidden');
    refreshHierarchyData()
    $(this).remove()
  })


  $('#pep').keypress(function(evt) {
    evt = (evt) ? evt : window.event;
    var charCode = (evt.which) ? evt.which : evt.keyCode;
    $('.ajs-message.ajs-error.ajs-visible').remove()
    $('#pep_field').removeClass('error')
    if (charCode == 8 || charCode == 37) {
        return true;
    } else if (charCode == 46) {
        return false;
    } else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
        return false;
    }
    return true;
  });

  $('#dep').keypress(function(evt) {
    evt = (evt) ? evt : window.event;
    var charCode = (evt.which) ? evt.which : evt.keyCode;
    $('.ajs-message.ajs-error.ajs-visible').remove()
    $('#dep_field').removeClass('error')
    if (charCode == 8 || charCode == 37) {
        return true;
    } else if (charCode == 46) {
        return false;
    } else if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57)) {
        return false;
    }
    return true;
  });

  $('.submit_hoed').click(function(){
    $('.ajs-message.ajs-error.ajs-visible').remove()
    let account_id = $(this).attr('accountID')
    let me_sortable = $('input[name="product[married_employee]"]').val()
    let se_sortable = $('input[name="product[single_employee]"]').val()
    let spe_sortable = $('input[name="product[single_parent_employee]"]').val()
    let pep = $('#pep').val()
    let dep = $('#dep').val()
    let pep_dom = ""
    let dep_dom = ""
    if($('#pep_multiplier').html() == "Days"){
      pep_dom = "day"
    }
    else {
      pep_dom = "month"
    }
    if($('#dep_multiplier').html() == "Days"){
      dep_dom = "day"
    }
    else {
      dep_dom = "month"
    }
    const csrf = $('input[name="_csrf_token"]').val();
    let step = $(this).attr('step')
    if(pep=="" && dep==""){
      $('#pep_field').removeClass('error')
      $('#dep_field').removeClass('error')
      $('#pep_field').addClass('error')
      $('#dep_field').addClass('error')
      alertify.error('<i class="close icon"></i><p>Please enter Principal and Dependent Enrollment Period</p>');
    }
    else if(pep==""){

      $('#pep_field').removeClass('error')
      $('#pep_field').addClass('error')

      alertify.error('<i class="close icon"></i><p>Please enter Principal Enrollment Period</p>');
    }
    else if(dep==""){
      $('#dep_field').removeClass('error')
      $('#dep_field').addClass('error')
      alertify.error('<i class="close icon"></i><p>Please enter Dependent Enrollment Period</p>');
    }
    else{
    $.ajax({
      url:`/accounts/${account_id}/save_ahoed/`,
      headers: {"X-CSRF-TOKEN": csrf},
      data: {id:
        account_id,
        account_params: {
          "account_id": account_id,
          "me_sortable" : me_sortable,
          "spe_sortable" : spe_sortable,
          "se_sortable" : se_sortable,
          "pep" : pep,
          "dep" : dep,
          "pep_dom" : pep_dom,
          "dep_dom" : dep_dom
        }
      },
      type: 'post',
      success: function(response){
        let obj = JSON.parse(response)
        if(obj == "fail"){
          alertify.error('<i class="close icon"></i><div class="header">Failed</div><p>Please enter atleast one dependent of each type.</p>');
        } else {
          if(step == "setup?step=6"){
            window.location.replace(`${step}`)
          }
            alertify.success('<i class="close icon"></i><div class="header">Success</div><p>Hierarchy of Eligible Dependents has been updated successfully.</p>');
        }
      }
    });
  }
  })

})

onmount('div[role="add-coverage-fund"]', function(){
  let counter = 0
  let csrf = $('input[name="_csrf_token"]').val();
  const delete_coverage_fund = (cof_id) => {
    $.ajax({
      url:`/accounts/${cof_id}/delete_coverage_fund`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'delete',
      success: function(response){
        const result = JSON.parse(response)
        if (result.length == 0) {
          $("#coverage_funds_tbl").DataTable( {
            destroy: true,
            data: result,
            searching: false,
            bFilter: false,
            paging: false,
            "columns": [
              { "title": "Coverage"},
              { "title": "Revolving Fund"},
              { "title": "Replenish Threshold"},
              { "title": "Action"},
            ]
          });
          click_delete_coverage_fund()
          /*swal({
            title: 'Coverage Fund',
            text: `Deleted successfully`,
            type: 'success',
            confirmButtonText: '<i class="check icon"></i> Okay',
            confirmButtonClass: 'ui positive button',
            buttonsStyling: false,
            reverseButtons: true,
            allowOutsideClick: false
          }).then(function() {
           //$('#form-cancel').submit()
          })*/
          alertify.error('<i id="notification_error" class="close icon"></i><p>Coverage Fund successfully deleted.</p>');
        }
        else if(result == false) {
          click_delete_coverage_fund()
        }else {
          //$('tbody[id="remove_body"]').remove()
          let dataSet = []
          for(let cof of result){
            let data_array = []
            data_array.push(cof.coverage.name)
            data_array.push(cof.revolving_fund)
            data_array.push(cof.replenish_threshold)
            data_array.push('<a href="#" coverageFundId="'+ cof.id +'" name="delete_coverage_fund"><i class="red large trash link icon"></i></a>')
            dataSet.push(data_array)
          }
          $("#coverage_funds_tbl").DataTable( {
            destroy: true,
            data: dataSet,
            searching: false,
            bFilter: false,
            paging: false,
            "columns": [
              { "title": "Coverage"},
              { "title": "Revolving Fund"},
              { "title": "Replenish Threshold"},
              { "title": "Action"},
            ]
          });
          click_delete_coverage_fund()
          /*swal({
            title: 'Coverage Fund',
            text: `Deleted successfully`,
            type: 'success',
            confirmButtonText: '<i class="check icon"></i> Okay',
            confirmButtonClass: 'ui positive button',
            buttonsStyling: false,
            reverseButtons: true,
            allowOutsideClick: false
          }).then(function() {
           //$('#form-cancel').submit()
          })*/
          alertify.error('<i id="notification_error" class="close icon"></i><p>Coverage Fund successfully deleted.</p>');
        }
      },
      error: function(){
        alert("Error deleting coverage fund")
        click_delete_coverage_fund()
      }
    })
  }

  const click_delete_coverage_fund = () => {
    $('a[name="delete_coverage_fund"]').on('click', function(){
      const cof_id = $(this).attr("coverageFundId")
      if(cof_id != undefined || cof_id != "") {
        delete_coverage_fund(cof_id)
      }
    })
  }

  click_delete_coverage_fund()

	$('table[role="modified_table"]').dataTable({
    searching: false,
    bFilter: false,
    bInfo: false,
    paging: false
  })

  var currency = new Inputmask("numeric", {
    allowMinus:false,
    radixPoint: ".",
    groupSeparator: ",",
    digits: 2,
    autoGroup: true,
    // prefix: '₱ ',
    rightAlign: false
  });

  currency.mask($('.currency'))

  $('a[name="coverage_funds"]').on('click', function(){
    $('form[id="modal_coverage_fund"]')[0].reset()
    $('div[role="add-coverage-fund"]').modal({autofocus: false}).modal('show')

    $('button[name="hide_coverage_fund"]').on('click', function(){
      $('div[role="add-coverage-fund"]').modal('hide')
    })
    $('button[name="save_coverage_fund"]').prop('disabled', false)
    $('.multiple').dropdown("clear")

    const account_group_id = $(this).attr('accountGroupID');
    let csrf = $('input[name="_csrf_token"]').val();

    $.fn.form.settings.rules.ZeroValue= function(param) {
      if (parseInt(param) > 0){
        return true
      } else {
        return false
      }
    }

    $('#modal_coverage_fund').form({
      on: 'blur',
      inline: true,
      fields: {
        'account[coverage_ids][]': {
          identifier: 'account[coverage_ids][]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Coverage'
          },
         ]
        },
        'account[revolving_fund]': {
          identifier: 'account[revolving_fund]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Revolving Fund'
          },
          {
            type  : 'ZeroValue[param]',
            prompt: 'Revolving Fund value must be more than 0'
          },
          ]
        },
        'account[replenish_threshold]': {
          identifier: 'account[replenish_threshold]',
          rules: [{
            type  : 'empty',
            prompt: 'Please enter Replenish Threshold'
          },
          {
            type  : 'ZeroValue[param]',
            prompt: 'Replenish Threshold value must be more than 0'
          },
          ]
        }
      },
      onSuccess: function() {
        $(this).prop('disabled', true)
        let object = $('#modal_coverage_fund').serializeArray().reduce(function(m,o){ m[o.name] = o.value; return m;}, {})
           let params = _.omitBy(object, ['account[coverage_ids][]'])
           params = _.set(params, 'coverage_ids', $('#coverage_ids').val())
          $.ajax({
            url:`/accounts/${account_group_id}/create_coverage_fund`,
            headers: {"X-CSRF-TOKEN": csrf},
            type: 'post',
            data: {params: params},
            success: function(response){
              const result = JSON.parse(response)
              if(result == false) {
                $('div[role="add-coverage-fund"]').modal('hide')
              }else {
                //$('tbody[id="remove_body"]').remove()
                let dataSet = []
                for(let cof of result){
                  let data_array = []
                  data_array.push(cof.coverage.name)
                  data_array.push(cof.revolving_fund)
                  data_array.push(cof.replenish_threshold)
                  data_array.push('<a href="#!" coverageFundId="'+ cof.id +'" name="delete_coverage_fund"><i class="red large trash link icon"></i></a>')
                  dataSet.push(data_array)
                }
                $("#coverage_funds_tbl").DataTable( {
                  destroy: true,
                  data: dataSet,
                  searching: false,
                  bFilter: false,
                  paging: false,
                  "columns": [
                    { "title": "Coverage"},
                    { "title": "Revolving Fund"},
                    { "title": "Replenish Threshold"},
                    { "title": "Action"},
                  ]
                });
                $(this).prop('disabled', false)
                $('div[role="add-coverage-fund"]').modal('hide')
              }
              counter = 0
              click_delete_coverage_fund()
            },
            error: function(){
              alert("Error inserting coverage fund")
              $('div[role="add-coverage-fund"]').modal('hide')
              $(this).prop('disabled', false)
              click_delete_coverage_fund()
            }
          })
          return false; // false is required if you do don't want to let it submit

        },
        onFailure: function() {
           return false; // false is required if you do don't want to let it submit
        }
    });

    $('button[name="save_coverage_fund"]').on('click', function(e){
      if(counter == 0){
        counter++
        $('#modal_coverage_fund').submit()
      }
    })
  })
})

onmount('#accountShow', function(){


  $('.uneligible-peme').on('click', function(){
    $('.ajs-message.ajs-error.ajs-visible').remove()
    alertify.error('<i id="notification_error" class="close icon"></i><p>Plan cannot be added. Only one PEME Plan is allowed to be added in an account</p>');
    event.preventDefault()
    event.stopPropagation()
  })
})

onmount('div[id="account_product_standard"]', function () {
  const csrf = $('input[name="_csrf_token"]').val();

  $('div[name="modal_product_standard"]').click(function () {
    let account_id = $(this).attr('accountID')
    $('div[id="account_product_standard"]')
      .modal({
        autofocus: false,
        closable: false,
        selector: {
          deny: '.deny.button'
        }
      })
      .modal('show');

    $('#tbl_product_standard').DataTable({
      "destroy": true,
      "ajax": {
        "url": `/accounts/load_products?type=standard&id=${account_id}`,
        "headers": { "X-CSRF-TOKEN": csrf },
        "type": "get"
      },
      "processing": true,
      "serverSide": true,
      "deferRender": true,
      "drawCallback": function (settings) {

        $('div[id="account_product_standard"]')
          .modal({
            autofocus: false,
            closable: false,
            selector: {
              deny: '.deny.button'
            }
          })
          .modal('refresh');

        var valArray = [];
        $('#product_select_std').on('change', function () {
          let table = $('#tbl_product_standard').DataTable()
          let rows = table.rows({ 'search': 'applied' }).nodes()

          if($(this).is(':checked')) {
            $('input[type="checkbox"]', rows).each(function() {
              let value = $(this).val()

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
            })
          } else {
            valArray.length = 0
            $('input[name="account_product[product_id][]"]').each(function() {
              $(this).prop('checked', false)
            })
          }

          $('input[name="account_product[product_ids]"]').val(valArray)
        })

        $('.uneligible-product').on('click', function(){
          $('.ajs-message.ajs-error.ajs-visible').remove()
          alertify.error('<i id="notification_error" class="close icon"></i><p>Plan cannot be added. Coverages in the following plans must have a Coverage Fund set up</p>');
          event.preventDefault()
          event.stopPropagation()
        })

        $("input:checkbox").each(function () {
          var value = $(this).val();

          if (this.checked) {
            valArray.push(value);
          } else {
            var index = valArray.indexOf(value);

            if (index >= 0) {
              valArray.splice(index, 1)
            }
          }
          $('div[id="account_product_standard"]').find('input[name="account_product[product_ids]"]').val(valArray);
        });

        $("input:checkbox").on('change', function () {
          var value = $(this).val();

          if (this.checked) {
            valArray.push(value);
          } else {
            var index = valArray.indexOf(value);

            if (index >= 0) {
              valArray.splice(index, 1)
            }
          }

          $('div[id="account_product_standard"]').find('input[name="account_product[product_ids]"]').val(valArray);
        });
      }
    })
  })
})

onmount('div[id="account_product_custom"]', function () {
  const csrf = $('input[name="_csrf_token"]').val();

  $('div[name="modal_product_custom"]').click(function () {
    let account_id = $(this).attr('accountID')
    $('div[id="account_product_custom"]')
      .modal({
        autofocus: false,
        closable: false,
        selector: {
          deny: '.deny.button'
        }
      })
      .modal('show');

    $('#tbl_product_custom').DataTable({
      "destroy": true,
      "ajax": {
        "url": `/accounts/load_products?type=custom&id=${account_id}`,
        "headers": { "X-CSRF-TOKEN": csrf },
        "type": "get"
      },
      "processing": true,
      "serverSide": true,
      "deferRender": true,
      "drawCallback": function (settings) {

        $('div[id="account_product_custom"]')
          .modal({
            autofocus: false,
            closable: false,
            selector: {
              deny: '.deny.button'
            }
          })
          .modal('refresh');

        var valArray = [];
        $('#product_select_ctm').on('change', function () {
          let table = $('#tbl_product_standard').DataTable()
          let rows = table.rows({ 'search': 'applied' }).nodes()

          if($(this).is(':checked')) {
            $('input[type="checkbox"]', rows).each(function() {
              let value = $(this).val()

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
            })
          } else {
            valArray.length = 0
            $('input[name="account_product[product_id][]"]').each(function() {
              $(this).prop('checked', false)
            })
          }

          $('input[name="account_product[product_ids]"]').val(valArray)
        })

        $('.uneligible-product').on('click', function(){
          $('.ajs-message.ajs-error.ajs-visible').remove()
          alertify.error('<i id="notification_error" class="close icon"></i><p>Plan cannot be added. Coverages in the following plans must have a Coverage Fund set up</p>');
          event.preventDefault()
          event.stopPropagation()
        })

        $("input:checkbox").each(function () {
          var value = $(this).val();

          if (this.checked) {
            valArray.push(value);
          } else {
            var index = valArray.indexOf(value);

            if (index >= 0) {
              valArray.splice(index, 1)
            }
          }
          $('div[id="account_product_custom"]').find('input[name="account_product[product_ids]"]').val(valArray);
        });

        $("input:checkbox").on('change', function () {
          var value = $(this).val();

          if (this.checked) {
            valArray.push(value);
          } else {
            var index = valArray.indexOf(value);

            if (index >= 0) {
              valArray.splice(index, 1)
            }
          }

          $('div[id="account_product_custom"]').find('input[name="account_product[product_ids]"]').val(valArray);
        });
      }
    })
  })
})

