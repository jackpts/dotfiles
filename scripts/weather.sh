#!/bin/bash

weather_data=$(curl -s "https://wttr.in/?format=%C+%t")

if [ "$weather_data" ]; then
    temp=$(echo "$weather_data" | awk 'match($0, /(-?[0-9]+)°C/, a) {print a[1]}')
    weather=$(echo "$weather_data" | grep -oE '[A-Za-z ]+' | head -n 1 | sed 's/ *$//')

    case "$weather" in
    "Clear" | "Sunny") icon="☀️" ;;
    "Partly cloudy") icon="🌤" ;;
    "Cloudy") icon="☁️" ;;
    "Overcast") icon="🌥" ;;
    "Mist") icon="🌫" ;;
    "Patchy light drizzle") icon="󰕋 " ;;
    "Patchy rain possible") icon="🌦" ;;
    "Patchy rain nearby") icon="🌦" ;;
    "Patchy snow possible") icon="🌨" ;;
    "Patchy sleet possible") icon="🌧" ;;
    "Patchy freezing drizzle possible") icon="🌧" ;;
    "Thundery outbreaks possible") icon="⛈" ;;
    "Blowing snow") icon="❄️" ;;
    "Blizzard") icon="❄️" ;;
    "Fog") icon="🌫" ;;
    "Freezing fog") icon="🌫" ;;
    "Light drizzle") icon="🌦" ;;
    "Light rain") icon="🌦" ;;
    "Light rain with thunderstorm") icon="⛈ ";;
    "Moderate rain at times") icon="🌦" ;;
    "Moderate rain") icon="🌦" ;;
    "Heavy rain at times") icon="🌦" ;;
    "Heavy rain") icon="🌦" ;;
    "Light snow") icon="❄️" ;;
    "Light snow grains") icon="❄️" ;;
    "Light snow shower") icon="🌨️" ;;
    "Moderate snow") icon="❄️" ;;
    "Heavy snow") icon="❄️" ;;
    "Ice pellets") icon="❄️" ;;
    "Light rain shower") icon="🌦" ;;
    "Moderate or heavy rain shower") icon="🌦" ;;
    "Torrential rain shower") icon="🌦" ;;
    "Light sleet") icon="🌧" ;;
    "Moderate or heavy sleet") icon="🌧" ;;
    "Light snow showers") icon="❄️" ;;
    "Moderate or heavy snow showers") icon="❄️" ;;
    "Light showers of ice pellets") icon="❄️" ;;
    "Moderate or heavy showers of ice pellets") icon="❄️" ;;
    "Patchy light rain with thunder") icon="⛈" ;;
    "Moderate or heavy rain with thunder") icon="⛈" ;;
    "Rain with thunderstorm") icon="⛈️" ;;
    "Patchy light snow with thunder") icon="⛈" ;;
    "Moderate or heavy snow with thunder") icon="⛈" ;;
    "Rain and snow shower") icon="⛈️" ;;
    *) icon="❓" ;; # unknown
    esac

    echo "{\"text\": \"${icon} ${temp}°C\", \"tooltip\": \"${weather}\"}"
else
    echo "{\"text\": \"No data\", \"tooltip\": \"Unable to fetch weather\"}"
fi
