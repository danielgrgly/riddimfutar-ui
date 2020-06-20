# riddimfutár-ui

This repo is for the RIDDIMFUTÁR app's Flutter frontend. The Serverless Node.js-based backend can be found in [this repository](https://github.com/danielgrgly/riddimfutar-api).

## Important legal stuff

**This project is not afflitiated with the Budapesti Közlekedési Központ (BKK) and the Forgalomirányítási és Utastájékoztatási Rendszer (FUTÁR) in any way. This project is solely for educational and experimental purposes.**

## What will this app do?

This Flutter app will provide the users with **location-based riddim music**. The base idea is the following:
- you get on board on an overground public transport vehicle like a bus, tram or trolley.
- you select the current stop, your ride (e.g. tram number 4 to "Széll Kálmán tér")
- a random beat will start
- as you get closer to the next stop, the music gets faster and faster
- when you arrive at the stop, the app announces the stop and a very lit beat drops
- then the app announces the next stop and another music will start

## Development

Clone the repo, install dependencies with `pub get install`, add your own environment variables (backend deployment URL, S3 bucket URL, etc.), and run `flutter run`.
