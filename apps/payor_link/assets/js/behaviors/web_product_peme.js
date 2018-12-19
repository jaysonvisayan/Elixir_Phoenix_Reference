onmount('div[id="main_step1_general_peme"]', function () {
  $('#general_form')
  .form({
    inline : true,
    fields: {
      'product[name]': {
        identifier: 'product[name]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter a name.'
          }
        ]
      },
      'product[description]': {
        identifier: 'product[description]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter a description.'
          }
        ]
      },
      'product[type]': {
        identifier: 'product[type]',
        rules: [
          {
            type: 'empty',
            prompt: 'Please enter a type.'
          }
        ]
      },
      'product[standard_product]': {
        identifier: 'product[standard_product]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please enter a plan classification.'
          }
        ]
      },
      'product[member_type][]': {
        identifier: 'product[member_type][]',
        rules: [
          {
            type: 'checked',
            prompt: 'Please select atleast one member type.'
          }
        ]
      }
    }
  })

  // $('#btnCancel').click(function() {

  // })

  // $('#btnDraft').click(function() {

  // })
})
