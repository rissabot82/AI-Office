(function () {
    "use strict";
    function esc(value) {
        return String(value == null ? "" : value)
            .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;").replace(/'/g, "&#039;");
    }
    function metric(label, value) {
        return '<div class="sh-card"><div class="sh-value">' + esc(value) +
            '</div><div class="sh-label">' + esc(label) + '</div></div>';
    }
    async function loadSelfHosting() {
        var host = document.getElementById("self-hosting-module");
        if (!host) return;
        try {
            var response = await fetch("/data/self-hosting.json?ts=" + Date.now(), { cache: "no-store" });
            if (!response.ok) throw new Error("HTTP " + response.status);
            var data = await response.json();
            var m = data.metrics || {};
            var runtime = data.runtime || {};
            var hw = data.hardware || {};
            var gpu = Array.isArray(hw.gpu) && hw.gpu.length ? hw.gpu[0].name : "Unknown GPU";
            var recent = Array.isArray(data.recent_inference) ? data.recent_inference : [];
            var inferenceHtml = recent.length ? recent.map(function (item) {
                return '<div class="sh-run"><strong>' + esc(item.model) + '</strong><span>' +
                    esc(item.status) + ' · ' + esc(item.elapsed_ms) + ' ms</span></div>';
            }).join("") : '<div class="sh-empty">No persisted inference results yet.</div>';
            host.innerHTML =
                '<section class="sh-panel">' +
                '<div class="sh-header"><div><div class="sh-kicker">SELF-HOSTED AI OFFICE</div><h2>Local Inference</h2></div>' +
                '<span class="sh-status sh-' + esc(data.status) + '">' + esc(data.status) + '</span></div>' +
                '<div class="sh-grid">' +
                metric("Providers", m.providers || 0) +
                metric("Connected", m.connected_providers || 0) +
                metric("Models", m.models || 0) +
                metric("Ready Models", m.ready_models || 0) +
                metric("Routing Rules", m.routing_rules || 0) +
                metric("Inference Runs", m.inference_results || 0) +
                '</div>' +
                '<div class="sh-details">' +
                '<div><span>Runtime</span><strong>' + esc(runtime.provider || "ollama") + '</strong></div>' +
                '<div><span>Endpoint</span><strong>' + esc(runtime.endpoint || "") + '</strong></div>' +
                '<div><span>Health</span><strong>' + esc(runtime.health || "") + '</strong></div>' +
                '<div><span>RAM</span><strong>' + esc(hw.memory_gb || 0) + ' GB</strong></div>' +
                '<div><span>GPU</span><strong>' + esc(gpu) + '</strong></div>' +
                '</div><div class="sh-subtitle">Recent Local Inference</div><div class="sh-runs">' +
                inferenceHtml + '</div></section>';
        } catch (error) {
            host.innerHTML = '<section class="sh-panel sh-error"><h2>Local Inference</h2><div>Dashboard data unavailable: ' +
                esc(error.message) + '</div></section>';
        }
    }
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", loadSelfHosting);
    } else {
        loadSelfHosting();
    }
})();