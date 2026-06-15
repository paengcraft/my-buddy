# Corner Todo Board Design

## Goal

Add a shared TODO board to My Buddy. The board appears when the user drags the buddy into a screen corner docking zone. TODO data is stored locally on both Macs and synchronized through the existing LAN and Cloudflare relay paths.

## Decisions

- Use the product term "corner docking zone", not "Hot Corners", because macOS already has a system feature with that name.
- Do not store TODO data on the relay server. The relay only validates and forwards TODO messages.
- Each app keeps its own local copy of the shared TODO snapshot.
- TODO rows show completion state, text, author (`me` or `buddy`), and a visible delete button.
- A deleted TODO removes its text locally, but a tombstone with `id`, `deletedAt`, and `deletedByDeviceId` remains for sync conflict resolution.
- Conflict rule: latest timestamp wins. If a remote item was updated after the local delete timestamp, the item is restored. If the delete timestamp is later, the item stays deleted.

## UI

Dragging the buddy near a visible screen corner docks it. When docked, the root overlay grows to show a compact TODO board next to the buddy. Dragging the buddy away from the corner undocks it and returns to normal buddy mode.

The MVP board supports:

- Add TODO
- Toggle done
- Delete
- Author tag for each row
- Count/status text for sync state

The board uses compact 6-8px radii instead of large rounded pills.

## Data Flow

1. The local user creates, toggles, or deletes a TODO.
2. `BuddyAppState` updates the local snapshot and persists it.
3. The app sends a `todo_snapshot` event over UDP LAN and the Cloudflare relay.
4. The peer merges the snapshot using `BuddyTodoSyncPolicy`.
5. Both sides persist the merged snapshot locally.

Snapshots are intentionally used for the MVP because they are simpler than an event log and robust enough for the small shared list size.

## Storage

Use `UserDefaults` with a Codable snapshot keyed by the active peer device id. This matches the existing app's lightweight persistence style. If the peer device id changes after reinstall, the old shared list is not automatically attached to the new identity.

## Relay

Extend relay protocol validation to accept `todo_snapshot` messages. The Durable Object still stores no TODO state.

## Testing

- Unit-test TODO merge behavior, including delete-versus-update restoration.
- Unit-test corner docking decisions against visible screen frames.
- Unit-test relay protocol validation for valid and invalid TODO snapshots.
- Keep source-level tests for UI affordances where full UI automation would be brittle.
