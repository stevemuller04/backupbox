'use strict';

function UI(modalSelector, backupbox) {
	var $modalSelector = $(modalSelector);

	function showModal(btnClass, title, text) {
		return new Promise(function(resolve, reject) {
			var wantAction = false;
			$modalSelector.off("hidden.bs.modal").on("hidden.bs.modal", function() {
				(wantAction ? resolve : reject)();
			});
			$modalSelector.find("[data-role=action]").off("click").on("click", function() {
				wantAction = true;
				$modalSelector.modal("hide");
			});

			$modalSelector.find("[data-role=title]").html(title);
			$modalSelector.find("[data-role=body]").html(text);
			$modalSelector.find("[data-role=action]").html(title).removeClass().addClass("btn " + btnClass);
			$modalSelector.modal("show");
		});
	}

	function ignore() {}
	function error(jqXHR, textStatus, errorThrown) {
		console.log("COMMAND ERROR", textStatus, errorThrown);
	}
	function ok(data, textStatus, jqXHR) {
		if (data.error)
			console.log("COMMAND ERROR", textStatus, data.error);
		else
			$("body").html('<div class="d-flex flex-column align-items-center mt-5"><svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 24 24"><path d="M12 2c5.514 0 10 4.486 10 10s-4.486 10-10 10-10-4.486-10-10 4.486-10 10-10zm0-2c-6.627 0-12 5.373-12 12s5.373 12 12 12 12-5.373 12-12-5.373-12-12-12zm-1.959 17l-4.5-4.319 1.395-1.435 3.08 2.937 7.021-7.183 1.422 1.409-8.418 8.591z"/></svg><h1 class="display-4 mt-4">OK</h1></div>');
	}

	this.reboot = function() {
		var modal = showModal("btn-secondary", "Reboot", "Restarts the backup box. This page might be unavailable for a moment.");
		modal.then(function() { backupbox.reboot().then(ok, error); }, ignore);
	};
	this.shutdown = function() {
		var modal = showModal("btn-secondary", "Shutdown", "Turns off the backup box. <strong>Unplug and replug the device to turn it back on.</strong>");
		modal.then(function() { backupbox.shutdown().then(ok, error); }, ignore);
	};
	this.clean = function() {
		var modal = showModal("btn-danger", "Clean", "Cleans all ransomware protection snapshots. The may free up a considerable amount of disk space. However, make sure that the current back-up is not compromised (‟encrypted”) before you proceed (it will delete all safety copies).");
		modal.then(function() { backupbox.clean().then(ok, error); }, ignore);
	};
	this.reset = function() {
		var modal = showModal("btn-danger", "Reset", "Completely resets the backup box. <strong class=\"text-uppercase\">This will erase all back-ups and all ransomware protection snapshots.</strong> Only use this after you plugged in a new hard drive.");
		modal.then(function() { backupbox.reset().then(ok, error); }, ignore);
	};
}
