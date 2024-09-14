<script>
    $: selected = "Incorrect";

		function selectCorrect() {
    		selected = "Correct"
		}
		function selectIncorrect() {
    		selected = "Incorrect"
		}
    
</script>


<style>
    .button {
   		background-color: #000000;
   		border: 1px;
   		border-color: #ffffff;
   		border-style: solid;
   		padding: 5px;
   		margin: 0px;
    }

    .no-margin {
        margin: 0px;
    }
</style>

<div>
    <button on:click={selectIncorrect} class="button">
        Incorrect
    </button>
    <button on:click={selectCorrect} class="button">
        Correct
    </button>
    <div>
        {#if selected == "Correct"}
            <slot name="Correct" class="no-margin"/>
        {/if}
        {#if selected == "Incorrect"}
            <slot name="Incorrect" class="no-margin"/>
        {/if}
    </div>
</div>

