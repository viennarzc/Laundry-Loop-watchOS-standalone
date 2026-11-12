# Laundry Loop next-release verification

Checked on November 12, 2026. This is a development handoff, not a release approval.

## Verified

- The watchOS simulator Debug and Release configurations build with Xcode 27.2's watchOS 27.2 SDK.
- The 40 mm Apple Watch SE 3 simulator passed 20 unit tests, including reminder profiles, app/widget snapshot compatibility, the Overdue boundary, denied authorization, and the permission-prompt race. Eight UI-test executions passed for start, pause/resume, add time, completion actions, profile persistence, and denied-permission guidance.
- A SwiftData store created with the previous model migrated on macOS with its washer/dryer settings, reminder lead, haptics, and recent preset intact; the existing user received Persistent. The existing watch preview also retained its active washer and displayed Persistent.
- The watch app and widget simulator bundles contain privacy manifests declaring the UserDefaults reason CA92.1. Both manifests passed `plutil -lint`. The Release simulator build contains all five App Intents in its extracted metadata.
- A local watchOS device archive succeeded using Xcode because Bitrig does not support that device build destination. Its app and widget contain both privacy manifests and matching app-group entitlements, and `codesign --verify --deep --strict` passed outside the sandbox. The archive uses an Apple Development signing identity; it is not a distribution-signed export.
- The built-in watch simulator displayed the profile selector and the running rectangular Smart Stack widget. The widget model's Completed and Overdue transitions were exercised by unit tests.

## Remaining before release

- Designate a release version and a new build number. The project remains at 1.0.0 (12), and build 12 has already been uploaded.
- Produce and validate a distribution-signed export for TestFlight when the release candidate is designated. The verified archive uses development signing.
- Verify notification delivery, haptics, authorization changes, and the completed/overdue transitions on an Apple Watch. Verify rectangular, circular, and inline widget families, including transitions while the app is closed.
- Run the five App Intents from supported Siri or Shortcuts entry points and confirm persistence, notifications, and widget updates. Metadata extraction alone does not verify runtime behavior.
- Interview 8–10 users and validate the Standard profile's 15-minute follow-up before treating its timing as research-backed.
- Upload a new candidate when requested, verify processing and TestFlight availability, run the release smoke checks, and recheck App Store Connect metadata and release settings.

## App Store Connect snapshot

- On November 12, 2026, the record matching the project's container identifier `me.vnnz.LaundryLoop` showed iOS version 1.0 as **Ready for Sale**, with build 12 attached. Build 12 is expired for TestFlight. This does not verify territory availability or the next candidate.
- A separate record, `me.vnnz.LaundryLoop.watchapp`, showed version 1.0 **Prepare for Submission** and no builds. It is a different bundle identifier; do not treat its status as the status of the matching container record.

The UserDefaults declaration follows [Apple's required-reason API guidance](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).
