import { get } from "svelte/store";
import { afterEach, describe, expect, test, vi } from "vitest";
import { createBuddyEventController } from "./buddyEvents";

describe("buddy event controller", () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  test("increments the reaction token for local reactions", () => {
    const controller = createBuddyEventController();

    controller.triggerReaction();

    expect(get(controller.state).reactionToken).toBe(1);
  });

  test("increments the reaction token for peer reaction events", () => {
    const controller = createBuddyEventController();

    controller.applyFrontendEvent({
      type: "reaction",
      device_id: "peer-1",
      reaction: "tap",
    });

    expect(get(controller.state).reactionToken).toBe(1);
  });

  test("shows and clears a peer chat bubble", () => {
    vi.useFakeTimers();
    const controller = createBuddyEventController({ bubbleDurationMs: 1200 });

    controller.applyFrontendEvent({
      type: "chat_message",
      device_id: "peer-1",
      text: "hello",
      sent_at: "1",
    });

    expect(get(controller.state).activeBubble?.text).toBe("hello");

    vi.advanceTimersByTime(1200);

    expect(get(controller.state).activeBubble).toBeNull();
  });

  test("adds discovered peers by device id", () => {
    const controller = createBuddyEventController();

    controller.applyFrontendEvent({
      type: "peer_discovered",
      peer: {
        device_id: "peer-1",
        display_name: "Desk",
        address: "192.168.1.20:49277",
        last_seen_ms: 123,
      },
    });

    expect(get(controller.state).peers).toHaveLength(1);
    expect(get(controller.state).peers[0]?.display_name).toBe("Desk");
  });
});
