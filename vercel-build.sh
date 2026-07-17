#!/bin/bash
echo "GEMINI_API_KEY=$GEMINI_API_KEY" > .env
echo "APP_URL=$APP_URL" >> .env
echo "OPENWEATHER_API_KEY=$OPENWEATHER_API_KEY" >> .env
echo "SUPABASE_URL=$SUPABASE_URL" >> .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
echo "GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID" >> .env
echo "NVIDIA_API_KEY=$NVIDIA_API_KEY" >> .env

if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi
./flutter/bin/flutter build web --release

