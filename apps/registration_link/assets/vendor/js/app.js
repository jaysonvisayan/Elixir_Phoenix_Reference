$('.ui.dropdown').dropdown();
$('.ui.radio.checkbox')
  .checkbox()
;

$('.menued-rows__dropdown').click( function() {
  $(this).find(".container").toggle();
});
$('.advanced-search-trigger').click( function() {
  $(".advanced-search").toggle();
});


// Open and Close Triggered Panel which click on the Button
var triggered = $('.sidebar');

$('.hamburger-trigger').click(function() {
  if($(triggered).hasClass('out')) {
    $(triggered).removeClass('out');
    $('.hamburger-overlay').hide();
  } else {
    $(triggered).addClass('out');
    $('.hamburger-overlay').show();
  }
});

// Close Triggered When clicked outside of the div
$(document).mouseup(function(e)
{
    // If the target of the click isn't the container nor a descendant of the container
    if (!triggered.is(e.target) && triggered.has(e.target).length === 0)
    {
        triggered.removeClass('out');
				$('.hamburger-overlay').hide();
    }
});

//Open modal
function openModal(trigger, modal) {
  $(modal).modal('attach events', trigger, 'show');
}

function callVerticalMenu () {
  if($(window).width() <=767) $('.header .ui.menu').addClass("vertical");
  else $('.header .ui.menu').removeClass("vertical");
}

openModal('.modal-open-viewlog', '.ui.modal.view-log');
openModal('.modal-open-export', '.ui.modal.export');
openModal('.modal-open-requestloa', '.ui.modal.requestloa')

$('.ui.tiny.modal.modal-success')
  .modal('attach events', '.modal-open-success', 'show')
;
$('.ui.tiny.modal.modal-fail')
  .modal('attach events', '.modal-open-fail', 'show')
;

$('.menu .item')
  .tab()
;

$('#rangeStartDate').calendar({
  type: 'date',
  endCalendar: $('#rangeEndDate')
});

$('#rangeEndDate').calendar({
  type: 'date',
  startCalendar: $('#rangeStartDate')
});

$('#birthDate').calendar({
  type: 'date'
});

$('#procedureDate').calendar({
  type: 'date'
});

//Member card - only 4 numbers per box
$(document).ready(function(){



  $( window ).load(function() {
    callVerticalMenu();
  });
  $( window ).resize(function() {
    callVerticalMenu();
  });

	$(".member-card-number").keyup(function() {
	    if($(this).val().length >= 4) {
	      var input_flds = $(this).closest('form').find(':input');
	      input_flds.eq(input_flds.index(this) + 1).focus();
	    }
	});
});
