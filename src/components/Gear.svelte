<script>
  console.log(document);

  $: scrollPercent = 0;

  function getScrollPercent() {
    let h = document.documentElement,
      b = document.body,
      st = "scrollTop",
      sh = "scrollHeight";
    return (h[st] || b[st]) / ((h[sh] || b[sh]) - h.clientHeight);
  }

  setInterval(() => {
    scrollPercent = getScrollPercent();
  }, 5);
</script>

<div style="transform: scale(20%) translate(-50%, 50%); transform-origin: bottom left">
  <div
    style="transform: rotate({scrollPercent}turn); transform-origin: center;"
  >
    <img src="/assets/gear.webp" alt="A gear." />
  </div>
</div>
