use tauri::Manager;

pub fn configure_main_window(app: &tauri::App) -> tauri::Result<()> {
    let Some(window) = app.get_webview_window("main") else {
        return Ok(());
    };

    window.set_always_on_top(true)?;
    window.set_decorations(false)?;
    window.set_shadow(false)?;
    window.set_resizable(false)?;

    Ok(())
}
