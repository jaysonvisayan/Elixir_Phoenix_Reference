onmount('div[id="formValidation"]', function(){
		// $('#formValidation form').form({
	//   on: 'blur',
	//   inline: true,
	//   fields: {
	//     testField: {
	//       identifier: 'testField',
	//       rules: [{
	//         type: 'empty',
	//         prompt: 'Test Field must have a value'
	//       }]
	//     }
	//   }
	// });

	$('.ui.form').form({
		on: 'blur',
	  	inline: true,
	    fields: {
	      name: {
	        identifier: 'name',
	        rules: [
	          {
	            type   : 'empty',
	            prompt : 'Please enter your name'
	          }
	        ]
	      },
	      skills: {
	        identifier: 'skills',
	        rules: [
	          {
	            type   : 'minCount[2]',
	            prompt : 'Please select at least two skills'
	          }
	        ]
	      },
	      gender: {
	        identifier: 'gender',
	        rules: [
	          {
	            type   : 'empty',
	            prompt : 'Please select a gender'
	          }
	        ]
	      },
	      username: {
	        identifier: 'username',
	        rules: [
	          {
	            type   : 'empty',
	            prompt : 'Please enter a username'
	          }
	        ]
	      },
	      password: {
	        identifier: 'password',
	        rules: [
	          {
	            type   : 'empty',
	            prompt : 'Please enter a password'
	          },
	          {
	            type   : 'minLength[6]',
	            prompt : 'Your password must be at least {ruleValue} characters'
	          }
	        ]
	      },
	      terms: {
	        identifier: 'terms',
	        rules: [
	          {
	            type   : 'checked',
	            prompt : 'You must agree to the terms and conditions'
	          }
	        ]
	      }
	    }
	});


});
