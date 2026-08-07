(function () {
    "use strict";

    function escapeHtml(value) {
        return String(value == null ? "" : value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function metric(label, value) {
        return '<div class="ae-metric">' +
            '<div class="ae-metric-value">' + escapeHtml(value) + '</div>' +
            '<div class="ae-metric-label">' + escapeHtml(label) + '</div>' +
            '</div>';
    }

    async function loadEnterprise() {
        var host = document.getElementById("autonomous-enterprise-module");
        if (!host) return;

        try {
            var response = await fetch("/data/autonomous-enterprise.json?ts=" + Date.now(), {
                cache: "no-store"
            });

            if (!response.ok) {
                throw new Error("HTTP " + response.status);
            }

            var data = await response.json();
            var m = data.metrics || {};
            var runs = Array.isArray(data.recent_runs) ? data.recent_runs : [];

            var runHtml = runs.length
                ? runs.map(function (run) {
                    return '<div class="ae-run">' +
                        '<div><strong>' + escapeHtml(run.work_title || run.enterprise_run_id) + '</strong></div>' +
                        '<div class="ae-run-meta">' +
                            escapeHtml(run.status) + ' · ' +
                            escapeHtml(run.completed_steps) + ' completed · ' +
                            escapeHtml(run.failed_steps) + ' failed' +
                        '</div>' +
                    '</div>';
                }).join("")
                : '<div class="ae-empty">No enterprise runs recorded yet.</div>';

            host.innerHTML =
                '<section class="ae-panel">' +
                    '<div class="ae-header">' +
                        '<div>' +
                            '<div class="ae-kicker">AI OFFICE v2.0</div>' +
                            '<h2>Autonomous AI Enterprise</h2>' +
                        '</div>' +
                        '<div class="ae-status">' + escapeHtml(data.status || "ready") + '</div>' +
                    '</div>' +
                    '<div class="ae-grid">' +
                        metric("Work Items", m.work_items || 0) +
                        metric("Active Work", m.active_work_items || 0) +
                        metric("Plans", m.plans || 0) +
                        metric("Departments", m.departments || 0) +
                        metric("Capabilities", m.capabilities || 0) +
                        metric("Runs", m.runs || 0) +
                        metric("Completed Runs", m.completed_runs || 0) +
                        metric("Failed Runs", m.failed_runs || 0) +
                    '</div>' +
                    '<div class="ae-subtitle">Recent Enterprise Runs</div>' +
                    '<div class="ae-runs">' + runHtml + '</div>' +
                '</section>';
        }
        catch (error) {
            host.innerHTML =
                '<section class="ae-panel ae-error">' +
                    '<h2>Autonomous AI Enterprise</h2>' +
                    '<div>Dashboard data unavailable: ' + escapeHtml(error.message) + '</div>' +
                '</section>';
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", loadEnterprise);
    } else {
        loadEnterprise();
    }
})();
