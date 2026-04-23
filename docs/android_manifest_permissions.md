# Android Manifest Permissions — Notifications

When the Android platform folder is generated (`flutter create --platforms android`),
add these permissions to `android/app/src/main/AndroidManifest.xml` **inside the
`<manifest>` element, before `<application>`**:

```xml
<!-- Notifications (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Exact alarms — required for scheduled notifications on Android 12+ -->
<!-- On Android 12 (API 31): user may need to grant this in system settings -->
<!-- On Android 13+ (API 33): granted automatically if targetSdk >= 33      -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />

<!-- Re-schedule notifications after device reboot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Vibration -->
<uses-permission android:name="android.permission.VIBRATE" />
```

Add inside `<application>`:

```xml
<!-- flutter_local_notifications: boot receiver -->
<receiver
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
    android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
    </intent-filter>
</receiver>
```

## Notes

| Concern | Detail |
|---------|--------|
| `SCHEDULE_EXACT_ALARM` (Android 12, API 31–32) | Users who deny this in system settings will receive inexact alarms only. The app should detect this and show an in-app prompt directing users to Settings → Special app access → Alarms & reminders. |
| `POST_NOTIFICATIONS` (Android 13+, API 33+) | Must be requested at runtime via `requestPermission()` in `FlutterLocalNotificationsDatasource`. Already handled in code. |
| iOS | No manifest changes needed. Permissions are requested at runtime via `requestPermissions()` in `IOSFlutterLocalNotificationsPlugin`. Already handled in code. |
| Quiet hours | Implemented entirely in Dart (`NotificationRecurrenceEngine`). No native changes needed. |
