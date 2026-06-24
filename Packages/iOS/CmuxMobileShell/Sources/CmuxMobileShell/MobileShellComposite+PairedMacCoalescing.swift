internal import CMUXMobileCore
internal import CmuxMobilePairedMac
internal import CmuxMobileShellModel

extension MobileShellComposite {
    /// Collapse duplicate paired-Mac rows that dial the same host/port.
    ///
    /// A device can accumulate multiple Mac device ids for the same physical host
    /// across debug/reload/pairing paths. The user's Computers screen is a list
    /// of reachable computers, so two rows with the same dial endpoint are one
    /// logical computer. Prefer the active row, then the freshest route record.
    static func coalescePairedMacsByDialEndpoint(
        _ macs: [MobilePairedMac],
        supportedKinds: [CmxAttachTransportKind],
        preferNonLoopback: Bool
    ) -> [MobilePairedMac] {
        var selectedByKey: [String: MobilePairedMac] = [:]
        var orderByKey: [String: Int] = [:]

        for (index, mac) in macs.enumerated() {
            let key = dialEndpointKey(
                for: mac,
                supportedKinds: supportedKinds,
                preferNonLoopback: preferNonLoopback
            ) ?? "device:\(mac.macDeviceID)"
            orderByKey[key] = min(orderByKey[key] ?? index, index)
            guard let existing = selectedByKey[key] else {
                selectedByKey[key] = mac
                continue
            }
            if mac.sortsBeforeDuplicate(existing) {
                selectedByKey[key] = mac
            }
        }

        return selectedByKey
            .sorted { lhs, rhs in
                (orderByKey[lhs.key] ?? .max) < (orderByKey[rhs.key] ?? .max)
            }
            .map(\.value)
    }

    private static func dialEndpointKey(
        for mac: MobilePairedMac,
        supportedKinds: [CmxAttachTransportKind],
        preferNonLoopback: Bool
    ) -> String? {
        guard let (host, port) = firstReconnectHostPortRoute(
            mac.routes,
            supportedKinds: supportedKinds,
            preferNonLoopback: preferNonLoopback
        ), let normalizedHost = MobileShellRouteAuthPolicy.normalizedManualHost(host) else {
            return nil
        }
        return "host:\(normalizedHost.lowercased()):\(port)"
    }
}

private extension MobilePairedMac {
    func sortsBeforeDuplicate(_ other: MobilePairedMac) -> Bool {
        if isActive != other.isActive {
            return isActive
        }
        if lastSeenAt != other.lastSeenAt {
            return lastSeenAt > other.lastSeenAt
        }
        return macDeviceID < other.macDeviceID
    }
}
