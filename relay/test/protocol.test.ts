import { describe, expect, test } from "vitest";
import { allowMessage, isValidRoomCode, parseRelayMessage } from "../src/protocol";

describe("room code validation", () => {
  test("accepts eight character non-ambiguous uppercase base32 codes", () => {
    expect(isValidRoomCode("ABCD2345")).toBe(true);
  });

  test("rejects ambiguous, lowercase, and wrong length codes", () => {
    expect(isValidRoomCode("ABCD1234")).toBe(false);
    expect(isValidRoomCode("abcd2345")).toBe(false);
    expect(isValidRoomCode("ABCD234")).toBe(false);
    expect(isValidRoomCode("ABCD23456")).toBe(false);
  });
});

describe("relay message parsing", () => {
  test("accepts valid chat messages", () => {
    const message = parseRelayMessage(
      JSON.stringify({
        type: "chat_message",
        message_id: "message-1",
        device_id: "device-1",
        display_name: "Buddy",
        text: "hello",
        sent_at: 1770000000,
      }),
    );

    expect(message).toEqual({
      type: "chat_message",
      message_id: "message-1",
      device_id: "device-1",
      display_name: "Buddy",
      text: "hello",
      sent_at: 1770000000,
    });
  });

  test("rejects oversized chat text", () => {
    const message = parseRelayMessage(
      JSON.stringify({
        type: "chat_message",
        message_id: "message-1",
        device_id: "device-1",
        display_name: "Buddy",
        text: "x".repeat(281),
        sent_at: 1770000000,
      }),
    );

    expect(message).toBeNull();
  });

  test("accepts ping heartbeats", () => {
    const message = parseRelayMessage(
      JSON.stringify({
        type: "ping",
        device_id: "device-1",
        display_name: "Buddy",
        sent_at: 1770000000,
      }),
    );

    expect(message).toEqual({
      type: "ping",
      device_id: "device-1",
      display_name: "Buddy",
      sent_at: 1770000000,
    });
  });
});

describe("rate limiting", () => {
  test("allows only twenty messages within ten seconds", () => {
    const meta = { deviceId: "device-1", displayName: "Buddy", messageTimestamps: [] };

    for (let index = 0; index < 20; index += 1) {
      expect(allowMessage(meta, 1000)).toBe(true);
    }

    expect(allowMessage(meta, 1000)).toBe(false);
    expect(allowMessage(meta, 12_000)).toBe(true);
  });
});
