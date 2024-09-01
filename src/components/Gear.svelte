<script>
  console.log(document);

  $: rotation = 0;

  function getRotation() {
    console.info(document.documentElement.scrollTop * .0005)
    return document.documentElement.scrollTop * .0005;
  }

  setInterval(() => {
    rotation = getRotation();
  }, 5);
</script>

<div style="transform: scale(20%) translate(-50%, 50%); transform-origin: bottom left">
  <div
    style="transform: rotate({rotation}turn); transform-origin: center;"
  >
    <img src="/assets/gear.webp" alt="A gear." />
  </div>
</div>
