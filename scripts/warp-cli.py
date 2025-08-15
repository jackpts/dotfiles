#!/usr/bin/env python3
import asyncio
import json
import os
import sys
import threading
from queue import Queue
from threading import Thread

import requests
from prompt_toolkit import PromptSession
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.formatted_text import HTML
from rich.console import Console
from rich.panel import Panel

# Исправление для Python 3.13
try:
    asyncio.set_event_loop_policy(asyncio.DefaultEventLoopPolicy())
except Exception:
    pass

API_URL = "http://localhost:1234/v1/chat/completions"
MODEL = "qwen/qwen3-coder-30b"
console = Console()
session = PromptSession()
kb = KeyBindings()
history = []
output_queue = Queue()

def get_project_info():
    try:
        current_dir = os.getcwd()
        while current_dir != '/':
            pkg_path = os.path.join(current_dir, 'package.json')
            if os.path.exists(pkg_path):
                with open(pkg_path, 'r') as f:
                    pkg = json.load(f)
                
                deps = list(pkg.get('dependencies', {}).keys())
                dev_deps = list(pkg.get('devDependencies', {}).keys())
                
                return f"""
Проект: {os.path.basename(current_dir)}
Зависимости: {', '.join(deps[:5])}{'...' if len(deps) > 5 else ''}
Dev-зависимости: {', '.join(dev_deps[:5])}{'...' if len(dev_deps) > 5 else ''}
                """
            current_dir = os.path.dirname(current_dir)
        
        return "Не найден package.json в проекте"
    except Exception as e:
        return f"Ошибка анализа проекта: {str(e)}"

def stream_response(prompt):
    global history
    
    project_info = ""
    if any(word in prompt.lower() for word in ['pkg', 'package', 'dependency', 'installed', 'angular']):
        project_info = get_project_info()
    
    system_msg = "You are a helpful coding assistant"
    if project_info:
        system_msg += f"\n\nТекущий проект:\n{project_info}"
    
    messages = [{"role": "system", "content": system_msg}] + history + [
        {"role": "user", "content": prompt}
    ]
    
    try:
        response = requests.post(
            API_URL,
            json={
                "model": MODEL,
                "messages": messages,
                "stream": True,
                "temperature": 0.2,
                "max_tokens": 2048
            },
            stream=True,
            timeout=300
        )
        
        full_response = ""
        # КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Буфер для неполных JSON
        json_buffer = ""
        
        for line in response.iter_lines():
            if line:
                try:
                    line_str = line.decode('utf-8')
                    
                    # Обработка SSE
                    if line_str.startswith('data: '):
                        json_data = line_str[6:].strip()
                        
                        # Собираем неполные JSON
                        json_buffer += json_data
                        if json_buffer.endswith(']') or json_buffer.endswith('}'):
                            try:
                                data = json.loads(json_buffer)
                                json_buffer = ""  # Сброс буфера
                                
                                if 'choices' in data and data['choices']:
                                    delta = data['choices'][0]['delta'].get('content', '')
                                    if delta:
                                        full_response += delta
                                        output_queue.put(delta)
                            except json.JSONDecodeError:
                                # Игнорируем неполные фрагменты
                                continue
                                
                    # Обработка [DONE]
                    elif line_str.strip() == 'data: [DONE]':
                        break
                        
                except Exception as e:
                    # ИГНОРИРУЕМ ошибки парсинга для многострочного кода
                    if "Expecting value" not in str(e):
                        output_queue.put(f"\n[bold red]Ошибка парсинга:[/bold red] {str(e)}")
                    continue
        
        history.append({"role": "user", "content": prompt})
        history.append({"role": "assistant", "content": full_response})
        
        if len(history) > 10:
            history = history[-10:]
            
    except Exception as e:
        output_queue.put(f"\n[bold red]Ошибка LM Studio:[/bold red] {str(e)}")

def render_output():
    buffer = ""
    while True:
        chunk = output_queue.get()
        if chunk is None:
            break
        buffer += chunk
        console.print(chunk, end="")
        sys.stdout.flush()
        
        if "```" in buffer:
            parts = buffer.split("```")
            if len(parts) % 2 == 0:
                console.print("\n", end="")
                sys.stdout.flush()
            else:
                buffer = ""

@kb.add('c-m')
def _(event):
    event.current_buffer.validate_and_handle()

def main():
    console.print(Panel(
        "[bold green]Qwen3-Coder CLI для Neovim[/bold green]\n"
        "[italic]Нажмите Ctrl+M (Ctrl+Enter) для отправки[/italic]",
        title="LM Studio",
        expand=False
    ))
    
    while True:
        try:
            user_input = session.prompt(
                HTML("<ansiblue><b>❱</b></ansiblue> "),
                key_bindings=kb,
                multiline=True
            ).strip()
            
            if not user_input:
                continue
                
            console.print("[cyan]Генерирую ответ...[/cyan]")
            output_queue.queue.clear()
            
            thread = Thread(target=stream_response, args=(user_input,), daemon=True)
            thread.start()
            
            render_thread = Thread(target=render_output, daemon=True)
            render_thread.start()
            
            thread.join()
            
            output_queue.put(None)
            render_thread.join(timeout=0.5)
            
        except (KeyboardInterrupt, EOFError):
            console.print("\n[red]Выход[/red]")
            sys.exit(0)

if __name__ == "__main__":
    main()
