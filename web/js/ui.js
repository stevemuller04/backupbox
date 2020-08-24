'use strict';

function uiReboot() {
	$("body").text("Rebooting...");
	$.ajax({
		type: "POST",
		url: "/reboot",
		dataType: "application/json",
		data: {},
		success: function(r) {
			$("body").text("The backup box is now restarting!");
		},
		error: function() {
			$("body").text("Command failed");
		},
	});
}

function uiShutdown() {
	$("body").text("Shutting down...");
	$.ajax({
		type: "POST",
		url: "/shutdown",
		dataType: "application/json",
		data: {},
		success: function(r) {
			$("body").text("The backup box is now shutting down!");
		},
		error: function() {
			$("body").text("Command failed");
		},
	});
}
function uiClean() {
	if (prompt('This is a dangerous action! Confirm to proceed by typing "confirm clean"', '') !== 'confirm clean') {
		alert('Cancelled');
		return;
	}
	$("body").text("Cleaning...");
	$.ajax({
		type: "POST",
		url: "/clean",
		dataType: "application/json",
		data: {},
		success: function(r) {
			$("body").text("Cleaning was successful!");
		},
		error: function() {
			$("body").text("Command failed");
		},
	});
}
function uiReset() {
	if (prompt('This is a dangerous action! Confirm to proceed by typing "confirm reset"', '') !== 'confirm reset') {
		alert('Cancelled');
		return;
	}
	$("body").text("Resetting...");
	$.ajax({
		type: "POST",
		url: "/reset",
		dataType: "application/json",
		data: {},
		success: function(r) {
			$("body").text("The backup box has been reset. All backups and snapshots have been deleted!");
		},
		error: function() {
			$("body").text("Command failed");
		},
	});
}
