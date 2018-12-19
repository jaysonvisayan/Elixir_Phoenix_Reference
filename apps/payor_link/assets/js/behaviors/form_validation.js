/* CLUSTER PAGE */
onmount('div[name="ClusterValidation"]', function () {
  /* CAPITALIZE ALL LETTER OF CLUSTER CODE */
  $('input[id="cluster_code"]').on('keyup', function(evt){
    $(this).val(function (_, val) {
      return val.toUpperCase();
    });
  });


  /* CAPITALIZE FIRST LETTER OF CLUSTER NAME IN EVERY WORD*/
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

  $('input[id="cluster_name"]').keypress(function() {
    $(this).capitalize();
  }).capitalize();

  let csrf = $('input[name="_csrf_token"]').val();
  let clusterCode = $('input[type="text"][name="cluster[code]"]').val()

  $.ajax({
    url:`/clusters/load/cluster_code`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let data = JSON.parse(response);
      let array = $.map(data, function(value, index) {
                        return [value.code];
      });
      $.fn.form.settings.rules.checkClusterCode = function(param) {
        return array.indexOf(param) == -1 ? true : false;
      }

      $('#Cluster')
      .form({
        on: blur,
        inline: true,
        fields: {
          'cluster[code]': {
            identifier: 'cluster[code]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter cluster code.'
            },
            {
              type   : 'checkClusterCode[param]',
              prompt : 'Cluster code is already taken!'
            }
            ]
          },
          'cluster[name]': {
            identifier: 'cluster[name]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter cluster name.'
            }
            ]
          }
        }
      });
    }
  });

  /* TEXT INPUT VALIDATION */
  
});

onmount('div[name="ClusterValidations_edit"]', function () {
  /* CAPITALIZE ALL LETTER OF CLUSTER CODE */
  $('input[id="cluster_code"]').on('keyup', function(evt){
    $(this).val(function (_, val) {
      return val.toUpperCase();
    });
  });

  /* CAPITALIZE FIRST LETTER OF CLUSTER NAME IN EVERY WORD*/
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

  $('input[id="cluster_name"]').keypress(function() {
    $(this).capitalize();
  }).capitalize();

  let csrf = $('input[name="_csrf_token"]').val();
  let clusterName = $('input[type="text"][name="cluster[name]"]').val()

  $.ajax({
    url:`/clusters/load/cluster_name`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let data = JSON.parse(response);
      let array = $.map(data, function(value, index) {
                        return [value.name];
      });
      $.fn.form.settings.rules.checkClusterName = function(param) {
        return array.indexOf(param) == -1 ? true : false;
      }

      $('#Cluster')
      .form({
        on: blur,
        inline: true,
        fields: {
          'cluster[name]': {
            identifier: 'cluster[name]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter cluster name.'
            },
            {
              type   : 'checkClusterName[param]',
              prompt : 'Cluster name is already taken!'
            }
            ]
          }
        }
      });
    }
  });

  /* TEXT INPUT VALIDATION */
});
/* END OF CLUSTER PAGE */

onmount('div[name="ClusterValidations"]', function () {
  /* CAPITALIZE ALL LETTER OF CLUSTER CODE */
  $('input[id="cluster_code"]').on('keyup', function(evt){
    $(this).val(function (_, val) {
      return val.toUpperCase();
    });
  });

  let csrf = $('input[name="_csrf_token"]').val();
  let clusterCode = $('input[type="text"][name="cluster[code]"]').val()

  $.ajax({
    url:`/clusters/load/cluster_code`,
    headers: {"X-CSRF-TOKEN": csrf},
    type: 'get',
    success: function(response){
      let data = JSON.parse(response);
      let array = $.map(data, function(value, index) {
                        return [value.code];
      });
      $.fn.form.settings.rules.checkClusterCode = function(param) {
        return array.indexOf(param) == -1 ? true : false;
      }

      $('#Cluster')
      .form({
        on: blur,
        inline: true,
        fields: {
          'cluster[code]': {
            identifier: 'cluster[code]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter cluster code.'
            },
            {
              type   : 'checkClusterCode[param]',
              prompt : 'Cluster code is already taken!'
            }
            ]
          },
          'cluster[name]': {
            identifier: 'cluster[name]',
            rules: [
            {
              type: 'empty',
              prompt: 'Please enter cluster name.'
            }
            ]
          }
        }
      });
    }
  });

});
/* END OF CLUSTER PAGE */