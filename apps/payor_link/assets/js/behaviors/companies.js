onmount('div[id="company_index"]', function() {
  $('#modal_company_success').modal('show')
});

onmount('.newcompany', function() {

    $('input[id="company_code"]').on('keyup', function(evt) {
        $(this).val(function(_, val) {
            return val.toUpperCase();
        });
    }); 

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

    $('input[id="company_name"]').keypress(function() {
        $(this).capitalize();
    }).capitalize();


    //-------------------------------------------------------------------------------------------------------------
    
    let csrf = $('input[name="_csrf_token"]').val();

    $('#company_code').keyup(function() {
      let company_code = $('#company_code').val()
      $.ajax({
        url: `/get_company_by_code/${company_code}`,
        headers: {
            "X-CSRF-TOKEN": csrf
        },
        type: 'get',
        success: function(response) {
          let data = JSON.parse(response)
          let array = $.map(data, function(value, index) {
            return [value.code]
          })
           
          $.fn.form.settings.rules.checkCompanyCode = function(param){
            if (array[0])
            { 
              console.log(false)
              console.log(array[0])
              return false 
            }
            else
            { 
              console.log(array[0])
              console.log(true)
              return true 
            }
          }
          
          $('.ui.form')
          .form({
            inline: true,
            on: 'submit',
            fields: {
                'company[code]': {
                    identifier: 'company[code]',
                    rules: [{
                            type: 'empty',
                            prompt: 'Company Code is required'
                        },
                        {
                         type: 'checkCompanyCode[param]',
                         prompt: 'Company Code already exists'
                        }
                    ]
                },
                'company[name]': {
                    identifier: 'company[name]',
                    rules: [{
                            type: 'empty',
                            prompt: 'Company Name is required'
                        }
                    ]
                }
            }

          });

        } //----------------------------------------------------------------------- ajax success end
      }) //----------------------------------------------------------------------- ajax end
    }); //----------------------------------------------------------------------- onchange end

    $('.ui.form')
    .form({
      inline: true,
      on: 'submit',
      fields: {
          'company[code]': {
              identifier: 'company[code]',
              rules: [{
                      type: 'empty',
                      prompt: 'Company Code is required'
                  }
              ]
          },
          'company[name]': {
              identifier: 'company[name]',
              rules: [{
                      type: 'empty',
                      prompt: 'Company Name is required'
                  }
              ]
          }
      }
    });

}); //----------------------------------------------------------------------- omount end