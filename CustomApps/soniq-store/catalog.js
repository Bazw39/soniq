// SONIQ Store catalog. Loaded via the custom app manifest ("subfiles").
// Extension entries mirror the real files shipped in the Extensions/ folder.
// Theme swatches mirror Themes/SONIQDefault/color.ini.

var SONIQ_STORE_CATALOG = {
	extensions: [
		{ name: "Bookmark", file: "bookmark.js", author: "khanhas", description: "Store pages, tracks, or tracks at a specific time to view or listen later." },
		{ name: "Full App Display", file: "fullAppDisplay.js", author: "khanhas", description: "Fancy artwork and track status display." },
		{ name: "Keyboard Shortcut", file: "keyboardShortcut.js", author: "khanhas, OhItsTom", description: "Extra keybinds for keyboard-driven navigation in the Spotify client." },
		{ name: "Loopy Loop", file: "loopyLoop.js", author: "khanhas", description: "Right-click the progress bar to set song markers and skip sections. Points persist per song." },
		{ name: "Popup Lyrics", file: "popupLyrics.js", author: "khanhas", description: "Pop the current track lyrics up in a dedicated view." },
		{ name: "Shuffle+", file: "shuffle+.js", author: "khanhas, Tetrax-10", description: "True shuffle with zero bias, injected into play buttons and context menus." },
		{ name: "Trashbin", file: "trashbin.js", author: "khanhas, OhItsTom", description: "Throw songs to the trashbin and never hear them again (auto-skip)." },
		{ name: "Christian Spotify", file: "autoSkipExplicit.js", author: "khanhas", description: "Auto skip explicit songs. Toggle in the Profile menu." },
		{ name: "Auto Skip Video", file: "autoSkipVideo.js", author: "khanhas", description: "Auto skip video tracks that cannot play in some regions." },
		{ name: "WebNowPlaying", file: "webnowplaying.js", author: "khanhas, keifufu", description: "Exposes media info and controls to WebNowPlaying (e.g. Rainmeter widgets)." },
		{ name: "SONIQ Store Button", file: "soniqStore.js", author: "SONIQ", description: "Star button in the top bar that opens the SONIQ Store. Enabled by default with the store." },
	],
	themes: [
		{
			name: "SONIQDefault",
			source: "bundled",
			description: "The default SONIQ theme. Ships with 6 color schemes.",
			schemes: [
				{ name: "green-dark", main: "2E2837", button: "00e089", text: "FFFFFF" },
				{ name: "nord-light", main: "ECEFF4", button: "88c0d0", text: "2E3440" },
				{ name: "nord-dark", main: "2e3440", button: "5E81AC", text: "D8DEE9" },
				{ name: "pink-white", main: "FAFAFA", button: "FE6F61", text: "000000" },
				{ name: "purple", main: "0A0E14", button: "6F3C89", text: "FFFFFF" },
				{ name: "dracula", main: "282a36", button: "ffb86c", text: "FFFFFF" },
			],
		},
		{
			name: "Sleek",
			source: "community",
			url: "https://github.com/spicetify/themes/tree/main/Sleek",
			description: "Community theme from the spicetify/themes collection. Download it into your Themes folder, then enable it below.",
		},
		{
			name: "Dribbbl",
			source: "community",
			url: "https://github.com/spicetify/themes/tree/main/Dribbbl",
			description: "Community theme from the spicetify/themes collection. Download it into your Themes folder, then enable it below.",
		},
		{
			name: "Nord",
			source: "community",
			url: "https://github.com/spicetify/themes/tree/main/Nord",
			description: "Community theme from the spicetify/themes collection. Download it into your Themes folder, then enable it below.",
		},
		{
			name: "Dracula",
			source: "community",
			url: "https://github.com/spicetify/themes/tree/main/Dracula",
			description: "Community theme from the spicetify/themes collection. Download it into your Themes folder, then enable it below.",
		},
	],
};
