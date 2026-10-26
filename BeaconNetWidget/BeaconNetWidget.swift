import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: .now,
            configuration: ConfigurationAppIntent(),
            network: .empty
        )
    }

    func snapshot(
        for configuration: ConfigurationAppIntent,
        in context: Context
    ) async -> SimpleEntry {
        SimpleEntry(
            date: .now,
            configuration: configuration,
            network: WidgetDataStore.load()
        )
    }

    func timeline(
        for configuration: ConfigurationAppIntent,
        in context: Context
    ) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(
            date: .now,
            configuration: configuration,
            network: WidgetDataStore.load()
        )

        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: .now
        ) ?? .now.addingTimeInterval(900)

        return Timeline(
            entries: [entry],
            policy: .after(nextUpdate)
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let network: WidgetNetworkData
}

struct BeaconNetWidgetEntryView: View {
    let entry: Provider.Entry

    private var statusColor: Color {
        entry.network.isMonitoring ? .green : .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .font(.title2)

                Text("NetPulse")
                    .font(.headline)

                Spacer()

                Circle()
                    .fill(statusColor)
                    .frame(width: 9, height: 9)
            }

            Text(
                entry.network.isMonitoring
                    ? "Мониторинг активен"
                    : "Мониторинг остановлен"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Divider()

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Устройства онлайн")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        "\(entry.network.onlineDevices) / " +
                        "\(entry.network.totalDevices)"
                    )
                    .font(.title2.bold())
                    .monospacedDigit()
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("Шлюз")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(entry.network.gatewayIP ?? "Не задан")
                        .font(.caption.monospaced())
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Text(entry.network.networkName)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let lastScan = entry.network.lastScanDate {
                    Text(lastScan, style: .time)
                } else {
                    Text("Нет данных")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct BeaconNetWidget: Widget {
    let kind = "BeaconNetWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: Provider()
        ) { entry in
            BeaconNetWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Состояние сети")
        .description("Мониторинг и обнаруженные устройства.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
    }
}

#Preview(as: .systemSmall) {
    BeaconNetWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        configuration: ConfigurationAppIntent(),
        network: WidgetNetworkData.empty
    )
}
