#!/usr/bin/env bash
set -euo pipefail

# Sway Backup Script
# Creates encrypted 7zip archive with maximum compression
# Author: Auto-generated backup script
# Usage: ./sway-backup.sh

# Configuration
BACKUP_PASSWORD="t2"
BACKUP_DIR="/run/media/jacky/media/backup/regular"

# Exclusion patterns (directories/files to exclude from backup)
EXCLUSION_PATTERNS=(
	".git"
	"node_modules"
	".cache"
	"__pycache__"
	"*.tmp"
	"*.log"
	".DS_Store"
	"*.mp*"
    "*/tmp/*"
    "tmp"
    "*.dump"
    "*/debug/*"
    "*/build/*"
    "*/ai*/models/*"
    "*/target/release/*"
    # Rust/Cargo exclusions (large cache files)
    ".cargo"
    # Fish variable symlinks (point to dotfiles, avoid duplicates)
    "fish_variables.*"
)

# Get current date
day=$(date +%d)
month=$(date +%m)
year=$(date +%Y)

# Archive name
ARCHIVE_NAME="backup_${day}_${month}_${year}.7z"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"
ZEN_ARCHIVE_NAME="backup_zen_${day}_${month}_${year}.7z"
ZEN_ARCHIVE_PATH="${BACKUP_DIR}/${ZEN_ARCHIVE_NAME}"
ZEN_ARCHIVE_CREATED=0

# Core backup items (always included)
CORE_BACKUP_ITEMS=(
	# System configs
	"/etc/hosts"
	"/etc/resolv.conf"
	"/etc/systemd/resolved.conf"
	"/etc/systemd/system.conf"
	"/etc/systemd/logind.conf"  # KillUserProcesses=yes
	"/etc/profile"
	"/etc/nsswitch.conf"
	"/etc/fstab"
	"/etc/locale.conf"
	"/etc/vconsole.conf"
	"/etc/pacman.conf"
	"/etc/pacman.d/mirrorlist"
	"/etc/sddm.conf"
	"/etc/pam.d/sddm*"
	"/etc/plymouth/plymouthd.conf"
	"/etc/mkinitcpio.conf"
	"/etc/default/grub"
	"/etc/security/faillock.conf"
	"/etc/bluetooth/main.conf"
	# "/boot/refind_linux.conf"
	# "/boot/EFI/refind/refind.conf"
	# "/etc/wireguard/"

	# User configs and dotfiles
	"$HOME/.config/fish"
	"$HOME/.gnupg"
	"$HOME/.password-store/"
	"$HOME/.ssh"
	"$HOME/.git*"
	"$HOME/vpn"
	"$HOME/.config/kdeconnect"
	"$HOME/dotfiles"
	"$HOME/.qwen/*.json"
	"$HOME/.gemini/*.json"
	"$HOME/.docker/config.json"
	"$HOME/.my.cnf"  # chmod 600 ~/.my.cnf

	# Data and documents
	"$HOME/obsidian/"
	"$HOME/*.kdbx"
	"$HOME/Documents/browser/"
	"$HOME/Documents/sfs*.json"

	# Wayland/Sway configs
	"/usr/share/wayland-sessions/hyprland.desktop"
	"/usr/share/rofi/themes/"
	"/usr/share/applications/"

	# GTK configs (Nemo bookmarks)
	"$HOME/.config/gtk-3.0/"
	"$HOME/.config/gtk-4.0/"

	# AI/IDE configs
	"$HOME/.codeium/windsurf/mcp_config.json"
	"$HOME/bitbucket/SL/.windsurf/"
	"$HOME/bitbucket/SL/.warp/"

	# Package lists (generated during backup)
	"$HOME/soft/*.txt"
	"$HOME/soft/*.jsonlz4"

	# MySQL dump (when enabled)
	# "$HOME/soft/mysql_dump_*.sql"

	# Git configs (already covered by $HOME/.git* above)
	# "$HOME/.gitconfig-gitlab"  # duplicate - removed
	# "$HOME/.gitconfig-bitbucket"  # duplicate - removed
)

# Additional backup items (add more paths here as needed)
# Example: ADDITIONAL_BACKUP_ITEMS+=("$HOME/my-custom-folder")
ADDITIONAL_BACKUP_ITEMS=(
	# Add custom paths here
	# "$HOME/.ssh/"
	# "$HOME/.config/some-app/"
)

# Zen backup items (stored in separate archive)
ZEN_BACKUP_ITEMS=(
	"$HOME/.zen/"*.default
	"$HOME/.zen/profiles.ini"
	"$HOME/.zen/installs.ini"
)

# Color output functions
print_info() {
	echo -e "\033[1;34m[INFO]\033[0m $1"
}

# Create separate Zen archive to keep main backup smaller
create_zen_backup() {
	ZEN_ARCHIVE_CREATED=0
	print_info "Collecting Zen backup items..."
	collect_backup_items ZEN_BACKUP_ITEMS
	local zen_items=("${VALID_ITEMS[@]}")

	if [[ ${#zen_items[@]} -eq 0 ]]; then
		print_warning "No Zen items found; skipping separate Zen archive"
		return 0
	fi

	if [[ -f "$ZEN_ARCHIVE_PATH" ]]; then
		print_warning "Existing Zen backup found, removing: $ZEN_ARCHIVE_NAME"
		rm "$ZEN_ARCHIVE_PATH"
	fi

	local temp_log="/tmp/7z_zen_backup_$$.log"
	print_info "Creating Zen backup archive: $ZEN_ARCHIVE_NAME"

	if LANG=C 7z a -t7z -mx=9 -mhe=on -snl -spf -p"$BACKUP_PASSWORD" "$ZEN_ARCHIVE_PATH" "${zen_items[@]}" >"$temp_log" 2>&1; then
		print_success "Zen backup created successfully!"
		rm -f "$temp_log"
		ZEN_ARCHIVE_CREATED=1
		return 0
	else
		print_error "Failed to create Zen backup archive"
		print_error "7zip output:"
		cat "$temp_log"
		rm -f "$temp_log"
		return 1
	fi
}

show_zen_backup_info() {
	if [[ "$ZEN_ARCHIVE_CREATED" -eq 1 ]] && [[ -f "$ZEN_ARCHIVE_PATH" ]]; then
		local size
		size=$(du -h "$ZEN_ARCHIVE_PATH" | cut -f1)
		print_success "Zen Backup Details:"
		echo "  Location: $ZEN_ARCHIVE_PATH"
		echo "  Size: $size"
		echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
	fi
}

print_success() {
	echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

print_error() {
	echo -e "\033[1;31m[ERROR]\033[0m $1"
}

print_warning() {
	echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# Check dependencies
check_dependencies() {
	local deps=("7z" "find")
	local missing=()

	for dep in "${deps[@]}"; do
		if ! command -v "$dep" >/dev/null 2>&1; then
			missing+=("$dep")
		fi
	done

	if [[ ${#missing[@]} -ne 0 ]]; then
		print_error "Missing dependencies: ${missing[*]}"
		print_info "Please install: sudo pacman -S p7zip"
		exit 1
	fi
}

# Create backup directory if it doesn't exist
create_backup_dir() {
	if [[ ! -d "$BACKUP_DIR" ]]; then
		print_info "Creating backup directory: $BACKUP_DIR"
		mkdir -p "$BACKUP_DIR"
	fi
}

# Check for problematic symbolic links that could cause issues
check_symlinks() {
	print_info "Checking for problematic symbolic links..."

	for item in "$@"; do
		if [[ -d "$item" ]]; then
			local symlink_loops
			# Find circular symlinks or excessive depth
			mapfile -t symlink_loops < <(find "$item" -type l -exec test -e {} \; -prune -o -type l -print 2>/dev/null | head -10)

			if [[ ${#symlink_loops[@]} -gt 0 ]]; then
				print_warning "Found potentially problematic symlinks in $item:"
				for link in "${symlink_loops[@]}"; do
					local target
					target=$(readlink "$link" 2>/dev/null || echo "<unreadable>")
					print_warning "  $link -> $target"
				done
			fi
		fi
	done
}

# Check if backup items exist and collect valid paths
collect_backup_items() {
	local -n items_ref=$1
	local valid_items=()

	for item in "${items_ref[@]}"; do
	# Handle glob patterns (like bookmarks-*.json)
		if [[ "$item" == *"*"* ]]; then
			# Use find to expand glob patterns
			local expanded_files
			mapfile -t expanded_files < <(find "$(dirname "$item")" -name "$(basename "$item")" 2>/dev/null || true)

			if [[ ${#expanded_files[@]} -gt 0 ]]; then
				# Special handling for bookmarks and sfs files: only keep the latest one
				if [[ "$item" == *"bookmarks-"*".json" ]] || [[ "$item" == *"sfs*"".json" ]]; then
					local latest_file
					# Sort by modification time and get the newest
					latest_file=$(printf '%s\n' "${expanded_files[@]}" | xargs ls -t 2>/dev/null | head -1)
					if [[ -n "$latest_file" ]] && [[ -e "$latest_file" ]]; then
						valid_items+=("$latest_file")
						if [[ "$item" == *"bookmarks-"*".json" ]]; then
							print_info "Found latest bookmark: $latest_file"
						else
							print_info "Found latest sfs file: $latest_file"
						fi
					fi
				else
					# For other patterns, include all matches
					for file in "${expanded_files[@]}"; do
						if [[ -e "$file" ]]; then
							valid_items+=("$file")
							print_info "Found: $file"
						fi
					done
				fi
			else
				print_warning "No files found matching pattern: $item"
			fi
		else
			# Regular file/directory check
			if [[ -e "$item" ]]; then
				valid_items+=("$item")
				print_info "Found: $item"
			else
				print_warning "Not found (skipping): $item"
			fi
		fi
	done

	# Return valid items via global array
	VALID_ITEMS=("${valid_items[@]}")
}

# Create the backup archive
create_backup() {
	local all_items=()

	# Create soft directory
	if [[ ! -d "$HOME/soft/" ]]; then
		mkdir -p "$HOME/soft/"
	fi

	# Export package lists
	print_info "Exporting package lists..."
	pacman -Qqen >"$HOME/soft/pkglist_pacman.txt"
	pacman -Qqem >"$HOME/soft/pkglist_aur.txt"
	flatpak list >"$HOME/soft/pkglist_flatpak.txt"
	# GNOME extensions (commented out - not using GNOME currently)
	# ls -1 ~/.local/share/gnome-shell/extensions/ >"$HOME/soft/gnome_ext_list.txt"

	# Zed extensions backup
	print_info "Exporting Zed extensions..."
	if [[ -d "$HOME/.local/share/zed/extensions/installed/" ]]; then
		ls "$HOME/.local/share/zed/extensions/installed/" >"$HOME/soft/zed_ext_list.txt"
	fi

	# dconf backup for Nemo
	print_info "Exporting Nemo dconf settings..."
	dconf dump /org/nemo/ >"$HOME/dotfiles/nemo-dconf-settings" 2>/dev/null || true

	# MySQL DB backup (commented out temporarily)
	# print_info "Backing up MySQL database..."
	# mysql_date=$(date +"%Y-%m-%d")
	# mysql_file="mysql_dump_$mysql_date.sql"
	# mariadb-dump --all-databases --host=127.0.0.1 --port=33066 > "$HOME/soft/$mysql_file"

	# rsync themes (commented out temporarily)
	# print_info "Syncing themes to backup location..."
	# rsync -avh --progress /usr/share/themes/ /run/media/jacky/back2up/once/themes/
	# rsync -avh --progress /usr/share/sddm/themes/ /run/media/jacky/back2up/once/sddm_themes/
	# rsync -avh --progress /usr/share/plymouth/themes/ /run/media/jacky/back2up/once/plymouth_themes/

	# Collect core backup items
	print_info "Collecting core backup items..."
	collect_backup_items CORE_BACKUP_ITEMS
	all_items+=("${VALID_ITEMS[@]}")

	# Collect additional backup items if any
	if [[ ${#ADDITIONAL_BACKUP_ITEMS[@]} -gt 0 ]]; then
		print_info "Collecting additional backup items..."
		collect_backup_items ADDITIONAL_BACKUP_ITEMS
		all_items+=("${VALID_ITEMS[@]}")
	fi

	# Check if we have items to backup
	if [[ ${#all_items[@]} -eq 0 ]]; then
		print_error "No valid backup items found!"
		exit 1
	fi

	print_info "Total items to backup: ${#all_items[@]}"

	# Check for problematic symlinks in backup items
	check_symlinks "${all_items[@]}"

	# Remove existing backup with same name if it exists
	if [[ -f "$ARCHIVE_PATH" ]]; then
		print_warning "Existing backup found, removing: $ARCHIVE_NAME"
		rm "$ARCHIVE_PATH"
	fi

	# Create the backup archive with maximum compression and password
	print_info "Creating backup archive: $ARCHIVE_NAME"
	print_info "Using maximum compression (this may take a while...)"

	# Use 7z with maximum compression (-mx=9) and password protection (-p)
	# -t7z: 7zip format
	# -mx=9: maximum compression
	# -mhe=on: encrypt headers
	# -p: password (will be prompted securely)
	# -snl: store symbolic links as links (not follow them)
	# Build exclusion arguments from patterns
	local exclusion_args=()
	for pattern in "${EXCLUSION_PATTERNS[@]}"; do
		exclusion_args+=("-xr!${pattern}")
	done

	local temp_log="/tmp/7z_backup_$$.log"

	print_info "Exclusion patterns: ${EXCLUSION_PATTERNS[*]}"

	if LANG=C 7z a -t7z -mx=9 -mhe=on -snl -spf "${exclusion_args[@]}" -p"$BACKUP_PASSWORD" "$ARCHIVE_PATH" "${all_items[@]}" >"$temp_log" 2>&1; then
		print_success "Backup created successfully!"
		# Show warnings if any
		if grep -q "WARNING" "$temp_log"; then
			print_warning "Backup completed with warnings:"
			grep "WARNING" "$temp_log" | head -5
		fi
		rm -f "$temp_log"
		return 0
	else
		print_error "Failed to create backup archive"
		print_error "7zip output:"
		cat "$temp_log"
		rm -f "$temp_log"
		return 1
	fi
}

# Display backup information
show_backup_info() {
	if [[ -f "$ARCHIVE_PATH" ]]; then
		local size
		size=$(du -h "$ARCHIVE_PATH" | cut -f1)
		print_success "Backup Details:"
		echo "  Location: $ARCHIVE_PATH"
		echo "  Size: $size"
		echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
		echo "  Password: ****"

		# Show archive contents (without extracting)
		print_info "Archive contents:"
		7z l "$ARCHIVE_PATH" -p"$BACKUP_PASSWORD" 2>/dev/null | grep -E "^[0-9]" | head -20 || true

		local total_files
		total_files=$(7z l "$ARCHIVE_PATH" -p"$BACKUP_PASSWORD" 2>/dev/null | grep "files" | tail -1 | awk '{print $1}' || true)
		if [[ -n "$total_files" ]]; then
			echo "  Total files: $total_files"
		fi
	fi
}

# Backup yt-tg-chat-bot SQLite database
backup_yt_tg_db() {
	print_info "Backing up yt-tg-chat-bot SQLite database..."

	local YT_TG_DIR="$HOME/github/yt-tg-chat-bot"
	local DB_PATH="$YT_TG_DIR/bot.db"
	local BACKUP_TIMESTAMP
	BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M)
	local BACKUP_NAME="bot_backup_${BACKUP_TIMESTAMP}.db"
	local BACKUP_DEST="$YT_TG_DIR/$BACKUP_NAME"

	if [[ ! -d "$YT_TG_DIR" ]]; then
		print_warning "yt-tg-chat-bot directory not found: $YT_TG_DIR"
		return 0
	fi

	if [[ ! -f "$DB_PATH" ]]; then
		print_warning "SQLite database not found: $DB_PATH"
		return 0
	fi

	if ! command -v sqlite3 >/dev/null 2>&1; then
		print_warning "sqlite3 not found, skipping DB backup"
		return 0
	fi

	# Check if database is locked (bot is running)
	if sqlite3 "$DB_PATH" "SELECT 1;" >/dev/null 2>&1; then
		cd "$YT_TG_DIR"
		if sqlite3 "$DB_PATH" ".backup '$BACKUP_DEST'"; then
			print_success "SQLite database backed up to: $BACKUP_DEST"
		else
			print_warning "Failed to backup SQLite database (may be in use)"
		fi
	else
		print_warning "Database is locked (bot is running), skipping backup"
	fi
}

# Cleanup old backups (optional)
cleanup_old_backups() {
	local keep_count=5 # Keep last 5 backups

	print_info "Checking for old backups to cleanup..."

	# Find and sort backup files by modification time
	local old_backups
	mapfile -t old_backups < <(find "$BACKUP_DIR" -name "backup_*.7z" -type f -printf '%T@ %p\n' | sort -nr | tail -n +$((keep_count + 1)) | cut -d' ' -f2-)

	if [[ ${#old_backups[@]} -gt 0 ]]; then
		print_info "Removing ${#old_backups[@]} old backup(s)..."
		for backup in "${old_backups[@]}"; do
			print_info "Removing: $(basename "$backup")"
			rm "$backup"
		done
	else
		print_info "No old backups to remove"
	fi
}

# Main execution
main() {
	print_info "Starting Sway backup process..."
	print_info "Date: $(date '+%Y-%m-%d %H:%M:%S')"

	# Check if running with proper permissions
	if [[ ! -r "$HOME" ]]; then
		print_error "Cannot read home directory: $HOME"
		exit 1
	fi

	# Run all backup steps
	check_dependencies
	create_backup_dir
	backup_yt_tg_db

	# Create backup and check result
	if create_backup; then
		show_backup_info

		if ! create_zen_backup; then
			print_error "Zen backup process failed!"
			notify-send -u critical -i dialog-error \
				"✗ Zen Backup Failed" \
				"Check the logs for details"
			exit 1
		fi
		show_zen_backup_info

		# Success notification
		local backupFileName
		backupFileName=$(basename "$ARCHIVE_PATH")
		local fileSize
		fileSize=$(du -sh "$ARCHIVE_PATH" | awk '{print $1}')
		local message
		message="Main: $backupFileName ($fileSize)"
		if [[ "$ZEN_ARCHIVE_CREATED" -eq 1 ]] && [[ -f "$ZEN_ARCHIVE_PATH" ]]; then
			local zenBackupFileName
			zenBackupFileName=$(basename "$ZEN_ARCHIVE_PATH")
			local zenFileSize
			zenFileSize=$(du -sh "$ZEN_ARCHIVE_PATH" | awk '{print $1}')
			message+="\nZen: $zenBackupFileName ($zenFileSize)"
		fi
		print_success "Backup process completed successfully!"
		print_success "Backup size: $fileSize"
		notify-send -u normal -i dialog-information \
			"✓ Backup Complete" \
			"$message"
	else
		# Failure notification
		print_error "Backup process failed!"
		notify-send -u critical -i dialog-error \
			"✗ Backup Failed" \
			"Check the logs for details"
		exit 1
	fi
}

# Handle script interruption
trap 'print_error "Backup interrupted!"; exit 130' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
