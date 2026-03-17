# GuriboyCodes Claude Variant — Quick Start Guide

## 30-Second Setup

```bash
# Navigate to project
cd /sessions/vibrant-determined-babbage/guriboycodes-claude-variant

# Install dependencies (already done, but for reference)
npm install

# Start development server
npm run dev

# Open browser to http://localhost:3000
```

## Build for Production

```bash
npm run build
# Output: dist/ directory ready to deploy
```

## Deploy Immediately

### Option 1: Vercel (Easiest)
1. Push code to GitHub
2. Go to vercel.com/new
3. Import your GitHub repo
4. Deploy in 1 click!

### Option 2: Netlify
1. Run `npm run build`
2. Drag `dist` folder to netlify.com
3. Done!

## Key Files to Customize

| File | What to Edit |
|------|-------------|
| `src/components/Hero.jsx` | Personal info, social links |
| `src/data/projects.js` | Add/edit projects |
| `src/data/hackathons.js` | Update hackathons |
| `src/components/CareerJourney.jsx` | Career positions |
| `tailwind.config.js` | Brand colors |

## Folder Structure

```
guriboycodes-claude-variant/
├── src/                    # React source code
│   ├── components/        # 9 page sections
│   ├── data/             # Projects & hackathons
│   ├── utils/            # Helper functions
│   └── App.jsx           # Main component
├── public/               # Static files
├── dist/                 # Production build (generated)
├── package.json          # Dependencies
├── vite.config.js        # Build config
├── tailwind.config.js    # Theme colors
└── README.md             # Full docs
```

## Available Scripts

```bash
npm run dev          # Start dev server
npm run build        # Build for production
npm run preview      # Preview production build
npm run lint         # Run ESLint
npm update           # Update dependencies
npm audit            # Security audit
```

## Color Scheme (Claude Brand)

```css
Primary:    #D97757 (Warm terracotta)
Secondary:  #E8B4A0 (Light warm)
Accent:     #C4704A (Deep terracotta)
Background: #0D0A08 (Warm dark)
Text:       #F5EDE8 (Warm white)
```

Change in `tailwind.config.js` → `theme.extend.colors.claude`

## Performance Stats

✅ 304 KB total size
✅ 91 KB gzipped  
✅ 87 KB JS (gzipped)
✅ 3.9 KB CSS (gzipped)
✅ Sub-second load time

## Features Included

✓ Responsive design
✓ Dark mode toggle
✓ Smooth animations
✓ Lazy-loaded images
✓ Mobile menu
✓ Project filtering
✓ Video playback
✓ Accessible HTML
✓ SEO optimized

## Troubleshooting

**Port 3000 already in use?**
```bash
npm run dev -- --port 3001
```

**Build fails?**
```bash
rm -rf node_modules dist
npm install
npm run build
```

**Images not loading?**
- Check CDN URLs in `src/data/projects.js`
- Verify GitHub repo is public
- Replace with your own image URLs if needed

## Documentation

- **README.md** — Full feature documentation
- **DEPLOYMENT.md** — Detailed deployment guide
- **PROJECT_SUMMARY.txt** — Complete project overview

## Need Help?

1. Check README.md
2. Review DEPLOYMENT.md  
3. Read component comments
4. Check tailwind.config.js for configuration

## Next Steps

1. ✅ Run locally: `npm run dev`
2. ✅ Customize content (optional)
3. ✅ Build: `npm run build`
4. ✅ Deploy to Vercel/Netlify
5. ✅ Add custom domain (optional)

---

**That's it! Your portfolio is ready to deploy.** 🚀

Built with Claude • Vite • React • Tailwind CSS
