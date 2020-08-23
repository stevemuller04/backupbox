'use strict';

function uiReboot() {
	$.ajax({
		type: "POST",
		url: "/reboot",
		dataType: "application/json",
		data: {},
		success: function(r) {
			alert("The backup box is now restarting!");
		},
		error: function() {
			alert("Command failed");
		},
	});
}

function uiShutdown() {
	$.ajax({
		type: "POST",
		url: "/shutdown",
		dataType: "application/json",
		data: {},
		success: function(r) {
			alert("The backup box is now shutting down!");
		},
		error: function() {
			alert("Command failed");
		},
	});
}
function uiClean() {
	$.ajax({
		type: "POST",
		url: "/clean",
		dataType: "application/json",
		data: {},
		success: function(r) {
			alert("Cleaning was successful!");
		},
		error: function() {
			alert("Command failed");
		},
	});
}
function uiReset() {
	$.ajax({
		type: "POST",
		url: "/reset",
		dataType: "application/json",
		data: {},
		success: function(r) {
			alert("The backup box has been reset. All backups and snapshots have been deleted!");
		},
		error: function() {
			alert("Command failed");
		},
	});
}
