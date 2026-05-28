use crate::{
    models::{BuddyEvent, FrontendEvent, WireEvent},
    state::{is_self_event, now_ms, peer_from_presence, AppState},
};
use std::{net::SocketAddr, sync::Arc, time::Duration};
use tauri::{AppHandle, Emitter};
use tokio::net::UdpSocket;

pub const BUDDY_PORT: u16 = 49277;
pub const FRONTEND_EVENT_NAME: &str = "buddy-event";

const BROADCAST_ADDRESS: &str = "255.255.255.255:49277";
const BUFFER_SIZE: usize = 4096;

pub async fn bind_udp_socket() -> std::io::Result<UdpSocket> {
    let socket = UdpSocket::bind(("0.0.0.0", BUDDY_PORT)).await?;
    socket.set_broadcast(true)?;
    Ok(socket)
}

pub fn start_listener(app_handle: AppHandle, app_state: Arc<AppState>) {
    let Some(socket) = app_state.udp_socket.clone() else {
        return;
    };

    tauri::async_runtime::spawn(async move {
        let mut buffer = [0_u8; BUFFER_SIZE];

        loop {
            let Ok((size, source)) = socket.recv_from(&mut buffer).await else {
                continue;
            };

            let Ok(event) = serde_json::from_slice::<WireEvent>(&buffer[..size]) else {
                continue;
            };

            route_inbound_event(&app_handle, &app_state, event, source);
        }
    });
}

pub fn start_presence_loop(app_state: Arc<AppState>) {
    tauri::async_runtime::spawn(async move {
        loop {
            let event = WireEvent::presence(
                app_state.identity.device_id.clone(),
                app_state.identity.display_name.clone(),
            );
            let _ = broadcast_wire_event(&app_state, event).await;
            tokio::time::sleep(Duration::from_secs(5)).await;
        }
    });
}

pub async fn broadcast_buddy_event(
    app_state: &AppState,
    buddy_event: BuddyEvent,
) -> Result<(), String> {
    let event = match buddy_event {
        BuddyEvent::Presence => WireEvent::presence(
            app_state.identity.device_id.clone(),
            app_state.identity.display_name.clone(),
        ),
        other => WireEvent::from_local(app_state.identity.device_id.clone(), other),
    };

    broadcast_wire_event(app_state, event).await
}

async fn broadcast_wire_event(app_state: &AppState, event: WireEvent) -> Result<(), String> {
    let Some(socket) = app_state.udp_socket.as_ref() else {
        return Err("LAN socket is not available.".to_string());
    };

    let payload = serde_json::to_vec(&event).map_err(|error| error.to_string())?;
    socket
        .send_to(&payload, BROADCAST_ADDRESS)
        .await
        .map_err(|error| error.to_string())?;

    Ok(())
}

fn route_inbound_event(
    app_handle: &AppHandle,
    app_state: &AppState,
    event: WireEvent,
    source: SocketAddr,
) {
    if is_self_event(&app_state.identity.device_id, &event) {
        return;
    }

    if let Some(peer) = peer_from_presence(&event, &source.to_string(), now_ms()) {
        if let Ok(mut peers) = app_state.peers.lock() {
            peers.insert(peer.device_id.clone(), peer.clone());
        }

        let _ = app_handle.emit(FRONTEND_EVENT_NAME, FrontendEvent::PeerDiscovered { peer });
        return;
    }

    let frontend_event = match event {
        WireEvent::Reaction {
            device_id,
            reaction,
        } => FrontendEvent::Reaction {
            device_id,
            reaction,
        },
        WireEvent::ChatMessage {
            device_id,
            text,
            sent_at,
        } => FrontendEvent::ChatMessage {
            device_id,
            text,
            sent_at,
        },
        WireEvent::Presence { .. } => return,
    };

    let _ = app_handle.emit(FRONTEND_EVENT_NAME, frontend_event);
}
