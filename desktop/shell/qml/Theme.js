// SPDX-License-Identifier: MIT
.pragma library

function colors(theme) {
    if (theme === "midnight") return {
        text: "#F9EDF6", muted: "#D0BDD1", ink: "#261C34",
        panel: "#E42A2138", sheet: "#F02B223B", card: "#523E5B",
        border: "#9F789C", accent: "#F1A8C9", accentText: "#281C36",
        glow: "#B25893", hover: "#6F4C72", shadow: "#A8000714"
    };
    if (theme === "celestial") return {
        text: "#EEF7FF", muted: "#C2D6E9", ink: "#162648",
        panel: "#DC1A2A4F", sheet: "#F01D3157", card: "#334A70",
        border: "#739AC1", accent: "#9BE7ED", accentText: "#16314B",
        glow: "#78C7ED", hover: "#435F88", shadow: "#B0001128"
    };
    return {
        text: "#47354D", muted: "#766078", ink: "#392F4A",
        panel: "#EEFFF8FC", sheet: "#F8FFF9FC", card: "#F9E6F0",
        border: "#D9AFC5", accent: "#B85E87", accentText: "#FFFAFD",
        glow: "#F2A7C9", hover: "#F4D9E7", shadow: "#5F76536F"
    };
}
