<script lang="ts">
  import type { SpeechBubbleMessage } from "$lib/stores/buddyEvents";

  let {
    message,
  }: {
    message: SpeechBubbleMessage | null;
  } = $props();
</script>

{#if message}
  <div class="speech-bubble" role="status" aria-live="polite">
    {message.text}
  </div>
{/if}

<style>
  .speech-bubble {
    max-width: 220px;
    padding: 10px 13px;
    border: 2px solid #1f2937;
    border-radius: 18px;
    background: #fffdf5;
    color: #172033;
    font-size: 14px;
    font-weight: 700;
    line-height: 1.32;
    text-align: center;
    box-shadow: 0 10px 22px rgb(15 23 42 / 0.14);
    overflow-wrap: anywhere;
    animation: bubble-in 180ms ease-out;
  }

  .speech-bubble::after {
    content: "";
    position: absolute;
    left: 50%;
    bottom: -9px;
    width: 16px;
    height: 16px;
    border-right: 2px solid #1f2937;
    border-bottom: 2px solid #1f2937;
    background: #fffdf5;
    transform: translateX(-50%) rotate(45deg);
  }

  @keyframes bubble-in {
    from {
      opacity: 0;
      transform: translateY(8px) scale(.96);
    }

    to {
      opacity: 1;
      transform: translateY(0) scale(1);
    }
  }
</style>
