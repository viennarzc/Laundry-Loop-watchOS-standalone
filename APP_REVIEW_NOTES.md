# App Review Notes (App Store Connect)

Hello App Review Team,

Thank you for reviewing **Laundry Loop**.

Laundry Loop is an Apple Watch app with a WidgetKit extension that helps users track washer/dryer cycles.

## What to expect during review

- The app works fully offline and stores data locally on device.
- No login or account is required.
- No third-party analytics SDKs, ad SDKs, or cross-app tracking are used.
- The app may request **local notification** permission to send cycle completion/reminder alerts.

## Notifications

Notifications are optional and are only used for timer/cycle reminders.

## Widget behavior

The widget reads cycle snapshot data from the app group container used by the watch app + widget extension for display.

## Data handling

- No cloud backend is used for user cycle data.
- No personal data is sold or shared with data brokers/advertisers.

## Contact

If you need additional details during review, please contact:

**support@viennci.dev**
