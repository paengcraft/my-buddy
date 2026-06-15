# My Buddy Manual Smoke Test

Use this checklist after changing native UI, relay protocol, packaging, or diagnostic behavior.

## One-Mac A/B Test

1. Run `cd native && RESET_DEFAULTS=1 ./scripts/run_test_pair.sh`.
2. Right-click both buddies and confirm settings open without text overlap.
3. On My Buddy A, click the Relay `+` button.
4. Confirm an eight-character code appears and is copied.
5. Paste the same code into My Buddy B and click `Join` on both apps.
6. Confirm both apps show a connected or waiting relay state.
7. Send chat from A to B and B to A.
8. Confirm the sender composer stays open and the receiver shows the speech bubble.
9. Click each quick reaction and confirm the other buddy reacts.
10. Change size with presets, slider, `-`, and `+`; quit and reopen to confirm the size persists.
11. Drag My Buddy A into a screen corner and confirm the shared TODO board opens.
12. Add a TODO on A and confirm B shows the same TODO with the author label `buddy`.
13. Toggle the TODO on B and confirm A shows the completed state.
14. Delete the TODO on either app and confirm it disappears on both apps.
15. Drag the buddy out of the corner and confirm the TODO board closes.
16. Click `Test Relay` and confirm `Health OK`.
17. Click the diagnostics button and paste the clipboard into a text editor; confirm it contains app, bundle, size, peer count, relay status, health, relay code, last error, and worker URL.

## Different-Network Test

1. Open the latest DMG on two Macs using different networks.
2. Create a relay code on the first Mac and join with the same code on the second Mac.
3. Send chat and quick reactions in both directions.
4. Add, complete, and delete a shared TODO in both directions.
5. Turn off internet briefly on one Mac, then reconnect.
6. Confirm the app reports reconnecting and resumes chat, reactions, and TODO sync after the connection returns.

## Billing Guard

Before deployment, run:

```bash
cd relay
npm run check:billing
```

The command must report only the Worker and approved Durable Object binding. It must fail if D1, R2, KV, Workers AI, Queues, Images, Stream, or similar resources appear in the dry-run output.
