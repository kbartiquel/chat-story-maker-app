# Textery Admin Hosting

This folder contains a Firebase Hosting-ready admin frontend for Textery.

## What it does

- Hosts a clean admin dashboard at `/admin`
- Talks to the live Textery API on Cloud Run
- Lets you:
  - log in with `ADMIN_PASSWORD`
  - edit paywall and limit settings
  - reset to defaults
  - preview the currently visible plans
  - monitor API health

## Current API base

The hosted admin uses:

`https://textery-api-7uam4panra-uc.a.run.app`

## Deploy

From the project root:

```bash
firebase deploy --project <your-firebase-project-id> --only hosting
```

If your Firebase Hosting domain is:

`https://your-site.web.app`

then the admin will be available at:

`https://your-site.web.app/admin`

## Notes

- The API still runs on Cloud Run.
- The admin is just the hosted frontend layer.
- CORS is already permissive in the FastAPI server, so the hosted admin can call the API directly.
