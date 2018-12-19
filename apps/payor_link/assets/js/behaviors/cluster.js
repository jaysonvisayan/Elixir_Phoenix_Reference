onmount('div[id="ClusterValidation"]', function () {

  $('.btnCluster').on('click', function(){
    let cluster_id = $(this).attr('cluster_id')

    swal({
          title: 'Delete Cluster?',
          text: 'Deleting this cluster will permanently remove it from the system. ',
          type: 'question',
          showCancelButton: true,
          cancelButtonText: '<i class="remove icon"></i> No, Keep Cluster',
          confirmButtonText: '<i class="check icon"></i> Yes, Delete Cluster',
          cancelButtonClass: 'ui negative button',
          confirmButtonClass: 'ui positive button',
          reverseButtons: true,
          buttonsStyling: false
          }).then(function () {
              window.location.replace(`/clusters/${cluster_id}/delete`);
          })
  })
})

function showAllLogs(cluster_id)
{
  $.ajax({
      url:`/clusters/${cluster_id}/logs`,
      type: 'GET',
      success: function(response){
        let obj = JSON.parse(response)
        $("#cluster_logs_table tbody").html('')
        if (jQuery.isEmptyObject(obj)) {
          let no_log =
          `No Matching Logs Found!`
          $("#timeline").removeClass('feed timeline');
          $('p[role="append_logs"]').text(no_log)
        }
        else  {
          for (let logs of obj) {
            let new_row =
            `<div class="event row_logs"> \
             <div class="label"> \
             <i class="blue circle icon"></i> \
             </div> \
              <div class="content"> \
              <div class="summary"> \
              <a> \
             <p class="log-date">${logs.inserted_at}</p>\
             </a> \
             </div> \
             <div class="extra text" id="log_message"> \
             ${logs.message}\
             </div> \
             </div> \
             </div> \
              </tr>`

          $("#timeline").addClass('feed timeline')
          $('div[class="ui feed timeline"]').append(new_row)
            }
        }
        $('p[class="log-date"]').each(function(){
           let date = $(this).html();
           $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
        })
      }
   })
}


onmount('div[id="showCluster"]', function(){

  $('.print-account').click(function() {
    let cluster_id = $(this).attr('clusterID')
    window.open(`/clusters/${cluster_id}/print_cluster`, '_blank')
  });

  $('#logsModal')
  .modal({
    closable  : false,
    onHide: function() {
        $('input[name="cluster[search]"]').val("");
        $('.row_logs').remove();
        $('p[role="append_logs"]').text(" ")
        showAllLogs(cluster_id)
     }
  })
  .modal('attach events', '#logs', 'show');

  $('p[class="log-date"]').each(function(){
    let date = $(this).html();
    $(this).html(moment(date).format("MMMM Do YYYY, h:mm a"));
  })

  $('div[id="log_message"]').each(function(){
    var $this = $(this);
    var t = $this.text();
    $this.html(t.replace('&lt','<').replace('&gt', '>'));
  })

  let cluster_id = $('input[name="cluster_id"]').val();

  $('#btnSearchLogs').on('click', function(){

      let message = $('input[name="cluster[search]"]').val();

      if (message == "" || message == null)
      {
        $('.row_logs').remove();
        $('p[role="append_logs"]').text(" ")
        showAllLogs(cluster_id)
      }
      else
      {
        $('.row_logs').remove();
        $('p[role="append_logs"]').text(" ")

        $.ajax({
        url:`/clusters/${cluster_id}/${message}/logs`,
        type: 'GET',
        success: function(response){
          let obj = JSON.parse(response)
          $("#cluster_logs_table tbody").html('')
          if (jQuery.isEmptyObject(obj)) {
            let no_log =
            `No Matching Logs Found!`
            $("#timeline").removeClass('feed timeline');
            $('p[role="append_logs"]').text(no_log)
          }
          else  {
            for (let logs of obj) {
              let new_row =
              `<div class="event row_logs"> \
               <div class="label"> \
               <i class="blue circle icon"></i> \
               </div> \
                <div class="content"> \
                <div class="summary"> \
                <a> \
               <p class="log-date">${logs.inserted_at}</p>\
               </a> \
               </div> \
               <div class="extra text" id="log_message"> \
               ${logs.message}\
               </div> \
               </div> \
               </div> \
                </tr>`

            $("#timeline").addClass('feed timeline')
            $('div[class="ui feed timeline"]').append(new_row)
            }
          }
          $('p[class="log-date"]').each(function(){
             let date = $(this).html();
             $(this).html(moment(date).format('MMMM Do YYYY, h:mm a'));
          })
          }
        })
      }
   })

})

onmount('div[id="Step3Validation"]', function(){
  $('.print-account').click(function() {
    let cluster_id = $(this).attr('clusterID')
    window.open(`/clusters/${cluster_id}/print_cluster`, '_blank')
  });
  $('#btnSubmit').click(function() {
    alertify.success('<i class="close icon"></i><p>Cluster successfully created</p>', 'info');

  })
})

onmount('button[id="deleteCluster"]', function () {

  const csrf = $('input[name="_csrf_token"]').val()

  $('#deleteCluster').on('click', function() {
    let clusterID = $(this).attr('clusterID')
    swal({
      title: 'Delete Cluster?',
      text: "Deleting this Cluster will permanently remove it from the system.",
      type: 'warning',
      showCancelButton: true,
      confirmButtonText: '<i class="check icon"></i> Yes, Delete Cluster',
      cancelButtonText: '<i class="remove icon"></i> No, Keep Cluster',
      confirmButtonClass: 'ui button',
      cancelButtonClass: 'ui button',
      buttonsStyling: false,
      reverseButtons: true,
      allowOutsideClick: false
    }).then(function() {
        window.location.replace(`/clusters/${clusterID}/delete`)
    }).catch(swal.noop)
  })

})
