#!/bin/bash

API_KEY="<YOUR_API_KEY>"
CITY_ID="625144"

weather_data=$(curl -sf "http://api.openweathermap.org/data/2.5/weather?id=${CITY_ID}&appid=${API_KEY}&units=metric")

if [ "$weather_data" ]; then
    temp=$(echo "$weather_data" | jq ".main.temp" | xargs printf "%.0f")
    weather=$(echo "$weather_data" | jq -r ".weather[0].description")
    icon_code=$(echo "$weather_data" | jq -r ".weather[0].icon")

    case "$icon_code" in
    "01d" | "01n") icon="☀️" ;; # clear sky
    "02d" | "02n") icon="🌤" ;;  # few clouds
    "03d" | "03n") icon="☁️" ;; # scattered clouds
    "04d" | "04n") icon="🌥" ;;  # broken clouds
    "09d" | "09n") icon="🌧" ;;  # shower rain
    "10d" | "10n") icon="🌦" ;;  # rain
    "11d" | "11n") icon="⛈" ;;  # thunderstorm
    "13d" | "13n") icon="❄️" ;; # snow
    "50d" | "50n") icon="🌫" ;;  # mist
    *) icon="❓" ;;              # unknown
    esac

    echo "{\"text\": \"${icon} ${temp}°C\", \"tooltip\": \"${weather}\", \"class\": \"${icon_code}\"}"
else
    echo "{\"text\": \"No data\", \"tooltip\": \"Unable to fetch weather\"}"
fi
