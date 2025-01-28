document.addEventListener("DOMContentLoaded", function () {
  const menu = document.querySelector(".eww-menu");
  const buttons = document.querySelectorAll(".button");

  buttons.forEach((button) => {
    button.addEventListener("click", function () {
      menu.style.transform = "translateX(-100%)";
      setTimeout(() => {
        menu.style.display = "none";
      }, 300);
    });
  });
});
