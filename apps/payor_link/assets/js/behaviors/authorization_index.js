onmount('div[id="auth_index"]', function(){

  function decodeCharEntity(value){
    let parser = new DOMParser;
    let dom = parser.parseFromString(value, 'text/html')
    return dom.body.textContent;
  }

  $('#auth_table tbody').on('click', '.view-authorization-logs', function(){
    let auth_id = $(this).attr('authID')
    $.ajax({
      url:`/authorizations/${auth_id}/logs`,
        type: 'get',
        datatype: 'json',
        success: function(response){
          console.log(response)
          $('#logsContainer').empty()
          if (response.length == 0) {
            $('#logsContainer').append('NO LOGS FOUND')
          } else {
            $('#logsContainer').append(`<div class="ui feed timeline" id="logsContainer2"></div>`)
            for (let log of response) {
              let formatted_date = moment(log.inserted_at).format('MMMM Do YYYY, h:mm a')
              $('#logsContainer2').append(`
                  <div class="event">
                    <div class="label">
                    <i class="blue circle icon"></i>
                    </div>
                    <div class="content">
                      <div class="summary">
                        <p class="">${formatted_date}</p>
                      </div>
                      <div class="extra text" id="">
                        ${log.message}
                      </div>
                    </div>
                  </div>
                `)
            }
          }
          $('#authorizationLogsModal').modal('show')
        },
        error: function(){
          alert("Error getting authorization logs")
        }
    })
  })

  setInterval(function(){
    $('.dropdown').each(function() {
      if ($(this).hasClass('initiated') == false) {
        $(this).addClass('initiated')
        $(this).dropdown()
      }
    })
  }, 100)

})
