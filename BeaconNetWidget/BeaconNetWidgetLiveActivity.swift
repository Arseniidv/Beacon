
import ActivityKit
import WidgetKit
import SwiftUI

struct NetworkScanActivityAttributes: ActivityAttributes {
    var networkName: String
    var subnet: String
    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable {
            case scanning
            case monitoring
            case completed
            case failed
            case cancelled
        }

        var phase: Phase
        var progress: Int?
        var discoveredDevices: Int
        var totalDevices: Int
        var statusMessage: String
        var updatedAt: Date
    }
}

struct BeaconNetWidgetLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(
            for: NetworkScanActivityAttributes.self
        ) { context in
            LockScreenActivityView(
                attributes: context.attributes,
                state: context.state
            )
            .activityBackgroundTint(Color.black.opacity(0.92))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in

            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.title2)
                        .foregroundStyle(.green)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(progressText(context.state))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.green)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.networkName)
                        .font(.headline)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.state.statusMessage)
                            .font(.subheadline)
                            .lineLimit(2)

                        if let progress = context.state.progress {
                            ProgressView(
                                value: Double(
                                    min(max(progress, 0), 100)
                                ),
                                total: 100
                            )
                            .tint(.green)
                        }

                        HStack {
                            Label(
                                "\(context.state.discoveredDevices)",
                                systemImage: "desktopcomputer"
                            )

                            Spacer()

                            Text(context.attributes.subnet)
                                .lineLimit(1)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

            } compactLeading: {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(.green)

            } compactTrailing: {
                Text(shortStatus(context.state))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.green)

            } minimal: {
                Image(systemName: "network")
                    .foregroundStyle(.green)
            }
            .keylineTint(.green)
        }
    }

    private func progressText(
        _ state: NetworkScanActivityAttributes.ContentState
    ) -> String {
        guard let progress = state.progress else {
            return state.phase == .monitoring ? "LIVE" : "—"
        }

        return "\(min(max(progress, 0), 100))%"
    }

    private func shortStatus(
        _ state: NetworkScanActivityAttributes.ContentState
    ) -> String {
        if let progress = state.progress {
            return "\(min(max(progress, 0), 100))%"
        }

        return state.phase == .monitoring ? "LIVE" : "…"
    }
}

private struct LockScreenActivityView: View {
    let attributes: NetworkScanActivityAttributes
    let state: NetworkScanActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(.green)

                Text("NetPulse")
                    .font(.headline)

                Spacer()

                Text(statusTitle)
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            Text(attributes.networkName)
                .font(.subheadline.bold())

            Text(state.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let progress = state.progress {
                ProgressView(
                    value: Double(min(max(progress, 0), 100)),
                    total: 100
                )
                .tint(.green)
            }

            HStack {
                Label(
                    "\(state.discoveredDevices) устройств",
                    systemImage: "desktopcomputer"
                )

                Spacer()

                Text(attributes.subnet)
                    .lineLimit(1)
            }
            .font(.caption)
        }
        .foregroundStyle(.white)
        .padding()
    }

    private var statusTitle: String {
        switch state.phase {
        case .scanning: return "Сканирование"
        case .monitoring: return "Мониторинг"
        case .completed: return "Завершено"
        case .failed: return "Ошибка"
        case .cancelled: return "Отменено"
        }
    }
}
