onmount('#Comment', function(){
$('div[id="comment_text"]').each(function(){
  var $this = $(this);
  var t = $this.text();
    $this.html(t.replace('&lt','<').replace('&gt', '>'));
});

$("table > tbody > tr").hide().slice(0, 8).show();

 $(function() {
    var loading = function() {
        var over = '<div id="overlay" class="ui active inverted dimmer"> <div class="ui text loader">Loading</div> </div> <p></p> </div>';
        $(over).appendTo('p[role=append_loader');

        setTimeout(function(){
          $('#overlay').remove();
          $("table > tbody > tr").hide().slice(0, 10000).show();
          $('#LoadMore').css('display', 'none');
        }, 1000);

    };
    $('#LoadMore').click(loading);
});

var count = 0;
function writeOutput() {
  $('#load_counter').html(count);
}

function doCount() {
   count++;
}

$("#LoadMore").on("click", function() {
    doCount();
    writeOutput();
    $('#LoadMore').css('display', 'none');
 // $("table > tbody > tr").hide().slice(0, 10000).show();
 // $('#LoadMore').css('display', 'none');
});

$('a[name="comment_modal"]').on('click', function(){


  if ($('#comment_count').val() <= 3) { $('#LoadMore').css('display', 'none'); }
  else { $('#LoadMore').css('display', 'block'); }

  const click_value = $('#load_counter').html();
  if (click_value == '1')
  {
    $('#LoadMore').css('display', 'none');
  }

	$('div[role="add-comment"]').modal('show');
  $('div[id="message"]').remove()
  $('#comment_text_area').removeClass('error')
  $('#btnComment').removeClass('disabled')

	const account_id = $(this).attr('CommentAccountID');
	const user_id = $(this).attr('CommentUserID');
  const user_firstname = $(this).attr('CommentUserFirstName');
  const user_lastname = $(this).attr('CommentUserLastName');
	const csrf = $('input[name="_csrf_token"]').val();

	$.ajax({
      url:`/api/v1/accounts/${account_id}/get_an_account`,
      headers: {"X-CSRF-TOKEN": csrf},
      type: 'get',
      success: function(response){
        let data = JSON.parse(response)
        $('#account_comment_account_id').val(account_id)
        $('#account_comment_user_id').val(user_id)
        $('#user_firstname').val(user_firstname)
        $('#user_lastname').val(user_lastname)
      },
      error: function(){
        window.location.href=`/accounts/${account_id}`;
      }
    })
 })

$('#account_comment_comment').keyup(function ()
{
  if($(this).find('account_comment_comment').val() != "")
  {
   let text_max_length = 250;
   $('#comment_text_area').removeClass('error')
   $('div[id="message"]').remove()
   $('#btnComment').removeClass('disabled')

   $('#message_count').val(text_max_length + ' characters')
    var text_length = $('#account_comment_comment').val().length;
    var text_remaining = text_max_length - text_length;
    $('#message_count').html(text_remaining + "/250")
  }
});

$('#btnComment').on('click', function(){

  const account_ids = $('input[name="account_comment[account_id]"').val();
  const user_ids = $('input[name="account_comment[user_id]"').val();
  let _comment = $('#account_comment_comment').val();
  _comment = _comment.replace(/\n/g,'<br />');
  _comment = _comment.replace(/&/g,'and');
  let _userfirstname = $('#user_firstname').val();
  let _userlastname = $('#user_lastname').val();
  const csrf2 = $('input[name="_csrf_token"]').val();

  if (_comment == "")
  {
    //$('p[role=app]').append('<div id="message" class="ui negative message"> <div class="header">There were some errors with your submission </div> <ul class="list"> <li>Comment is required!</li> </ul> </div>')
    $('#comment_text_area').addClass('error')
    $('#btnComment').addClass('disabled')
  }
  else
  {
    var req =
       $.ajax({
        url:`/api/v1/accounts/${account_ids}/new_comment`,
        headers: {"X-CSRF-TOKEN": csrf2},
        type: 'post',
        data: {id: account_ids, account_comment: { "account_id" : account_ids, "user_id" : user_ids, "comment" : _comment}},
        dataType: 'json',
        beforeSend: function()
        {
          $('#overlay2').css("display", "block");
        },
        complete: function()
        {
          $('#overlay2').css("display", "none");
        }
      });

      req.done(function (data){
         $('p[role="append"]').prepend('<div class="field" style="z-index: 100"> ' +
          '<div class="ui comments"> ' +
          '<div class="comment"><a class="avatar"> ' +
          '<img src="/images/file-upload.png"> </a> ' +
          '<div class="content"> ' +
          '<a class="author"> '+ _userfirstname + ' ' + _userlastname + '</a>' +
          '<div class="metadata"> ' +
          '<div class="date">Just Now</div> ' +
          '</div> '+
          '<div class="text" id="comment_text"> ' + _comment + ' </div> ' +
          '</div> </div> </div>')

         $('#account_comment_comment').val("");
      });
    }
  })
})



