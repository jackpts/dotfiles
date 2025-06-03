#!/bin/bash

weather_data=$(curl -s "https://wttr.in/?format=%C+%t")

if [ "$weather_data" ] && [[ $weather_data != *"Location unknown"* ]]; then
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

# echo "Fallback!"

# If location is unknown - get 2nd API from OpenWeatherMap using coordinates (Minsk)

# Import environment variables from .env file
export $(grep -v '^#' .env | xargs)
api_key=$OPENWEATHERMAP_API_KEY

    weather_data=$(curl -s "http://api.openweathermap.org/data/2.5/weather?lat=53.9&lon=27.5667&appid=${api_key}&units=metric")

    if [ "$weather_data" ]; then
        temp=$(echo $weather_data | jq '.main.temp' | cut -d '.' -f 1)
        weather=$(echo $weather_data | jq -r '.weather[0].description')
        icon=$(echo "$owm_data" | jq -r '.weather[0].icon')


        case "$icon" in
        "01d" | "01n") icon="☀️" ;;
        "02d" | "02n") icon="🌤" ;;
        "03d" | "03n" | "04d" | "04n") icon="☁️" ;;
        "09d" | "09n" | "10d" | "10n") icon="🌧" ;;
        "11d" | "11n") icon="⛈" ;;
        "13d" | "13n") icon="❄️" ;;
        "50d" | "50n") icon="🌫" ;;

        # Clear sky
            800) icon="☀️" ;; # Clear sky (day)
            801) icon="🌤" ;; # Few clouds
            802) icon="⛅" ;; # Scattered clouds
            803|804) icon="☁️" ;; # Broken/Overcast clouds


        # Drizzle
            300|301|302|310|311|312|313|314|321) icon="🌦" ;; # Light/Moderate/Heavy drizzle

            # Rain
            500|501) icon="🌦" ;; # Light/Moderate rain
            502|503|504) icon="🌧" ;; # Heavy rain
            511) icon="❄️" ;; # Freezing rain
            520|521|522|531) icon="🌦" ;; # Shower rain

            # Snow
            600|601|602|611|612|613|615|616|620|621|622) icon="❄️" ;; # Snow, sleet, shower snow

            # Thunderstorm
            200|201|202|210|211|212|221|230|231|232) icon="⛈" ;; # Thunderstorm with rain/snow

            # Atmosphere (fog, mist, haze)
            701|711|721|731|741|751|761|762|771|781) icon="🌫" ;; # Mist, fog, haze, sandstorm

            # Special cases
            "Thunderstorm with light rain") icon="⛈" ;;
            "Thunderstorm with heavy rain") icon="⛈" ;;
            "Light intensity shower rain") icon="🌦" ;;
            "Heavy intensity shower rain") icon="🌦" ;;
            "Freezing rain") icon="❄️" ;;
            "Light intensity drizzle") icon="🌦" ;;
            "Heavy intensity drizzle") icon="🌦" ;;
            "Shower snow") icon="❄️" ;;
            "Shower drizzle") icon="🌦" ;;
            "Sand/dust whirls") icon="🌪" ;; # Custom emoji
            "Tornado") icon="🌪" ;;
            "Squalls") icon="🌬" ;;
            "Ash") icon="🌋" ;; # Custom emoji
            "Hail") icon="🧊" ;; # Custom emoji

            # Unknown
            *) icon="❓" ;;
        esac

        echo "{\"text\": \"${icon} ${temp}°C\", \"tooltip\": \"${weather}\"}"
    else
        echo "{\"text\": \"No data\", \"tooltip\": \"Unable to fetch weather\"}"
    fi
fi
