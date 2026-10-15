// SONIQ Store custom app: browse bundled extensions and themes,
// with one-click terminal commands to enable them.
// Catalog data lives in catalog.js (loaded via manifest "subfiles").

/// <reference path="../../globals.d.ts" />

const { React: react, React: { useState } } = Spicetify;

// Define a function called "render" to specify app entry point
// This function will be used to mount app to main view.
function render() {
	return react.createElement(StoreApp);
}

function copyText(text, label) {
	const done = () => Spicetify.showNotification((label || "Copied") + " — paste it in a terminal, then run: soniq apply");
	try {
		const result = Spicetify.Platform.ClipboardAPI.copy(text);
		if (result && typeof result.then === "function") result.then(done).catch(() => fallbackCopy(text, done));
		else done();
	} catch {
		fallbackCopy(text, done);
	}
}

function fallbackCopy(text, done) {
	try {
		const area = document.createElement("textarea");
		area.value = text;
		document.body.appendChild(area);
		area.select();
		document.execCommand("copy");
		document.body.removeChild(area);
		done();
	} catch {
		Spicetify.showNotification("Copy failed. Run this in a terminal: " + text, true);
	}
}

const shell = {
	page: { padding: "24px 32px 64px", color: "var(--spice-text)" },
	header: { display: "flex", alignItems: "center", gap: "12px", marginBottom: "4px" },
	title: { fontSize: "2rem", fontWeight: "800", margin: 0 },
	sub: { color: "var(--spice-subtext)", margin: "0 0 20px" },
	tabs: { display: "flex", gap: "8px", marginBottom: "24px" },
	grid: { display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: "16px" },
	card: {
		background: "var(--spice-card)",
		borderRadius: "12px",
		padding: "18px",
		display: "flex",
		flexDirection: "column",
		gap: "8px",
	},
	name: { fontSize: "1.05rem", fontWeight: "700", margin: 0 },
	meta: { fontSize: "0.8rem", color: "var(--spice-subtext)" },
	desc: { fontSize: "0.9rem", color: "var(--spice-subtext)", flex: 1 },
	swatches: { display: "flex", gap: "6px", flexWrap: "wrap" },
};

function TabButton({ id, label, active, onSelect }) {
	return react.createElement(
		"button",
		{
			onClick: () => onSelect(id),
			style: {
				padding: "8px 20px",
				borderRadius: "999px",
				border: "none",
				cursor: "pointer",
				fontWeight: "700",
				background: active ? "var(--spice-button)" : "var(--spice-highlight)",
				color: active ? "#000" : "var(--spice-text)",
			},
		},
		label
	);
}

function ActionButton({ label, onClick }) {
	return react.createElement(
		"button",
		{
			onClick,
			style: {
				padding: "8px 14px",
				borderRadius: "8px",
				border: "1px solid var(--spice-button)",
				background: "transparent",
				color: "var(--spice-text)",
				cursor: "pointer",
				fontWeight: "700",
				alignSelf: "flex-start",
			},
		},
		label
	);
}

function Swatch({ hex, title, onClick }) {
	return react.createElement("button", {
		title,
		onClick,
		style: {
			width: "34px",
			height: "34px",
			borderRadius: "50%",
			border: "2px solid var(--spice-subtext)",
			background: "#" + hex,
			cursor: "pointer",
		},
	});
}

function ExtensionCard({ item }) {
	return react.createElement(
		"div",
		{ style: shell.card },
		react.createElement("p", { style: shell.name }, item.name),
		react.createElement("p", { style: shell.meta }, "by " + item.author + " · " + item.file),
		react.createElement("p", { style: shell.desc }, item.description),
		react.createElement(ActionButton, {
			label: "Copy enable command",
			onClick: () => copyText("soniq config extensions " + item.file, "Enable command copied"),
		})
	);
}

function ThemeCard({ item }) {
	const pickScheme = (scheme) =>
		copyText("soniq config current_theme " + item.name + " color_scheme " + scheme.name + "\nsoniq apply", "Theme command copied");
	const children = [
		react.createElement("p", { style: shell.name, key: "n" }, item.name),
		react.createElement(
			"p",
			{ style: shell.meta, key: "m" },
			item.source === "bundled" ? "bundled with SONIQ" : "community theme"
		),
		react.createElement("p", { style: shell.desc, key: "d" }, item.description),
	];
	if (item.schemes) {
		children.push(
			react.createElement(
				"div",
				{ style: shell.swatches, key: "s" },
				item.schemes.map((scheme) =>
					react.createElement(Swatch, {
						key: scheme.name,
						hex: scheme.button,
						title: scheme.name + " — click to copy enable command",
						onClick: () => pickScheme(scheme),
					})
				)
			),
			react.createElement(ActionButton, {
				key: "b",
				label: "Copy enable command",
				onClick: () => copyText("soniq config current_theme " + item.name + "\nsoniq apply", "Theme command copied"),
			})
		);
	} else {
		children.push(
			react.createElement(ActionButton, {
				key: "u",
				label: "Copy download link",
				onClick: () => copyText(item.url, "Download link copied"),
			}),
			react.createElement(ActionButton, {
				key: "b",
				label: "Copy enable command",
				onClick: () =>
					copyText("soniq config current_theme " + item.name + "\nsoniq apply", "Theme command copied (after download)"),
			})
		);
	}
	return react.createElement("div", { style: shell.card }, children);
}

function AboutTab() {
	return react.createElement(
		"div",
		{ style: { maxWidth: "640px", lineHeight: "1.6", color: "var(--spice-subtext)" } },
		react.createElement("p", null, "The SONIQ Store lists extensions and themes that ship with or work with SONIQ."),
		react.createElement(
			"p",
			null,
			"Extensions and themes are applied by the SONIQ command line, so each card copies the exact terminal command. Paste it in a terminal, run it, then run ",
			react.createElement("code", null, "soniq apply"),
			" and restart Spotify when asked."
		),
		react.createElement(
			"p",
			null,
			"Tip: enable this store permanently with ",
			react.createElement("code", null, "soniq config custom_apps soniq-store"),
			" followed by ",
			react.createElement("code", null, "soniq apply"),
			"."
		)
	);
}

function StoreApp() {
	const [tab, setTab] = useState("extensions");
	const catalog = window.SONIQ_STORE_CATALOG || { extensions: [], themes: [] };

	return react.createElement(
		"section",
		{ style: shell.page },
		react.createElement(
			"div",
			{ style: shell.header },
			react.createElement("h1", { style: shell.title }, "★ SONIQ Store")
		),
		react.createElement("p", { style: shell.sub }, "Extensions, themes and color schemes for your Spotify client."),
		react.createElement(
			"div",
			{ style: shell.tabs },
			react.createElement(TabButton, { id: "extensions", label: "Extensions", active: tab === "extensions", onSelect: setTab }),
			react.createElement(TabButton, { id: "themes", label: "Themes", active: tab === "themes", onSelect: setTab }),
			react.createElement(TabButton, { id: "about", label: "About", active: tab === "about", onSelect: setTab })
		),
		tab === "extensions"
			? react.createElement(
					"div",
					{ style: shell.grid },
					catalog.extensions.map((item) => react.createElement(ExtensionCard, { key: item.file, item }))
				)
			: null,
		tab === "themes"
			? react.createElement(
					"div",
					{ style: shell.grid },
					catalog.themes.map((item) => react.createElement(ThemeCard, { key: item.name, item }))
				)
			: null,
		tab === "about" ? react.createElement(AboutTab) : null
	);
}
