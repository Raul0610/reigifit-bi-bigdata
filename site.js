function toggleMobileMenu(){
  var menu = document.getElementById('mobileMenu');
  var btn = document.querySelector('.hamburger');
  if(!menu) return;
  var isOpen = menu.classList.toggle('open');
  if(btn){ btn.setAttribute('aria-expanded', isOpen ? 'true' : 'false'); }
}
