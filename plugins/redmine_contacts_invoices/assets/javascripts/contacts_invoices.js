function remove_fields (link) {
	$(link).prev("input[type=hidden]").val("1")
  $(link).parents('.fields').fadeOut("slow");
}

function add_fields (link, association, content) {
	var	new_id = new Date().getTime();
	var regexp = new RegExp("new_" + association, "g");
	$('#sortable tr').last().after(content.replace(regexp, new_id))
  // insert({'after':content.replace(regexp, new_id)});
	// new Effect.Highlight(new_id);
}

function formatCurrency(num) {
    num = isNaN(num) || num === '' || num === null ? 0.00 : num;
    return parseFloat(num).toFixed(2);
}

function updateTotal(element) {
	row = $(element).parents('tr');
	amount_value = row.find('.price input').val() * row.find('.quantity input').val();
  row.find('.total').html(formatCurrency(amount_value));
	return false;
}

function activateTextAreaResize(element) {
  $(element).keyup(function() {
    while($(element).outerHeight() < element.scrollHeight + parseFloat($(element).css("borderTopWidth")) + parseFloat($(element).css("borderBottomWidth")) && $(element).outerHeight() < 300) {
          $(element).height($(element).height()+15);
    };
  });

}


