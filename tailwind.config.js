/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx}",
  ],
  theme: {
    extend: {
      colors: {
        ink: '#141414',
        paper: '#F3EFE7',
        brutal: {
          orange: '#D97757',
          yellow: '#FFC700',
          lilac: '#C4B0F3',
          mint: '#A6E3C4',
          pink: '#F5B8C8',
        },
      },
      fontFamily: {
        display: ['"Archivo Black"', 'Impact', 'Haettenschweiler', 'sans-serif'],
        sans: ['"Space Grotesk"', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        mono: ['"Space Mono"', 'ui-monospace', 'monospace'],
      },
      boxShadow: {
        'brutal-sm': '3px 3px 0 0 #141414',
        brutal: '5px 5px 0 0 #141414',
        'brutal-lg': '8px 8px 0 0 #141414',
        'brutal-xl': '12px 12px 0 0 #141414',
      },
      borderWidth: {
        3: '3px',
      },
    }
  },
  plugins: [],
}
