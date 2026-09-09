# Bluetooth Battery Reporting Setup

## Problem
By default, BlueZ (the Linux Bluetooth stack) doesn't expose battery information for connected Bluetooth devices. This causes the BluetoothIndicator to show "N/A" instead of battery percentages.

## Solution
Enable BlueZ experimental features to expose the `org.bluez.Battery1` D-Bus interface.

### Steps to Enable

1. **Edit BlueZ configuration:**
   ```bash
   sudo nvim /etc/bluetooth/main.conf
   ```

2. **Enable experimental features:**
   Find and uncomment/modify the `Experimental` line:
   ```conf
   [General]
   Experimental = true
   ```

3. **Restart Bluetooth service:**
   ```bash
   sudo systemctl restart bluetooth.service
   ```

4. **Reconnect your Bluetooth devices** (disconnect and connect again)

5. **Verify battery reporting is working:**
   ```bash
   gdbus call --system --dest org.bluez \
     --object-path /org/bluez/hci0/dev_XX_XX_XX_XX_XX_XX \
     --method org.freedesktop.DBus.Properties.Get org.bluez.Battery1 Percentage
   ```
   Replace `XX_XX_XX_XX_XX_XX` with your device's MAC address (colons replaced with underscores).

## How It Works

The updated `BluetoothIndicator.qml` now:

1. **Primary method**: Queries battery via D-Bus `org.bluez.Battery1` interface
2. **Fallback method**: Uses `bluetoothctl info` battery parsing (less reliable)
3. Shows "N/A" if neither method returns battery data

### D-Bus Query Example
```bash
# Get battery percentage for device 8C:7A:AA:89:69:24
gdbus call --system --dest org.bluez \
  --object-path /org/bluez/hci0/dev_8C_7A_AA_89_69_24 \
  --method org.freedesktop.DBus.Properties.Get org.bluez.Battery1 Percentage
```

## Device Compatibility

**Works well with:**
- Most modern Bluetooth headphones/earbuds
- Bluetooth keyboards and mice with BLE
- Gaming controllers (PlayStation, Xbox)

**Limited support:**
- Apple AirPods (may require additional setup)
- Older Bluetooth Classic devices (pre-BLE)

## Troubleshooting

### Battery still shows N/A after enabling experimental features

1. **Check if the device supports battery reporting:**
   ```bash
   bluetoothctl info <MAC_ADDRESS>
   ```
   Look for "Battery Percentage" in the output.

2. **Verify the Battery1 interface exists:**
   ```bash
   gdbus introspect --system --dest org.bluez \
     --object-path /org/bluez/hci0/dev_XX_XX_XX_XX_XX_XX | grep -i battery
   ```

3. **Check BlueZ logs:**
   ```bash
   sudo journalctl -u bluetooth.service -f
   ```

4. **Ensure you're using a recent BlueZ version:**
   ```bash
   bluetoothctl --version
   ```
   Battery reporting requires BlueZ 5.48+ (experimental features needed until 5.56+).

### Experimental features won't enable

- Check for syntax errors in `/etc/bluetooth/main.conf`
- Ensure you have proper permissions to restart the Bluetooth service
- Try rebooting the system after making changes

## References

- [BlueZ D-Bus Battery API](https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc/battery-api.txt)
- [Arch Wiki: Bluetooth](https://wiki.archlinux.org/title/Bluetooth)
