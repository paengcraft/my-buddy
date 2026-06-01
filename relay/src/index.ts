import { DurableObject } from "cloudflare:workers";
import {
  allowMessage,
  isValidRoomCode,
  parseRelayMessage,
  type ClientMeta,
} from "./protocol";

export interface Env {
  PAIRING_ROOM: DurableObjectNamespace<PairingRoom>;
}

const maximumSocketsPerRoom = 2;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function defaultMeta(): ClientMeta {
  return {
    deviceId: "",
    displayName: "Nearby Buddy",
    messageTimestamps: [],
  };
}

function readMeta(socket: WebSocket): ClientMeta {
  const attachment = socket.deserializeAttachment();
  if (isRecord(attachment)) {
    return {
      deviceId: typeof attachment.deviceId === "string" ? attachment.deviceId : "",
      displayName:
        typeof attachment.displayName === "string" ? attachment.displayName : "Nearby Buddy",
      messageTimestamps: Array.isArray(attachment.messageTimestamps)
        ? attachment.messageTimestamps.filter((value): value is number => typeof value === "number")
        : [],
    };
  }
  return defaultMeta();
}

function writeMeta(socket: WebSocket, meta: ClientMeta): void {
  socket.serializeAttachment(meta);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/health") {
      return Response.json({ ok: true });
    }

    const match = url.pathname.match(/^\/room\/([A-Z2-9]{8})$/);
    const roomCode = match?.[1];
    if (!roomCode || !isValidRoomCode(roomCode)) {
      return new Response("Not found", { status: 404 });
    }

    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("Expected WebSocket", { status: 426 });
    }

    const id = env.PAIRING_ROOM.idFromName(roomCode);
    return env.PAIRING_ROOM.get(id).fetch(request);
  },
};

export class PairingRoom extends DurableObject<Env> {
  async fetch(): Promise<Response> {
    if (this.ctx.getWebSockets().length >= maximumSocketsPerRoom) {
      return Response.json({ type: "error", code: "room_full" }, { status: 409 });
    }

    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];
    this.ctx.acceptWebSocket(server);
    writeMeta(server, defaultMeta());
    server.send(JSON.stringify({ type: "ready" }));
    return new Response(null, { status: 101, webSocket: client });
  }

  async webSocketMessage(socket: WebSocket, message: string | ArrayBuffer): Promise<void> {
    const meta = readMeta(socket);
    if (!allowMessage(meta, Date.now())) {
      writeMeta(socket, meta);
      socket.send(JSON.stringify({ type: "error", code: "rate_limited" }));
      return;
    }

    const parsed = parseRelayMessage(message);
    if (!parsed) {
      writeMeta(socket, meta);
      socket.send(JSON.stringify({ type: "error", code: "invalid_message" }));
      return;
    }

    meta.deviceId = parsed.device_id;
    meta.displayName = parsed.display_name;
    writeMeta(socket, meta);

    if (parsed.type === "hello") {
      for (const existingSocket of this.ctx.getWebSockets()) {
        if (existingSocket === socket) {
          continue;
        }

        const existingMeta = readMeta(existingSocket);
        if (existingMeta.deviceId.length > 0) {
          socket.send(JSON.stringify({
            type: "peer",
            device_id: existingMeta.deviceId,
            display_name: existingMeta.displayName,
          }));
        }
      }

      this.broadcast(socket, {
        type: "peer",
        device_id: parsed.device_id,
        display_name: parsed.display_name,
      });
      return;
    }

    if (parsed.type === "ping") {
      socket.send(JSON.stringify({ type: "pong", server_time: Date.now() }));
      return;
    }

    this.broadcast(socket, parsed);
  }

  async webSocketClose(socket: WebSocket): Promise<void> {
    writeMeta(socket, defaultMeta());
  }

  async webSocketError(socket: WebSocket): Promise<void> {
    writeMeta(socket, defaultMeta());
  }

  private broadcast(sender: WebSocket, payload: unknown): void {
    const data = JSON.stringify(payload);
    for (const socket of this.ctx.getWebSockets()) {
      if (socket !== sender) {
        socket.send(data);
      }
    }
  }
}
