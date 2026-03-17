/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx}",
  ],
  theme: {
    extend: {
      colors: {
        claude: {
          primary: '#D97757',
          secondary: '#E8B4A0',
          accent: '#C4704A',
          dark: '#0D0A08',
          card: 'rgba(25,18,12,0.8)',
          text: '#F5EDE8',
          text_dim: '#C4B5AB',
        }
      },
      backgroundColor: {
        'claude-dark': '#0D0A08',
      }
    }
  },
  plugins: [],
}
