'use strict';

function BackupBox() {
	this.reboot = function() {
		return $.ajax({
			type: "POST",
			url: "/reboot",
			dataType: "json",
			data: {},
		});
	};

	this.shutdown = function() {
		return $.ajax({
			type: "POST",
			url: "/shutdown",
			dataType: "json",
			data: {},
		});
	};

	this.clean = function() {
		return new Promise(function(resolve, reject) {
			if (prompt('This is a dangerous action! Confirm to proceed by typing "confirm clean"', '') !== 'confirm clean') {
				reject("cancelled by user");
			} else {
				$.ajax({
					type: "POST",
					url: "/clean",
					dataType: "json",
					data: {},
				}).then(resolve, reject);
			}
		});
	};

	this.reset = function() {
		return new Promise(function(resolve, reject) {
			if (prompt('This is a dangerous action! Confirm to proceed by typing "confirm reset"', '') !== 'confirm reset') {
				reject("cancelled by user");
			} else {
				$.ajax({
					type: "POST",
					url: "/reset",
					dataType: "json",
					data: {},
				}).then(resolve, reject);
			}
		});
	};
}
