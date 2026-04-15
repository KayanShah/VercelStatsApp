<div align="center">
<br/>

# Vercel Stats App
**Live analytics dashboard for your Vercel projects, always in your pocket.**  
Built by [Kayan Shah](https://github.com/KayanShah)

<br/>

[![Swift](https://img.shields.io/badge/Built%20with-Swift%20%2F%20SwiftUI-f05138?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/swift/)
[![Platform](https://img.shields.io/badge/Platform-iOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/)
[![Vercel](https://img.shields.io/badge/Powered%20by-Vercel%20API-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://vercel.com)
[![License](https://img.shields.io/badge/License-MIT%20%2B%20Attribution-000000?style=for-the-badge)](./LICENSE)

<br/>

![Divider](https://img.shields.io/badge/─────────────────────────────────────────────-transparent?style=flat-square)

</div>

---

## ✦ About

**Vercel Stats App** is a native iOS app that gives you instant access to your Vercel Web Analytics — visits, page views, bounce rate, top pages, countries, devices, browsers, and OS — all from your phone.

No browser. No laptop. Just your data, fast, wherever you are.

Built entirely in SwiftUI, it connects directly to the Vercel API using your personal access token and pulls real-time analytics for all your projects.

---

## ✦ Features

| | Feature |
|---|---|
| 📊 | **Analytics Dashboard** — visits, unique visitors, page views, and bounce rate at a glance |
| 📈 | **Visits Over Time** — bar chart showing daily traffic over the selected period |
| 🗂️ | **Top Pages** — ranked by visitors with proportional fill bars |
| 🌍 | **Top Countries** — flag, name, and percentage breakdown |
| 📱 | **Devices, Browsers & OS** — full visitor breakdown matching the Vercel dashboard |
| 🚀 | **Deployments** — live deployment history with status, branch, commit message, and time |
| 🗃️ | **Multi-Project Support** — switch between all your Vercel projects instantly |
| ⏱️ | **24h / 7d / 30d** — toggle between time periods with one tap |
| 🌙 | **Light & Dark Theme** — toggle in Settings, persists across launches |
| 🔒 | **Secure Token Storage** — your API token is stored locally on device, never shared |

---

## ✦ Getting Started

### 1. Fork the repo

Click **Fork** at the top right of this page to create your own copy of the repository. This is required — do not clone or copy the code directly.

### 2. Clone your fork

```bash
git clone https://github.com/YOUR_USERNAME/VercelStatsApp.git
cd VercelStatsApp
```

### 3. Open in Xcode

Open `Vercel Analytics.xcodeproj` in Xcode 15+. Set the deployment target to **iOS 16.0** or later.

### 4. Get a Vercel API Token

1. Go to [vercel.com/account/tokens](https://vercel.com/account/tokens)
2. Click **Create Token**
3. Set scope to **Full Account** and expiration to **No Expiration**
4. Copy the token

### 5. Run the app

Build and run on a simulator or real device. Paste your token into the login screen and connect.

---

## ✦ Tech Stack

| | |
|---|---|
| Language | Swift 5.9 |
| Framework | SwiftUI |
| Networking | URLSession + Vercel REST API |
| State | ObservableObject / @Published |
| Storage | UserDefaults + AppStorage |
| Min Target | iOS 16.0 |

---

## ✦ License

This project is licensed under the **MIT License with Attribution**.

Any use, modification, distribution, or incorporation of this code — in whole or in part — must include clear attribution to the original author:

> **Kayan Shah** · [github.com/KayanShah](https://github.com/KayanShah)

See the full license in Settings → License within the app.

---

<div align="center">

© 2026 Kayan Shah · All rights reserved.

</div>
