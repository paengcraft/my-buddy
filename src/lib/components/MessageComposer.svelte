<script lang="ts">
  let {
    onSend,
  }: {
    onSend: (text: string) => void | Promise<void>;
  } = $props();

  let text = $state("");

  function submit(event: SubmitEvent) {
    event.preventDefault();
    const message = text.trim();

    if (!message) {
      return;
    }

    text = "";
    void onSend(message);
  }
</script>

<form class="composer" onsubmit={submit}>
  <input
    aria-label="Message"
    maxlength="120"
    placeholder="Say something"
    bind:value={text}
  />
  <button type="submit" aria-label="Send message">Send</button>
</form>

<style>
  .composer {
    display: flex;
    width: min(260px, 100%);
    gap: 6px;
    padding: 7px;
    border: 1px solid rgb(31 41 55 / 0.16);
    border-radius: 999px;
    background: rgb(255 255 255 / 0.78);
    box-shadow: 0 12px 26px rgb(15 23 42 / 0.12);
    backdrop-filter: blur(16px);
  }

  input {
    min-width: 0;
    flex: 1;
    border: 0;
    border-radius: 999px;
    padding: 8px 10px;
    background: transparent;
    color: #172033;
    font: inherit;
    outline: none;
  }

  button {
    flex: 0 0 auto;
    border: 0;
    border-radius: 999px;
    padding: 8px 12px;
    background: #172033;
    color: white;
    font: inherit;
    font-weight: 800;
    cursor: pointer;
  }

  button:hover {
    background: #2456a6;
  }
</style>
