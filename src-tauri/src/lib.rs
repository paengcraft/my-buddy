mod commands;
mod models;
mod network;
mod platform;
mod state;

use std::sync::Arc;
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            let udp_socket = tauri::async_runtime::block_on(network::bind_udp_socket())
                .ok()
                .map(Arc::new);
            let app_state = Arc::new(state::AppState::new("Buddy", udp_socket));

            network::start_listener(app.handle().clone(), app_state.clone());
            network::start_presence_loop(app_state.clone());
            app.manage(app_state);
            platform::configure_main_window(app)?;

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::get_local_identity,
            commands::list_peers,
            commands::send_reaction,
            commands::send_chat_message
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
