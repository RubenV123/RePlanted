# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it **privately** by emailing the maintainers directly rather than opening a public issue.

**Do not** create a public GitHub issue for security vulnerabilities.

## Supported Versions

This is a hackathon prototype. Only the latest `main` branch receives security attention.

## Security Boundaries (What This Project Does Not Provide)

This project is an **MVP prototype** for the AIESEC Hackathon. It explicitly does **not** provide:

- **Food-safety certification**: Temperature and allergen fields record evidence but do **not** certify food as safe
- **Identity verification**: No KYC, no authentication beyond Supabase auth
- **Payment processing**: No financial transactions
- **Push notifications**: Not implemented
- **Automated compliance**: No FSSAI or regulatory validation
- **Background location tracking**: Only foreground location when rider has app open and granted permission
- **Production-grade encryption**: Uses Supabase defaults for transport (TLS) and storage

## Known Security Considerations

### For Developers

1. **Never commit real Supabase keys** — Use `.env` (gitignored) and copy from `.env.example`
2. **Never use `service_role` key in client code** — Only the publishable/anon key belongs in the app
3. **Row-Level Security (RLS) is enforced** — The Supabase schema uses RLS to control data access by role
4. **Camera evidence is stored in private Supabase Storage bucket** — Access controlled by RLS policies
5. **Location data is opt-in** — Only collected when rider explicitly grants foreground permission during active delivery

### For Deployers

1. **Configure proper Supabase RLS policies** — The migrations include policies but verify they match your needs
2. **Use HTTPS in production** — Expo web builds served over HTTPS
3. **Validate environment variables** — Ensure `.env` is not accidentally deployed
4. **Google Maps API key** — If building for store distribution, restrict the API key to your app bundle ID

## Security Scanning

This repository includes automated security scanning via GitHub Actions:

- **Daily npm audit** — Checks for vulnerable dependencies in `replated-app/`
- **Secret scanning** — Searches for common secret patterns in source code
- **CI linting** — Basic syntax and structure checks on every push

## License

This project is licensed under the MIT License. See `replated-app/LICENSE` for details.