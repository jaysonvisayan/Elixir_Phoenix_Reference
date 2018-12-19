onmount('div[id="translation_edit"]', function(){
  const locale = $('#locale').val()
  let csrf = $('input[name="_csrf_token"]').val();
  let translation_base = $('input[type="text"][id="translation_base_value"]').val()
  $.ajax({
    url:`/${locale}/translations/load/base_value`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      console.log(response)
      let array_edit = $.map(response, function(value, index) {
        return [value.base_value];
      });

      array_edit.splice($.inArray(translation_base, array_edit),1)
      $.fn.form.settings.rules.checkEditBase = function(param) {
        return array_edit.indexOf(param) == -1 ? true : false;
      }
      $('#translation_edit')
      .form({
        inline: true,
        on: 'blur',
        fields: {
          'translation[base_value]': {
            identifier: 'translation[base_value]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter Base Value'
            },
            {
              type   : 'checkEditBase[param]',
              prompt : 'Base Value already exists!'
            }
            ]
          },
          'translation[translated_value]': {
            identifier: 'translation[translated_value]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter Translated Value'
            }]
          },
          'translation[language]': {
            identifier: 'translation[language]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter Language Value'
            }]
          }
        }
      })
    }
  })
})
onmount('div[id="translation_new"]', function(){
  const locale = $('#locale').val()
  let csrf = $('input[name="_csrf_token"]').val();
  $.ajax({
    url:`/${locale}/translations/load/base_value`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      console.log(response)
      let array = $.map(response, function(value, index) {
        return [value.base_value];
      });
      $.fn.form.settings.rules.checkBase = function(param) {
        return array.indexOf(param) == -1 ? true : false;
      }
      $('#translation_new')
      .form({
        inline: true,
        on: 'blur',
        fields: {
          'translation[base_value]': {
            identifier: 'translation[base_value]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter Base Value'
            },
            {
              type   : 'checkBase[param]',
              prompt : 'Base Value already exists!'
            }
            ]
          },
          'translation[translated_value]': {
            identifier: 'translation[translated_value]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter Translated Value'
            }]
          },
          'translation[language]': {
            identifier: 'translation[language]',
            rules: [{
              type: 'empty',
              prompt: 'Please enter Language Value'
            }]
          }
        }
      })
    }
  })
})
