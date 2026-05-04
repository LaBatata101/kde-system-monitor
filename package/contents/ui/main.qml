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
    property real cpuClockMHz: 0
    property var cpuCoreClocks: ({})
    property var cpuCores: []
    property var cpuHistory: []
    property var topProcesses: []

    property real ramTotal: 0
    property real ramUsed: 0
    property real ramFree: 0
    property real ramCached: 0
    property real swapTotal: 0
    property real swapUsed: 0
    property var ramHistory: []
    property var ramTopProcesses: []

    property string netUploadSpeed: "0 B/s"
    property string netDownloadSpeed: "0 B/s"
    property string netUploadCompactSpeed: "0   B/s"
    property string netDownloadCompactSpeed: "0   B/s"
    property real netUploadRaw: 0
    property real netDownloadRaw: 0
    property var netHistory: []

    property var storageDevices: []
    property string storageReadSpeed: "0 B/s"
    property string storageWriteSpeed: "0 B/s"
    property real storageReadRaw: 0
    property real storageWriteRaw: 0
    property var storageHistory: []
    property var storageBlockDevices: []
    property var temperatures: []
    property string systemUptime: ""
    property var gpus: []
    property int selectedSection: -1

    //  Internal state 
    property var _cpuPrev: ({})
    property var _netPrev: ({rx: 0, tx: 0, time: 0})
    property var _diskPrev: ({read: 0, write: 0, time: 0})
    readonly property string _topProcessesCommand: "ps -eo pcpu=,comm= --sort=-pcpu 2>/dev/null | awk '$2 !~ /^(ps|awk|sh|bash|dash|zsh)$/ { print; count++; if (count == 5) exit }'"
    readonly property string _ramTopProcessesCommand: "ps -eo rss=,pmem=,comm= --sort=-rss 2>/dev/null | awk '$3 !~ /^(ps|awk|sh|bash|dash|zsh)$/ { print; count++; if (count == 5) exit }'"

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
        if (expanded && selectedSection === sectionIndex) {
            expanded = false
            return
        }

        selectedSection = sectionIndex
        expanded = true
    }

    function compactToolTipTitle(sectionKey) {
        switch (sectionKey) {
        case "cpu": return "CPU"
        case "ram": return "RAM"
        case "network": return "Network"
        case "storage": return "Storage"
        case "temps": return "Temperatures"
        }
        return "System Monitor"
    }

    function compactToolTipSummary(sectionKey) {
        switch (sectionKey) {
        case "cpu":
            return "Usage " + formatPercent(cpuTotal)
                + " (user " + formatPercent(cpuUser)
                + ", system " + formatPercent(cpuSystem) + ")"
                + " @ " + cpuClockText()
        case "ram":
            return ramTotal > 0
                ? "Used " + formatMemoryMib(ramUsed) + " / " + formatMemoryMib(ramTotal)
                    + " (" + formatPercent(ramUsed / ramTotal * 100) + ")"
                : "Memory usage unavailable"
        case "network":
            return "Up " + netUploadSpeed + ", down " + netDownloadSpeed
        case "storage":
            return storageDevices.length > 0
                ? storageDevices[0].used + " / " + storageDevices[0].size + " (" + storageDevices[0].percent + "%)"
                : "Storage usage unavailable"
        case "temps":
            return compactTemperaturesSummary()
        }
        return "CPU, RAM, Network, Storage and Temperatures"
    }

    function openSystemResourceMonitor() {
        exe.connectSource("kstart plasma-systemmonitor")
    }

    function openConfigurationWindow() {
        var configureAction = Plasmoid.internalAction("configure")
        if (configureAction) {
            configureAction.trigger()
        } else {
            Plasmoid.requestConfiguration()
        }
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

    function formatMemoryKib(kib) {
        if (kib < 1024) return kib.toFixed(0) + " KB"
        if (kib < 1048576) return (kib / 1024).toFixed(kib < 10240 ? 1 : 0) + " MB"
        return (kib / 1048576).toFixed(1) + " GB"
    }

    function formatMemoryMib(mib) {
        if (mib < 1024) return mib.toFixed(mib < 100 ? 1 : 0) + " MB"
        return (mib / 1024).toFixed(1) + " GB"
    }

    function formatPercent(percent) {
        return percent < 1 ? percent.toFixed(1) + "%" : percent.toFixed(0) + "%"
    }

    function formatCpuClock(mhz) {
        if (mhz <= 0) return ""
        if (mhz < 1000) return mhz.toFixed(0) + " MHz"
        return (mhz / 1000).toFixed(2) + " GHz"
    }

    function cpuClockText() {
        return formatCpuClock(cpuClockMHz) || "unavailable"
    }

    function cpuCoreClockText(coreName) {
        return formatCpuClock(cpuCoreClocks[coreName] || 0)
    }

    function formatStorageBytes(bytes) {
        if (bytes < 1024) return bytes.toFixed(0) + " B"
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB"
        if (bytes < 1099511627776) return (bytes / 1073741824).toFixed(1) + " GB"
        return (bytes / 1099511627776).toFixed(1) + " TB"
    }

    function compactTemperaturesSummary() {
        if (temperatures.length === 0) return "Temperature data unavailable"

        var hottest = temperatures[0]
        for (var i = 1; i < temperatures.length; i++) {
            if (temperatures[i].value > hottest.value) hottest = temperatures[i]
        }

        return hottest.label + ": " + hottest.value.toFixed(1) + " °C"
    }

    toolTipMainText: ""
    toolTipSubText: ""

    //  Executable data source 
    P5Support.DataSource {
        id: exe
        engine: "executable"
        connectedSources: []

        onNewData: function(src, data) {
            exe.disconnectSource(src)
            var out = data["stdout"] || ""
            if (src.indexOf("/proc/stat") !== -1)          parseCpuStat(out)
            else if (src.indexOf("/proc/diskstats") !== -1) parseDiskStats(out)
            else if (src.indexOf("/proc/meminfo") !== -1)  parseMemInfo(out)
            else if (src.indexOf("/proc/net/dev") !== -1)  parseNetDev(out)
            else if (src.indexOf("df ") !== -1)            parseDf(out)
            else if (src.indexOf("lsblk -J") !== -1)       parseBlockDevices(out)
            else if (src.indexOf("sensors") !== -1)        parseSensors(out)
            else if (src.indexOf("uptime") !== -1)         systemUptime = out.trim().replace(/^up\s+/, "")
            else if (src.indexOf("lspci") !== -1)          parseGpu(out)
            else if (src.indexOf("/proc/cpuinfo") !== -1)  parseCpuInfo(out)
            else if (src.indexOf("pcpu=") !== -1)          parseProcs(out)
            else if (src.indexOf("rss=") !== -1)           parseRamProcs(out)
        }
    }

    // Timers 
    Timer {
        interval: Math.max(500, plasmoid.configuration.updateInterval)
        running: true
        repeat: true
        onTriggered: {
            exe.connectSource("cat /proc/stat")
            exe.connectSource("cat /proc/cpuinfo")
            exe.connectSource("cat /proc/net/dev")
            exe.connectSource("cat /proc/diskstats")
            exe.connectSource(_topProcessesCommand)
        }
    }

    Timer {
        interval: Math.max(500, plasmoid.configuration.updateInterval)
        running: true
        repeat: true
        onTriggered: {
            exe.connectSource("cat /proc/meminfo")
            exe.connectSource("df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep '^/dev'")
            exe.connectSource("lsblk -J -b -o NAME,SIZE,TYPE,MODEL,TRAN,RM 2>/dev/null")
            exe.connectSource("sensors 2>/dev/null || echo ''")
            exe.connectSource("uptime -p 2>/dev/null || uptime")
            exe.connectSource(_ramTopProcessesCommand)
        }
    }

    Timer {
        interval: 30000; running: true; repeat: false
        onTriggered: {
            exe.connectSource("lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | sed 's/.*: //'")
        }
    }

    Component.onCompleted: {
        exe.connectSource("cat /proc/stat")
        exe.connectSource("cat /proc/diskstats")
        exe.connectSource(_topProcessesCommand)
        exe.connectSource("cat /proc/meminfo")
        exe.connectSource(_ramTopProcessesCommand)
        exe.connectSource("lsblk -J -b -o NAME,SIZE,TYPE,MODEL,TRAN,RM 2>/dev/null")
        exe.connectSource("cat /proc/cpuinfo")
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

        var hist = ramHistory.slice()
        hist.push(ramTotal > 0 ? Math.max(0, Math.min(1, ramUsed / ramTotal)) : 0)
        if (hist.length > 60) hist.shift()
        ramHistory = hist
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
                if (mnt === "/" || mnt.startsWith("/home") || mnt.startsWith("/mnt") || mnt.startsWith("/media") || mnt.startsWith("/run/media")) {
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

    function parseBlockDevices(raw) {
        var devs = []
        try {
            var parsed = JSON.parse(raw)
            var blockDevices = parsed.blockdevices || []

            function usageForNode(node) {
                var path = "/dev/" + node.name
                for (var i = 0; i < storageDevices.length; i++) {
                    if (storageDevices[i].device === path) return storageDevices[i]
                }

                var children = node.children || []
                for (var j = 0; j < children.length; j++) {
                    var childUsage = usageForNode(children[j])
                    if (childUsage) return childUsage
                }

                return null
            }

            blockDevices.forEach(function(device) {
                if (device.type !== "disk" || device.name.indexOf("zram") === 0) return

                var model = (device.model || "").trim()
                var transport = (device.tran || "").trim()
                var removable = device.rm === true
                var usage = usageForNode(device)
                devs.push({
                    name: model || device.name,
                    path: "/dev/" + device.name,
                    size: formatStorageBytes(parseFloat(device.size) || 0),
                    detail: (transport ? transport.toUpperCase() : "Disk") + (removable ? " • Removable" : ""),
                    hasUsage: usage !== null,
                    used: usage ? usage.used : "",
                    usageSize: usage ? usage.size : formatStorageBytes(parseFloat(device.size) || 0),
                    percent: usage ? usage.percent : 0
                })
            })
        } catch (e) {
            devs = []
        }
        storageBlockDevices = devs
    }

    function isWholeDiskDevice(name) {
        return name.match(/^(sd[a-z]+|vd[a-z]+|xvd[a-z]+|hd[a-z]+|nvme\d+n\d+|mmcblk\d+|md\d+)$/) !== null
    }

    function parseDiskStats(raw) {
        var now = Date.now()
        var readBytes = 0
        var writeBytes = 0

        raw.split("\n").forEach(function(line) {
            var parts = line.trim().split(/\s+/)
            if (parts.length < 10) return

            var name = parts[2]
            if (!isWholeDiskDevice(name)) return

            readBytes += (parseInt(parts[5]) || 0) * 512
            writeBytes += (parseInt(parts[9]) || 0) * 512
        })

        var dt = _diskPrev.time > 0 ? (now - _diskPrev.time) / 1000 : 1
        var readRate = _diskPrev.time > 0 ? Math.max(0, (readBytes - _diskPrev.read) / dt) : 0
        var writeRate = _diskPrev.time > 0 ? Math.max(0, (writeBytes - _diskPrev.write) / dt) : 0
        _diskPrev = {read: readBytes, write: writeBytes, time: now}

        storageReadRaw = readRate
        storageWriteRaw = writeRate
        storageReadSpeed = formatRate(readRate)
        storageWriteSpeed = formatRate(writeRate)

        var hist = storageHistory.slice()
        hist.push({read: readRate, write: writeRate})
        if (hist.length > 60) hist.shift()
        storageHistory = hist
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

    function parseCpuInfo(raw) {
        var model = ""
        var currentCore = ""
        var clocks = {}
        var clockTotal = 0
        var clockCount = 0

        raw.split("\n").forEach(function(line) {
            var processorMatch = line.match(/^processor\s*:\s*(\d+)/)
            if (processorMatch) {
                currentCore = "cpu" + processorMatch[1]
                return
            }

            var modelMatch = line.match(/^model name\s*:\s*(.+)$/)
            if (modelMatch && !model) {
                model = modelMatch[1].trim()
                return
            }

            var clockMatch = line.match(/^cpu MHz\s*:\s*([\d.]+)/)
            if (clockMatch) {
                var clock = parseFloat(clockMatch[1]) || 0
                if (clock > 0) {
                    var coreName = currentCore || ("cpu" + clockCount)
                    clocks[coreName] = clock
                    clockTotal += clock
                    clockCount++
                }
            }
        })

        if (model) cpuModel = model
        if (clockCount > 0) {
            cpuClockMHz = clockTotal / clockCount
            cpuCoreClocks = clocks
        }
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

    function parseRamProcs(raw) {
        var procs = []
        raw.trim().split("\n").forEach(function(line) {
            var parts = line.trim().split(/\s+/)
            if (parts.length >= 3) {
                var rssKib = parseFloat(parts[0]) || 0
                procs.push({
                    memory: parseFloat(parts[1]) || 0,
                    memoryValue: formatMemoryKib(rssKib),
                    name: parts.slice(2).join(" ")
                })
            }
        })
        ramTopProcesses = procs
    }

    // Representations 
    compactRepresentation: CompactView {}
    fullRepresentation: FullView {}
}
