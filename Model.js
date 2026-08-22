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
    sliderDevice: ""
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
    monitorLine: monitorLine
  }
}
