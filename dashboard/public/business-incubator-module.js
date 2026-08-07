(function () {
    "use strict";

    const SNAPSHOT_URL = "/runtime/business-incubator-snapshot.json";

    function escapeHtml(value) {
        return String(value == null ? "" : value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function badge(value) {
        const normalized = String(value || "unknown").toLowerCase();
        return '<span class="biz-badge biz-' + escapeHtml(normalized) + '">' +
            escapeHtml(String(value || "unknown").replace(/_/g, " ")) +
            "</span>";
    }

    function money(value) {
        const number = Number(value || 0);
        return number.toLocaleString(undefined, {
            style: "currency",
            currency: "USD",
            maximumFractionDigits: 0
        });
    }

    async function renderBusinessIncubator() {
        const host =
            document.querySelector("[data-ai-office-business-incubator]") ||
            document.getElementById("business-incubator-module");

        if (!host) {
            return;
        }

        try {
            const response = await fetch(SNAPSHOT_URL + "?t=" + Date.now(), {
                cache: "no-store"
            });

            if (!response.ok) {
                throw new Error("Snapshot unavailable");
            }

            const data = await response.json();
            const summary = data.summary || {};
            const ideas = Array.isArray(data.ideas) ? data.ideas : [];
            const portfolio = Array.isArray(data.portfolio) ? data.portfolio : [];

            let html = '<section class="biz-panel">';
            html += '<div class="biz-heading"><div><h2>Business Incubator</h2>';
            html += '<p>Idea validation, venture scoring, launch economics, and portfolio priority.</p></div>';
            html += '<span class="biz-version">v' + escapeHtml(data.version || "1.8.0") + "</span></div>";

            html += '<div class="biz-metrics">';
            html += '<div><strong>' + escapeHtml(summary.ideas || 0) + '</strong><span>Ideas</span></div>';
            html += '<div><strong>' + escapeHtml(summary.validation_results || 0) + '</strong><span>Validations</span></div>';
            html += '<div><strong>' + escapeHtml(summary.venture_evaluations || 0) + '</strong><span>Evaluations</span></div>';
            html += '<div><strong>' + escapeHtml((summary.recommendations || {}).go || 0) + '</strong><span>GO</span></div>';
            html += "</div>";

            html += '<div class="biz-table-wrap"><table class="biz-table"><thead><tr>';
            html += "<th>Venture</th><th>Status</th><th>Validation</th><th>Score</th><th>Recommendation</th><th>Monthly Profit</th>";
            html += "</tr></thead><tbody>";

            if (ideas.length === 0) {
                html += '<tr><td colspan="6" class="biz-empty">No active ventures yet.</td></tr>';
            } else {
                ideas.forEach(function (idea) {
                    html += "<tr>";
                    html += "<td><strong>" + escapeHtml(idea.name) + "</strong><small>" + escapeHtml(idea.opportunity_type) + "</small></td>";
                    html += "<td>" + badge(idea.status) + "</td>";
                    html += "<td>" + escapeHtml(idea.validation_score) + " " + badge(idea.validation_status) + "</td>";
                    html += "<td>" + escapeHtml(idea.venture_score) + "</td>";
                    html += "<td>" + badge(idea.recommendation) + "</td>";
                    html += "<td>" + money(idea.expected_monthly_profit) + "</td>";
                    html += "</tr>";
                });
            }

            html += "</tbody></table></div>";

            if (portfolio.length > 0) {
                html += '<div class="biz-portfolio"><h3>Portfolio Priority</h3>';
                portfolio.slice(0, 5).forEach(function (item) {
                    html += '<div class="biz-rank"><span>#' + escapeHtml(item.rank) + "</span>";
                    html += "<strong>" + escapeHtml(item.name) + "</strong>";
                    html += "<em>" + escapeHtml(item.score) + "</em></div>";
                });
                html += "</div>";
            }

            html += "</section>";
            host.innerHTML = html;
        } catch (error) {
            host.innerHTML = '<section class="biz-panel"><h2>Business Incubator</h2><p class="biz-empty">Dashboard snapshot is not available yet.</p></section>';
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", renderBusinessIncubator);
    } else {
        renderBusinessIncubator();
    }

    window.AIOfficeBusinessIncubator = {
        refresh: renderBusinessIncubator
    };
})();
