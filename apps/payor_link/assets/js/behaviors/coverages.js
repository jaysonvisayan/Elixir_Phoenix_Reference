onmount('div[id="coverages_new"]', function(){

/* CAPITALIZE ALL LETTER OF COVERAGE CODE */
  $('input[id="coverage_code"]').on('keyup', function(evt){
    console.log("hehe");
    $(this).val(function (_, val) {
      return val.toUpperCase();
    });
  });


  /* CAPITALIZE FIRST LETTER OF Coverage NAME IN EVERY WORD*/
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

  $('input[id="coverage_name"]').keypress(function() {
    $(this).capitalize();
  }).capitalize();

  $('.modal')
  .modal({
    closable  : false,
    onDeny    : function(){
      return true;
    },
    onApprove : function() {
       $('#validate')
        .form({
          on: blur,
          inline: true,
          fields: {
            'coverage[code]': {
              identifier: 'coverage[code]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Code is required'
                }
              ]
            },

            'coverage[name]': {
              identifier: 'coverage[name]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Name is required'
                }
              ]
            },
            'coverage[description]': {
              identifier: 'coverage[description]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Description is required'
                }
              ]
            },
            'coverage[status]': {
              identifier: 'coverage[status]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Status is required'
                }
              ]
            },
            'coverage[type]': {
              identifier: 'coverage[type]',
              rules: [
                {
                  type: 'empty',
                  prompt: 'Type is required'
                }
              ]
            }

          }
        });
$('#coverage').submit()

    }
  })

  $('.modal').modal('attach events', '.submit', 'show');

});


