# GuriboyCodes — Claude Variant Portfolio

A stunning, production-ready portfolio website for GuriboyCodes (Gurinder Singh) built with Vite, React, and Tailwind CSS. Features Claude's warm, sophisticated brand identity.

## Features

✨ **Modern Design**
- Claude brand colors: Warm terracotta (#D97757) primary with sophisticated dark backgrounds
- Responsive mobile-first design
- Smooth animations with Framer Motion
- Dark mode optimization

🚀 **Performance**
- Vite for ultra-fast builds
- Lazy-loaded images
- Optimized bundle size
- Production-ready build configuration

📱 **Fully Responsive**
- Desktop, tablet, and mobile optimized
- Smooth scroll navigation
- Touch-friendly navigation

## Sections

1. **Navigation** — Fixed header with smooth scrolling and dark mode toggle
2. **Hero** — Engaging introduction with CTA buttons and social links
3. **Stats** — Animated counters showcasing impact metrics
4. **Scrolling Ticker** — Rotating highlights and achievements
5. **Career Journey** — Clickable timeline with expandable details
6. **Philosophy** — Engineering pillars and values
7. **Projects** — Filterable project grid with categories
8. **Hackathons** — Gallery with video playback capability
9. **Contact** — Social links and call-to-action footer

## Getting Started

### Prerequisites
- Node.js 16+ and npm/yarn

### Installation

```bash
cd guriboycodes-claude-variant
npm install
```

### Development

```bash
npm run dev
```

Starts the development server at `http://localhost:3000`

### Build

```bash
npm run build
```

Generates optimized production build in the `dist` directory.

### Preview

```bash
npm run preview
```

Preview the production build locally.

## Deployment

### Vercel (Recommended)

This project is configured for Vercel deployment:

1. Push to GitHub
2. Connect repository to Vercel
3. Vercel automatically detects Vite configuration
4. Deploys on push

The `vercel.json` file includes:
- Build command: `npm run build`
- Output directory: `dist`
- Dev command: `npm run dev`

### Other Platforms

**Netlify:**
```bash
npm run build
```
Set publish directory to `dist`

**GitHub Pages:**
Update `vite.config.js` with `base: '/repository-name/'`

## Project Structure

```
guriboycodes-claude-variant/
├── src/
│   ├── components/          # React components
│   ├── data/               # Project & experience data
│   ├── utils/              # Utility functions
│   ├── App.jsx             # Main app component
│   ├── main.jsx            # Entry point
│   └── index.css           # Global styles
├── public/                 # Static assets
├── index.html              # HTML template
├── vite.config.js          # Vite configuration
├── tailwind.config.js      # Tailwind configuration
├── postcss.config.js       # PostCSS configuration
├── vercel.json             # Vercel deployment config
└── package.json            # Dependencies & scripts
```

## Technologies

- **React 18** — UI library
- **Vite 4** — Build tool & dev server
- **Tailwind CSS 3** — Utility-first styling
- **Framer Motion 10** — Animation library
- **Lucide React** — Icon library
- **PostCSS & Autoprefixer** — CSS processing

## Claude Brand Colors

- **Primary**: `#D97757` (Warm terracotta)
- **Secondary**: `#E8B4A0` (Lighter warm)
- **Accent**: `#C4704A` (Deeper terracotta)
- **Dark Background**: `#0D0A08` (Warm dark)
- **Card Background**: `rgba(25,18,12,0.8)`
- **Text**: `#F5EDE8` (Warm white)
- **Text Dim**: `#C4B5AB` (Muted text)

## Configuration

### Tailwind Configuration

Color system is defined in `tailwind.config.js`:
```javascript
colors: {
  claude: {
    primary: '#D97757',
    secondary: '#E8B4A0',
    accent: '#C4704A',
    dark: '#0D0A08',
    // ... more colors
  }
}
```

### Image CDN

Images are hosted on GitHub:
```
https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio/claude-portfolio/public
```

## Customization

### Update Personal Information

Edit `src/components/Hero.jsx`:
```jsx
// Update social links
const socialLinks = [
  { icon: Github, href: 'YOUR_GITHUB_URL', label: 'GitHub' },
  // ...
]
```

### Add New Projects

Edit `src/data/projects.js`:
```javascript
export const projects = [
  {
    id: 1,
    title: 'Project Name',
    category: 'Category',
    description: 'Description',
    image: 'IMAGE_URL',
    technologies: ['Tech1', 'Tech2'],
    links: { github: '#', demo: '#' },
  },
  // ...
]
```

### Modify Colors

Update `tailwind.config.js` to change the color scheme:
```javascript
colors: {
  claude: {
    primary: '#YOUR_COLOR',
    // ...
  }
}
```

## Performance Optimization

- Images use lazy loading
- Smooth scroll behavior
- Optimized animations with Framer Motion
- Minimal CSS with Tailwind utilities
- Code splitting with Vite

## Browser Support

- Chrome/Edge 88+
- Firefox 78+
- Safari 14+
- Opera 74+

## License

This project is open source and available under the MIT License.

## Author

**Gurinder Singh** (GuriboyCodes)
- GitHub: [Ripnrip](https://github.com/Ripnrip)
- LinkedIn: [Gurinder Singh](https://www.linkedin.com/in/gurinder-singh-a30a1a48)
- Email: [gurinder@binary-bros.com](mailto:gurinder@binary-bros.com)

## Support

For issues, questions, or suggestions, please open an issue on GitHub or contact directly.

---

Built with Claude ✨
