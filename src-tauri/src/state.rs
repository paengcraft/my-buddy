use crate::models::{LocalIdentity, PeerInfo, WireEvent};
use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
    time::{SystemTime, UNIX_EPOCH},
};
use tokio::net::UdpSocket;
use uuid::Uuid;

pub const MAX_CHAT_TEXT_LEN: usize = 120;

pub struct AppState {
    pub identity: LocalIdentity,
    pub peers: Mutex<HashMap<String, PeerInfo>>,
    pub udp_socket: Option<Arc<UdpSocket>>,
}

impl AppState {
    pub fn new(display_name: impl Into<String>, udp_socket: Option<Arc<UdpSocket>>) -> Self {
        Self {
            identity: LocalIdentity {
                device_id: Uuid::new_v4().to_string(),
                display_name: display_name.into(),
            },
            peers: Mutex::new(HashMap::new()),
            udp_socket,
        }
    }
}

pub fn validate_chat_text(text: &str) -> Result<String, String> {
    let trimmed = text.trim();

    if trimmed.is_empty() {
        return Err("Message cannot be blank.".to_string());
    }

    if trimmed.chars().count() > MAX_CHAT_TEXT_LEN {
        return Err(format!(
            "Message must be {MAX_CHAT_TEXT_LEN} characters or fewer."
        ));
    }

    Ok(trimmed.to_string())
}

pub fn is_self_event(local_device_id: &str, event: &WireEvent) -> bool {
    event.device_id() == local_device_id
}

pub fn peer_from_presence(
    event: &WireEvent,
    address: &str,
    last_seen_ms: u128,
) -> Option<PeerInfo> {
    match event {
        WireEvent::Presence {
            device_id,
            display_name,
        } => Some(PeerInfo {
            device_id: device_id.clone(),
            display_name: display_name.clone(),
            address: address.to_string(),
            last_seen_ms,
        }),
        _ => None,
    }
}

pub fn now_ms() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis())
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{BuddyEvent, ReactionKind, WireEvent};

    #[test]
    fn accepts_short_chat_message() {
        assert_eq!(validate_chat_text("hello").unwrap(), "hello");
    }

    #[test]
    fn rejects_blank_chat_message() {
        assert!(validate_chat_text("   ").is_err());
    }

    #[test]
    fn rejects_long_chat_message() {
        let text = "a".repeat(MAX_CHAT_TEXT_LEN + 1);
        assert!(validate_chat_text(&text).is_err());
    }

    #[test]
    fn serializes_reaction_wire_event() {
        let event = WireEvent::from_local(
            "device-1",
            BuddyEvent::Reaction {
                reaction: ReactionKind::Tap,
            },
        );
        let json = serde_json::to_string(&event).unwrap();

        assert!(json.contains("\"type\":\"reaction\""));
        assert!(json.contains("\"device_id\":\"device-1\""));
    }

    #[test]
    fn filters_self_wire_event() {
        let event = WireEvent::from_local(
            "device-1",
            BuddyEvent::Reaction {
                reaction: ReactionKind::Tap,
            },
        );

        assert!(is_self_event("device-1", &event));
        assert!(!is_self_event("device-2", &event));
    }

    #[test]
    fn builds_peer_info_from_presence() {
        let event = WireEvent::presence("device-2", "Desk Buddy");
        let peer = peer_from_presence(&event, "192.168.1.20:49277", 123).unwrap();

        assert_eq!(peer.device_id, "device-2");
        assert_eq!(peer.display_name, "Desk Buddy");
        assert_eq!(peer.address, "192.168.1.20:49277");
        assert_eq!(peer.last_seen_ms, 123);
    }
}
