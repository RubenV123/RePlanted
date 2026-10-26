# RePlated mobile app

Native Expo / React Native app for Android and iOS. It supports local demo mode and a Supabase-backed team mode. The browser prototype remains in the sibling replated-mvp folder.

## Start the app

In PowerShell, run from the app folder:

    cd C:\Users\sheeb\Downloads\AIESEC_Hackathon\replated-app
    npm start

This project starts Expo Go. Do not add --dev-client. Install Expo Go on your phone, keep phone and computer on the same Wi-Fi, and scan the fresh QR shown in the terminal. Android emulators need Android Studio; iOS Simulator needs macOS.

## Run on the PC Android emulator

Install Android Studio and its Android SDK / Android Emulator components. In Android Studio, open Device Manager, create a Pixel virtual device, download a system image if asked, and press Play to start it. Then run this from the project folder:

    npm run android

The command starts Expo Go and opens the project on the running emulator; no phone or QR scan is needed. Expo CLI can also open an already-running emulator by pressing A after npm start.



## Run the website

This is the same Expo project as the Android app, with a responsive web layout and browser-specific map and time controls. From the `replated-app` folder, run:

    npm run web

Expo opens the website in your browser. On a wide screen, each workspace uses a left navigation rail; on a narrow screen it switches to the app-style bottom bar. Donor, NGO and rider flows use the same Supabase project when the `EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY` values in `.env` are configured. Without them, the website runs in local demo mode and its data stays in that browser.

## Enable Supabase

Supabase credentials have not been supplied, so the app currently starts in its local demo mode. To connect a project:

1. Create a Supabase project.
2. Copy .env.example to .env. Set EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY from the Supabase Connect panel. Use the publishable key; never put a service_role key in a mobile app.
3. Run both migrations in filename order in Supabase SQL Editor:

       supabase/migrations/0001_replated.sql
       supabase/migrations/20261024211555_add_replated_workflows.sql
       supabase/migrations/20261024215116_add_delivery_tracking_receipt_evidence.sql

   If `0001_replated.sql` was already applied, run only the second migration.
4. Restart Expo with npm start so it loads the environment variables.
5. Create team accounts in the app. New signups are donors. Change other accounts' roles using the SQL editor, replacing the emails:

       update public.profiles p set role='dispatcher'
       from auth.users u where p.id=u.id and u.email='operator@example.com';

       update public.profiles p set role='recipient'
       from auth.users u where p.id=u.id and u.email='ngo@example.com';

       update public.profiles p set role='rider'
       from auth.users u where p.id=u.id and u.email='rider@example.com';

Roles are read from Supabase profiles; the role picker selects a workspace but does not grant account permissions. New signups create donor accounts with name, phone, organization and address. An administrator must verify and promote NGO and rider accounts. Listings are shared through Postgres; offers, declines and reviews sync through Realtime. Private camera evidence is stored in the `food-evidence` bucket, and RLS controls which participants can read it. The workflow is donor offer → NGO capacity acceptance → rider pickup claim → pickup/drop-off photos → NGO inspection → review or reasoned rejection. NGO decline records exclude that NGO from later offers for the same batch.

The app UI is English-only. Prepared and pickup-deadline times use the Android system time picker; temperature accepts digits only. An NGO sees a live rider map during pickup-to-delivery while the rider has the app open and has granted foreground location permission. The rider location stops updating when the delivery is accepted, completed, the app is closed, or permission is denied. Expo Go includes Maps for development; store builds need a Google Maps Android API key configured for `react-native-maps`. The demo can run without Supabase, but it is local-only and does not share live GPS or changes across devices.

## Limits

This is a hackathon MVP. Live GPS is foreground-only and depends on location permission, network connectivity, and the rider keeping the app open. It has no payments, identity checks, push notifications, automated temperature validation or FSSAI verification. The external map route depends on the address being accurate. Safety fields and human review prompts do not certify food. Validate real handling, licensing, permissions and operating procedures before live distribution.
