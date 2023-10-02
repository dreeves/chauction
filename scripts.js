// http://padm.us/ep/pad/export/<padname>/latest?format=txt
$(document).ready( function(){
  $('.submit').click( function() {
    if ( $(this).attr('disabled') ) {
      return;
    }
    $('.submit').html("<img src='spinner3-bluey.gif' />").attr('disabled','true').css('padding', '0 10px');
    $.ajax({
      url: 'wrapper.php', 
      success: function(data) { 
        $('#results').html(data); 
        $('.submit').removeAttr('disabled').html('Recalculate').css('padding', '4px 10px');
      }
    });
  }); 
  $('.submit').click();
});
