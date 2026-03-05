
#!/usr/bin/env python3

import json
import os
import sys
from datetime import datetime
from typing import Any, Dict, Optional

import requests

WEATHER_CODES = {
    '113': '🌈',
    '116': '⛅️',
    '119': '☁️',
    '122': '☁️',
    '143': '󰖑',
    '176': '🌦',
    '179': '🌧',
    '182': '🌧',
    '185': '🌧',
    '200': '⛈',
    '227': '🌨',
    '230': '❄️',
    '248': '󰖑',
    '260': '󰖑',
    '263': '🌦',
    '266': '🌦',
    '281': '🌧',
    '284': '🌧',
    '293': '🌦',
    '296': '🌦',
    '299': '🌧',
    '302': '🌧',
    '305': '🌧',
    '308': '🌧',
    '311': '🌧',
    '314': '🌧',
    '317': '🌧',
    '320': '🌨',
    '323': '🌨',
    '326': '🌨',
    '329': '❄️',
    '332': '❄️',
    '335': '❄️',
    '338': '❄️',
    '350': '🌧',
    '353': '🌦',
    '356': '🌧',
    '359': '🌧',
    '362': '🌧',
    '365': '🌧',
    '368': '🌨',
    '371': '❄️',
    '374': '🌧',
    '377': '🌧',
    '386': '⛈',
    '389': '🌩',
    '392': '⛈',
    '395': '❄️'
}

WTTR_URL = "https://wttr.in/?format=j1"
DEFAULT_LAT = float(os.environ.get("WEATHER_LAT", "53.9"))
DEFAULT_LON = float(os.environ.get("WEATHER_LON", "27.5667"))

OPEN_METEO_URL = (
    "https://api.open-meteo.com/v1/forecast"
    "?current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m"
    "&hourly=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,wind_speed_10m"
    "&timezone=auto"
    f"&latitude={DEFAULT_LAT}&longitude={DEFAULT_LON}"
)

OPEN_METEO_CODES = {
    0: "☀️",
    1: "🌤",
    2: "⛅️",
    3: "☁️",
    45: "🌫",
    48: "🌫",
    51: "🌦",
    53: "🌦",
    55: "🌦",
    56: "🌨",
    57: "🌨",
    61: "🌧",
    63: "🌧",
    65: "🌧",
    66: "🌨",
    67: "🌨",
    71: "🌨",
    73: "🌨",
    75: "❄️",
    77: "❄️",
    80: "🌦",
    81: "🌦",
    82: "🌧",
    85: "❄️",
    86: "❄️",
    95: "⛈",
    96: "⛈",
    99: "⛈",
}


def format_time(time):
    return time.replace("00", "").zfill(2)


def format_temp(temp):
    return (temp+"°").ljust(3)


def format_chances(hour):
    chances = {
        "chanceoffog": "Fog",
        "chanceoffrost": "Frost",
        "chanceofovercast": "Overcast",
        "chanceofrain": "Rain",
        "chanceofsnow": "Snow",
        "chanceofsunshine": "Sunshine",
        "chanceofthunder": "Thunder",
        "chanceofwindy": "Wind"
    }

    conditions = []
    for event in chances.keys():
        if int(hour[event]) > 0:
            conditions.append(chances[event]+" "+hour[event]+"%")
    return ", ".join(conditions)


def build_error(message: str) -> Dict[str, str]:
    return {'text': '🌡️ N/A', 'tooltip': message}


def fetch_wttr() -> Optional[Dict[str, Any]]:
    try:
        resp = requests.get(WTTR_URL, timeout=10)
        resp.raise_for_status()
        parsed = resp.json()
        if not parsed.get('current_condition'):
            return None
        return parsed
    except Exception:
        return None


def format_wttr(weather: Dict[str, Any]) -> Dict[str, str]:
    current = weather['current_condition'][0]
    data = {
        'text': WEATHER_CODES.get(current['weatherCode'], '🌡️') + "  " + current['FeelsLikeC'] + "°"
    }

    tooltip_lines = [
        f"<b>{current['weatherDesc'][0]['value']} {current['temp_C']}°C</b>",
        f"Feels like: {current['FeelsLikeC']}°C",
        f"Wind: {current['windspeedKmph']}Km/h",
        f"Humidity: {current['humidity']}%",
    ]

    for i, day in enumerate(weather['weather']):
        label = "Today" if i == 0 else "Tomorrow" if i == 1 else day['date']
        tooltip_lines.append(f"\n<b>{label}, {day['date']}</b>")
        tooltip_lines.append(
            f"⬆️ {day['maxtempC']}° ⬇️ {day['mintempC']}° "
            f"🌅 {day['astronomy'][0]['sunrise']} 🌇 {day['astronomy'][0]['sunset']}"
        )
        for hour in day['hourly']:
            if i == 0 and int(format_time(hour['time'])) < datetime.now().hour - 2:
                continue
            tooltip_lines.append(
                f"{format_time(hour['time'])} {WEATHER_CODES.get(hour['weatherCode'], '🌡️')} "
                f"{format_temp(hour['FeelsLikeC'])} {hour['weatherDesc'][0]['value']}, {format_chances(hour)}"
            )

    data['tooltip'] = "\n".join(tooltip_lines)
    return data


def fetch_open_meteo() -> Optional[Dict[str, Any]]:
    try:
        resp = requests.get(OPEN_METEO_URL, timeout=10)
        resp.raise_for_status()
        return resp.json()
    except Exception:
        return None


def format_open_meteo(payload: Dict[str, Any]) -> Optional[Dict[str, str]]:
    current = payload.get('current')
    hourly = payload.get('hourly') or {}
    if not current:
        return None

    code = int(current.get('weather_code', 0))
    icon = OPEN_METEO_CODES.get(code, '🌡️')
    temp = current.get('temperature_2m', '?')
    feels = current.get('apparent_temperature', '?')
    humidity = current.get('relative_humidity_2m', '?')
    wind = current.get('wind_speed_10m', '?')

    data = {
        'text': f"{icon}  {int(round(temp)) if isinstance(temp, (int, float)) else temp}°"
    }

    tooltip_lines = [
        f"<b>Open-Meteo {temp}°C</b>",
        f"Feels like: {feels}°C",
        f"Wind: {wind} km/h",
        f"Humidity: {humidity}%",
    ]

    times = hourly.get('time', [])
    temps = hourly.get('temperature_2m', [])
    feels_list = hourly.get('apparent_temperature', [])
    codes = hourly.get('weather_code', [])

    for idx in range(min(8, len(times))):
        timestamp = times[idx]
        try:
            hour_label = datetime.fromisoformat(timestamp).strftime("%H:%M")
        except ValueError:
            hour_label = timestamp
        code_hour = int(codes[idx]) if idx < len(codes) else 0
        icon_hour = OPEN_METEO_CODES.get(code_hour, '🌡️')
        temp_hour = temps[idx] if idx < len(temps) else '?'
        feels_hour = feels_list[idx] if idx < len(feels_list) else '?'
        tooltip_lines.append(
            f"{hour_label} {icon_hour} {temp_hour}° (feels {feels_hour}°)"
        )

    data['tooltip'] = "\n".join(tooltip_lines)
    return data


def main() -> None:
    weather = fetch_wttr()
    if weather:
        try:
            output = format_wttr(weather)
        except Exception as exc:
            output = build_error(f'Weather processing error: {exc}')
    else:
        fallback_payload = fetch_open_meteo()
        if fallback_payload:
            formatted = format_open_meteo(fallback_payload)
            output = formatted if formatted else build_error('Fallback weather data unavailable')
        else:
            output = build_error('Weather data unavailable (no endpoints)')

    print(json.dumps(output))


if __name__ == '__main__':
    main()
