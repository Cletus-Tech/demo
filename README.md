# Demo Trading Dashboard

A self-contained, dark-themed trading dashboard built with plain HTML, CSS and JavaScript. Prices are simulated in the browser and balances are practice funds only. No real money, no backend, no build step.

## Features

- Portfolio overview with balances, allocation bar and a "view all assets" toggle
- Deposit, withdraw and convert between assets
- Trade panel with leverage slider, take-profit / stop-loss and a "Set with AI" shortcut
- Live simulated price chart with moving-average indicator, trend and horizontal line drawing tools, and PNG export
- Open positions with liquidation logic, trade history and CSV export
- Notifications menu, language menu and a canned demo chat widget
- Balances persist in `localStorage`
- Responsive layout with a mobile slide-out navigation

## Getting started

Open `index.html` in a browser. Everything (markup, styles and scripts) is in that one file, so there is nothing to install or build.

## Project structure

```
.
├── index.html    # The whole app: markup, CSS and JavaScript
├── .nojekyll     # Tells GitHub Pages to serve files as-is
├── LICENSE
└── README.md
```

## Configuration

All branding and behavior is controlled by the `CONFIG` object at the top of the `<script>` block in `index.html`: brand name, user name, currency symbol, max leverage, tick speed, volatility, trade durations, sidebar navigation, categories and the asset list with starting prices.

Change `storageKey` per deployment so saved balances from different sites do not clash.

## Deploy with GitHub Pages

1. Push this repository to GitHub with `index.html` at the repository root.
2. Go to **Settings → Pages**.
3. Under **Build and deployment**, choose **Deploy from a branch**, select `main` and `/ (root)`, then save.
4. Your site will be live at `https://<your-username>.github.io/<repo-name>/`.

## Disclaimer

This project is a simulation for demonstration and learning. It does not connect to any market, exchange or payment provider, and nothing in it is financial advice.

## License

Released under the [MIT License](LICENSE).
