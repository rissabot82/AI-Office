const refreshButton = document.getElementById("refreshButton");

function statusBadge(value) {
  const safe = String(value || "unknown").toLowerCase().replace(/\s+/g, "_");
  return `<span class="badge ${safe}">${value || "unknown"}</span>`;
}

function formatDate(value) {
  if (!value) return "Unknown time";

  const parsed = new Date(value);

  if (Number.isNaN(parsed.getTime())) return value;

  return parsed.toLocaleString();
}

function renderSystem(system) {
  const host = document.getElementById("systemStatus");
  const entries = [
    ["AI Office", system.ai_office],
    ["OpenClaw", system.openclaw],
    ["Bridge", system.bridge],
    ["Memory", system.memory],
    ["Workflows", system.autonomous_workflows],
  ];

  host.innerHTML = entries.map(([label, value]) => `
    <div class="status-item">
      <span class="status-dot ${String(value).toLowerCase()}"></span>
      <strong>${label}</strong>
      <span>${value}</span>
    </div>
  `).join("");
}

function renderDepartments(items) {
  const host = document.getElementById("departments");

  if (!items || items.length === 0) {
    host.innerHTML = `<div class="empty">No departments found.</div>`;
    return;
  }

  host.innerHTML = items.map(item => `
    <div class="department-card">
      <div class="department-head">
        <h3>${item.name}</h3>
        ${statusBadge(item.status)}
      </div>
      <p>${item.active_work} active · ${item.plans} plans · ${item.inbox} inbox</p>
    </div>
  `).join("");
}

function renderQueues(queues) {
  const host = document.getElementById("queues");

  host.innerHTML = Object.entries(queues || {}).map(([name, count]) => `
    <div class="queue-row">
      <span>${name.replace("-", " ")}</span>
      <span class="queue-value">${count}</span>
    </div>
  `).join("");
}

function renderMemory(items) {
  const host = document.getElementById("recentMemory");

  if (!items || items.length === 0) {
    host.innerHTML = `<div class="empty">No persistent memory records yet.</div>`;
    return;
  }

  host.innerHTML = items.map(item => `
    <div class="timeline-row">
      <div>
        <div class="timeline-title">${item.title || item.memory_id}</div>
        <div class="timeline-meta">
          ${item.scope} · ${item.type} · ${formatDate(item.updated_at)}
        </div>
      </div>
      <span class="badge">${Math.round((item.confidence || 0) * 100)}%</span>
    </div>
  `).join("");
}

function renderRuns(items) {
  const host = document.getElementById("recentRuns");

  if (!items || items.length === 0) {
    host.innerHTML = `<div class="empty">No autonomous runs yet.</div>`;
    return;
  }

  host.innerHTML = items.map(item => `
    <div class="timeline-row">
      <div>
        <div class="timeline-title">${item.run_id}</div>
        <div class="timeline-meta">
          Step ${item.current_step} · ${formatDate(item.updated_at)}
        </div>
      </div>
      ${statusBadge(item.status)}
    </div>
  `).join("");
}

function renderSummary(data) {
  const counts = data.counts || {};

  document.getElementById("activeRuns").textContent = counts.active_runs || 0;
  document.getElementById("memoryCount").textContent = counts.total_memory || 0;

  const attention = (counts.failed_runs || 0) + (counts.waiting_approval || 0);
  document.getElementById("attentionCount").textContent = attention;

  document.getElementById("workflowSummary").textContent =
    `${counts.open_goals || 0} open goals across the autonomous workflow engine.`;

  document.getElementById("memorySummary").textContent =
    `${counts.active_memory || 0} active records available for recall and context.`;

  document.getElementById("attentionSummary").textContent =
    attention === 0
      ? "No approvals or failed runs currently require attention."
      : `${counts.waiting_approval || 0} approvals and ${counts.failed_runs || 0} failed runs require review.`;
}

async function loadDashboard() {
  refreshButton.disabled = true;
  refreshButton.textContent = "Refreshing";

  try {
    const response = await fetch("/api/status", { cache: "no-store" });

    if (!response.ok) {
      throw new Error(`Dashboard API returned ${response.status}`);
    }

    const data = await response.json();

    renderSystem(data.system || {});
    renderSummary(data);
    renderDepartments(data.departments || []);
    renderQueues(data.queues || {});
    renderMemory(data.recent_memory || []);
    renderRuns(data.recent_runs || []);

    document.getElementById("lastUpdated").textContent =
      `Updated ${formatDate(data.generated_at)}`;
  } catch (error) {
    document.getElementById("lastUpdated").textContent = error.message;
  } finally {
    refreshButton.disabled = false;
    refreshButton.textContent = "Refresh";
  }
}

refreshButton.addEventListener("click", loadDashboard);

loadDashboard();
setInterval(loadDashboard, 15000);
