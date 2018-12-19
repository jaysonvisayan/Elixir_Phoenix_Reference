onmount('input[id="open_modal_facilities"]', function () {
  $('#p_facilities').modal({autofocus: false, closable: false}).modal('show');
  let product_coverage_id = $('.title.facility_accordion.active').attr('productCoverageID');
  $('input[name="product[product_coverage_id]"]').val(product_coverage_id);
});

onmount('input[id="open_modal"]', function () {
	 $('.ui.modal').modal('show');
});

onmount('input[id="open_modal_pb"]', function () {
	 $('#pb_modal').modal('show');
});

onmount('input[id="open_modal_pb"]', function () {
	 $('#pb_modal_edit').modal('show');
});

onmount('input[id="open_modal_benefit_limits"]', function () {
	 $('#add_modal').modal('show');
});

onmount('input[id="open_modal_genex"]', function () {
	 $('.ui.genex.modal').modal('show');
});

onmount('input[id="open_modal_pre_exist"]', function () {
	 $('.ui.pre-existing.modal').modal('show');
});

onmount('input[id="open_modal_exclusion_disease"]', function () {
	 $('#add_disease').modal('show');
});

onmount('input[id="open_modal_exclusion_procedure"]', function () {
	 $('#procedure_modal').modal('show');
});

onmount('input[id="open_modal_benefit_disease"]', function () {
	 $('#modalAddDisease').modal('show');
});

onmount('input[id="open_modal_benefit_procedure"]', function () {
	 $('#modalAddProcedure').modal('show');
});

onmount('input[id="open_modal_benefit_ruv"]', function () {
	 $('#modalAddRUV').modal('show');
});

onmount('input[id="open_modal_benefit_package"]', function () {
	 $('#modalAddPackage').modal('show');
});

onmount('input[id="open_modal_benefit_pharmacy"]', function () {
	 $('#modalAddPharmacy').modal('show');
});

onmount('input[id="open_modal_benefit_miscellaneous"]', function () {
	 $('#modalAddMiscellaneous').modal('show');
});
