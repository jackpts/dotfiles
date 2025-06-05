#!/bin/bash

weather_data=$(curl -s "https://wttr.in/?format=%C+%t")

if [ "$weather_data" ]; then
    temp=$(echo "$weather_data" | awk 'match($0, /(-?[0-9]+)°C/, a) {print a[1]}')
    weather=$(echo "$weather_data" | grep -oE '[A-Za-z ]+' | head -n 1 | sed 's/ *$//')

    if [[ $weather != *"Unknown location"* ]]; then
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
        "Shallow fog") icon="🌫" ;;
        "Freezing fog") icon="🌫" ;;
        "Light drizzle") icon="🌦" ;;
        "Light rain") icon="🌦" ;;
        "Light rain with thunderstorm") icon="⛈ " ;;
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
        exit 0
    fi
fi

# If location is unknown - get 2nd API from OpenWeatherMap using coordinates (Minsk)
# echo "Fallback!"

# Import environment variables from .env file
export $(grep -v '^#' $HOME/scripts/.env | xargs)
api_key=$OPENWEATHERMAP_API_KEY

weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/weather?lat=53.9&lon=27.5667&appid=${api_key}&units=metric")

if [ "$weather_data" ]; then
    temp=$(echo $weather_data | jq '.main.temp' | cut -d '.' -f 1)
    weather=$(echo $weather_data | jq -r '.weather[0].description')

    # echo "weather=${weather}"
    # echo "icon=${icon}"

    case "$weather" in
    "clear sky") icon="☀️" ;;
    "partly cloudy") icon="🌤" ;;
    "cloudy") icon="☁️" ;;
    "overcast") icon="🌥" ;;
    "mist") icon="🌫" ;;
    "patchy light drizzle") icon="󰕋 " ;;
    "patchy rain possible") icon="🌦" ;;
    "patchy rain nearby") icon="🌦" ;;
    "patchy snow possible") icon="🌨" ;;
    "patchy sleet possible") icon="🌧" ;;
    "patchy freezing drizzle possible") icon="🌧" ;;
    "thundery outbreaks possible") icon="⛈" ;;
    "blowing snow") icon="❄️" ;;
    "blizzard") icon="❄️" ;;
    "fog") icon="🌫" ;;
    "shallow fog") icon="🌫" ;;
    "freezing fog") icon="🌫" ;;
    "light drizzle") icon="🌦" ;;
    "light rain") icon="🌦" ;;
    "light rain with thunderstorm") icon="⛈ " ;;
    "moderate rain at times") icon="🌦" ;;
    "moderate rain") icon="🌦" ;;
    "heavy rain at times") icon="🌦" ;;
    "heavy rain") icon="🌦" ;;
    "light snow") icon="❄️" ;;
    "light snow grains") icon="❄️" ;;
    "light snow shower") icon="🌨️" ;;
    "moderate snow") icon="❄️" ;;
    "heavy snow") icon="❄️" ;;
    "ice pellets") icon="❄️" ;;
    "light rain shower") icon="🌦" ;;
    "moderate or heavy rain shower") icon="🌦" ;;
    "torrential rain shower") icon="🌦" ;;
    "light sleet") icon="🌧" ;;
    "moderate or heavy sleet") icon="🌧" ;;
    "light snow showers") icon="❄️" ;;
    "moderate or heavy snow showers") icon="❄️" ;;
    "light showers of ice pellets") icon="❄️" ;;
    "moderate or heavy showers of ice pellets") icon="❄️" ;;
    "patchy light rain with thunder") icon="⛈" ;;
    "moderate or heavy rain with thunder") icon="⛈" ;;
    "rain with thunderstorm") icon="⛈️" ;;
    "patchy light snow with thunder") icon="⛈" ;;
    "moderate or heavy snow with thunder") icon="⛈" ;;
    "rain and snow shower") icon="⛈️" ;;
    *) icon="❓" ;; # unknown
    esac

    echo "{\"text\": \"${icon} ${temp}°C\", \"tooltip\": \"${weather}\"}"
else
    echo "{\"text\": \"No data\", \"tooltip\": \"Unable to fetch weather\"}"
fi
