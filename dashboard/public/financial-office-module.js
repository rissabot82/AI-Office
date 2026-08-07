(function () {
  function esc(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }

  function money(value) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
      maximumFractionDigits: 0
    }).format(Number(value || 0));
  }

  function badge(value) {
    const safe = String(value || "unknown").toLowerCase().replace(/\s+/g, "_");
    return `<span class="badge ${safe}">${esc(value || "unknown")}</span>`;
  }

  function ensurePanel() {
    if (document.getElementById("financialOfficePanel")) return;

    const main = document.querySelector("main");
    if (!main) return;

    const section = document.createElement("section");
    section.id = "financialOfficePanel";
    section.className = "financial-office-section";

    section.innerHTML = `
      <article class="panel">
        <div class="panel-heading">
          <div>
            <p class="eyebrow">PERSONAL FINANCIAL OFFICE</p>
            <h2>Financial control center</h2>
          </div>
          <span id="finStatus">${badge("loading")}</span>
        </div>

        <div class="fin-metrics">
          <div>
            <span id="finLiquid">$0</span>
            <small>Liquid cash</small>
          </div>
          <div>
            <span id="finDebt">$0</span>
            <small>Total debt</small>
          </div>
          <div>
            <span id="finMonthlyNet">$0</span>
            <small>Monthly net</small>
          </div>
          <div>
            <span id="finGoals">0%</span>
            <small>Goals funded</small>
          </div>
        </div>
      </article>

      <div class="two-column">
        <article class="panel">
          <div class="panel-heading">
            <div>
              <p class="eyebrow">GOALS & DEBT</p>
              <h2>Current priorities</h2>
            </div>
          </div>
          <div id="finPriorities" class="fin-list"></div>
        </article>

        <article class="panel">
          <div class="panel-heading">
            <div>
              <p class="eyebrow">RECOMMENDATIONS</p>
              <h2>What needs attention</h2>
            </div>
          </div>
          <div id="finRecommendations" class="timeline"></div>
        </article>
      </div>

      <div class="two-column">
        <article class="panel">
          <div class="panel-heading">
            <div>
              <p class="eyebrow">SIDE HUSTLES</p>
              <h2>Income experiments</h2>
            </div>
          </div>
          <div id="finSideHustles" class="fin-list"></div>
        </article>

        <article class="panel">
          <div class="panel-heading">
            <div>
              <p class="eyebrow">PLANNING</p>
              <h2>Latest projections</h2>
            </div>
          </div>
          <div id="finPlanning" class="fin-list"></div>
        </article>
      </div>
    `;

    main.appendChild(section);
  }

  function renderPriorities(data) {
    const host = document.getElementById("finPriorities");
    if (!host) return;

    const rows = [];

    for (const goal of (data.goals || []).slice(0, 5)) {
      rows.push(`
        <div class="fin-row">
          <div>
            <strong>${esc(goal.name)}</strong>
            <small>${esc(goal.goal_type)} · ${goal.progress_percent || 0}% funded</small>
          </div>
          <span>${money(goal.current_amount)} / ${money(goal.target_amount)}</span>
        </div>
      `);
    }

    for (const debt of (data.debts || []).slice(0, 5)) {
      rows.push(`
        <div class="fin-row">
          <div>
            <strong>${esc(debt.name)}</strong>
            <small>${Number(debt.interest_rate || 0).toFixed(2)}% APR · min ${money(debt.minimum_payment)}</small>
          </div>
          <span>${money(debt.balance)}</span>
        </div>
      `);
    }

    host.innerHTML = rows.length
      ? rows.join("")
      : `<div class="empty">No goals or debts recorded yet.</div>`;
  }

  function renderRecommendations(items) {
    const host = document.getElementById("finRecommendations");
    if (!host) return;

    if (!items || items.length === 0) {
      host.innerHTML = `<div class="empty">No recommendations yet.</div>`;
      return;
    }

    host.innerHTML = items.slice(0, 8).map(item => `
      <div class="timeline-row">
        <div>
          <div class="timeline-title">${esc(item.recommendation)}</div>
          <div class="timeline-meta">${esc(item.category)}</div>
        </div>
        ${badge(item.priority)}
      </div>
    `).join("");
  }

  function renderSideHustles(items) {
    const host = document.getElementById("finSideHustles");
    if (!host) return;

    if (!items || items.length === 0) {
      host.innerHTML = `<div class="empty">No side-hustle performance records yet.</div>`;
      return;
    }

    host.innerHTML = items.slice(0, 8).map(item => `
      <div class="fin-row">
        <div>
          <strong>${esc(item.name)}</strong>
          <small>${Number(item.profit_margin || 0).toFixed(1)}% margin · ${money(item.hourly_rate)}/hr</small>
        </div>
        <span>${money(item.net_profit)}</span>
      </div>
    `).join("");
  }

  function renderPlanning(data) {
    const host = document.getElementById("finPlanning");
    if (!host) return;

    const rows = [];

    if (data.latest_forecast) {
      rows.push(`
        <div class="fin-row">
          <div>
            <strong>Cash-flow forecast</strong>
            <small>${esc(data.latest_forecast.start_date)} → ${esc(data.latest_forecast.end_date)}</small>
          </div>
          <span>${money(data.latest_forecast.projected_closing_balance)}</span>
        </div>
      `);
    }

    if (data.latest_paycheck_plan) {
      rows.push(`
        <div class="fin-row">
          <div>
            <strong>Paycheck plan</strong>
            <small>${esc(data.latest_paycheck_plan.pay_date)} · ${data.latest_paycheck_plan.allocation_count} allocations</small>
          </div>
          <span>${money(data.latest_paycheck_plan.remaining_cash)} left</span>
        </div>
      `);
    }

    host.innerHTML = rows.length
      ? rows.join("")
      : `<div class="empty">No projections have been generated yet.</div>`;
  }

  async function loadFinancialOffice() {
    ensurePanel();

    try {
      const response = await fetch("/financial-office-status.json", { cache: "no-store" });
      if (!response.ok) throw new Error(`Financial snapshot returned ${response.status}`);

      const data = await response.json();

      document.getElementById("finStatus").innerHTML = badge(data.status || "ready");
      document.getElementById("finLiquid").textContent = money(data.total_liquid_balance);
      document.getElementById("finDebt").textContent = money(data.total_debt_balance);
      document.getElementById("finMonthlyNet").textContent = money(data.monthly_net);
      document.getElementById("finGoals").textContent = `${Number(data.goal_progress_percent || 0).toFixed(0)}%`;

      renderPriorities(data);
      renderRecommendations(data.latest_recommendations || []);
      renderSideHustles(data.side_hustles || []);
      renderPlanning(data);
    } catch (error) {
      const status = document.getElementById("finStatus");
      if (status) status.innerHTML = badge("unavailable");
    }
  }

  document.addEventListener("DOMContentLoaded", loadFinancialOffice);
  setInterval(loadFinancialOffice, 15000);
})();
