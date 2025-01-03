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

    .button-selected {
   		background-color: #cccccc;
   		border: 1px;
   		border-color: #ffffff;
   		color: #000000;
   		border-style: solid;
   		padding: 5px;
   		margin: 0px;
    }

    .no-margin {
        margin: 0px;
    }
</style>

<div>
    {#if selected == "Correct"}
        <button on:click={selectIncorrect} class="button">
            Incorrect
        </button>
        <button on:click={selectCorrect} class="button-selected">
            Correct
        </button>
    {/if}
    {#if selected == "Incorrect"}
        <button on:click={selectIncorrect} class="button-selected">
            Incorrect
        </button>
        <button on:click={selectCorrect} class="button">
            Correct
        </button>
    {/if}
    <div>
        {#if selected == "Correct"}
            <slot name="Correct" class="no-margin"/>
        {/if}
        {#if selected == "Incorrect"}
            <slot name="Incorrect" class="no-margin"/>
        {/if}
    </div>
</div>

