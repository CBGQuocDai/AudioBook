# mobile_client_new

## API Host/Port Configuration

Project now supports quick switching with compile-time flags:

- `API_BASE_URL` (highest priority override)
- `API_DEVICE_BASE_URL` (used for physical phone)
- `USE_ANDROID_EMULATOR` (`true` to force `10.0.2.2`)

Current default in this repo is physical phone mode (`USE_ANDROID_EMULATOR=false`):

- `http://192.168.1.82:8080/api`

Emulator mode automatically uses:

- `http://10.0.2.2:8080/api`

You can still explicitly pass `API_BASE_URL` for any custom target.

## Run commands

From `mobile_client` folder:

```bash
flutter pub get
```

Android emulator (backend on same PC):

```bash
flutter run --dart-define=USE_ANDROID_EMULATOR=true
```

Android/iOS physical device on same Wi-Fi:

```bash
flutter run --dart-define=API_DEVICE_BASE_URL=http://<YOUR_PC_LAN_IP>:8080/api --dart-define=USE_ANDROID_EMULATOR=false
```

Web (Chrome):

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
```

## IDE quick profiles

- `main.dart`: physical phone (LAN)
- `main_emulator.dart`: Android emulator

## Backend requirements for multi-device

- Backend must listen on all interfaces (`0.0.0.0`) and correct port.
- Open inbound firewall rule for backend port (default `8080`).
- Test from another device browser:
	- `http://<YOUR_PC_LAN_IP>:8080/api/actuator/health` (or any public API path).

## Common host/port mistakes

- Using `localhost` on physical phone points to phone itself, not your PC.
- `10.0.2.2` only works inside Android emulator.
- Hardcoded LAN IP breaks when changing network/router.