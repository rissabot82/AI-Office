(function () {
    "use strict";

    async function loadOperationsIntegrations() {
        const host =
            document.querySelector("[data-ai-office-operations-integrations]") ||
            document.getElementById("operations-integrations-module");

        if (!host) return;

        try {
            const response = await fetch("/data/operations-integrations.json?ts=" + Date.now(), {
                cache: "no-store"
            });

            if (!response.ok) {
                throw new Error("HTTP " + response.status);
            }

            const data = await response.json();
            const m = data.metrics || {};

            const cards = [
                ["Intake", m.intake || 0],
                ["Discord Intake", m.discord_intake || 0],
                ["Dispatches", m.dispatch_total || 0],
                ["Queued", m.dispatch_queued || 0],
                ["Integrations", m.integrations || 0],
                ["Healthy", m.integrations_healthy || 0],
                ["Jobs", m.jobs || 0],
                ["Job Runs", m.job_runs || 0]
            ];

            const health = (data.integration_health || []).map(function (item) {
                return '<tr><td>' + esc(item.integration_name) + '</td><td><span class="ops-status ops-' +
                    esc(item.status) + '">' + esc(item.status) + '</span></td><td>' +
                    esc(item.details) + '</td></tr>';
            }).join("");

            const dispatch = (data.recent_dispatch || []).map(function (item) {
                return '<tr><td>' + esc(item.title) + '</td><td>' +
                    esc(item.destination) + '</td><td><span class="ops-status ops-' +
                    esc(item.status) + '">' + esc(item.status) + '</span></td></tr>';
            }).join("");

            host.innerHTML =
                '<section class="ops-module">' +
                    '<div class="ops-header">' +
                        '<div><div class="ops-eyebrow">AI OFFICE v1.9</div>' +
                        '<h2>Operations & Integrations</h2></div>' +
                        '<span class="ops-overall ops-' + esc(data.status) + '">' + esc(data.status) + '</span>' +
                    '</div>' +
                    '<div class="ops-grid">' +
                        cards.map(function (card) {
                            return '<div class="ops-card"><div class="ops-value">' +
                                esc(card[1]) + '</div><div class="ops-label">' + esc(card[0]) + '</div></div>';
                        }).join("") +
                    '</div>' +
                    '<div class="ops-panels">' +
                        '<div class="ops-panel"><h3>Integration Health</h3>' +
                            '<table><thead><tr><th>Integration</th><th>Status</th><th>Details</th></tr></thead>' +
                            '<tbody>' + (health || '<tr><td colspan="3">No integration health records yet.</td></tr>') +
                            '</tbody></table></div>' +
                        '<div class="ops-panel"><h3>Recent Dispatch</h3>' +
                            '<table><thead><tr><th>Task</th><th>Destination</th><th>Status</th></tr></thead>' +
                            '<tbody>' + (dispatch || '<tr><td colspan="3">No operational dispatches yet.</td></tr>') +
                            '</tbody></table></div>' +
                    '</div>' +
                '</section>';
        } catch (error) {
            host.innerHTML =
                '<section class="ops-module"><h2>Operations & Integrations</h2>' +
                '<p class="ops-error">Dashboard data unavailable: ' + esc(error.message) + '</p></section>';
        }
    }

    function esc(value) {
        return String(value === undefined || value === null ? "" : value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", loadOperationsIntegrations);
    } else {
        loadOperationsIntegrations();
    }

    window.AIOfficeOperationsIntegrations = {
        refresh: loadOperationsIntegrations
    };
})();