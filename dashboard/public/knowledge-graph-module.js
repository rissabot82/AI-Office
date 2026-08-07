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
    if (document.getElementById("knowledgeGraphPanel")) {
      return;
    }

    const main = document.querySelector("main");

    if (!main) {
      return;
    }

    const section = document.createElement("section");
    section.className = "two-column knowledge-graph-section";
    section.id = "knowledgeGraphPanel";

    section.innerHTML = `
      <article class="panel">
        <div class="panel-heading">
          <div>
            <p class="eyebrow">KNOWLEDGE GRAPH</p>
            <h2>Connected intelligence</h2>
          </div>
          <span id="kgStatus">${badge("loading")}</span>
        </div>
        <div class="kg-metrics">
          <div><span id="kgEntities">0</span><small>Entities</small></div>
          <div><span id="kgRelationships">0</span><small>Relationships</small></div>
          <div><span id="kgInferences">0</span><small>Inferences</small></div>
          <div><span id="kgContradictions">0</span><small>Contradictions</small></div>
        </div>
        <div id="kgEntityTypes" class="kg-types"></div>
      </article>

      <article class="panel">
        <div class="panel-heading">
          <div>
            <p class="eyebrow">REASONING</p>
            <h2>Recent graph activity</h2>
          </div>
        </div>
        <div id="kgActivity" class="timeline"></div>
      </article>
    `;

    main.appendChild(section);
  }

  function renderTypes(counts) {
    const host = document.getElementById("kgEntityTypes");
    if (!host) return;

    const entries = Object.entries(counts || {})
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8);

    if (!entries.length) {
      host.innerHTML = `<div class="empty">No entity types populated yet.</div>`;
      return;
    }

    host.innerHTML = entries.map(([name, count]) => `
      <div class="kg-type-row">
        <span>${esc(name.replaceAll("_", " "))}</span>
        <strong>${count}</strong>
      </div>
    `).join("");
  }

  function renderActivity(data) {
    const host = document.getElementById("kgActivity");
    if (!host) return;

    const rows = [];

    for (const item of (data.recent_inferences || []).slice(0, 4)) {
      rows.push(`
        <div class="timeline-row">
          <div>
            <div class="timeline-title">${esc(item.summary || item.inference_id)}</div>
            <div class="timeline-meta">Inference · ${(item.confidence * 100).toFixed(0)}% confidence</div>
          </div>
          ${badge(item.inference_type)}
        </div>
      `);
    }

    for (const item of (data.recent_relationships || []).slice(0, 4)) {
      rows.push(`
        <div class="timeline-row">
          <div>
            <div class="timeline-title">${esc(item.from_entity_name)} → ${esc(item.to_entity_name)}</div>
            <div class="timeline-meta">${esc(item.relationship_type)} · ${(item.confidence * 100).toFixed(0)}% confidence</div>
          </div>
          ${badge("relationship")}
        </div>
      `);
    }

    if (!rows.length) {
      host.innerHTML = `<div class="empty">No graph activity yet.</div>`;
      return;
    }

    host.innerHTML = rows.join("");
  }

  async function loadKnowledgeGraph() {
    ensurePanel();

    try {
      const response = await fetch("/knowledge-graph-status.json", { cache: "no-store" });

      if (!response.ok) {
        throw new Error(`Knowledge Graph snapshot returned ${response.status}`);
      }

      const data = await response.json();

      document.getElementById("kgStatus").innerHTML = badge(data.status || "ready");
      document.getElementById("kgEntities").textContent = data.entity_count || 0;
      document.getElementById("kgRelationships").textContent = data.relationship_count || 0;
      document.getElementById("kgInferences").textContent = data.inference_count || 0;
      document.getElementById("kgContradictions").textContent = data.contradiction_count || 0;

      renderTypes(data.entity_type_counts || {});
      renderActivity(data);
    } catch (error) {
      const status = document.getElementById("kgStatus");
      if (status) status.innerHTML = badge("unavailable");
    }
  }

  document.addEventListener("DOMContentLoaded", loadKnowledgeGraph);
  setInterval(loadKnowledgeGraph, 15000);
})();
