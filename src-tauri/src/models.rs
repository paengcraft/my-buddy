use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct LocalIdentity {
    pub device_id: String,
    pub display_name: String,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
pub struct PeerInfo {
    pub device_id: String,
    pub display_name: String,
    pub address: String,
    pub last_seen_ms: u128,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ReactionKind {
    Tap,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum BuddyEvent {
    Reaction { reaction: ReactionKind },
    ChatMessage { text: String, sent_at: String },
    Presence,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum WireEvent {
    Reaction {
        device_id: String,
        reaction: ReactionKind,
    },
    ChatMessage {
        device_id: String,
        text: String,
        sent_at: String,
    },
    Presence {
        device_id: String,
        display_name: String,
    },
}

impl WireEvent {
    pub fn from_local(device_id: impl Into<String>, event: BuddyEvent) -> Self {
        let device_id = device_id.into();

        match event {
            BuddyEvent::Reaction { reaction } => Self::Reaction {
                device_id,
                reaction,
            },
            BuddyEvent::ChatMessage { text, sent_at } => Self::ChatMessage {
                device_id,
                text,
                sent_at,
            },
            BuddyEvent::Presence => Self::Presence {
                device_id,
                display_name: "Buddy".to_string(),
            },
        }
    }

    pub fn presence(device_id: impl Into<String>, display_name: impl Into<String>) -> Self {
        Self::Presence {
            device_id: device_id.into(),
            display_name: display_name.into(),
        }
    }

    pub fn device_id(&self) -> &str {
        match self {
            Self::Reaction { device_id, .. }
            | Self::ChatMessage { device_id, .. }
            | Self::Presence { device_id, .. } => device_id,
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum FrontendEvent {
    Reaction {
        device_id: String,
        reaction: ReactionKind,
    },
    ChatMessage {
        device_id: String,
        text: String,
        sent_at: String,
    },
    PeerDiscovered {
        peer: PeerInfo,
    },
}
