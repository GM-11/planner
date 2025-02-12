/** @type {import('tailwindcss').Config} */
module.exports = {
  // NOTE: Update this to include the paths to all of your component files.
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./components/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        primary: {
          50: "#f8fafc",
          100: "#f1f5f9",
          200: "#e2e8f0",
          300: "#cbd5e1",
          400: "#94a3b8",
          500: "#64748b", // Main brand color
          600: "#475569",
          700: "#334155",
          800: "#1e293b",
          900: "#0f172a",
        },
        secondary: {
          DEFAULT: "#3b82f6", // Blue
        },
        accent: {
          DEFAULT: "#10b981", // Emerald
        },
      },
      fontFamily: {
        poppins_100: ["Poppins_100Thin"],
        poppins_200: ["Poppins_200ExtraLight"],
        poppins_300: ["Poppins_300Light"],
        poppins_400: ["Poppins_400Regular"],
        poppins_500: ["Poppins_500Medium"],
        poppins_600: ["Poppins_600SemiBold"],
        poppins_700: ["Poppins_700Bold"],
        poppins_800: ["Poppins_800ExtraBold"],
        poppins_900: ["Poppins_900Black"],
        poppins_100_italic: ["Poppins_100Thin_Italic"],
        poppins_200_italic: ["Poppins_200ExtraLight_Italic"],
        poppins_300_italic: ["Poppins_300Light_Italic"],
        poppins_400_italic: ["Poppins_400Regular_Italic"],
        poppins_500_italic: ["Poppins_500Medium_Italic"],
        poppins_600_italic: ["Poppins_600SemiBold_Italic"],
        poppins_700_italic: ["Poppins_700Bold_Italic"],
        poppins_800_italic: ["Poppins_800ExtraBold_Italic"],
        poppins_900_italic: ["Poppins_900Black_Italic"],
      },
    },
  },
  plugins: [],
};
