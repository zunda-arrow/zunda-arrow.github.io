<script>
  console.log(document);

  $: rotation = 0;

  function getRotation() {
    return document.documentElement.scrollTop * .0005;
  }

  setInterval(() => {
    rotation = getRotation();
  }, 5);
</script>

<style>
	.gear {
    transform: scale(25%) translate(-45%, 45%);
    transform-origin: bottom left;
    filter: brightness(0) invert(100%);
    visibility: visible;
	}

  @media (orientation: portrait) {
  	.gear {
      visibility: hidden;
    }
  }
</style>

<div class="gear">
  <div
    style="transform: rotate({rotation}turn); transform-origin: center;"
  >
    <img src="/assets/gear.webp" alt="A gear." />
  </div>
</div>
