#!/usr/bin/env python3

import os
import subprocess
import shutil
import re
from datetime import datetime

# Конфигурация
LOGO_PATH = os.path.expanduser("~/dotfiles/.config/fastfetch/she-logo.jpg")
SCALE_PERCENT = 30  # 30% ширины терминала
CLEAR_ANSI = re.compile(r'\x1b\[[0-9;]*[mGKH]')

def check_arch():
    if not os.path.exists("/etc/arch-release"):
        print("\033[31mError: This script works only on Arch Linux\033[0m")
        exit(1)

def get_terminal_size():
    return shutil.get_terminal_size()

def generate_image():
    term_width = get_terminal_size().columns
    image_width = term_width * SCALE_PERCENT // 100
    
    try:
        result = subprocess.run([
            "chafa",
            "--scale", str(SCALE_PERCENT / 100),
            "--symbols", "solid+all",
            "--colors", "256",
            "--fill", "block",
            "--align", "left",
            LOGO_PATH
        ], capture_output=True, text=True, check=True)
        
        return result.stdout.splitlines()
    except subprocess.CalledProcessError:
        print("\033[31mError: Failed to generate image. Is chafa installed?\033[0m")
        print("\033[33mInstall with: sudo pacman -S chafa\033[0m")
        exit(1)

def strip_ansi(text):
    return CLEAR_ANSI.sub('', text)

def get_system_info():
    # Сбор системной информации (упрощенная версия)
    info = []
    colors = {
        'GREEN': '\033[32m',
        'YELLOW': '\033[33m',
        'NC': '\033[0m'
    }
    
    def add_line(title, value):
        info.append(f"{colors['GREEN']}{title}:{colors['NC']} {value}")

    # OS
    with open('/etc/os-release') as f:
        os_data = dict(re.findall(r'^(NAME|VERSION_ID)="([^"]+)"', f.read(), re.MULTILINE))
    add_line("OS", f"{os_data.get('NAME', 'N/A')} {os_data.get('VERSION_ID', '')}")

    # Остальные параметры (аналогично предыдущим версиям)
    add_line("Kernel", os.uname().release)
    add_line("Host", subprocess.getoutput("hostnamectl --static"))
    add_line("CPU", subprocess.getoutput("lscpu | grep 'Model name' | cut -d: -f2").strip())
    add_line("Memory", subprocess.getoutput("free -h | awk '/^Mem:/ {print $3\"/\"$2}'").strip())
    
    # Добавьте остальные параметры аналогично
    
    return info

def combine_output(image_lines, text_lines):
    max_lines = max(len(image_lines), len(text_lines))
    term_width = get_terminal_size().columns
    
    for i in range(max_lines):
        # Обработка изображения
        img_line = image_lines[i] if i < len(image_lines) else ""
        clean_img = strip_ansi(img_line)
        img_visible_len = len(clean_img)
        
        # Обработка текста
        text_line = text_lines[i] if i < len(text_lines) else ""
        
        # Форматирование
        if img_visible_len > 0:
            # Выводим изображение и текст на одной строке
            print(f"{img_line}\033[0m{text_line}")
        else:
            # Если изображение закончилось, выводим текст с отступом
            print(f"{' ' * term_width}{text_line}")

def main():
    check_arch()
    image = generate_image()
    text = get_system_info()
    combine_output(image, text)

if __name__ == "__main__":
    main()
