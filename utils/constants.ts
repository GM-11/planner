export const importanceLevels = [
  "less-important",
  "mildly-important",
  "important",
  "very-important",
];

export const importanceColors = ["#22c55e", "#eab308", "#f97316", "#ef4444"];

export function toTitleCase(str: string): string {
  return str
    .toLowerCase()
    .split(" ")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}
