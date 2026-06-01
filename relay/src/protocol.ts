export type RelayMessage =
  | { type: "hello"; device_id: string; display_name: string }
  | { type: "ping"; device_id: string; display_name: string; sent_at: number }
  | {
      type: "reaction";
      message_id: string;
      device_id: string;
      display_name: string;
      reaction_id: string;
      sent_at: number;
    }
  | {
      type: "chat_message";
      message_id: string;
      device_id: string;
      display_name: string;
      text: string;
      sent_at: number;
    };

export type ClientMeta = {
  deviceId: string;
  displayName: string;
  messageTimestamps: number[];
};

const roomCodePattern = /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$/;
const maximumMessageBytes = 2048;
const maximumMessagesPerWindow = 20;
const rateWindowMs = 10_000;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isShortString(value: unknown, maximumLength: number): value is string {
  return typeof value === "string" && value.length > 0 && value.length <= maximumLength;
}

export function isValidRoomCode(value: string): boolean {
  return roomCodePattern.test(value);
}

export function parseRelayMessage(message: string | ArrayBuffer): RelayMessage | null {
  if (typeof message !== "string") {
    return null;
  }
  if (new TextEncoder().encode(message).byteLength > maximumMessageBytes) {
    return null;
  }

  let value: unknown;
  try {
    value = JSON.parse(message);
  } catch {
    return null;
  }

  if (!isRecord(value)) {
    return null;
  }

  if (value.type === "hello") {
    if (!isShortString(value.device_id, 128) || !isShortString(value.display_name, 80)) {
      return null;
    }
    return {
      type: "hello",
      device_id: value.device_id,
      display_name: value.display_name,
    };
  }

  if (value.type === "ping") {
    if (
      !isShortString(value.device_id, 128) ||
      !isShortString(value.display_name, 80) ||
      typeof value.sent_at !== "number"
    ) {
      return null;
    }
    return {
      type: "ping",
      device_id: value.device_id,
      display_name: value.display_name,
      sent_at: value.sent_at,
    };
  }

  if (value.type === "reaction") {
    if (
      !isShortString(value.message_id, 128) ||
      !isShortString(value.device_id, 128) ||
      !isShortString(value.display_name, 80) ||
      !isShortString(value.reaction_id, 80) ||
      typeof value.sent_at !== "number"
    ) {
      return null;
    }
    return {
      type: "reaction",
      message_id: value.message_id,
      device_id: value.device_id,
      display_name: value.display_name,
      reaction_id: value.reaction_id,
      sent_at: value.sent_at,
    };
  }

  if (value.type === "chat_message") {
    if (
      !isShortString(value.message_id, 128) ||
      !isShortString(value.device_id, 128) ||
      !isShortString(value.display_name, 80) ||
      typeof value.text !== "string" ||
      value.text.trim().length === 0 ||
      value.text.length > 280 ||
      typeof value.sent_at !== "number"
    ) {
      return null;
    }
    return {
      type: "chat_message",
      message_id: value.message_id,
      device_id: value.device_id,
      display_name: value.display_name,
      text: value.text,
      sent_at: value.sent_at,
    };
  }

  return null;
}

export function allowMessage(meta: ClientMeta, now: number): boolean {
  meta.messageTimestamps = meta.messageTimestamps.filter(
    (timestamp) => now - timestamp < rateWindowMs,
  );
  if (meta.messageTimestamps.length >= maximumMessagesPerWindow) {
    return false;
  }
  meta.messageTimestamps.push(now);
  return true;
}
