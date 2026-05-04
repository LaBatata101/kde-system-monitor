import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

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
    property string gpuName: ""
    property real gpuUsage: 0
    property real gpuClockMHz: 0
    property real gpuTemperature: 0
    property real gpuMemoryUsedMiB: 0
    property real gpuMemoryTotalMiB: 0
    property var gpuDevices: []
    property var gpuProcesses: []
    property var gpuHistory: []
    property int selectedSection: -1
    //  Internal state
    property var _cpuPrev: ({})
    property var _netPrev: ({
            "rx": 0,
            "tx": 0,
            "time": 0
        })
    property var _diskPrev: ({
            "read": 0,
            "write": 0,
            "time": 0
        })
    property var _nvidiaGpuDevices: []
    property var _sysfsGpuDevices: []
    property var _nvidiaGpuProcesses: []
    property var _drmGpuProcesses: []
    property var _gpuHistories: ({})
    readonly property string _topProcessesCommand: "ps -eo pcpu=,comm= --sort=-pcpu 2>/dev/null | awk '$2 !~ /^(ps|awk|sh|bash|dash|zsh)$/ { print; count++; if (count == 5) exit }'"
    readonly property string _ramTopProcessesCommand: "ps -eo rss=,pmem=,comm= --sort=-rss 2>/dev/null | awk '$3 !~ /^(ps|awk|sh|bash|dash|zsh)$/ { print; count++; if (count == 5) exit }'"
    readonly property string _nvidiaGpuCommand: "command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-gpu=name,utilization.gpu,clocks.current.graphics,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null"
    readonly property string _nvidiaGpuProcessesCommand: "command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader,nounits 2>/dev/null"
    readonly property string _drmGpuProcessesCommand: "for p in /proc/[0-9]*; do pid=${p##*/}; name=$(cat \"$p/comm\" 2>/dev/null); mem=$(awk 'function flush() { if (vram > 0) { if (cid != \"\") { if (!(cid in seen)) { total += vram; seen[cid] = 1 } } else { total += vram } } cid = \"\"; vram = 0 } FILENAME != file { flush(); file = FILENAME } /^drm-client-id:/ { cid = $2 } /^drm-memory-vram:/ { vram += $2 } END { flush(); if (total > 0) printf \"%.1f\", total / 1024 }' \"$p\"/fdinfo/* 2>/dev/null); if [ -n \"$mem\" ]; then echo \"$pid,$name,$mem\"; fi; done | sort -t, -k3,3nr | head -5"
    readonly property string _sysfsGpuCommand: "for d in /sys/class/drm/card*/device; do if [ -f \"$d/gpu_busy_percent\" ]; then card=$(basename $(dirname \"$d\")); pci=$(basename $(readlink -f \"$d\")); name=$(lspci -D -s \"$pci\" 2>/dev/null | sed 's/^[^ ]* //; s/.*: //'); busy=$(cat \"$d/gpu_busy_percent\" 2>/dev/null); clock=\"\"; if [ -f \"$d/gt_cur_freq_mhz\" ]; then clock=$(cat \"$d/gt_cur_freq_mhz\" 2>/dev/null); elif [ -f \"$d/pp_dpm_sclk\" ]; then clock=$(grep '\\*' \"$d/pp_dpm_sclk\" 2>/dev/null | sed 's/.*: *//; s/[mM][hH][zZ].*//'); fi; temp=\"\"; for h in \"$d\"/hwmon/hwmon*; do if [ -f \"$h/temp1_input\" ]; then temp=$(cat \"$h/temp1_input\" 2>/dev/null); temp=$((temp / 1000)); break; fi; done; vramUsed=\"\"; vramTotal=\"\"; if [ -f \"$d/mem_info_vram_used\" ]; then vramUsed=$(cat \"$d/mem_info_vram_used\" 2>/dev/null); vramUsed=$((vramUsed / 1048576)); fi; if [ -f \"$d/mem_info_vram_total\" ]; then vramTotal=$(cat \"$d/mem_info_vram_total\" 2>/dev/null); vramTotal=$((vramTotal / 1048576)); fi; echo \"$card|$pci|$name|$busy|$clock|$temp|$vramUsed|$vramTotal\"; fi; done"
    //  Helpers
    readonly property color themeHoverColor: root.withAlpha(Kirigami.Theme.textColor, 0.06)
    readonly property color themeTrackColor: root.withAlpha(Kirigami.Theme.textColor, 0.12)
    readonly property color themeFaintTrackColor: root.withAlpha(Kirigami.Theme.textColor, 0.05)
    readonly property color themeBorderColor: root.withAlpha(Kirigami.Theme.textColor, 0.35)
    readonly property color themeGraphBackgroundColor: root.withAlpha(Kirigami.Theme.textColor, 0.08)
    readonly property color themeGraphGridColor: root.withAlpha(Kirigami.Theme.textColor, 0.12)
    readonly property color themeGraphLabelColor: root.withAlpha(Kirigami.Theme.textColor, 0.55)
    readonly property color themePlaceholderTextColor: root.withAlpha(Kirigami.Theme.textColor, 0.35)
    readonly property color themeBarLabelColor: Kirigami.Theme.highlightedTextColor

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    function openSection(sectionIndex) {
        if (root.expanded && root.selectedSection === sectionIndex) {
            root.expanded = false;
            return;
        }
        root.selectedSection = sectionIndex;
        root.expanded = true;
    }

    function compactToolTipTitle(sectionKey) {
        switch (sectionKey) {
        case "cpu":
            return "CPU";
        case "ram":
            return "RAM";
        case "network":
            return "Network";
        case "storage":
            return "Storage";
        case "temps":
            return "Temperatures";
        case "gpu":
            return "GPU";
        }
        return "System Monitor";
    }

    function compactToolTipSummary(sectionKey) {
        switch (sectionKey) {
        case "cpu":
            return "Usage " + root.formatPercent(root.cpuTotal) + " (user " + root.formatPercent(root.cpuUser) + ", system " + root.formatPercent(root.cpuSystem) + ")" + " @ " + root.cpuClockText();
        case "ram":
            return root.ramTotal > 0 ? "Used " + root.formatMemoryMib(root.ramUsed) + " / " + root.formatMemoryMib(root.ramTotal) + " (" + root.formatPercent(root.ramUsed / root.ramTotal * 100) + ")" : "Memory usage unavailable";
        case "network":
            return "Up " + root.netUploadSpeed + ", down " + root.netDownloadSpeed;
        case "storage":
            return root.storageDevices.length > 0 ? root.storageDevices[0].used + " / " + root.storageDevices[0].size + " (" + root.storageDevices[0].percent + "%)" : "Storage usage unavailable";
        case "temps":
            return root.compactTemperaturesSummary();
        case "gpu":
            return root.gpuTooltipSummary();
        }
        return "CPU, RAM, GPU, Network, Storage and Temperatures";
    }

    function openSystemResourceMonitor() {
        exe.connectSource("kstart plasma-systemmonitor");
    }

    function openConfigurationWindow() {
        let configureAction = Plasmoid.internalAction("configure");
        if (configureAction)
            configureAction.trigger();
        else
            Plasmoid.requestConfiguration();
    }

    function formatRate(bytes) {
        if (bytes < 1024)
            return bytes.toFixed(0) + " B/s";

        if (bytes < 1.04858e+06)
            return (bytes / 1024).toFixed(1) + " KB/s";

        return (bytes / 1.04858e+06).toFixed(1) + " MB/s";
    }

    function formatCompactRate(bytes) {
        if (bytes < 1024) {
            const value = bytes.toFixed(0);
            let padding = "";
            for (let i = value.length; i < 4; i++)
                padding += " ";
            return value + padding + "B/s";
        }
        if (bytes < 1.04858e+06)
            return (bytes / 1024).toFixed(0) + " KB/s";

        return (bytes / 1.04858e+06).toFixed(1) + " MB/s";
    }

    function formatMemoryKib(kib) {
        if (kib < 1024)
            return kib.toFixed(0) + " KB";

        if (kib < 1.04858e+06)
            return (kib / 1024).toFixed(kib < 10240 ? 1 : 0) + " MB";

        return (kib / 1.04858e+06).toFixed(1) + " GB";
    }

    function formatMemoryMib(mib) {
        if (mib < 1024)
            return mib.toFixed(mib < 100 ? 1 : 0) + " MB";

        return (mib / 1024).toFixed(1) + " GB";
    }

    function formatPercent(percent) {
        return percent < 1 ? percent.toFixed(1) + "%" : percent.toFixed(0) + "%";
    }

    function formatCpuClock(mhz) {
        if (mhz <= 0)
            return "";

        if (mhz < 1000)
            return mhz.toFixed(0) + " MHz";

        return (mhz / 1000).toFixed(2) + " GHz";
    }

    function cpuClockText() {
        return root.formatCpuClock(root.cpuClockMHz) || "unavailable";
    }

    function cpuCoreClockText(coreName) {
        return root.formatCpuClock(root.cpuCoreClocks[coreName] || 0);
    }

    function gpuNameText() {
        if (root.gpuDevices.length > 1)
            return root.gpuDevices.length + " GPUs";

        return root.gpuName || (root.gpus.length > 0 ? root.gpus[0] : "GPU");
    }

    function gpuUsageText() {
        return root.gpuUsage >= 0 ? root.formatPercent(root.gpuUsage) : "unavailable";
    }

    function gpuClockText() {
        return root.formatCpuClock(root.gpuClockMHz) || "unavailable";
    }

    function gpuTemperatureText() {
        return root.gpuTemperature >= 0 ? root.gpuTemperature.toFixed(0) + " °C" : "unavailable";
    }

    function gpuMemoryText() {
        if (root.gpuMemoryTotalMiB <= 0)
            return "unavailable";

        return root.formatMemoryMib(root.gpuMemoryUsedMiB) + " / " + root.formatMemoryMib(root.gpuMemoryTotalMiB);
    }

    function gpuTooltipSummary() {
        return "Usage " + root.gpuUsageText() + " @ " + root.gpuClockText() + " | " + root.gpuTemperatureText();
    }

    function gpuDeviceUsageText(device) {
        return device && device.usage >= 0 ? root.formatPercent(device.usage) : "unavailable";
    }

    function gpuDeviceClockText(device) {
        return device ? (root.formatCpuClock(device.clockMHz || 0) || "unavailable") : "unavailable";
    }

    function gpuDeviceMemoryText(device) {
        if (!device || device.memoryTotalMiB <= 0)
            return "unavailable";

        return root.formatMemoryMib(device.memoryUsedMiB) + " / " + root.formatMemoryMib(device.memoryTotalMiB);
    }

    function gpuDeviceTemperatureText(device) {
        return device && device.temperature > 0 ? device.temperature.toFixed(0) + " °C" : "unavailable";
    }

    function formatStorageBytes(bytes) {
        if (bytes < 1024)
            return bytes.toFixed(0) + " B";

        if (bytes < 1.04858e+06)
            return (bytes / 1024).toFixed(1) + " KB";

        if (bytes < 1.07374e+09)
            return (bytes / 1.04858e+06).toFixed(1) + " MB";

        if (bytes < 1.09951e+12)
            return (bytes / 1.07374e+09).toFixed(1) + " GB";

        return (bytes / 1.09951e+12).toFixed(1) + " TB";
    }

    function compactTemperaturesSummary() {
        if (root.temperatures.length === 0)
            return "Temperature data unavailable";

        let hottest = root.temperatures[0];
        for (let i = 1; i < root.temperatures.length; i++) {
            if (root.temperatures[i].value > hottest.value)
                hottest = root.temperatures[i];
        }
        return hottest.label + ": " + hottest.value.toFixed(1) + " °C";
    }

    //  Parsers
    function parseCpuStat(raw) {
        let lines = raw.trim().split("\n");
        let cores = [];
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            if (!line.startsWith("cpu"))
                break;

            let parts = line.split(/\s+/);
            let name = parts[0];
            let user = parseInt(parts[1]) || 0;
            let nice = parseInt(parts[2]) || 0;
            let sys = parseInt(parts[3]) || 0;
            let idle = parseInt(parts[4]) || 0;
            let iowt = parseInt(parts[5]) || 0;
            let irq = parseInt(parts[6]) || 0;
            let sirq = parseInt(parts[7]) || 0;
            let total = user + nice + sys + idle + iowt + irq + sirq;
            let active = user + nice + sys + irq + sirq;
            let prev = root._cpuPrev[name];
            if (prev) {
                let dt = total - prev.total;
                if (dt > 0) {
                    let pct = (active - prev.active) / dt * 100;
                    let pctUser = (user + nice - prev.user - prev.nice) / dt * 100;
                    let pctSys = (sys - prev.sys) / dt * 100;
                    if (name === "cpu") {
                        root.cpuTotal = Math.max(0, Math.min(100, pct));
                        root.cpuUser = Math.max(0, Math.min(100, pctUser));
                        root.cpuSystem = Math.max(0, Math.min(100, pctSys));
                        let hist = root.cpuHistory.slice();
                        hist.push(root.cpuTotal / 100);
                        if (hist.length > 60)
                            hist.shift();

                        root.cpuHistory = hist;
                    } else {
                        cores.push({
                            "name": name,
                            "usage": Math.max(0, Math.min(100, pct)),
                            "user": Math.max(0, Math.min(100, pctUser)),
                            "system": Math.max(0, Math.min(100, pctSys))
                        });
                    }
                }
            } else if (name !== "cpu") {
                cores.push({
                    "name": name,
                    "usage": 0,
                    "user": 0,
                    "system": 0
                });
            }
            let updated = Object.assign({}, root._cpuPrev);
            updated[name] = {
                "total": total,
                "active": active,
                "user": user,
                "nice": nice,
                "sys": sys
            };
            root._cpuPrev = updated;
        }
        if (cores.length > 0)
            root.cpuCores = cores;
    }

    function parseMemInfo(raw) {
        let info = {};
        raw.split("\n").forEach(function (line) {
            let m = line.match(/^(\S+):\s+(\d+)/);
            if (m)
                info[m[1]] = parseInt(m[2]);
        });
        root.ramTotal = (info["MemTotal"] || 0) / 1024;
        let free = (info["MemFree"] || 0) / 1024;
        let buf = (info["Buffers"] || 0) / 1024;
        let cache = (info["Cached"] || 0) / 1024;
        let srec = (info["SReclaimable"] || 0) / 1024;
        let shmem = (info["Shmem"] || 0) / 1024;
        root.ramCached = cache + srec - shmem;
        root.ramFree = free + buf + root.ramCached;
        root.ramUsed = root.ramTotal - root.ramFree;
        root.swapTotal = (info["SwapTotal"] || 0) / 1024;
        root.swapUsed = root.swapTotal - (info["SwapFree"] || 0) / 1024;
        let hist = root.ramHistory.slice();
        hist.push(root.ramTotal > 0 ? Math.max(0, Math.min(1, root.ramUsed / root.ramTotal)) : 0);
        if (hist.length > 60)
            hist.shift();

        root.ramHistory = hist;
    }

    function parseNetDev(raw) {
        let now = Date.now();
        let totalRx = 0, totalTx = 0;
        raw.split("\n").forEach(function (line) {
            // /proc/net/dev: iface: rx_bytes ... tx_bytes
            // Column layout: iface, rx_bytes(1), rx_pkts(2)...rx_8(8), tx_bytes(9)
            let m = line.match(/^\s*([^:]+):\s*(\d+)(?:\s+\d+){7}\s+(\d+)/);
            if (m) {
                let iface = m[1].trim();
                if (iface !== "lo") {
                    totalRx += parseInt(m[2]) || 0;
                    totalTx += parseInt(m[3]) || 0;
                }
            }
        });
        let dt = root._netPrev.time > 0 ? (now - root._netPrev.time) / 1000 : 1;
        let rxRate = root._netPrev.time > 0 ? Math.max(0, (totalRx - root._netPrev.rx) / dt) : 0;
        let txRate = root._netPrev.time > 0 ? Math.max(0, (totalTx - root._netPrev.tx) / dt) : 0;
        root._netPrev = {
            "rx": totalRx,
            "tx": totalTx,
            "time": now
        };
        root.netDownloadRaw = rxRate;
        root.netUploadRaw = txRate;
        root.netDownloadSpeed = root.formatRate(rxRate);
        root.netUploadSpeed = root.formatRate(txRate);
        root.netDownloadCompactSpeed = root.formatCompactRate(rxRate);
        root.netUploadCompactSpeed = root.formatCompactRate(txRate);
        let maxRate = Math.max(rxRate, txRate, 1024);
        let hist = root.netHistory.slice();
        hist.push({
            "rx": rxRate / maxRate,
            "tx": txRate / maxRate
        });
        if (hist.length > 60)
            hist.shift();

        root.netHistory = hist;
    }

    function parseDf(raw) {
        let devs = [];
        let lines = raw.trim().split("\n");
        for (let i = 0; i < lines.length; i++) {
            let parts = lines[i].trim().split(/\s+/);
            if (parts.length >= 6) {
                let mnt = parts[5];
                if (mnt === "/" || mnt.startsWith("/home") || mnt.startsWith("/mnt") || mnt.startsWith("/media") || mnt.startsWith("/run/media"))
                    devs.push({
                        "device": parts[0],
                        "size": parts[1],
                        "used": parts[2],
                        "avail": parts[3],
                        "percent": parseInt(parts[4]) || 0,
                        "mount": mnt
                    });
            }
        }
        root.storageDevices = devs;
    }

    function parseBlockDevices(raw) {
        function usageForNode(node) {
            let path = "/dev/" + node.name;
            for (let i = 0; i < root.storageDevices.length; i++) {
                if (root.storageDevices[i].device === path)
                    return root.storageDevices[i];
            }
            let children = node.children || [];
            for (let j = 0; j < children.length; j++) {
                let childUsage = usageForNode(children[j]);
                if (childUsage)
                    return childUsage;
            }
            return null;
        }

        let devs = [];
        try {
            let parsed = JSON.parse(raw);
            let blockDevices = parsed.blockdevices || [];
            blockDevices.forEach(function (device) {
                if (device.type !== "disk" || device.name.indexOf("zram") === 0)
                    return;

                let model = (device.model || "").trim();
                let transport = (device.tran || "").trim();
                let removable = device.rm === true;
                let usage = usageForNode(device);
                devs.push({
                    "name": model || device.name,
                    "path": "/dev/" + device.name,
                    "size": root.formatStorageBytes(parseFloat(device.size) || 0),
                    "detail": (transport ? transport.toUpperCase() : "Disk") + (removable ? " • Removable" : ""),
                    "hasUsage": usage !== null,
                    "used": usage ? usage.used : "",
                    "usageSize": usage ? usage.size : root.formatStorageBytes(parseFloat(device.size) || 0),
                    "percent": usage ? usage.percent : 0
                });
            });
        } catch (e) {
            devs = [];
        }
        root.storageBlockDevices = devs;
    }

    function isWholeDiskDevice(name) {
        return name.match(/^(sd[a-z]+|vd[a-z]+|xvd[a-z]+|hd[a-z]+|nvme\d+n\d+|mmcblk\d+|md\d+)$/) !== null;
    }

    function parseDiskStats(raw) {
        let now = Date.now();
        let readBytes = 0;
        let writeBytes = 0;
        raw.split("\n").forEach(function (line) {
            let parts = line.trim().split(/\s+/);
            if (parts.length < 10)
                return;

            let name = parts[2];
            if (!root.isWholeDiskDevice(name))
                return;

            readBytes += (parseInt(parts[5]) || 0) * 512;
            writeBytes += (parseInt(parts[9]) || 0) * 512;
        });
        let dt = root._diskPrev.time > 0 ? (now - root._diskPrev.time) / 1000 : 1;
        let readRate = root._diskPrev.time > 0 ? Math.max(0, (readBytes - root._diskPrev.read) / dt) : 0;
        let writeRate = root._diskPrev.time > 0 ? Math.max(0, (writeBytes - root._diskPrev.write) / dt) : 0;
        root._diskPrev = {
            "read": readBytes,
            "write": writeBytes,
            "time": now
        };
        root.storageReadRaw = readRate;
        root.storageWriteRaw = writeRate;
        root.storageReadSpeed = root.formatRate(readRate);
        root.storageWriteSpeed = root.formatRate(writeRate);
        let hist = root.storageHistory.slice();
        hist.push({
            "read": readRate,
            "write": writeRate
        });
        if (hist.length > 60)
            hist.shift();

        root.storageHistory = hist;
    }

    function parseSensors(raw) {
        let temps = [];
        let section = "";
        raw.split("\n").forEach(function (line) {
            // Section header: line starts at col 0, no °C symbol
            if (line.match(/^[A-Za-z0-9]/) && !line.includes("°C")) {
                section = line.split(":")[0].trim();
                return;
            }
            let m = line.match(/^([^:]+):\s+[+-]?([\d.]+)°C/);
            if (m) {
                let label = (section ? section + "/" : "") + m[1].trim();
                temps.push({
                    "label": label,
                    "value": parseFloat(m[2])
                });
            }
        });
        if (temps.length > 0)
            root.temperatures = temps;
    }

    function parseGpu(raw) {
        let list = [];
        raw.trim().split("\n").forEach(function (line) {
            if (line.indexOf("|") !== -1)
                return;

            if (line.trim())
                list.push(line.trim());
        });
        root.gpus = list;
        if (!root.gpuName && list.length > 0)
            root.gpuName = list[0];

        root.syncGpuDevices(false);
    }

    function updateGpuHistory(usage) {
        let hist = root.gpuHistory.slice();
        hist.push(Math.max(0, Math.min(1, usage / 100)));
        if (hist.length > 60)
            hist.shift();

        root.gpuHistory = hist;
    }

    function syncGpuDevices(sampleHistory) {
        let shouldSampleHistory = sampleHistory === true;
        let merged = root._nvidiaGpuDevices.slice();
        for (let i = 0; i < root._sysfsGpuDevices.length; i++) {
            let sysfsDevice = root._sysfsGpuDevices[i];
            let duplicate = false;
            for (let j = 0; j < merged.length; j++) {
                if (merged[j].name === sysfsDevice.name || merged[j].id === sysfsDevice.id) {
                    duplicate = true;
                    break;
                }
            }
            if (!duplicate)
                merged.push(sysfsDevice);
        }
        for (let k = 0; k < root.gpus.length; k++) {
            let gpuLabel = root.gpus[k];
            let normalizedLabel = gpuLabel.toLowerCase();
            let isNvidiaPlaceholder = normalizedLabel.indexOf("nvidia") !== -1 && root._nvidiaGpuDevices.length > 0;
            let represented = isNvidiaPlaceholder;
            for (let m = 0; m < merged.length && !represented; m++) {
                let normalizedName = String(merged[m].name || "").toLowerCase();
                represented = normalizedName.length > 0 && (normalizedLabel.indexOf(normalizedName) !== -1 || normalizedName.indexOf(normalizedLabel) !== -1);
            }
            if (!represented)
                merged.push({
                    "id": "gpu" + k,
                    "name": gpuLabel,
                    "usage": 0,
                    "clockMHz": 0,
                    "temperature": 0,
                    "memoryUsedMiB": 0,
                    "memoryTotalMiB": 0
                });
        }
        let updatedHistories = Object.assign({}, root._gpuHistories);
        for (let h = 0; h < merged.length; h++) {
            let device = merged[h];
            let historyKey = String(device.id || device.name || h);
            let deviceHistory = (updatedHistories[historyKey] || []).slice();
            if (shouldSampleHistory) {
                deviceHistory.push(Math.max(0, Math.min(1, (device.usage || 0) / 100)));
                if (deviceHistory.length > 60)
                    deviceHistory.shift();
            }
            updatedHistories[historyKey] = deviceHistory;
            device.history = deviceHistory;
        }
        root._gpuHistories = updatedHistories;
        root.gpuDevices = merged;
        let summary = null;
        for (let l = 0; l < merged.length; l++) {
            if (!summary || merged[l].usage > summary.usage)
                summary = merged[l];
        }
        if (summary) {
            root.gpuName = summary.name;
            root.gpuUsage = Math.max(0, Math.min(100, summary.usage || 0));
            root.gpuClockMHz = summary.clockMHz || 0;
            root.gpuTemperature = summary.temperature || 0;
            root.gpuMemoryUsedMiB = summary.memoryUsedMiB || 0;
            root.gpuMemoryTotalMiB = summary.memoryTotalMiB || 0;
            root.gpuHistory = summary.history || [];
        }
    }

    function parseNvidiaGpu(raw) {
        let devices = [];
        raw.trim().split("\n").forEach(function (line, index) {
            let parts = line.split(",");
            if (parts.length < 6)
                return;

            devices.push({
                "id": "nvidia" + index,
                "name": parts[0].trim(),
                "usage": Math.max(0, Math.min(100, parseFloat(parts[1]) || 0)),
                "clockMHz": parseFloat(parts[2]) || 0,
                "temperature": parseFloat(parts[3]) || 0,
                "memoryUsedMiB": parseFloat(parts[4]) || 0,
                "memoryTotalMiB": parseFloat(parts[5]) || 0
            });
        });
        root._nvidiaGpuDevices = devices;
        root.syncGpuDevices(devices.length > 0);
    }

    function parseNvidiaGpuProcesses(raw) {
        let processes = [];
        raw.trim().split("\n").forEach(function (line) {
            let parts = line.split(",");
            if (parts.length < 3)
                return;

            let pid = parseInt(parts[0]) || 0;
            let name = parts[1].trim();
            let memoryMiB = parseFloat(parts[2]) || 0;
            if (pid > 0 && name.length > 0)
                processes.push({
                    "pid": pid,
                    "name": name,
                    "memoryMiB": memoryMiB
                });
        });
        root._nvidiaGpuProcesses = processes;
        root.syncGpuProcesses();
    }

    function parseDrmGpuProcesses(raw) {
        let processes = [];
        raw.trim().split("\n").forEach(function (line) {
            let parts = line.split(",");
            if (parts.length < 3)
                return;

            let pid = parseInt(parts[0]) || 0;
            let name = parts[1].trim();
            let memoryMiB = parseFloat(parts[2]) || 0;
            if (pid > 0 && name.length > 0)
                processes.push({
                    "pid": pid,
                    "name": name,
                    "memoryMiB": memoryMiB
                });
        });
        root._drmGpuProcesses = processes;
        root.syncGpuProcesses();
    }

    function syncGpuProcesses() {
        let byPid = {};
        let merged = [];

        function addProcesses(processes) {
            for (let i = 0; i < processes.length; i++) {
                let processInfo = processes[i];
                let key = String(processInfo.pid);
                if (byPid[key]) {
                    byPid[key].memoryMiB = Math.max(byPid[key].memoryMiB, processInfo.memoryMiB);
                } else {
                    byPid[key] = {
                        "pid": processInfo.pid,
                        "name": processInfo.name,
                        "memoryMiB": processInfo.memoryMiB
                    };
                    merged.push(byPid[key]);
                }
            }
        }

        addProcesses(root._nvidiaGpuProcesses);
        addProcesses(root._drmGpuProcesses);
        merged.sort(function (a, b) {
            return b.memoryMiB - a.memoryMiB;
        });
        root.gpuProcesses = merged.slice(0, 5);
    }

    function parseSysfsGpu(raw) {
        let devices = [];
        raw.trim().split("\n").forEach(function (line, index) {
            let parts = line.indexOf("|") !== -1 ? line.split("|") : line.split(",");
            if (parts.length < 2)
                return;

            if (parts.length >= 8) {
                devices.push({
                    "id": parts[1].trim() || parts[0].trim(),
                    "name": parts[2].trim() || parts[0].trim(),
                    "usage": Math.max(0, Math.min(100, parseFloat(parts[3]) || 0)),
                    "clockMHz": parseFloat(parts[4]) || 0,
                    "temperature": parseFloat(parts[5]) || 0,
                    "memoryUsedMiB": parseFloat(parts[6]) || 0,
                    "memoryTotalMiB": parseFloat(parts[7]) || 0
                });
                return;
            }
            devices.push({
                "id": parts[0].trim(),
                "name": root.gpus[index] || parts[0].trim(),
                "usage": Math.max(0, Math.min(100, parseFloat(parts[1]) || 0)),
                "clockMHz": parseFloat(parts[2]) || 0,
                "temperature": parseFloat(parts[3]) || 0,
                "memoryUsedMiB": parseFloat(parts[4]) || 0,
                "memoryTotalMiB": parseFloat(parts[5]) || 0
            });
        });
        root._sysfsGpuDevices = devices;
        root.syncGpuDevices(devices.length > 0);
    }

    function parseCpuInfo(raw) {
        let model = "";
        let currentCore = "";
        let clocks = {};
        let clockTotal = 0;
        let clockCount = 0;
        raw.split("\n").forEach(function (line) {
            let processorMatch = line.match(/^processor\s*:\s*(\d+)/);
            if (processorMatch) {
                currentCore = "cpu" + processorMatch[1];
                return;
            }
            let modelMatch = line.match(/^model name\s*:\s*(.+)$/);
            if (modelMatch && !model) {
                model = modelMatch[1].trim();
                return;
            }
            let clockMatch = line.match(/^cpu MHz\s*:\s*([\d.]+)/);
            if (clockMatch) {
                let clock = parseFloat(clockMatch[1]) || 0;
                if (clock > 0) {
                    let coreName = currentCore || ("cpu" + clockCount);
                    clocks[coreName] = clock;
                    clockTotal += clock;
                    clockCount++;
                }
            }
        });
        if (model)
            root.cpuModel = model;

        if (clockCount > 0) {
            root.cpuClockMHz = clockTotal / clockCount;
            root.cpuCoreClocks = clocks;
        }
    }

    function parseProcs(raw) {
        let procs = [];
        raw.trim().split("\n").forEach(function (line) {
            let parts = line.trim().split(/\s+/);
            if (parts.length >= 2)
                procs.push({
                    "cpu": parseFloat(parts[0]) || 0,
                    "name": parts.slice(1).join(" ")
                });
        });
        root.topProcesses = procs;
    }

    function parseRamProcs(raw) {
        let procs = [];
        raw.trim().split("\n").forEach(function (line) {
            let parts = line.trim().split(/\s+/);
            if (parts.length >= 3) {
                let rssKib = parseFloat(parts[0]) || 0;
                procs.push({
                    "memory": parseFloat(parts[1]) || 0,
                    "memoryValue": root.formatMemoryKib(rssKib),
                    "name": parts.slice(2).join(" ")
                });
            }
        });
        root.ramTopProcesses = procs;
    }

    preferredRepresentation: compactRepresentation
    toolTipMainText: ""
    toolTipSubText: ""
    Component.onCompleted: {
        exe.connectSource("cat /proc/stat");
        exe.connectSource("cat /proc/diskstats");
        exe.connectSource(root._topProcessesCommand);
        exe.connectSource("cat /proc/meminfo");
        exe.connectSource(root._ramTopProcessesCommand);
        exe.connectSource("lsblk -J -b -o NAME,SIZE,TYPE,MODEL,TRAN,RM 2>/dev/null");
        exe.connectSource("cat /proc/cpuinfo");
        exe.connectSource("lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | sed 's/.*: //'");
        exe.connectSource(root._nvidiaGpuCommand);
        exe.connectSource(root._nvidiaGpuProcessesCommand);
        exe.connectSource(root._drmGpuProcessesCommand);
        exe.connectSource(root._sysfsGpuCommand);
    }

    //  Executable data source
    P5Support.DataSource {
        id: exe

        engine: "executable"
        connectedSources: []
        onNewData: function (src, data) {
            exe.disconnectSource(src);
            let out = data["stdout"] || "";
            if (src === root._sysfsGpuCommand || src.indexOf("gpu_busy_percent") !== -1)
                root.parseSysfsGpu(out);
            else if (src === root._nvidiaGpuCommand || src.indexOf("--query-gpu") !== -1)
                root.parseNvidiaGpu(out);
            else if (src === root._nvidiaGpuProcessesCommand || src.indexOf("--query-compute-apps") !== -1)
                root.parseNvidiaGpuProcesses(out);
            else if (src === root._drmGpuProcessesCommand || src.indexOf("/proc/[0-9]") !== -1)
                root.parseDrmGpuProcesses(out);
            else if (src.indexOf("/proc/stat") !== -1)
                root.parseCpuStat(out);
            else if (src.indexOf("/proc/diskstats") !== -1)
                root.parseDiskStats(out);
            else if (src.indexOf("/proc/meminfo") !== -1)
                root.parseMemInfo(out);
            else if (src.indexOf("/proc/net/dev") !== -1)
                root.parseNetDev(out);
            else if (src.indexOf("df ") !== -1)
                root.parseDf(out);
            else if (src.indexOf("lsblk -J") !== -1)
                root.parseBlockDevices(out);
            else if (src.indexOf("sensors") !== -1)
                root.parseSensors(out);
            else if (src.indexOf("uptime") !== -1)
                root.systemUptime = out.trim().replace(/^up\s+/, "");
            else if (src.indexOf("lspci") !== -1)
                root.parseGpu(out);
            else if (src.indexOf("/proc/cpuinfo") !== -1)
                root.parseCpuInfo(out);
            else if (src.indexOf("pcpu=") !== -1)
                root.parseProcs(out);
            else if (src.indexOf("rss=") !== -1)
                root.parseRamProcs(out);
        }
    }

    // Timers
    Timer {
        interval: Math.max(500, Plasmoid.configuration.updateInterval)
        running: true
        repeat: true
        onTriggered: {
            exe.connectSource("cat /proc/stat");
            exe.connectSource("cat /proc/cpuinfo");
            exe.connectSource("cat /proc/net/dev");
            exe.connectSource("cat /proc/diskstats");
            exe.connectSource(root._topProcessesCommand);
            exe.connectSource(root._nvidiaGpuCommand);
            exe.connectSource(root._nvidiaGpuProcessesCommand);
            exe.connectSource(root._drmGpuProcessesCommand);
            exe.connectSource(root._sysfsGpuCommand);
        }
    }

    Timer {
        interval: Math.max(500, Plasmoid.configuration.updateInterval)
        running: true
        repeat: true
        onTriggered: {
            exe.connectSource("cat /proc/meminfo");
            exe.connectSource("df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep '^/dev'");
            exe.connectSource("lsblk -J -b -o NAME,SIZE,TYPE,MODEL,TRAN,RM 2>/dev/null");
            exe.connectSource("sensors 2>/dev/null || echo ''");
            exe.connectSource("uptime -p 2>/dev/null || uptime");
            exe.connectSource(root._ramTopProcessesCommand);
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: false
        onTriggered: {
            exe.connectSource("lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | sed 's/.*: //'");
        }
    }

    // Representations
    compactRepresentation: CompactView {
        parentRef: root
    }

    fullRepresentation: FullView {
        parentRef: root
    }
}
