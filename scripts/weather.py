#!/usr/bin/env python3

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

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

CONFIG_DIR = Path(os.environ.get(
    "WEATHER_CONFIG_DIR",
    Path.home() / "dotfiles/.config/quickshell/jackbar",
))
LOCATIONS_FILE = CONFIG_DIR / "weather-locations.json"
SELECTED_FILE = CONFIG_DIR / "weather-selected"
DEFAULT_LOCATION_ID = "minsk"


def format_time(time):
    return time.replace("00", "").zfill(2)


def format_temp(temp):
    return (temp + "°").ljust(3)


def format_wind_ms(speed_kmh: Any) -> str:
    try:
        ms = float(speed_kmh) / 3.6
        if ms >= 10:
            return f"{round(ms)} m/s"
        return f"{ms:.1f} m/s"
    except (TypeError, ValueError):
        return f"{speed_kmh} m/s"


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
            conditions.append(chances[event] + " " + hour[event] + "%")
    return ", ".join(conditions)


def build_error(message: str, location_name: str = "") -> Dict[str, str]:
    return {'text': '🌡️ N/A', 'tooltip': message, 'location': location_name}


def load_locations() -> List[Dict[str, Any]]:
    if not LOCATIONS_FILE.is_file():
        return [{
            "id": "minsk",
            "name": "Minsk, Belarus",
            "lat": 53.9006,
            "lon": 27.5590,
        }]
    with LOCATIONS_FILE.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise ValueError("weather-locations.json must contain a list")
    return data


def find_location(locations: List[Dict[str, Any]], location_id: str) -> Optional[Dict[str, Any]]:
    for location in locations:
        if location.get("id") == location_id:
            return location
    return None


def default_location(locations: List[Dict[str, Any]]) -> Dict[str, Any]:
    location = find_location(locations, DEFAULT_LOCATION_ID)
    if location:
        return location
    return {
        "id": DEFAULT_LOCATION_ID,
        "name": "Minsk, Belarus",
        "lat": 53.9006,
        "lon": 27.5590,
    }


def read_selected_location_id() -> str:
    if SELECTED_FILE.is_file():
        selected = SELECTED_FILE.read_text(encoding="utf-8").strip()
        if selected:
            return selected
    return DEFAULT_LOCATION_ID


def write_selected_location_id(location_id: str) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    SELECTED_FILE.write_text(location_id + "\n", encoding="utf-8")


def resolve_location(location_id: Optional[str] = None) -> Dict[str, Any]:
    locations = load_locations()
    selected_id = location_id or read_selected_location_id()
    location = find_location(locations, selected_id)
    if location:
        return location
    if not location_id:
        write_selected_location_id(DEFAULT_LOCATION_ID)
    return default_location(locations)


def fetch_wttr(lat: float, lon: float) -> Optional[Dict[str, Any]]:
    url = f"https://wttr.in/{lat},{lon}?format=j1"
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        parsed = resp.json()
        if not parsed.get('current_condition'):
            return None
        return parsed
    except Exception:
        return None


def fetch_open_meteo(lat: float, lon: float) -> Optional[Dict[str, Any]]:
    url = (
        "https://api.open-meteo.com/v1/forecast"
        "?current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m"
        "&hourly=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,wind_speed_10m"
        "&timezone=auto"
        f"&latitude={lat}&longitude={lon}"
    )
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        return resp.json()
    except Exception:
        return None


def format_wttr(weather: Dict[str, Any], location_name: str) -> Dict[str, str]:
    current = weather['current_condition'][0]
    data = {
        'text': WEATHER_CODES.get(current['weatherCode'], '🌡️') + "  " + current['FeelsLikeC'] + "°",
        'location': location_name,
    }

    tooltip_lines = [
        f"<b>{current['weatherDesc'][0]['value']} {current['temp_C']}°C</b>",
        f"Feels like: {current['FeelsLikeC']}°C",
        f"Wind: {format_wind_ms(current['windspeedKmph'])}",
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


def _parse_timestamp(ts: str) -> Optional[datetime]:
    try:
        if ts.endswith("Z"):
            ts = ts.replace("Z", "+00:00")
        dt = datetime.fromisoformat(ts)
        if dt.tzinfo:
            return dt.astimezone().replace(tzinfo=None)
        return dt
    except ValueError:
        return None


def format_open_meteo(payload: Dict[str, Any], location_name: str) -> Optional[Dict[str, str]]:
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
        'text': f"{icon}  {int(round(temp)) if isinstance(temp, (int, float)) else temp}°",
        'location': location_name,
    }

    tooltip_lines = [
        f"<b>Open-Meteo {temp}°C</b>",
        f"Feels like: {feels}°C",
        f"Wind: {format_wind_ms(wind)}",
        f"Humidity: {humidity}%",
    ]

    times = hourly.get('time', [])
    temps = hourly.get('temperature_2m', [])
    feels_list = hourly.get('apparent_temperature', [])
    codes = hourly.get('weather_code', [])

    now_local = datetime.now()
    start_idx = 0
    for idx, timestamp in enumerate(times):
        parsed = _parse_timestamp(timestamp)
        if parsed and parsed >= now_local:
            start_idx = idx
            break
    else:
        start_idx = max(0, len(times) - 8)

    end_idx = min(start_idx + 8, len(times))

    for idx in range(start_idx, end_idx):
        timestamp = times[idx]
        parsed = _parse_timestamp(timestamp)
        hour_label = parsed.strftime("%H:%M") if parsed else timestamp
        code_hour = int(codes[idx]) if idx < len(codes) else 0
        icon_hour = OPEN_METEO_CODES.get(code_hour, '🌡️')
        temp_hour = temps[idx] if idx < len(temps) else '?'
        feels_hour = feels_list[idx] if idx < len(feels_list) else '?'
        tooltip_lines.append(
            f"{hour_label} {icon_hour} {temp_hour}° (feels {feels_hour}°)"
        )

    data['tooltip'] = "\n".join(tooltip_lines)
    return data


def fetch_weather(location: Dict[str, Any]) -> Dict[str, str]:
    location_name = location.get("name", "Unknown")
    lat = float(location["lat"])
    lon = float(location["lon"])

    weather = fetch_wttr(lat, lon)
    if weather:
        try:
            return format_wttr(weather, location_name)
        except Exception as exc:
            return build_error(f'Weather processing error: {exc}', location_name)

    fallback_payload = fetch_open_meteo(lat, lon)
    if fallback_payload:
        formatted = format_open_meteo(fallback_payload, location_name)
        if formatted:
            return formatted
        return build_error('Fallback weather data unavailable', location_name)

    return build_error('Weather data unavailable (no endpoints)', location_name)


def main() -> None:
    parser = argparse.ArgumentParser(description="Weather widget data provider")
    parser.add_argument("--json", action="store_true", help="Print weather JSON for the panel")
    parser.add_argument("--list-locations", action="store_true", help="Print configured locations")
    parser.add_argument("--location", help="Location id to use for this request")
    parser.add_argument("--set-location", help="Persist selected location id and fetch weather")
    args = parser.parse_args()

    if args.list_locations:
        print(json.dumps(load_locations()))
        return

    location_id = args.set_location or args.location
    if args.set_location:
        write_selected_location_id(args.set_location)

    location = resolve_location(location_id)
    output = fetch_weather(location)
    output["locationId"] = location.get("id", "")
    print(json.dumps(output))


if __name__ == '__main__':
    main()
