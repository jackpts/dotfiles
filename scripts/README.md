# Scripts Documentation

This directory contains various utility scripts for the dotfiles configuration, optimized for performance and reliability.

## Script Overview

### System Monitoring Scripts

#### `ram_usage_mb.sh`
- **Purpose**: Displays RAM usage with visual indicators
- **Output**: JSON format for Waybar integration
- **Features**: 
  - Configurable thresholds (70% warning, 90% critical)
  - Detailed tooltips with available memory
  - Error handling and validation
- **Usage**: Called by Waybar every 2 seconds

#### `home_free_space.sh`
- **Purpose**: Monitors home directory free space
- **Output**: JSON format for Waybar integration
- **Features**:
  - Low space warning (configurable threshold)
  - Multiple df output format support
  - Error handling for missing filesystems
- **Usage**: Called by Waybar every 5 minutes

#### `system_info.sh`
- **Purpose**: Provides comprehensive system information
- **Output**: JSON format for Waybar integration
- **Features**:
  - Caching system for performance
  - Uptime, CPU temperature, CPU usage, memory usage
  - 30-second cache duration
- **Usage**: Can be integrated into Waybar for system overview

### Application Launchers

#### `run_launcher.sh`
- **Purpose**: Enhanced application launcher with fallbacks
- **Features**:
  - Primary: Rofi with Catppuccin theme
  - Fallback: Rofi with alternative theme
  - Last resort: Walker launcher
  - Theme validation and error handling
- **Usage**: Called by Waybar app menu button

#### `launch_btop.sh`
- **Purpose**: Launches system monitor with optimal terminal configuration
- **Features**:
  - Multiple terminal emulator support (Kitty, Alacritty, GNOME Terminal)
  - Optimized window sizing for each terminal
  - Dependency checking
- **Usage**: Called by Waybar CPU/memory modules

### Window Management Scripts

#### `keyboard_layout.sh`
- **Purpose**: Detects and displays current keyboard layout
- **Output**: Short format (EN/RU) for Waybar
- **Features**:
  - Multiple fallback methods
  - Error handling for missing dependencies
  - Support for various layout names
- **Usage**: Called by Waybar language module

#### `waybar-taskbar-sorted.sh`
- **Purpose**: Provides sorted window information for taskbar
- **Output**: JSON format with window details
- **Features**:
  - Workspace-based sorting
  - Focus order preservation
  - Error handling for Sway communication
- **Usage**: Can be integrated into Waybar taskbar module

### System Utilities

#### `restore_wallpaper.sh`
- **Purpose**: Reliable wallpaper restoration on system startup
- **Features**:
  - Comprehensive error handling
  - Display readiness checking
  - Configurable retry logic
  - Detailed logging
- **Usage**: Called during Sway startup

## Performance Optimizations

### Caching
- `system_info.sh` implements file-based caching to reduce system calls
- Cache duration is configurable per script

### Error Handling
- All scripts use `set -euo pipefail` for strict error handling
- Comprehensive logging functions
- Graceful fallbacks where applicable

### Resource Management
- Optimized intervals for Waybar modules
- Reduced system call frequency
- Efficient data parsing

## Configuration

### Environment Variables
- Scripts respect standard environment variables
- Cache directories use `$HOME/.cache/` for consistency

### Dependencies
- All scripts check for required dependencies
- Graceful degradation when dependencies are missing
- Clear error messages for missing tools

## Integration

### Waybar Integration
- All monitoring scripts output JSON format compatible with Waybar
- Consistent tooltip formatting
- CSS class support for styling

### Sway Integration
- Scripts communicate with Sway using `swaymsg`
- Proper error handling for Wayland session issues
- Display readiness checking

## Maintenance

### Logging
- Scripts log to appropriate locations (`$HOME/.local/share/` or `$HOME/.cache/`)
- Log rotation should be implemented for long-running systems
- Debug information available via stderr

### Updates
- Scripts are designed to be easily maintainable
- Configuration constants at the top of each script
- Modular function design for easy modification

## Troubleshooting

### Common Issues
1. **Permission errors**: Ensure all scripts are executable (`chmod +x`)
2. **Missing dependencies**: Check error messages for required tools
3. **Waybar integration**: Verify JSON output format
4. **Sway communication**: Ensure running in Wayland session

### Debug Mode
- Set `set -x` in scripts for detailed execution tracing
- Check log files in `$HOME/.local/share/` and `$HOME/.cache/`
- Use `swaymsg -t get_tree` to debug window management issues