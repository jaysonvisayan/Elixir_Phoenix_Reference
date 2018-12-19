$(function() {


	$('.doctors-list .ui.dropdown').dropdown({
		action: 'select'
	});


    /**
     * Function to toggle checkbox when accordion is opened or closed
     * @param  {node} target_accordion 	Accordion that has been clicked
     * @param  {string} status          Status that need to be set for the checkbox
     */
    var toggleCheckboxonAccordian = function( target_accordion, status ){
    	var target = $(target_accordion).data('checkbox');
		var $checkbox = $(target);

		if($checkbox){
			$checkbox.checkbox(status);
		}
    }

    /**
     * Initialize the accordion
     * When the accordion is opened then the checkbox for the accordion is checked
     * and vice versa
     */
	$accordion = $('.ui.request-form').accordion({
		'exclusive' : false,
		onOpen: function(){
			toggleCheckboxonAccordian( this, 'set checked');
		},

		onClose: function(){
			toggleCheckboxonAccordian( this, 'set unchecked');
		}
	});


	/**
	 * Initialize checkbox
	 */
	$('.ui .checkbox').checkbox();



	$("input[type='radio']").change(function(){
	   if(this.checked) {
		$('div.ui.segment.add_blue').removeClass('add_blue');
		$('b').removeClass('blue_text');
		$(this).parent().parent().addClass('add_blue');
		$(this).addClass('blue_text');
	   }
	});

	$('.add_blue').hide();

	$("input[type='radio']").change(function(){
	   if(this.checked) {
		$(this).parent().find('b').addClass('blue_text');
	   }
	});


    // Hamburger menu for sidebar
	var initSidebar = function(){
		var $sidebar_menu = $('#sidebar_menu');
		var OPEN_MENU_CLASS = 'sidebar';
		var CLOSE_MENU_CLASS = 'remove';

		$toggle = $('.ui.sidebar')
				.sidebar('attach events', '#sidebar_menu');
	}
	initSidebar();




	var CLICKABLE_CLASS = 'clickable';
	var LIST_ACTIVE_CLASS = 'active';
	var $listDetail = $('#list_detail');
	var $listBack = $('.close', $listDetail);

	var $currentActiveItem, $request_form, $request_form_lab;


	/**
	 * Handling the slide out navigation for search doctor
	 */
  /*	var handleSearchDoctorDetail = function( onClickHandler ){
		$searchList = $('#search_list');

		$lists = $('.item', $searchList);

		$.each( $lists, function(index, list){
			$(this).click( function(event){
				onClickHandler( $(this), event );
			});
		});
	}
  */


	/**
	 * This callback is iterated for all the search results.
	 * This is called from handleSearchDoctorDetail function.
	 *
	 * This function right now is used only to demonstrate click action on the
	 * search result. This function can be used to add the action that triggers
	 * the modal popup.
	 * @param  {node} item  Each doctor result
	 * @param  {event} event Click event
	 */
	var itemClickHandler = function( item, event ){

		// No need to do any action if there is button or any other clickable actions
		if(event.target.classList.contains(CLICKABLE_CLASS)){
			return;
		}

		$listDetail.removeClass(LIST_ACTIVE_CLASS);

		if( item.hasClass(LIST_ACTIVE_CLASS) ){
			closeSlider(item);
			return;
		} else {
			openSlider(item);
			return;
		}

	}

	var closeSlider = function(item){
		$listDetail.removeClass( LIST_ACTIVE_CLASS );
		item.removeClass( LIST_ACTIVE_CLASS );
	}

	var openSlider = function(item){
		if( $currentActiveItem ){
			$currentActiveItem.removeClass(LIST_ACTIVE_CLASS)
		}

		item.addClass(LIST_ACTIVE_CLASS);
		$listDetail.addClass( LIST_ACTIVE_CLASS );

		$currentActiveItem = item;
	}

	$listBack.click( function(){
		closeSlider($currentActiveItem);
	});

  //	handleSearchDoctorDetail( itemClickHandler );



    $filterTabs = $('.filter-tabs .tabs .item');

    function handleFilterTabs(clickCallback){
    	$.each( $filterTabs, function(index, tab){
    		var $tab, tab_target, $tab_target;

    		$tab = $(tab);
    		tab_target = $tab.data('tab');
    		$tab_target = $('#' + tab_target);

    		$tab.click( function(){
    			clickCallback($tab_target, $tab);
    		});
    	});
    }

    var $active_tab = $('.filter-tabs .tabs .item.active');
    var $active_tab_target = $('.content-holder .tab-target.active');

    var handleTabClick = function($tab_target, $tab){

    	if( $active_tab_target ){
    		$active_tab_target.removeClass('active');
    	}

    	if( $active_tab ){
    		$active_tab.removeClass('active');
    	}

    	if($tab_target.hasClass('active')){
    		return;
    	}

    	$tab.addClass('active');
    	$tab_target.addClass('active');

    	if( $tab.data('tab') === 'map_tab'){
    		google.maps.event.trigger(map, "resize");
    	}

    	$active_tab_target = $tab_target;
    	$active_tab = $tab;
    }

    handleFilterTabs(handleTabClick);





});
