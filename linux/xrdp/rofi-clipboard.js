tab(config("clipboard_tab"));

var items = [];
var labels = [];

for (var row = 0; row < count(); ++row) {
    var item = getItem(row);
    var images = Object.keys(item).filter(function (format) {
        return format.indexOf("image/") === 0;
    });
    var label = images.length
        ? "[Image] " + images.join(", ")
        : str(item[mimeText] || "").replace(/[\x00-\x1f\x7f]+/g, " ").slice(0, 160);
    items.push(item);
    labels.push((row + 1) + ". " + (label || "[Data]"));
}

if (!items.length) {
    popup("Clipboard history", "No clips yet. Copy some text or an image first.");
    abort();
}

var result = execute(
    "rofi", "-dmenu", "-i", "-p", "Clipboard",
    "-format", "i", "-no-custom", null, labels.join("\n")
);

if (result && result.exit_code === 1) {
    abort();
}
if (!result || result.exit_code !== 0) {
    popup("Clipboard history", "Rofi failed to open the clipboard menu.");
    throw new Error(result ? str(result.stderr) : "Rofi did not return a result.");
}

var selected = str(result.stdout).trim();
if (!/^\d+$/.test(selected) || Number(selected) >= items.length) {
    popup("Clipboard history", "Rofi returned an invalid clipboard selection.");
    throw new Error("Invalid clipboard selection: " + selected);
}

// Retain the selected clip even if new clipboard events reorder the history.
copy(items[Number(selected)]);
