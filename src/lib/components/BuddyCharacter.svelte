<script lang="ts">
  import buddyImage from "$lib/assets/buddy-placeholder.svg";

  let {
    reactionToken,
    onInteract,
  }: {
    reactionToken: number;
    onInteract: () => void | Promise<void>;
  } = $props();

  let lastReactionToken = $state(0);
  let isReacting = $state(false);
  let reactionTimer: ReturnType<typeof setTimeout> | null = null;

  $effect(() => {
    if (reactionToken === lastReactionToken) {
      return;
    }

    lastReactionToken = reactionToken;
    isReacting = true;

    if (reactionTimer) {
      clearTimeout(reactionTimer);
    }

    reactionTimer = setTimeout(() => {
      isReacting = false;
      reactionTimer = null;
    }, 520);
  });

  function handleClick() {
    void onInteract();
  }
</script>

<button
  class:reacting={isReacting}
  class="buddy-character"
  type="button"
  aria-label="React with buddy"
  onclick={handleClick}
>
  <img src={buddyImage} alt="" draggable="false" />
</button>

<style>
  .buddy-character {
    width: 176px;
    height: 190px;
    border: 0;
    padding: 0;
    background: transparent;
    cursor: pointer;
    filter: drop-shadow(0 18px 20px rgb(15 23 42 / 0.2));
    transform-origin: 50% 92%;
    animation: idle-bob 2.8s ease-in-out infinite;
  }

  .buddy-character img {
    width: 100%;
    height: 100%;
    display: block;
    user-select: none;
    pointer-events: none;
  }

  .buddy-character.reacting {
    animation: tap-reaction 520ms cubic-bezier(.2, .9, .2, 1);
  }

  .buddy-character:focus-visible {
    outline: 3px solid #2563eb;
    outline-offset: 8px;
    border-radius: 24px;
  }

  @keyframes idle-bob {
    0%,
    100% {
      transform: translateY(0) rotate(-1deg);
    }

    50% {
      transform: translateY(-8px) rotate(1deg);
    }
  }

  @keyframes tap-reaction {
    0% {
      transform: translateY(0) scale(1) rotate(0deg);
    }

    35% {
      transform: translateY(-22px) scale(1.08) rotate(-5deg);
    }

    70% {
      transform: translateY(4px) scale(.98) rotate(4deg);
    }

    100% {
      transform: translateY(0) scale(1) rotate(0deg);
    }
  }
</style>
