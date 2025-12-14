# Voyage Sorgun TV Homescreen

A modern, elegant hotel TV welcome screen application with dynamic program scheduling, real-time weather information, and news ticker. Built as a single-page HTML application with an admin interface for program management.

## Features

### 🎨 Main Display (`voyage-sorgun-tv.html`)
- **Dynamic Greetings**: Time-based multilingual greetings (Turkish, German, Russian)
- **Real-time Weather**: Weather conditions with marine data (wave height, wind speed, wind direction)
- **Day/Night Theme**: Automatic theme switching based on time of day
- **Weather Effects**: Dynamic visual effects (rain, snow, fog, lightning) based on weather conditions
- **Program Schedule**: Display of daily activities, kids activities, evening shows, and after shows
- **News Ticker**: Bloomberg-style scrolling news ticker with political and sports news
- **Responsive Design**: Optimized for TV displays and various screen sizes

### ⚙️ Admin Panel (`admin.html`)
- **Excel-like Interface**: Intuitive spreadsheet-style program management
- **Time Slot Management**: Add/remove custom time slots (e.g., 10:00, 21:15, 23:30)
- **Category Management**: Organize programs by category (Daily Activities, Kids Activities, Evening Shows, etc.)
- **Login Protection**: Secure admin access with username/password authentication
- **Real-time Updates**: Changes reflect immediately on the main display

## Technologies Used

- **HTML5**: Single-page application structure
- **CSS3**: Modern styling with CSS variables, animations, and glassmorphism effects
- **JavaScript (Vanilla)**: Dynamic content updates and API integrations
- **Open-Meteo API**: Weather and marine data
- **NewsAPI.org**: News headlines and descriptions
- **localStorage**: Client-side data persistence

## Setup

### Prerequisites
- A modern web browser (Chrome, Firefox, Safari, Edge)
- Internet connection (for API calls)
- Optional: NewsAPI.org API key for real news (fallback example news included)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/voyage-homescreen.git
cd voyage-homescreen
```

2. Open `voyage-sorgun-tv.html` in a web browser or deploy to a web server.

3. (Optional) Configure News API:
   - Get a free API key from [NewsAPI.org](https://newsapi.org/)
   - The application will use example news if no API key is provided

## Usage

### Main Display

Simply open `voyage-sorgun-tv.html` in a browser. The application will:
- Automatically update date and time
- Fetch weather data every 10 minutes
- Update news ticker every 10 minutes
- Switch themes based on time of day
- Display current and upcoming programs

### Admin Panel

1. Open `admin.html` in a browser
2. Login with your admin credentials
3. Select a category from the dropdown
4. Add time slots using the "Add Time" input (format: HH:MM)
5. Click on any cell to edit program names
6. Click "Save All Programs" to persist changes

### Program Management

- **Time Slots**: Add custom times (e.g., 10:00, 21:15, 23:30)
- **Programs**: Enter program names directly in table cells
- **Categories**: Switch between different program categories
- **Auto-sort**: Time slots automatically sort chronologically

## File Structure

```
voyage-homescreen/
├── voyage-sorgun-tv.html    # Main display application
├── admin.html                # Admin panel for program management
└── README.md                 # This file
```

## Configuration

### Weather Location
Default location is set for Manavgat/Sorgun, Turkey. To change:
- Edit the `latitude` and `longitude` variables in the `updateWeather()` function

### News API Key
To use real news instead of example news:
1. Get an API key from NewsAPI.org
2. The application will automatically use it if available in localStorage
3. Or manually set: `localStorage.setItem('news-api-key', 'YOUR_API_KEY')`

## Features in Detail

### Dynamic Greetings
- **Morning** (6:00-12:00): "Good Morning" / "Günaydın" / "Guten Morgen" / "Доброе утро"
- **Afternoon** (12:00-18:00): "Good Afternoon" / "Tünaydın" / "Guten Tag" / "Добрый день"
- **Evening** (18:00-22:00): "Good Evening" / "İyi Akşamlar" / "Guten Abend" / "Добрый вечер"
- **Night** (22:00-6:00): "Good Night" / "İyi Geceler" / "Gute Nacht" / "Спокойной ночи"

### Weather Information
- Temperature with weather icon
- Wave height with icon
- Wind speed and direction with icon
- All displayed with equal sizing and formatting

### Program Display
- Shows current or next upcoming program
- Evening shows remain visible from morning until next day
- Programs automatically update when time passes

### Weather Effects
- **Rain**: Animated raindrops for rainy conditions
- **Snow**: Falling snowflakes for snowy weather
- **Fog**: Fog overlay effect
- **Lightning**: Flash effects for stormy conditions

## Browser Compatibility

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Opera (latest)

## Responsive Breakpoints

- **Desktop**: 1440px and above
- **Tablet**: 1200px - 1440px
- **Mobile**: 768px - 1200px
- **Small Mobile**: Below 768px

## License

This project is proprietary software developed for Voyage Sorgun Hotel.

## Support

For issues, questions, or contributions, please contact the development team.

## Acknowledgments

- Weather data provided by [Open-Meteo](https://open-meteo.com/)
- News data provided by [NewsAPI.org](https://newsapi.org/)
- Fonts: Cormorant Garamond (Google Fonts)

---

**Note**: This application is designed for hotel TV displays and requires a modern browser with JavaScript enabled.
