import tkinter as tk
from tkinter import scrolledtext
from fabric import Connection
import requests
import time


def send_to_mistral(prompt):
    try:
        API_URL = "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-v0.1"
        headers = {"Authorization": "Bearer XXX"}

        payload = {
            "inputs": prompt,
            "parameters": {
                "max_length": 100,
                "temperature": 0.7
            }
        }

        while True:
            response = requests.post(API_URL, headers=headers, json=payload)
            if response.status_code == 200:
                return response.json()[0]["generated_text"]
            elif response.status_code == 503:
                print("Model is loading... Wait.")
                time.sleep(10)
            else:
                return f"Error: {response.status_code} - {response.text}"
    except Exception as e:
        return f"Error: {str(e)}"


def on_send():
    user_input = entry.get()
    if user_input.strip() == "":
        return

    chat_area.config(state=tk.NORMAL)
    chat_area.insert(tk.END, f"You: {user_input}\n")
    chat_area.config(state=tk.DISABLED)

    response = send_to_mistral(user_input)
    chat_area.config(state=tk.NORMAL)
    chat_area.insert(tk.END, f"GPT: {response}\n")
    chat_area.config(state=tk.DISABLED)

    entry.delete(0, tk.END)


root = tk.Tk()
root.title("AI Chat Sidebar")
root.geometry("600x600+0+0")

chat_area = scrolledtext.ScrolledText(root, wrap=tk.WORD, state=tk.DISABLED)
chat_area.pack(fill=tk.BOTH, expand=True)

entry = tk.Entry(root)
entry.pack(fill=tk.X, padx=5, pady=5)

send_button = tk.Button(root, text="Send", command=on_send)
send_button.pack(fill=tk.X, padx=5, pady=5)

root.mainloop()
