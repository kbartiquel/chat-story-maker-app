const API_BASE = "https://textery-api-7uam4panra-uc.a.run.app";

const SETTINGS_META = {
  videoExportLimit: { label: "Free Video Exports", group: "limits", type: "number", hint: "How many exports a free user gets before premium is required." },
  aiGenerationLimit: { label: "Free AI Generations", group: "limits", type: "number", hint: "How many AI stories a free user can generate." },
  hardPaywall: { label: "Hard Paywall", group: "behavior", type: "boolean", hint: "When enabled, users cannot dismiss the paywall." },
  paywallCloseButtonDelay: { label: "Launch Close Delay", group: "behavior", type: "number", hint: "Seconds before close appears on launch paywall." },
  paywallCloseButtonDelayOnLimit: { label: "Limit Close Delay", group: "behavior", type: "number", hint: "Seconds before close appears on limit paywall." },
  paywallShowLoadingIndicator: { label: "Show Loading Indicator", group: "behavior", type: "boolean", hint: "Display the loading/countdown state before close appears." },
  showPaywallOnStart: { label: "Show Paywall On Start", group: "behavior", type: "boolean", hint: "Display paywall at launch for non-premium users." },
  paywallMonthly: { label: "Monthly Plan", group: "plans", type: "boolean", hint: "Show the monthly plan." },
  paywallWeekly: { label: "Weekly Plan", group: "plans", type: "boolean", hint: "Show the weekly plan." },
  paywallYearly: { label: "Yearly Plan", group: "plans", type: "boolean", hint: "Show the yearly plan." },
  paywallLifetime: { label: "Lifetime Plan", group: "plans", type: "boolean", hint: "Show the lifetime plan." }
};

const DATE_PRESETS = [
  { id: "today", label: "Today" },
  { id: "yesterday", label: "Yesterday" },
  { id: "last7", label: "Last 7 Days" },
  { id: "last30", label: "Last 30 Days" },
  { id: "thisMonth", label: "This Month" },
  { id: "lastMonth", label: "Last Month" },
  { id: "thisYear", label: "This Year" },
  { id: "all", label: "All Time" }
];

const FUNNELS = [
  { id: "trial_churned", label: "Trial Churned", match: (u) => hasEvent(u, "trial_started") && hasEvent(u, "trial_cancelled") },
  { id: "trial_expired", label: "Trial Expired", match: (u) => hasEvent(u, "trial_started") && hasEvent(u, "trial_expired") },
  { id: "trial_converted", label: "Trial → Paid", match: (u) => hasEvent(u, "trial_started") && hasEvent(u, "trial_converted") },
  { id: "paid_churned", label: "Paid Churned", match: (u) => hasEvent(u, "subscription_purchased") && hasEvent(u, "subscription_cancelled") },
  { id: "active_subscribers", label: "Active Subscribers", match: (u) => ["subscribed", "lifetime", "trial"].includes(u.subscriptionStatus) },
  { id: "free_users", label: "Free Users", match: (u) => ["free", "unknown"].includes(u.subscriptionStatus) },
  { id: "paywall_dropoff", label: "Paywall Drop-off", match: (u) => hasEvent(u, "paywall_shown") && !hasAnyEvent(u, ["purchase_completed", "subscription_purchased", "trial_converted", "lifetime_purchased"]) }
];

const loginShell = document.getElementById("loginShell");
const appShell = document.getElementById("appShell");
const loginError = document.getElementById("loginError");
const passwordInput = document.getElementById("passwordInput");
const jsonEditor = document.getElementById("jsonEditor");
const toast = document.getElementById("toast");

let authToken = sessionStorage.getItem("textery_admin_password") || "";
let currentSettings = {};
let activeTab = "dashboard";
let activePreset = "last30";
let dashData = null;
let activeFunnel = null;
let expandedUsers = new Set();

const activeStatusFilters = new Set();
const activePlanFilters = new Set();
const activeCountryFilters = new Set();
const activeJourneyFilters = new Set();
const activeFeatureFilters = new Set();

document.getElementById("apiBase").textContent = API_BASE;
passwordInput.value = authToken;

document.getElementById("loginBtn").addEventListener("click", login);
passwordInput.addEventListener("keydown", (event) => event.key === "Enter" && login());
document.getElementById("logoutBtn").addEventListener("click", logout);
document.getElementById("copyApiBtn").addEventListener("click", async () => {
  await navigator.clipboard.writeText(API_BASE);
  showToast("API URL copied");
});
document.getElementById("saveBtn").addEventListener("click", saveSettings);
document.getElementById("resetBtn").addEventListener("click", resetSettings);
document.getElementById("formatJsonBtn").addEventListener("click", formatJsonEditor);
document.getElementById("clearFiltersBtn").addEventListener("click", clearAllFilters);
jsonEditor.addEventListener("input", handleJsonEditorInput);

document.querySelectorAll(".tab").forEach((tab) => {
  tab.addEventListener("click", () => switchTab(tab.dataset.tab));
});

boot();

async function boot() {
  renderDatePills();
  renderFunnelButtons();
  await checkHealth();
  if (!authToken) return;
  showApp();
  await Promise.all([loadSettings(), loadDashboard()]);
}

async function login() {
  const password = passwordInput.value.trim();
  hideLoginError();
  if (!password) return showLoginError("Enter the admin password.");

  try {
    const response = await fetch(`${API_BASE}/admin/auth`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ password }),
    });
    const data = await response.json();
    if (!response.ok || !data.success) return showLoginError("Invalid admin password.");
    authToken = password;
    sessionStorage.setItem("textery_admin_password", password);
    showApp();
    await Promise.all([loadSettings(), loadDashboard()]);
    showToast("Logged in");
  } catch (error) {
    showLoginError("Could not connect to the API.");
  }
}

function logout() {
  authToken = "";
  sessionStorage.removeItem("textery_admin_password");
  appShell.classList.add("hidden");
  loginShell.classList.remove("hidden");
  passwordInput.value = "";
  hideLoginError();
}

function showApp() {
  loginShell.classList.add("hidden");
  appShell.classList.remove("hidden");
}

function showLoginError(message) {
  loginError.textContent = message;
  loginError.style.display = "block";
}

function hideLoginError() {
  loginError.style.display = "none";
}

async function checkHealth() {
  const pill = document.getElementById("apiStatus");
  try {
    const response = await fetch(`${API_BASE}/health`);
    if (!response.ok) throw new Error("bad");
    pill.textContent = "API Healthy";
    pill.classList.add("ok");
    pill.classList.remove("bad");
  } catch (error) {
    pill.textContent = "API Unreachable";
    pill.classList.add("bad");
    pill.classList.remove("ok");
  }
}

function authHeaders(extra = {}) {
  return { ...extra, Authorization: authToken };
}

async function loadSettings() {
  const response = await fetch(`${API_BASE}/admin/settings`, { headers: authHeaders() });
  if (!response.ok) throw new Error("Failed to load settings");
  currentSettings = await response.json();
  syncSettingsUI();
}

async function loadDashboard() {
  const { startDate, endDate } = presetToDates(activePreset);
  const params = new URLSearchParams();
  if (startDate) params.set("startDate", startDate);
  if (endDate) params.set("endDate", endDate);
  params.set("limit", "250");
  const response = await fetch(`${API_BASE}/admin/stats?${params.toString()}`, { headers: authHeaders() });
  if (!response.ok) throw new Error("Failed to load dashboard");
  dashData = await response.json();
  renderDashboard();
}

function switchTab(tab) {
  activeTab = tab;
  document.querySelectorAll(".tab").forEach((button) => button.classList.toggle("active", button.dataset.tab === tab));
  document.getElementById("dashboardTab").classList.toggle("hidden", tab !== "dashboard");
  document.getElementById("settingsTab").classList.toggle("hidden", tab !== "settings");
}

function renderDatePills() {
  const container = document.getElementById("datePills");
  container.innerHTML = DATE_PRESETS.map((preset) => `
    <button class="filter-pill ${preset.id === activePreset ? "active" : ""}" data-preset="${preset.id}">${preset.label}</button>
  `).join("");
  container.querySelectorAll("[data-preset]").forEach((button) => {
    button.addEventListener("click", async () => {
      activePreset = button.dataset.preset;
      renderDatePills();
      await loadDashboard();
    });
  });
}

function renderFunnelButtons() {
  const container = document.getElementById("funnelButtons");
  container.innerHTML = FUNNELS.map((funnel) => `
    <button class="funnel-btn ${funnel.id === activeFunnel ? "active" : ""}" data-funnel="${funnel.id}">${funnel.label}</button>
  `).join("");
  container.querySelectorAll("[data-funnel]").forEach((button) => {
    button.addEventListener("click", () => {
      activeFunnel = activeFunnel === button.dataset.funnel ? null : button.dataset.funnel;
      renderFunnelButtons();
      renderUsersTable();
    });
  });
}

function renderDashboard() {
  renderSummaryCards();
  renderEndpointBreakdown();
  renderBars("featureBars", dashData.featureBreakdown || [], "feature");
  renderBars("eventBars", dashData.eventBreakdown || [], "event");
  renderUserFilters();
  renderUsersTable();
}

function renderSummaryCards() {
  const summary = dashData.summary || {};
  const cards = [
    ["Active Users", summary.activeUsers || 0, "users active in this range"],
    ["New Users", summary.newUsers || 0, "first installs in this range"],
    ["Revenue", `$${formatMoney(summary.totalRevenue || 0)}`, "RevenueCat webhook events"],
  ];

  document.getElementById("summaryRow").innerHTML = cards.map(([label, value, sub]) => `
    <div class="stat-card">
      <div class="stat-label">${label}</div>
      <div class="stat-value">${value}</div>
      <div class="stat-sub">${sub}</div>
    </div>
  `).join("");
}

function renderEndpointBreakdown() {
  const container = document.getElementById("endpointBreakdown");
  const entries = Object.entries(dashData.byEndpoint || {});
  if (!entries.length) {
    container.innerHTML = '<div class="breakdown-pill">No request logs yet</div>';
    return;
  }
  container.innerHTML = entries.map(([name, count]) => `
    <div class="breakdown-pill">${escapeHtml(name)} <strong>${count}</strong></div>
  `).join("");
}

function renderBars(containerId, items, key) {
  const container = document.getElementById(containerId);
  if (!items.length) {
    container.innerHTML = '<div class="stat-sub">No data for this range.</div>';
    return;
  }
  const max = Math.max(...items.map((item) => item.count), 1);
  container.innerHTML = items.slice(0, 18).map((item) => `
    <div class="bar-item">
      <div class="bar-label">${escapeHtml(item[key])}</div>
      <div class="bar-wrap"><div class="bar-fill" style="width:${(item.count / max) * 100}%"></div></div>
      <div class="bar-count">${item.count}</div>
    </div>
  `).join("");
}

function renderUserFilters() {
  const users = dashData.users || [];
  renderFilterSet("statusFilters", countsFor(users, (user) => user.subscriptionStatus || "unknown"), activeStatusFilters, renderUsersTable);
  renderFilterSet("planFilters", countsFor(users, (user) => user.planType || "free"), activePlanFilters, renderUsersTable);
  renderFilterSet("countryFilters", countsFor(users, (user) => user.country || "Unknown"), activeCountryFilters, renderUsersTable);
  renderFilterSet("journeyFilters", countsFor(users, journeyTagsForUser), activeJourneyFilters, renderUsersTable, true);
  renderFilterSet("featureFilters", countsFor(users, featureTagsForUser), activeFeatureFilters, renderUsersTable, true);
}

function renderFilterSet(containerId, counts, activeSet, onChange, multiValue = false) {
  const container = document.getElementById(containerId);
  const entries = Object.entries(counts).sort((a, b) => b[1] - a[1]);
  container.innerHTML = entries.map(([label, count]) => `
    <button class="uf-pill ${activeSet.has(label) ? "active" : ""}" data-value="${escapeAttr(label)}">
      ${escapeHtml(label)} <span class="uf-count">${count}</span>
    </button>
  `).join("");
  container.querySelectorAll("[data-value]").forEach((button) => {
    button.addEventListener("click", () => {
      const value = button.dataset.value;
      if (activeSet.has(value)) activeSet.delete(value);
      else activeSet.add(value);
      renderUserFilters();
      onChange(multiValue);
    });
  });
}

function countsFor(users, selector) {
  const counts = {};
  for (const user of users) {
    const value = selector(user);
    const values = Array.isArray(value) ? value : [value];
    for (const entry of values.filter(Boolean)) {
      counts[entry] = (counts[entry] || 0) + 1;
    }
  }
  return counts;
}

function renderUsersTable() {
  const tbody = document.getElementById("usersTableBody");
  const users = filteredUsers();
  document.getElementById("filteredCount").textContent = `${users.length} user${users.length === 1 ? "" : "s"} in current view`;

  if (!users.length) {
    tbody.innerHTML = '<tr><td colspan="10">No users match the selected filters.</td></tr>';
    return;
  }

  tbody.innerHTML = users.map((user) => {
    const expanded = expandedUsers.has(user.userId);
    const revenue = user.totalRevenueUsd > 0 ? `$${formatMoney(user.totalRevenueUsd)}` : user.totalRevenue > 0 ? `${formatMoney(user.totalRevenue)} ${escapeHtml(user.revenueCurrency || "USD")}` : "—";
    return `
      <tr data-user-row="${escapeAttr(user.userId)}">
        <td>
          <div><strong>${escapeHtml(shortId(user.userId))}</strong></div>
          <div class="user-id-cell">${escapeHtml(user.userId)}</div>
        </td>
        <td>${formatDate(user.lastSeen)}</td>
        <td>${escapeHtml(user.lastEvent || "—")}</td>
        <td><span class="badge badge-${badgeClass(user.subscriptionStatus)}">${escapeHtml(user.subscriptionStatus || "unknown")}</span></td>
        <td>${escapeHtml(user.planType || "free")}</td>
        <td>${revenue}</td>
        <td>${user.eventCount || 0}</td>
        <td>${user.purchaseCount || 0}</td>
        <td>${escapeHtml(user.country || "—")}</td>
        <td><button class="btn-icon" data-delete-user="${escapeAttr(user.userId)}">Delete</button></td>
      </tr>
      ${expanded ? renderTimelineRow(user) : ""}
    `;
  }).join("");

  tbody.querySelectorAll("[data-user-row]").forEach((row) => {
    row.addEventListener("click", (event) => {
      if (event.target.closest("[data-delete-user]")) return;
      const userId = row.dataset.userRow;
      if (expandedUsers.has(userId)) expandedUsers.delete(userId);
      else expandedUsers.add(userId);
      renderUsersTable();
    });
  });

  tbody.querySelectorAll("[data-delete-user]").forEach((button) => {
    button.addEventListener("click", async (event) => {
      event.stopPropagation();
      const userId = button.dataset.deleteUser;
      if (!window.confirm(`Delete ${userId} from admin analytics?`)) return;
      await deleteUser(userId);
    });
  });
}

function renderTimelineRow(user) {
  const items = (user.events || []).slice(0, 20).map((event) => `
    <div class="event-item">
      <span class="event-dot"></span>
      <span class="event-name">${escapeHtml(event.event)}</span>
      <span class="event-props">${escapeHtml(shortProps(event.properties || {}))}</span>
      <span class="event-time">${formatDate(event.ts)}</span>
    </div>
  `).join("");
  return `
    <tr class="timeline-row">
      <td colspan="10">
        <div class="timeline-inner">
          <div class="timeline-title">User Timeline</div>
          <div class="timeline-events">${items || '<div class="stat-sub">No events recorded.</div>'}</div>
        </div>
      </td>
    </tr>
  `;
}

function filteredUsers() {
  const users = dashData?.users || [];
  return users.filter((user) => {
    if (activeFunnel) {
      const funnel = FUNNELS.find((entry) => entry.id === activeFunnel);
      if (funnel && !funnel.match(user)) return false;
    }

    if (activeStatusFilters.size && !activeStatusFilters.has(user.subscriptionStatus || "unknown")) return false;
    if (activePlanFilters.size && !activePlanFilters.has(user.planType || "free")) return false;
    if (activeCountryFilters.size && !activeCountryFilters.has(user.country || "Unknown")) return false;

    const journeys = new Set(journeyTagsForUser(user));
    for (const filter of activeJourneyFilters) {
      if (!journeys.has(filter)) return false;
    }

    const features = new Set(featureTagsForUser(user));
    for (const filter of activeFeatureFilters) {
      if (!features.has(filter)) return false;
    }

    return true;
  });
}

function journeyTagsForUser(user) {
  const tags = [];
  if (hasEvent(user, "first_install")) tags.push("Installed");
  if (hasAnyEvent(user, ["onboarding_started", "onboarding_completed"])) tags.push("Onboarded");
  if (hasEvent(user, "paywall_shown")) tags.push("Saw Paywall");
  if (hasAnyEvent(user, ["purchase_completed", "subscription_purchased", "trial_converted", "lifetime_purchased"])) tags.push("Purchased");
  if (hasEvent(user, "trial_started")) tags.push("Started Trial");
  if (hasEvent(user, "trial_cancelled")) tags.push("Cancelled Trial");
  return tags;
}

function featureTagsForUser(user) {
  const tags = [];
  if (hasAnyEvent(user, ["ai_generation_started", "ai_generation_completed", "request_generate"])) tags.push("AI Stories");
  if (hasAnyEvent(user, ["export_started", "export_completed", "request_render"])) tags.push("Video Export");
  if (hasEvent(user, "conversation_created")) tags.push("Story Creation");
  if (hasEvent(user, "folder_created")) tags.push("Folders");
  return tags;
}

function hasEvent(user, eventName) {
  return (user.events || []).some((event) => event.event === eventName);
}

function hasAnyEvent(user, eventNames) {
  return eventNames.some((name) => hasEvent(user, name));
}

async function deleteUser(userId) {
  try {
    const response = await fetch(`${API_BASE}/admin/user/${encodeURIComponent(userId)}`, {
      method: "DELETE",
      headers: authHeaders(),
    });
    if (!response.ok) throw new Error("Delete failed");
    await loadDashboard();
    showToast("User deleted");
  } catch (error) {
    showToast("Failed to delete user");
  }
}

function syncSettingsUI() {
  renderSettingsGroup("behaviorSettings", "behavior");
  renderSettingsGroup("planSettings", "plans");
  renderSettingsGroup("limitSettings", "limits");
  renderPlanPreview();
  jsonEditor.value = JSON.stringify(currentSettings, null, 2);
}

function renderSettingsGroup(containerId, group) {
  const container = document.getElementById(containerId);
  container.innerHTML = Object.entries(SETTINGS_META)
    .filter(([, meta]) => meta.group === group)
    .map(([key, meta]) => {
      const value = currentSettings[key];
      const control = meta.type === "boolean"
        ? `<label class="switch"><input type="checkbox" data-key="${key}" ${value ? "checked" : ""}><span class="slider"></span></label>`
        : `<input type="${meta.type}" value="${value ?? ""}" data-key="${key}">`;
      return `
        <div class="setting-row">
          <div class="setting-copy">
            <strong>${meta.label}</strong>
            <span>${meta.hint}</span>
          </div>
          <div>${control}</div>
        </div>
      `;
    }).join("");

  container.querySelectorAll("[data-key]").forEach((input) => {
    input.addEventListener("change", (event) => {
      const key = event.target.dataset.key;
      currentSettings[key] = event.target.type === "checkbox" ? event.target.checked : Number(event.target.value);
      renderPlanPreview();
      jsonEditor.value = JSON.stringify(currentSettings, null, 2);
    });
  });
}

function renderPlanPreview() {
  const plans = [
    ["Weekly", currentSettings.paywallWeekly],
    ["Monthly", currentSettings.paywallMonthly],
    ["Yearly", currentSettings.paywallYearly],
    ["Lifetime", currentSettings.paywallLifetime],
  ];
  document.getElementById("planPreview").innerHTML = plans.map(([label, active]) => `
    <span class="plan-chip ${active ? "active" : ""}">${label}</span>
  `).join("");
}

function handleJsonEditorInput() {
  try {
    currentSettings = JSON.parse(jsonEditor.value);
    syncSettingsUI();
    jsonEditor.style.borderColor = "";
  } catch (error) {
    jsonEditor.style.borderColor = "rgba(248,113,113,0.7)";
  }
}

function formatJsonEditor() {
  try {
    currentSettings = JSON.parse(jsonEditor.value);
    syncSettingsUI();
  } catch (error) {
    showToast("Fix the JSON first");
  }
}

async function saveSettings() {
  try {
    const response = await fetch(`${API_BASE}/admin/settings`, {
      method: "POST",
      headers: authHeaders({ "Content-Type": "application/json" }),
      body: JSON.stringify(currentSettings),
    });
    const data = await response.json();
    if (!response.ok || !data.success) throw new Error("save failed");
    currentSettings = data.settings;
    syncSettingsUI();
    showInlineAlert("settingsAlert", "Settings saved", true);
    showToast("Settings saved");
  } catch (error) {
    showInlineAlert("settingsAlert", "Failed to save settings", false);
  }
}

async function resetSettings() {
  if (!window.confirm("Reset settings to defaults?")) return;
  try {
    const response = await fetch(`${API_BASE}/admin/settings/reset`, {
      method: "POST",
      headers: authHeaders(),
    });
    const data = await response.json();
    if (!response.ok || !data.success) throw new Error("reset failed");
    currentSettings = data.settings;
    syncSettingsUI();
    showInlineAlert("settingsAlert", "Defaults restored", true);
  } catch (error) {
    showInlineAlert("settingsAlert", "Failed to reset settings", false);
  }
}

function showInlineAlert(id, message, success) {
  const el = document.getElementById(id);
  el.className = `alert ${success ? "alert-success" : "alert-error"}`;
  el.style.display = "block";
  el.textContent = message;
}

function clearAllFilters() {
  activeFunnel = null;
  activeStatusFilters.clear();
  activePlanFilters.clear();
  activeCountryFilters.clear();
  activeJourneyFilters.clear();
  activeFeatureFilters.clear();
  renderFunnelButtons();
  renderUserFilters();
  renderUsersTable();
}

function presetToDates(preset) {
  const now = new Date();
  const startOfDay = (date) => new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const endOfDay = (date) => new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);

  let start = null;
  let end = null;

  switch (preset) {
    case "today":
      start = startOfDay(now);
      end = endOfDay(now);
      break;
    case "yesterday": {
      const date = new Date(now);
      date.setDate(date.getDate() - 1);
      start = startOfDay(date);
      end = endOfDay(date);
      break;
    }
    case "last7":
      start = startOfDay(new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6));
      end = endOfDay(now);
      break;
    case "last30":
      start = startOfDay(new Date(now.getFullYear(), now.getMonth(), now.getDate() - 29));
      end = endOfDay(now);
      break;
    case "thisMonth":
      start = new Date(now.getFullYear(), now.getMonth(), 1);
      end = endOfDay(now);
      break;
    case "lastMonth":
      start = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      end = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);
      break;
    case "thisYear":
      start = new Date(now.getFullYear(), 0, 1);
      end = endOfDay(now);
      break;
    case "all":
    default:
      break;
  }

  return {
    startDate: start ? toDateOnly(start) : null,
    endDate: end ? toDateOnly(end) : null,
  };
}

function toDateOnly(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

function badgeClass(status) {
  return (status || "unknown").replaceAll(" ", "_");
}

function shortId(value) {
  if (!value) return "—";
  return value.length > 18 ? `${value.slice(0, 8)}...${value.slice(-4)}` : value;
}

function shortProps(properties) {
  const entries = Object.entries(properties || {}).filter(([, value]) => value !== null && value !== "");
  return entries.slice(0, 3).map(([key, value]) => `${key}:${value}`).join(" • ");
}

function formatMoney(value, digits = 2) {
  return Number(value || 0).toFixed(digits);
}

function formatDate(value) {
  if (!value) return "—";
  try {
    return new Date(value).toLocaleString();
  } catch (error) {
    return value;
  }
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function escapeAttr(value) {
  return escapeHtml(value).replaceAll("`", "&#096;");
}

function showToast(message) {
  toast.textContent = message;
  toast.classList.add("show");
  setTimeout(() => toast.classList.remove("show"), 2600);
}
