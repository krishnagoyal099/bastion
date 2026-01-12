/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'swiss-black': '#050505',
        'swiss-white': '#F2F2F2',
        'swiss-accent': '#CCFF00', // Acid Green
      },
      fontFamily: {
        swiss: ['Inter', 'Helvetica Neue', 'Helvetica', 'Arial', 'sans-serif'],
      },
      fontSize: {
        'massive': ['12vw', { lineHeight: '0.85', letterSpacing: '-0.04em' }],
      },
      spacing: {
        '128': '32rem',
      }
    },
  },
  plugins: [],
}
