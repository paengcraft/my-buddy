<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";
  import { listen } from "@tauri-apps/api/event";
  import { onMount } from "svelte";
  import BuddyCharacter from "$lib/components/BuddyCharacter.svelte";
  import MessageComposer from "$lib/components/MessageComposer.svelte";
  import SpeechBubble from "$lib/components/SpeechBubble.svelte";
  import {
    createBuddyEventController,
    type FrontendEvent,
    type PeerInfo,
  } from "$lib/stores/buddyEvents";
  import { createConnectionLabel } from "$lib/stores/connection";

  type LocalIdentity = {
    device_id: string;
    display_name: string;
  };

  const buddy = createBuddyEventController();
  const buddyState = buddy.state;
  const connectionLabel = createConnectionLabel(buddyState);

  let displayName = $state("Buddy");

  onMount(() => {
    let cleanup: (() => void) | undefined;
    let peerRefresh: ReturnType<typeof setInterval> | undefined;

    async function start() {
      try {
        const identity = await invoke<LocalIdentity>("get_local_identity");
        displayName = identity.display_name;
      } catch (error) {
        buddy.setNetworkError(String(error));
      }

      try {
        cleanup = await listen<FrontendEvent>("buddy-event", (event) => {
          buddy.applyFrontendEvent(event.payload);
        });
      } catch (error) {
        buddy.setNetworkError(String(error));
      }

      peerRefresh = setInterval(async () => {
        try {
          const peers = await invoke<PeerInfo[]>("list_peers");
          for (const peer of peers) {
            buddy.applyFrontendEvent({ type: "peer_discovered", peer });
          }
        } catch (error) {
          buddy.setNetworkError(String(error));
        }
      }, 4000);
    }

    void start();

    return () => {
      cleanup?.();
      if (peerRefresh) {
        clearInterval(peerRefresh);
      }
    };
  });

  async function reactToBuddy() {
    buddy.triggerReaction();

    try {
      await invoke("send_reaction", { reaction: "tap" });
      buddy.setNetworkError(null);
    } catch (error) {
      buddy.setNetworkError(String(error));
    }
  }

  async function sendMessage(text: string) {
    buddy.showLocalBubble(text);

    try {
      await invoke("send_chat_message", { text });
      buddy.setNetworkError(null);
    } catch (error) {
      buddy.setNetworkError(String(error));
    }
  }
</script>

<main class="buddy-stage" aria-label="Desktop buddy">
  <section class="bubble-slot" aria-label="Buddy message">
    <SpeechBubble message={$buddyState.activeBubble} />
  </section>

  <BuddyCharacter
    reactionToken={$buddyState.reactionToken}
    onInteract={reactToBuddy}
  />

  <section class="controls" aria-label="Buddy controls">
    <div class="status-row">
      <span class="status-dot" class:connected={$buddyState.peers.length > 0}></span>
      <span>{$connectionLabel}</span>
    </div>
    <MessageComposer onSend={sendMessage} />
    {#if $buddyState.networkError}
      <p class="network-error">{$buddyState.networkError}</p>
    {/if}
    <p class="identity">{displayName}</p>
  </section>
</main>

<style>
  :global(html),
  :global(body) {
    width: 100%;
    height: 100%;
    margin: 0;
    overflow: hidden;
    background: transparent;
    font-family:
      Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont,
      "Segoe UI", sans-serif;
  }

  :global(button),
  :global(input) {
    letter-spacing: 0;
  }

  .buddy-stage {
    position: relative;
    display: grid;
    grid-template-rows: 72px 190px auto;
    justify-items: center;
    width: 320px;
    min-height: 360px;
    padding: 14px 16px 16px;
    box-sizing: border-box;
    background: transparent;
    color: #172033;
  }

  .bubble-slot {
    position: relative;
    display: flex;
    align-items: flex-end;
    justify-content: center;
    min-height: 72px;
  }

  .controls {
    display: grid;
    justify-items: center;
    gap: 7px;
    width: 100%;
  }

  .status-row {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    max-width: 260px;
    padding: 6px 10px;
    border-radius: 999px;
    background: rgb(255 255 255 / 0.66);
    color: #172033;
    font-size: 12px;
    font-weight: 800;
    line-height: 1.2;
    box-shadow: 0 8px 20px rgb(15 23 42 / 0.1);
    backdrop-filter: blur(14px);
  }

  .status-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #f59e0b;
    box-shadow: 0 0 0 3px rgb(245 158 11 / 0.18);
  }

  .status-dot.connected {
    background: #10b981;
    box-shadow: 0 0 0 3px rgb(16 185 129 / 0.18);
  }

  .network-error {
    max-width: 260px;
    margin: 0;
    padding: 5px 8px;
    border-radius: 8px;
    background: rgb(254 226 226 / 0.86);
    color: #991b1b;
    font-size: 11px;
    font-weight: 700;
    line-height: 1.25;
    overflow-wrap: anywhere;
  }

  .identity {
    margin: 0;
    color: rgb(23 32 51 / 0.62);
    font-size: 11px;
    font-weight: 800;
  }
</style>
