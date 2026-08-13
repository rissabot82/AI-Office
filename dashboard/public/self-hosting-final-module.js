(function () {
"use strict";

function esc(v) {
  return String(v == null ? "" : v)
    .replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;")
    .replace(/"/g,"&quot;").replace(/'/g,"&#039;");
}

function metric(label, value) {
  return '<div class="shf-card"><div class="shf-value">' + esc(value) +
    '</div><div class="shf-label">' + esc(label) + '</div></div>';
}

function flag(label, ok) {
  return '<div class="shf-flag ' + (ok ? 'ok' : 'bad') + '"><span>' +
    esc(label) + '</span><strong>' + (ok ? 'ONLINE' : 'OFFLINE') + '</strong></div>';
}

async function loadFinalSelfHosting() {
  var host = document.getElementById("self-hosting-final-module");
  if (!host) return;

  try {
    var r = await fetch("/data/self-hosting-final.json?ts=" + Date.now(), {cache:"no-store"});
    if (!r.ok) throw new Error("HTTP " + r.status);
    var d = await r.json();

    var li = d.local_inference || {};
    var o = d.optimization || {};
    var rs = d.resilience || {};
    var res = d.resources || {};
    var s = d.services || {};
    var warnings = Array.isArray(res.warnings) ? res.warnings : [];

    host.innerHTML =
      '<section class="shf-panel">' +
        '<div class="shf-head">' +
          '<div><div class="shf-kicker">AI OFFICE v2.2</div><h2>Self-Hosted AI Office</h2></div>' +
          '<div class="shf-status ' + esc(d.overall_status) + '">' + esc(d.overall_status) + '</div>' +
        '</div>' +

        '<div class="shf-flags">' +
          flag("Ollama", !!s.ollama) +
          flag("OpenClaw", !!s.openclaw_gateway) +
          flag("Dashboard", !!s.dashboard) +
        '</div>' +

        '<div class="shf-grid">' +
          metric("Ready Models", li.ready_models || 0) +
          metric("Fleet Models", li.fleet_models || 0) +
          metric("Routing Rules", li.routing_rules || 0) +
          metric("Routing Decisions", o.routing_decisions || 0) +
          metric("Benchmarks", o.benchmarks || 0) +
          metric("Failovers", rs.failover_events || 0) +
        '</div>' +

        '<div class="shf-resource-grid">' +
          '<div><span>CPU</span><strong>' + esc(res.cpu_percent || 0) + '%</strong></div>' +
          '<div><span>RAM</span><strong>' + esc(res.memory_percent || 0) + '%</strong></div>' +
          '<div><span>C: Free</span><strong>' + esc(res.system_drive_free_gb || 0) + ' GB</strong></div>' +
          '<div><span>E: Free</span><strong>' + esc(res.ai_drive_free_gb || 0) + ' GB</strong></div>' +
          '<div><span>Benchmark</span><strong>' + esc(o.latest_benchmark_success_rate || 0) + '%</strong></div>' +
          '<div><span>Failed Recoveries</span><strong>' + esc(rs.failed_recoveries || 0) + '</strong></div>' +
        '</div>' +

        (warnings.length
          ? '<div class="shf-warning"><strong>Resource warnings:</strong> ' + esc(warnings.join(" | ")) + '</div>'
          : '<div class="shf-clean">No active resource warnings.</div>') +
      '</section>';
  } catch (e) {
    host.innerHTML = '<section class="shf-panel shf-error"><h2>Self-Hosted AI Office</h2><div>' +
      esc(e.message) + '</div></section>';
  }
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", loadFinalSelfHosting);
} else {
  loadFinalSelfHosting();
}
})();