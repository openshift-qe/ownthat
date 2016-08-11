$('table').on('click', '.clickable-row', function(event) {
  $(this).toggleClass("active");
  // if($(this).hasClass('active')){
  //  $(this).removeClass('active');
  // } else {
  //   $(this).addClass('active') // .siblings().removeClass('active');
  // }
});
