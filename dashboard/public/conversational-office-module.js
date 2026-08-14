(function () {
"use strict";

function esc(v) {
    return String(v == null ? "" : v)
        .replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")
        .replace(/"/g,"&quot;").replace(/'/g,"&#039;");
}

function metric(label, value) {
    return '<div class="co-card"><div class="co-value">' + esc(value) +
        '</div><div class="co-label">' + esc(label) + '</div></div>';
}

async function loadConversationalOffice() {
    var host = document.getElementById("conversational-office-module");
    if (!host) return;

    try {
        var r = await fetch("/data/conversational-office.json?ts=" + Date.now(), { cache: "no-store" });
        if (!r.ok) throw new Error("HTTP " + r.status);

        var d = await r.json();
        var m = d.metrics || {};
        var sessions = Array.isArray(d.recent_sessions) ? d.recent_sessions : [];

        var recent = sessions.length ? sessions.map(function (s) {
            return '<div class="co-session">' +
                '<div><strong>' + esc(s.title || s.session_id) + '</strong>' +
                '<span>' + esc(s.session_id) + '</span></div>' +
                '<div class="co-session-meta">' +
                esc(s.message_count) + ' messages · ' + esc(s.turn_count) + ' turns' +
                '</div></div>';
        }).join("") : '<div class="co-empty">No conversations yet.</div>';

        host.innerHTML =
            '<section class="co-panel">' +
                '<div class="co-head">' +
                    '<div><div class="co-kicker">AI OFFICE v2.3</div><h2>Conversational AI Office</h2></div>' +
                    '<span class="co-status">' + esc(d.status) + '</span>' +
                '</div>' +
                '<div class="co-grid">' +
                    metric("Sessions", m.sessions || 0) +
                    metric("Active", m.active_sessions || 0) +
                    metric("Messages", m.messages || 0) +
                    metric("Turns", m.turns || 0) +
                    metric("Completed", m.completed_turns || 0) +
                    metric("Failed", m.failed_turns || 0) +
                '</div>' +
                '<div class="co-subtitle">Recent Conversations</div>' +
                '<div class="co-sessions">' + recent + '</div>' +
            '</section>';
    } catch (e) {
        host.innerHTML = '<section class="co-panel co-error"><h2>Conversational AI Office</h2><div>' +
            esc(e.message) + '</div></section>';
    }
}

if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", loadConversationalOffice);
} else {
    loadConversationalOffice();
}
})();