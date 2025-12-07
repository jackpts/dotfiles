# AirPods Battery Monitoring on Linux

## The Problem

Apple AirPods use proprietary protocols for battery reporting that are not compatible with standard Bluetooth Battery Service (BBS). Unlike regular Bluetooth devices, AirPods only broadcast battery information during initial discovery, not while connected.

**This is why your AirPods show "N/A" even with BlueZ experimental features enabled.**

## Solutions

### Option 1: Install librepods (Recommended)

`librepods` is a tool that provides Apple-exclusive AirPods features for Linux, including battery monitoring.

#### Installation:

```bash
paru -S librepods-git
```

#### After installation:

1. Start the librepods service:
   ```bash
   systemctl --user enable --now librepods
   ```

2. librepods exposes AirPods battery via D-Bus and may also create UPower entries

3. The BluetoothIndicator.qml should automatically pick up battery info once librepods is running

#### Verification:

```bash
# Check if librepods is running
systemctl --user status librepods

# Check if battery info is now available
upower -e
# or
gdbus introspect --session --dest me.timschneeberger.LibrePods --object-path /me/timschneeberger/LibrePods
```

### Option 2: Manual Monitoring (Limited)

For basic battery monitoring without installing librepods, you can manually check battery during the discovery phase:

1. **Disconnect your AirPods**
2. **Open the case near your computer** (don't pair yet)
3. **Run this command immediately:**
   ```bash
   sudo hcitool lescan --duplicates &
   PID=$!
   sleep 5
   sudo kill $PID
   sudo hcidump -X | grep -A20 "AirPods"
   ```

This will show manufacturer data with battery levels, but only works when AirPods are discoverable (case open, not connected).

### Option 3: Alternative Bluetooth Devices

If you frequently need battery monitoring, consider using Bluetooth devices that support standard Battery Service (BBS):
- Sony WH-1000XM series
- Bose QuietComfort series  
- Most gaming controllers (PS5, Xbox)
- Modern Bluetooth keyboards/mice

These devices will work with the updated BluetoothIndicator.qml once BlueZ experimental features are enabled.

## Current Status

✅ BlueZ experimental features: **Enabled** (`/etc/bluetooth/main.conf`)  
✅ BluetoothIndicator.qml: **Updated** with multiple detection methods  
❌ AirPods battery: **Not compatible** without librepods  

## Reality Check

**librepods is installed but has a limitation:** It's a standalone GUI app that shows AirPods battery in its own window, but **it does NOT expose battery data via D-Bus or any system interface** for other tools to use.

### Current Situation:

✅ librepods shows battery in GUI  
❌ librepods doesn't share data with Waybar/scripts  
❌ AirPods don't support standard Bluetooth Battery Service  
❌ **No programmatic way to get AirPods battery on Linux**  

### Your Options:

1. **Keep librepods running** - View battery in its GUI window (click Bluetooth icon → open librepods)
2. **Accept "N/A"** for AirPods in Waybar - it's a known AirPods limitation
3. **Use different Bluetooth devices** (Sony, Bose, gaming controllers) that support standard protocols

## Testing Other Bluetooth Devices

If you have other Bluetooth devices (mouse, keyboard, controllers), connect them to test if battery reporting works. They should show battery percentage if they support BBS.
