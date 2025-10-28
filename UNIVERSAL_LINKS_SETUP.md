# Universal Links Setup Guide

## What Are Universal Links?

Universal Links allow your app to handle `https://` URLs instead of custom schemes like `narration://`. This provides a much better user experience:

**Benefits:**
- ✅ **App not installed?** → Opens web page with App Store link
- ✅ **App installed?** → Opens directly in app
- ✅ **Works in Messages, Email, Safari** → No "Cannot open" errors
- ✅ **Better for App Store discovery** → Can drive installs
- ✅ **More professional** → Uses your domain instead of custom scheme

## Current Implementation Status

✅ **App-side code** - Complete and ready
✅ **Entitlements** - Associated Domains configured
✅ **URL handling** - Supports both `https://narration.app/template?data=...` and `narration://template?data=...`

## What You Need to Set Up

### 1. Domain & Hosting

You'll need:
- A domain (e.g., `narration.app`)
- Web hosting (can be simple static hosting like GitHub Pages, Netlify, Vercel, or S3)

### 2. Apple App Site Association (AASA) File

Create a file at: `https://narration.app/.well-known/apple-app-site-association`

**No file extension!** Just `apple-app-site-association` (no .json)

**Content:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.yourcompany.Narration",
        "paths": ["/template", "/template/*"]
      }
    ]
  }
}
```

**Replace:**
- `TEAM_ID` → Your Apple Developer Team ID (e.g., `TUG3BHLSM4`)
- `com.yourcompany.Narration` → Your actual bundle identifier (currently `okekedev.Narration`)

**Example:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TUG3BHLSM4.okekedev.Narration",
        "paths": ["/template", "/template/*"]
      }
    ]
  }
}
```

### 3. Web Page for Non-App Users

Create `https://narration.app/template` (can be any path, but keep it consistent)

**Example HTML:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Import Narration Template</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            text-align: center;
        }
        .button {
            display: inline-block;
            background: #007AFF;
            color: white;
            padding: 15px 30px;
            border-radius: 10px;
            text-decoration: none;
            font-size: 18px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <h1>Clinical Documentation Template</h1>
    <p>Open this template in the Narration app to use it for your clinical documentation.</p>

    <div id="app-installed" style="display:none;">
        <p>Opening in Narration app...</p>
    </div>

    <div id="app-not-installed">
        <p>Don't have Narration yet?</p>
        <a href="https://apps.apple.com/app/idYOUR_APP_ID" class="button">
            Download from App Store
        </a>
    </div>

    <script>
        // Attempt to open in app
        const urlParams = new URLSearchParams(window.location.search);
        const data = urlParams.get('data');

        if (data) {
            // Try to open app (will fail silently if not installed)
            window.location.href = `narration://template?data=${data}`;

            // Show app opening message
            setTimeout(() => {
                document.getElementById('app-installed').style.display = 'block';
            }, 500);
        }
    </script>
</body>
</html>
```

### 4. Server Configuration

**AASA File Requirements:**
- Must be served over HTTPS
- Must return `Content-Type: application/json`
- No redirects allowed (must be 200 OK)
- File size limit: 128KB

**Nginx Example:**
```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    return 200 '{"applinks":{"apps":[],"details":[{"appID":"TUG3BHLSM4.okekedev.Narration","paths":["/template","/template/*"]}]}}';
}
```

**Apache .htaccess Example:**
```apache
<Files "apple-app-site-association">
    Header set Content-Type "application/json"
</Files>
```

### 5. Testing Universal Links

**Before App Store approval:**

1. **Install app via Xcode** on test device
2. **Open Safari** on test device
3. **Type URL**: `https://narration.app/template?data=test123`
4. **Tap Go** → Should open in app (not Safari)

**Validation:**
- Test with app installed → Should open in app
- Test with app deleted → Should open web page
- Share via Messages → Long press link should show "Open in Narration"

**Apple's Validator:**
```bash
curl -v https://narration.app/.well-known/apple-app-site-association
```

Should return JSON with no redirects.

### 6. After App Store Approval

Once your app is on the App Store:

1. Update web page with actual App Store link
2. iOS will automatically verify AASA file when users install app
3. Universal Links will work for all users immediately

## How Users Will Experience It

### **Scenario 1: App Installed**
1. User receives: `https://narration.app/template?data=abc123`
2. User taps link
3. iOS recognizes domain → Opens Narration app
4. Template imports automatically
5. Alert: "Template imported!"

### **Scenario 2: App NOT Installed**
1. User receives: `https://narration.app/template?data=abc123`
2. User taps link
3. Opens in Safari (no app to handle it)
4. Web page says: "Download Narration to import this template"
5. User downloads app → Taps link again → Opens in app

## Alternative: Short Links

For cleaner sharing, you can use a URL shortener:

**Before:**
```
https://narration.app/template?data=eyJpZCI6IjEyMzQ1Njc4LTEyMzQtMTIzNC0xMjM0LTEyMzQ1Njc4OTBhYiIsIm5hbWUiOiJIb21lIEhlYWx0aCBWaXNpdCIsInF1ZXN0aW9ucyI6W3siaWQiOiIxMjM0NTY3OC0xMjM0LTEyMzQtMTIzNC0xMjM0NTY3ODkwYWIiLCJudW1iZXIiOjEsInByb21wdCI6IldobyBkaWQgeW91IHZpc2l0IGFuZCB3aGF0IHdhcyB0aGVpciBjb25kaXRpb24/Iiwic2VjdGlvblRpdGxlIjoiUGF0aWVudCBJbmZvcm1hdGlvbiJ9XX0=
```

**After:**
```
https://narr.at/t/abc123
```

Set up a simple redirect on your server or use bit.ly, tinyurl, etc.

## Troubleshooting

**Universal Links not working?**
- Verify AASA file is accessible: `curl https://narration.app/.well-known/apple-app-site-association`
- Check Team ID and Bundle ID match exactly
- Ensure HTTPS (not HTTP)
- Clear Safari cache on test device
- Reinstall app from Xcode

**Still using custom scheme?**
- That's fine! `narration://` will continue to work as fallback
- Both schemes are supported simultaneously

## Summary

✅ **App is ready** - Code complete, no changes needed
⏳ **Web setup needed** - Domain, AASA file, landing page
🎯 **Result** - Professional sharing experience with App Store fallback

The custom `narration://` scheme still works, so sharing works immediately. Universal Links just add the polish for production!
