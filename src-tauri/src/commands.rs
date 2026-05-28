use crate::{
    models::{BuddyEvent, LocalIdentity, PeerInfo, ReactionKind},
    network,
    state::{now_ms, validate_chat_text, AppState},
};
use std::sync::Arc;
use tauri::State;

#[tauri::command]
pub fn get_local_identity(state: State<'_, Arc<AppState>>) -> LocalIdentity {
    state.identity.clone()
}

#[tauri::command]
pub fn list_peers(state: State<'_, Arc<AppState>>) -> Vec<PeerInfo> {
    state
        .peers
        .lock()
        .map(|peers| peers.values().cloned().collect())
        .unwrap_or_default()
}

#[tauri::command]
pub async fn send_reaction(
    reaction: ReactionKind,
    state: State<'_, Arc<AppState>>,
) -> Result<(), String> {
    let app_state = state.inner().clone();

    network::broadcast_buddy_event(&app_state, BuddyEvent::Reaction { reaction }).await
}

#[tauri::command]
pub async fn send_chat_message(
    text: String,
    state: State<'_, Arc<AppState>>,
) -> Result<(), String> {
    let text = validate_chat_text(&text)?;
    let app_state = state.inner().clone();
    let sent_at = now_ms().to_string();

    network::broadcast_buddy_event(&app_state, BuddyEvent::ChatMessage { text, sent_at }).await
}
