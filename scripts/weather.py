#!/usr/bin/env python3

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional
from zoneinfo import ZoneInfo

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

OPEN_METEO_DESCRIPTIONS = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Depositing rime fog",
    51: "Light drizzle",
    53: "Moderate drizzle",
    55: "Dense drizzle",
    56: "Light freezing drizzle",
    57: "Dense freezing drizzle",
    61: "Slight rain",
    63: "Moderate rain",
    65: "Heavy rain",
    66: "Light freezing rain",
    67: "Heavy freezing rain",
    71: "Slight snow",
    73: "Moderate snow",
    75: "Heavy snow",
    77: "Snow grains",
    80: "Slight rain showers",
    81: "Moderate rain showers",
    82: "Violent rain showers",
    85: "Slight snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm with slight hail",
    99: "Thunderstorm with heavy hail",
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
    return (str(temp) + "°").ljust(3)


def _round_temp(value: Any) -> str:
    if isinstance(value, (int, float)):
        return str(int(round(value)))
    return str(value)


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


def _parse_timestamp(ts: str) -> Optional[datetime]:
    """Parse Open-Meteo timestamps as naive local times for the forecast timezone."""
    try:
        if ts.endswith("Z"):
            ts = ts.replace("Z", "+00:00")
        dt = datetime.fromisoformat(ts)
        # Open-Meteo with timezone=auto returns naive wall-clock times in that zone.
        # Aware values are converted to naive UTC only as a last resort.
        if dt.tzinfo:
            return dt.astimezone(ZoneInfo("UTC")).replace(tzinfo=None)
        return dt
    except ValueError:
        return None


def _location_now(payload: Dict[str, Any]) -> datetime:
    """Current wall-clock time in the forecast location timezone (naive)."""
    tz_name = payload.get("timezone")
    if tz_name:
        try:
            return datetime.now(ZoneInfo(tz_name)).replace(tzinfo=None)
        except Exception:
            pass
    return datetime.now()


def _fmt_sun(ts: str) -> str:
    parsed = _parse_timestamp(ts)
    if not parsed:
        return ts
    return parsed.strftime("%H:%M")


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
        "&hourly=temperature_2m,apparent_temperature,weather_code,relative_humidity_2m,"
        "wind_speed_10m,precipitation_probability"
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
        "&timezone=auto"
        "&forecast_days=3"
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
        'text': WEATHER_CODES.get(current['weatherCode'], '🌡️') + "  " + current['temp_C'] + "°",
        'location': location_name,
    }

    tooltip_lines = [
        f"<b>{current['weatherDesc'][0]['value']} {current['temp_C']}°C</b>",
        f"Feels like: {current['FeelsLikeC']}°C",
        f"Wind: {format_wind_ms(current['windspeedKmph'])}",
        f"Humidity: {current['humidity']}%",
    ]

    now_hour = datetime.now().hour
    for i, day in enumerate(weather['weather']):
        label = "Today" if i == 0 else "Tomorrow" if i == 1 else day['date']
        tooltip_lines.append(f"\n<b>{label}, {day['date']}</b>")
        tooltip_lines.append(
            f"⬆️ {day['maxtempC']}° ⬇️ {day['mintempC']}° "
            f"🌅 {day['astronomy'][0]['sunrise']} 🌇 {day['astronomy'][0]['sunset']}"
        )
        for hour in day['hourly']:
            # wttr slots are 3-hourly in local time; skip slots that already ended
            if i == 0 and int(format_time(hour['time'])) < now_hour:
                continue
            tooltip_lines.append(
                f"{format_time(hour['time'])} {WEATHER_CODES.get(hour['weatherCode'], '🌡️')} "
                f"{format_temp(hour['tempC'])} {hour['weatherDesc'][0]['value']}, {format_chances(hour)}"
            )

    data['tooltip'] = "\n".join(tooltip_lines)
    return data


def format_open_meteo(payload: Dict[str, Any], location_name: str) -> Optional[Dict[str, str]]:
    current = payload.get('current')
    hourly = payload.get('hourly') or {}
    daily = payload.get('daily') or {}
    if not current:
        return None

    code = int(current.get('weather_code', 0))
    icon = OPEN_METEO_CODES.get(code, '🌡️')
    desc = OPEN_METEO_DESCRIPTIONS.get(code, "Weather")
    temp = current.get('temperature_2m', '?')
    feels = current.get('apparent_temperature', '?')
    humidity = current.get('relative_humidity_2m', '?')
    wind = current.get('wind_speed_10m', '?')
    temp_label = _round_temp(temp)
    feels_label = _round_temp(feels)

    data = {
        'text': f"{icon}  {temp_label}°",
        'location': location_name,
    }

    tooltip_lines = [
        f"<b>{desc} {temp_label}°C</b>",
        f"Feels like: {feels_label}°C",
        f"Wind: {format_wind_ms(wind)}",
        f"Humidity: {humidity}%",
    ]

    times = hourly.get('time', [])
    temps = hourly.get('temperature_2m', [])
    feels_list = hourly.get('apparent_temperature', [])
    codes = hourly.get('weather_code', [])
    humidity_list = hourly.get('relative_humidity_2m', [])
    precip_list = hourly.get('precipitation_probability', [])

    daily_dates = daily.get('time', [])
    daily_max = daily.get('temperature_2m_max', [])
    daily_min = daily.get('temperature_2m_min', [])
    daily_sunrise = daily.get('sunrise', [])
    daily_sunset = daily.get('sunset', [])

    now_local = _location_now(payload)
    now_floor = now_local.replace(minute=0, second=0, microsecond=0)

    for day_idx, day_date in enumerate(daily_dates):
        label = "Today" if day_idx == 0 else "Tomorrow" if day_idx == 1 else day_date
        tooltip_lines.append(f"\n<b>{label}, {day_date}</b>")

        max_t = _round_temp(daily_max[day_idx]) if day_idx < len(daily_max) else "?"
        min_t = _round_temp(daily_min[day_idx]) if day_idx < len(daily_min) else "?"
        sunrise = _fmt_sun(daily_sunrise[day_idx]) if day_idx < len(daily_sunrise) else "?"
        sunset = _fmt_sun(daily_sunset[day_idx]) if day_idx < len(daily_sunset) else "?"
        tooltip_lines.append(f"⬆️ {max_t}° ⬇️ {min_t}° 🌅 {sunrise} 🌇 {sunset}")

        shown = 0
        for idx, timestamp in enumerate(times):
            parsed = _parse_timestamp(timestamp)
            if not parsed or parsed.strftime("%Y-%m-%d") != day_date:
                continue
            # Only upcoming / current 3-hour slots in the location timezone
            if day_idx == 0 and parsed < now_floor:
                continue
            if parsed.hour % 3 != 0:
                continue

            code_hour = int(codes[idx]) if idx < len(codes) else 0
            icon_hour = OPEN_METEO_CODES.get(code_hour, '🌡️')
            desc_hour = OPEN_METEO_DESCRIPTIONS.get(code_hour, "Weather")
            temp_hour = _round_temp(temps[idx]) if idx < len(temps) else "?"
            feels_hour = _round_temp(feels_list[idx]) if idx < len(feels_list) else "?"
            humidity_hour = humidity_list[idx] if idx < len(humidity_list) else "?"
            precip_hour = precip_list[idx] if idx < len(precip_list) else None

            extras = [f"Humidity {humidity_hour}%"]
            if precip_hour is not None:
                extras.append(f"Rain {precip_hour}%")
            extras.append(f"Feels {feels_hour}°")

            tooltip_lines.append(
                f"{parsed.strftime('%H')} {icon_hour} {format_temp(temp_hour)} "
                f"{desc_hour}, {', '.join(extras)}"
            )
            shown += 1
            if shown >= 6:
                break

    data['tooltip'] = "\n".join(tooltip_lines)
    return data


def fetch_weather(location: Dict[str, Any]) -> Dict[str, str]:
    location_name = location.get("name", "Unknown")
    lat = float(location["lat"])
    lon = float(location["lon"])

    # Prefer Open-Meteo: wttr.in often serves stale "current" snapshots
    # that lag real local conditions by a couple of hours.
    primary = fetch_open_meteo(lat, lon)
    if primary:
        try:
            formatted = format_open_meteo(primary, location_name)
            if formatted:
                return formatted
        except Exception as exc:
            return build_error(f'Weather processing error: {exc}', location_name)

    fallback = fetch_wttr(lat, lon)
    if fallback:
        try:
            return format_wttr(fallback, location_name)
        except Exception as exc:
            return build_error(f'Weather processing error: {exc}', location_name)

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
