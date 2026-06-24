import CMUXMobileCore
import CmuxMobilePairedMac
import Foundation
import Testing
@testable import CmuxMobileShell

@MainActor
@Suite struct MobileShellCompositePairedMacCoalescingTests {
    @Test func loadPairedMacsCoalescesDuplicateHostPortRows() async throws {
        let pairedStore = DelayedTeamPairedMacStore(
            recordsByTeam: [
                "team-a": [
                    try Self.pairedMac(
                        id: "mac-old",
                        displayName: "Old duplicate",
                        host: " 100.82.214.112 ",
                        lastSeenAt: Date(timeIntervalSince1970: 10),
                        isActive: false
                    ),
                    try Self.pairedMac(
                        id: "mac-fresh",
                        displayName: "Fresh active",
                        host: "100.82.214.112",
                        lastSeenAt: Date(timeIntervalSince1970: 20),
                        isActive: true
                    ),
                    try Self.pairedMac(
                        id: "mac-other",
                        displayName: "Other Mac",
                        host: "100.82.214.113",
                        lastSeenAt: Date(timeIntervalSince1970: 30),
                        isActive: false
                    ),
                ],
            ],
            blockedTeams: []
        )
        let store = MobileShellComposite(
            isSignedIn: true,
            pairedMacStore: pairedStore,
            identityProvider: StaticIdentityProvider(userID: "user-1"),
            teamIDProvider: { "team-a" }
        )

        await store.loadPairedMacs()

        #expect(store.pairedMacs.map(\.macDeviceID) == ["mac-fresh", "mac-other"])
    }

    private static func pairedMac(
        id: String,
        displayName: String,
        host: String,
        lastSeenAt: Date,
        isActive: Bool
    ) throws -> MobilePairedMac {
        MobilePairedMac(
            macDeviceID: id,
            displayName: displayName,
            routes: [try CmxAttachRoute(id: "manual", kind: .tailscale, endpoint: .hostPort(host: host, port: 50922))],
            createdAt: Date(timeIntervalSince1970: 1),
            lastSeenAt: lastSeenAt,
            isActive: isActive,
            stackUserID: "user-1",
            teamID: "team-a"
        )
    }
}
