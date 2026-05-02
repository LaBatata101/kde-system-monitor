import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation

    //  Exposed data 
    property real cpuTotal: 0
    property real cpuUser: 0
    property real cpuSystem: 0
    property string cpuModel: ""
    property var cpuCores: []
    property var cpuHistory: []
    property var topProcesses: []

    property real ramTotal: 0
    property real ramUsed: 0
    property real ramFree: 0
    property real ramCached: 0
    property real swapTotal: 0
    property real swapUsed: 0

    property string netUploadSpeed: "0 B/s"
    property string netDownloadSpeed: "0 B/s"
    property string netUploadCompactSpeed: "0   B/s"
    property string netDownloadCompactSpeed: "0   B/s"
    property real netUploadRaw: 0
    property real netDownloadRaw: 0
    property var netHistory: []

    property var storageDevices: []
    property var temperatures: []
    property string systemUptime: ""
    property var gpus: []
    property int selectedSection: -1

    //  Internal state 
    property var _cpuPrev: ({})
    property var _netPrev: ({rx: 0, tx: 0, time: 0})

    //  Helpers 
    readonly property color themeHoverColor: withAlpha(Kirigami.Theme.textColor, 0.06)
    readonly property color themeTrackColor: withAlpha(Kirigami.Theme.textColor, 0.12)
    readonly property color themeFaintTrackColor: withAlpha(Kirigami.Theme.textColor, 0.05)
    readonly property color themeBorderColor: withAlpha(Kirigami.Theme.textColor, 0.35)
    readonly property color themeGraphBackgroundColor: withAlpha(Kirigami.Theme.textColor, 0.08)
    readonly property color themeGraphGridColor: withAlpha(Kirigami.Theme.textColor, 0.12)
    readonly property color themeGraphLabelColor: withAlpha(Kirigami.Theme.textColor, 0.55)
    readonly property color themePlaceholderTextColor: withAlpha(Kirigami.Theme.textColor, 0.35)
    readonly property color themeBarLabelColor: Kirigami.Theme.highlightedTextColor

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    function openSection(sectionIndex) {
        selectedSection = sectionIndex
        expanded = true
    }

    function formatRate(bytes) {
        if (bytes < 1024)       return bytes.toFixed(0) + " B/s"
        if (bytes < 1048576)    return (bytes / 1024).toFixed(1) + " KB/s"
        return (bytes / 1048576).toFixed(1) + " MB/s"
    }

    function formatCompactRate(bytes) {
        if (bytes < 1024) {
            var value = bytes.toFixed(0)
            var padding = ""
            for (var i = value.length; i < 4; i++) padding += " "
            return value + padding + "B/s"
        }
        if (bytes < 1048576)    return (bytes / 1024).toFixed(0) + " KB/s"
        return (bytes / 1048576).toFixed(1) + " MB/s"
    }

    //  Executable data source 
    P5Support.DataSource {
        id: exe
        engine: "executable"
        connectedSources: []

        onNewData: function(src, data) {
            exe.disconnectSource(src)
            var out = data["stdout"] || ""
            if (src.indexOf("/proc/stat") !== -1)          parseCpuStat(out)
            else if (src.indexOf("/proc/meminfo") !== -1)  parseMemInfo(out)
            else if (src.indexOf("/proc/net/dev") !== -1)  parseNetDev(out)
            else if (src.indexOf("df ") !== -1)            parseDf(out)
            else if (src.indexOf("sensors") !== -1)        parseSensors(out)
            else if (src.indexOf("uptime") !== -1)         systemUptime = out.trim().replace(/^up\s+/, "")
            else if (src.indexOf("lspci") !== -1)          parseGpu(out)
            else if (src.indexOf("/proc/cpuinfo") !== -1)  parseCpuModel(out)
            else if (src.indexOf("ps ") !== -1)            parseProcs(out)
        }
    }

    // Timers 
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            exe.connectSource("cat /proc/stat")
            exe.connectSource("cat /proc/net/dev")
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: {
            exe.connectSource("cat /proc/meminfo")
            exe.connectSource("df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep '^/dev'")
            exe.connectSource("sensors 2>/dev/null || echo ''")
            exe.connectSource("uptime -p 2>/dev/null || uptime")
            exe.connectSource("ps -eo pcpu,comm --sort=-pcpu 2>/dev/null | head -6 | tail -5")
        }
    }

    Timer {
        interval: 30000; running: true; repeat: false
        onTriggered: {
            exe.connectSource("cat /proc/cpuinfo 2>/dev/null | grep 'model name' | head -1 | cut -d: -f2")
            exe.connectSource("lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | sed 's/.*: //'")
        }
    }

    Component.onCompleted: {
        exe.connectSource("cat /proc/stat")
        exe.connectSource("cat /proc/cpuinfo 2>/dev/null | grep 'model name' | head -1 | cut -d: -f2")
        exe.connectSource("lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | sed 's/.*: //'")
    }

    //  Parsers 
    function parseCpuStat(raw) {
        var lines = raw.trim().split("\n")
        var cores = []

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (!line.startsWith("cpu")) break

            var parts = line.split(/\s+/)
            var name  = parts[0]
            var user  = parseInt(parts[1]) || 0
            var nice  = parseInt(parts[2]) || 0
            var sys   = parseInt(parts[3]) || 0
            var idle  = parseInt(parts[4]) || 0
            var iowt  = parseInt(parts[5]) || 0
            var irq   = parseInt(parts[6]) || 0
            var sirq  = parseInt(parts[7]) || 0

            var total  = user + nice + sys + idle + iowt + irq + sirq
            var active = user + nice + sys + irq + sirq
            var prev   = _cpuPrev[name]

            if (prev) {
                var dt  = total - prev.total
                if (dt > 0) {
                    var pct     = (active - prev.active) / dt * 100
                    var pctUser = (user + nice - prev.user - prev.nice) / dt * 100
                    var pctSys  = (sys - prev.sys) / dt * 100

                    if (name === "cpu") {
                        cpuTotal  = Math.max(0, Math.min(100, pct))
                        cpuUser   = Math.max(0, Math.min(100, pctUser))
                        cpuSystem = Math.max(0, Math.min(100, pctSys))
                        var hist = cpuHistory.slice()
                        hist.push(cpuTotal / 100)
                        if (hist.length > 60) hist.shift()
                        cpuHistory = hist
                    } else {
                        cores.push({
                            name:   name,
                            usage:  Math.max(0, Math.min(100, pct)),
                            user:   Math.max(0, Math.min(100, pctUser)),
                            system: Math.max(0, Math.min(100, pctSys))
                        })
                    }
                }
            } else if (name !== "cpu") {
                cores.push({ name: name, usage: 0, user: 0, system: 0 })
            }

            var updated = Object.assign({}, _cpuPrev)
            updated[name] = {total: total, active: active, user: user, nice: nice, sys: sys}
            _cpuPrev = updated
        }

        if (cores.length > 0) cpuCores = cores
    }

    function parseMemInfo(raw) {
        var info = {}
        raw.split("\n").forEach(function(line) {
            var m = line.match(/^(\S+):\s+(\d+)/)
            if (m) info[m[1]] = parseInt(m[2])
        })
        ramTotal  = (info["MemTotal"]     || 0) / 1024
        var free  = (info["MemFree"]      || 0) / 1024
        var buf   = (info["Buffers"]      || 0) / 1024
        var cache = (info["Cached"]       || 0) / 1024
        var srec  = (info["SReclaimable"] || 0) / 1024
        var shmem = (info["Shmem"]        || 0) / 1024
        ramCached = cache + srec - shmem
        ramFree   = free + buf + ramCached
        ramUsed   = ramTotal - ramFree
        swapTotal = (info["SwapTotal"] || 0) / 1024
        swapUsed  = swapTotal - (info["SwapFree"] || 0) / 1024
    }

    function parseNetDev(raw) {
        var now = Date.now()
        var totalRx = 0, totalTx = 0
        raw.split("\n").forEach(function(line) {
            // /proc/net/dev: iface: rx_bytes ... tx_bytes
            // Column layout: iface, rx_bytes(1), rx_pkts(2)...rx_8(8), tx_bytes(9)
            var m = line.match(/^\s*([^:]+):\s*(\d+)(?:\s+\d+){7}\s+(\d+)/)
            if (m) {
                var iface = m[1].trim()
                if (iface !== "lo") {
                    totalRx += parseInt(m[2]) || 0
                    totalTx += parseInt(m[3]) || 0
                }
            }
        })

        var dt = _netPrev.time > 0 ? (now - _netPrev.time) / 1000 : 1
        var rxRate = _netPrev.time > 0 ? Math.max(0, (totalRx - _netPrev.rx) / dt) : 0
        var txRate = _netPrev.time > 0 ? Math.max(0, (totalTx - _netPrev.tx) / dt) : 0
        _netPrev = {rx: totalRx, tx: totalTx, time: now}

        netDownloadRaw  = rxRate
        netUploadRaw    = txRate
        netDownloadSpeed = formatRate(rxRate)
        netUploadSpeed   = formatRate(txRate)
        netDownloadCompactSpeed = formatCompactRate(rxRate)
        netUploadCompactSpeed   = formatCompactRate(txRate)

        var maxRate = Math.max(rxRate, txRate, 1024)
        var hist = netHistory.slice()
        hist.push({rx: rxRate / maxRate, tx: txRate / maxRate})
        if (hist.length > 60) hist.shift()
        netHistory = hist
    }

    function parseDf(raw) {
        var devs = []
        var lines = raw.trim().split("\n")
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].trim().split(/\s+/)
            if (parts.length >= 6) {
                var mnt = parts[5]
                if (mnt === "/" || mnt.startsWith("/home") || mnt.startsWith("/mnt") || mnt.startsWith("/media")) {
                    devs.push({
                        device:  parts[0],
                        size:    parts[1],
                        used:    parts[2],
                        avail:   parts[3],
                        percent: parseInt(parts[4]) || 0,
                        mount:   mnt
                    })
                }
            }
        }
        storageDevices = devs
    }

    function parseSensors(raw) {
        var temps = []
        var section = ""
        raw.split("\n").forEach(function(line) {
            // Section header: line starts at col 0, no °C symbol
            if (line.match(/^[A-Za-z0-9]/) && !line.includes("°C")) {
                section = line.split(":")[0].trim()
                return
            }
            var m = line.match(/^([^:]+):\s+[+-]?([\d.]+)°C/)
            if (m) {
                var label = (section ? section + "/" : "") + m[1].trim()
                temps.push({label: label, value: parseFloat(m[2])})
            }
        })
        if (temps.length > 0) temperatures = temps
    }

    function parseGpu(raw) {
        var list = []
        raw.trim().split("\n").forEach(function(line) {
            if (line.trim()) list.push(line.trim())
        })
        gpus = list
    }

    function parseCpuModel(raw) {
        cpuModel = raw.trim()
    }

    function parseProcs(raw) {
        var procs = []
        raw.trim().split("\n").forEach(function(line) {
            var parts = line.trim().split(/\s+/)
            if (parts.length >= 2) {
                procs.push({cpu: parseFloat(parts[0]) || 0, name: parts.slice(1).join(" ")})
            }
        })
        topProcesses = procs
    }

    // Representations 
    compactRepresentation: CompactView {}
    fullRepresentation: FullView {}
}
