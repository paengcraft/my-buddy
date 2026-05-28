import { derived } from "svelte/store";
import type { BuddyUiState } from "./buddyEvents";

export function createConnectionLabel(state: import("svelte/store").Readable<BuddyUiState>) {
  return derived(state, ($state) => {
    if ($state.peers.length === 0) {
      return "Wi-Fi peer not found";
    }

    if ($state.peers.length === 1) {
      return `Connected nearby: ${$state.peers[0].display_name}`;
    }

    return `${$state.peers.length} nearby buddies`;
  });
}
