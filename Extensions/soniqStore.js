// NAME: SONIQ Store Button
// AUTHOR: SONIQ (NOX / VANTA / blasphemyw)
// DESCRIPTION: Adds a star button to the top bar that opens the SONIQ Store.

/// <reference path="../globals.d.ts" />

(function SoniqStoreButton() {
	const STORE_ROUTE = "/soniq-store";
	const STAR_ICON =
		'<svg height="16" width="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.5l2.92 6.36 6.58.72-4.9 4.55 1.35 6.47L12 17.1l-5.95 3.5 1.35-6.47-4.9-4.55 6.58-.72L12 2.5z"/></svg>';

	function openStore() {
		try {
			Spicetify.Platform.History.push(STORE_ROUTE);
		} catch (err) {
			console.error("[soniq-store] Could not open the store", err);
			Spicetify.showNotification("Could not open SONIQ Store. Enable the soniq-store custom app first.", true);
		}
	}

	function init(retries = 40) {
		if (Spicetify.Topbar && Spicetify.Platform?.History) {
			new Spicetify.Topbar.Button("SONIQ Store", STAR_ICON, openStore);
			return;
		}
		if (retries > 0) setTimeout(() => init(retries - 1), 300);
	}

	init();
})();
