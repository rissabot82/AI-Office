(function () {
  function esc(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }

  function badge(value) {
    const safe = String(value || "unknown").toLowerCase().replace(/\s+/g, "_");
    return `<span class="badge ${safe}">${esc(value || "unknown")}</span>`;
  }

  function ensurePanel() {
    if (document.getElementById("multiAgentPanel")) return;

    const main = document.querySelector("main");
    if (!main) return;

    const section = document.createElement("section");
    section.id = "multiAgentPanel";
    section.className = "two-column multi-agent-section";
    section.innerHTML = `
      <article class="panel">
        <div class="panel-heading">
          <div>
            <p class="eyebrow">MULTI-AGENT OPERATIONS</p>
            <h2>Agent workforce</h2>
          </div>
          <span id="maStatus">${badge("loading")}</span>
        </div>

        <div class="ma-metrics">
          <div><span id="maAgents">0</span><small>Agents</small></div>
          <div><span id="maAvailable">0</span><small>Available</small></div>
          <div><span id="maAssignments">0</span><small>Open work</small></div>
          <div><span id="maCollabs">0</span><small>Collaborations</small></div>
        </div>

        <div id="maDepartments" class="ma-departments"></div>
      </article>

      <article class="panel">
        <div class="panel-heading">
          <div>
            <p class="eyebrow">COLLABORATION RUNTIME</p>
            <h2>Agent activity</h2>
          </div>
          <span id="maConflictBadge">${badge("0 conflicts")}</span>
        </div>
        <div id="maActivity" class="timeline"></div>
      </article>
    `;

    main.appendChild(section);
  }

  function renderDepartments(counts) {
    const host = document.getElementById("maDepartments");
    if (!host) return;

    const entries = Object.entries(counts || {})
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10);

    if (!entries.length) {
      host.innerHTML = `<div class="empty">No persistent agents have been created yet.</div>`;
      return;
    }

    host.innerHTML = entries.map(([name, count]) => `
      <div class="ma-department-row">
        <span>${esc(name.replaceAll("_", " "))}</span>
        <strong>${count}</strong>
      </div>
    `).join("");
  }

  function renderActivity(items) {
    const host = document.getElementById("maActivity");
    if (!host) return;

    if (!items || items.length === 0) {
      host.innerHTML = `<div class="empty">No collaboration events yet.</div>`;
      return;
    }

    host.innerHTML = items.slice(0, 10).map(item => `
      <div class="timeline-row">
        <div>
          <div class="timeline-title">${esc(item.title || item.event_type)}</div>
          <div class="timeline-meta">
            ${esc(item.event_type)} · ${esc(item.detail || "")}
          </div>
        </div>
        ${badge(item.status)}
      </div>
    `).join("");
  }

  async function loadMultiAgent() {
    ensurePanel();

    try {
      const response = await fetch("/multi-agent-status.json", { cache: "no-store" });

      if (!response.ok) {
        throw new Error(`Multi-Agent snapshot returned ${response.status}`);
      }

      const data = await response.json();

      document.getElementById("maStatus").innerHTML = badge(data.status || "ready");
      document.getElementById("maAgents").textContent = data.agent_count || 0;
      document.getElementById("maAvailable").textContent = data.available_count || 0;
      document.getElementById("maAssignments").textContent = data.open_assignment_count || 0;
      document.getElementById("maCollabs").textContent = data.active_collaboration_count || 0;

      const conflicts = data.open_conflict_count || 0;
      document.getElementById("maConflictBadge").innerHTML =
        badge(`${conflicts} conflict${conflicts === 1 ? "" : "s"}`);

      renderDepartments(data.department_counts || {});
      renderActivity(data.recent_events || []);
    } catch (error) {
      const status = document.getElementById("maStatus");
      if (status) status.innerHTML = badge("unavailable");
    }
  }

  document.addEventListener("DOMContentLoaded", loadMultiAgent);
  setInterval(loadMultiAgent, 15000);
})();
