<script>
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
    filter: invert(88%) sepia(58%) saturate(0%) hue-rotate(140deg) brightness(98%) contrast(69%);
	}
</style>

<div class="gear">
  <div
    style="transform: rotate({rotation}turn); transform-origin: center;"
  >
    <img src="/assets/gear.webp" alt="A gear." />
  </div>
</div>
