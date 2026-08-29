function emptyStatus() {
  return {
    isDuo: false,
    vendor: "",
    product: "",
    family: "",
    lower: null,
    upper: null,
    mode: "unknown",
    lastMode: "",
    savedMode: "",
    saved: false,
    touchpadSliders: true,
    sliderDevice: "",
    loginFixed: false,
    loginFixNeedsReboot: false
  }
}

function parseStatus(raw) {
  var status = emptyStatus()
  try {
    var parsed = raw ? JSON.parse(String(raw)) : null
    if (!parsed || typeof parsed !== "object") return status
    status.isDuo = parsed.isDuo === true
    status.vendor = parsed.vendor || ""
    status.product = parsed.product || ""
    status.family = parsed.family || ""
    status.lower = parsed.lower || null
    status.upper = parsed.upper || null
    status.mode = parsed.mode || "unknown"
    status.lastMode = parsed.lastMode || ""
    status.savedMode = parsed.savedMode || ""
    status.saved = parsed.saved === true
    status.touchpadSliders = parsed.touchpadSliders !== false
    status.sliderDevice = parsed.sliderDevice || ""
    status.loginFixed = parsed.loginFixed === true
    status.loginFixNeedsReboot = parsed.loginFixNeedsReboot === true
    return status
  } catch (e) {
    return status
  }
}

function modes() {
  return [
    {
      id: "dual",
      label: "Dual laptop",
      detail: "Both OLEDs, stacked, main screen rotated 180°",
      icon: "󰍺"
    },
    {
      id: "lower",
      label: "Lower only",
      detail: "Main display, lid screen off",
      icon: "󰍹"
    }
  ]
}

function modeLabel(id) {
  var list = modes()
  for (var i = 0; i < list.length; i++) {
    if (list[i].id === id) return list[i].label
  }
  return "Unknown"
}

function modeIndex(id) {
  var list = modes()
  for (var i = 0; i < list.length; i++) {
    if (list[i].id === id) return i
  }
  return 0
}

function loginFixExplanation() {
  return [
    "The lower OLED is mounted upside down. The session and lock screen already compensate; the login path does not.",
    "After logout, this writes an SDDM greeter config that rotates the lower OLED 180° and matches scale on both panels.",
    "The first screen after a reboot is the stock Omarchy disk-unlock splash. That cannot be rotated per-display without breaking the session pointer, so it stays default: lower inverted, lid upright.",
    "You will be asked for your password. If a custom boot splash is still installed, this restores the default and rebuilds the UKI once (that can take a minute). Later applies only update the logout greeter."
  ]
}

function parseProgressLine(line) {
  var s = String(line || "")
  var prefix = "GPDDUO_PROGRESS\t"
  if (s.indexOf(prefix) !== 0) return null
  try {
    var parsed = JSON.parse(s.slice(prefix.length))
    if (!parsed || typeof parsed !== "object") return null
    var pct = Number(parsed.pct)
    if (!isFinite(pct)) pct = 0
    if (pct < 0) pct = 0
    if (pct > 100) pct = 100
    return {
      step: parsed.step || "",
      label: parsed.label || "",
      pct: pct
    }
  } catch (e) {
    return null
  }
}

function monitorLine(mon, role) {
  if (!mon || !mon.name) return role + ": not found"
  var bits = [mon.name]
  if (mon.disabled) bits.push("off")
  else {
    bits.push(mon.width + "×" + mon.height)
    if (Number(mon.transform) === 2) bits.push("180°")
    else if (Number(mon.transform) === 1) bits.push("90°")
    else if (Number(mon.transform) === 3) bits.push("270°")
  }
  return role + " · " + bits.join(" · ")
}

if (typeof module !== "undefined") {
  module.exports = {
    emptyStatus: emptyStatus,
    parseStatus: parseStatus,
    modes: modes,
    modeLabel: modeLabel,
    modeIndex: modeIndex,
    monitorLine: monitorLine,
    parseProgressLine: parseProgressLine,
    loginFixExplanation: loginFixExplanation
  }
}
