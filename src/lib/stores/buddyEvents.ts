import { writable, type Writable } from "svelte/store";

export type ReactionKind = "tap";

export type PeerInfo = {
  device_id: string;
  display_name: string;
  address: string;
  last_seen_ms: number;
};

export type FrontendEvent =
  | {
      type: "reaction";
      device_id: string;
      reaction: ReactionKind;
    }
  | {
      type: "chat_message";
      device_id: string;
      text: string;
      sent_at: string;
    }
  | {
      type: "peer_discovered";
      peer: PeerInfo;
    };

export type SpeechBubbleMessage = {
  deviceId: string;
  text: string;
  sentAt: string;
};

export type BuddyUiState = {
  reactionToken: number;
  activeBubble: SpeechBubbleMessage | null;
  peers: PeerInfo[];
  networkError: string | null;
};

export type BuddyEventController = {
  state: Writable<BuddyUiState>;
  triggerReaction: () => void;
  showLocalBubble: (text: string) => void;
  applyFrontendEvent: (event: FrontendEvent) => void;
  setNetworkError: (message: string | null) => void;
};

const DEFAULT_BUBBLE_DURATION_MS = 3200;

export function createBuddyEventController(options?: {
  bubbleDurationMs?: number;
}): BuddyEventController {
  const bubbleDurationMs = options?.bubbleDurationMs ?? DEFAULT_BUBBLE_DURATION_MS;
  const state = writable<BuddyUiState>({
    reactionToken: 0,
    activeBubble: null,
    peers: [],
    networkError: null,
  });
  let bubbleTimer: ReturnType<typeof setTimeout> | null = null;

  function triggerReaction() {
    state.update((current) => ({
      ...current,
      reactionToken: current.reactionToken + 1,
    }));
  }

  function showBubble(message: SpeechBubbleMessage) {
    if (bubbleTimer) {
      clearTimeout(bubbleTimer);
    }

    state.update((current) => ({
      ...current,
      activeBubble: message,
    }));

    bubbleTimer = setTimeout(() => {
      state.update((current) => ({
        ...current,
        activeBubble: null,
      }));
      bubbleTimer = null;
    }, bubbleDurationMs);
  }

  function showLocalBubble(text: string) {
    showBubble({
      deviceId: "local",
      text,
      sentAt: Date.now().toString(),
    });
  }

  function upsertPeer(peer: PeerInfo) {
    state.update((current) => {
      const peers = current.peers.filter(
        (candidate) => candidate.device_id !== peer.device_id,
      );

      return {
        ...current,
        peers: [...peers, peer].sort((left, right) =>
          left.display_name.localeCompare(right.display_name),
        ),
      };
    });
  }

  function applyFrontendEvent(event: FrontendEvent) {
    if (event.type === "reaction") {
      triggerReaction();
      return;
    }

    if (event.type === "chat_message") {
      showBubble({
        deviceId: event.device_id,
        text: event.text,
        sentAt: event.sent_at,
      });
      return;
    }

    upsertPeer(event.peer);
  }

  function setNetworkError(message: string | null) {
    state.update((current) => ({
      ...current,
      networkError: message,
    }));
  }

  return {
    state,
    triggerReaction,
    showLocalBubble,
    applyFrontendEvent,
    setNetworkError,
  };
}
