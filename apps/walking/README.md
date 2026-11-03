# Japanese Walking

A timer for Japanese interval walking: brisk and relaxed walking take turns,
three minutes each, five times — 30 minutes in total. A short countdown gives
time to put the phone away, and a sound marks every change of pace.

| Setting | Default | Range |
|---|---|---|
| Language | device | English, Russian |
| Vibration | medium | off, medium, strong |
| Rounds | 5 | 1–20 |
| Fast | 3 min | 1–10 min |
| Slow | 3 min | 1–10 min |
| Fast pace music | none | your own tracks |
| Slow pace music | none | your own tracks |

## Music

Pick tracks from the phone for each pace in the settings. During a walk the
fast music plays while you walk fast and the slow music while you walk slowly,
cross-fading over three seconds at every change. Each playlist continues where
it stopped and loops. A pace without tracks is silent, apart from the cues.

The chosen files are copied into the app, so they keep working if the
originals move. The web version has no music: browsers cannot keep the files.

## With the screen off

On Android the walk carries on with the screen off or the app in the
background. It shows up as a notification and on the lock screen with the
current pace and round, and can be paused or stopped from there or with a
headset button. For that the app declares a media-playback foreground service
and the wake-lock permission.

Android application id: `com.LLarean.JapaneseWalking`.

```sh
flutter run
```
