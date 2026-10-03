// Home screen widget: today's khatma portion and the verse it starts at.
//
// Not yet part of the Xcode project: add it as a Widget Extension target
// as described in docs/HOME_WIDGET.md. The app writes one entry per coming
// day into the shared App Group (home_widget), so the widget can move to
// the next day by itself at midnight.

import SwiftUI
import WidgetKit

private let appGroup = "group.app.tibyan.tibyan"

struct KhatmaEntry: TimelineEntry {
  let date: Date
  let title: String
  let portion: String
  let reference: String
  let url: URL?
}

private func dayKey(_ date: Date) -> String {
  let f = DateFormatter()
  f.calendar = Calendar(identifier: .gregorian)
  f.locale = Locale(identifier: "en_US_POSIX")
  f.dateFormat = "yyyy-MM-dd"
  return f.string(from: date)
}

private func entry(for date: Date) -> KhatmaEntry {
  let data = UserDefaults(suiteName: appGroup)
  let key = dayKey(date)
  let portion = data?.string(forKey: "portion_\(key)")
  return KhatmaEntry(
    date: date,
    title: data?.string(forKey: "title") ?? "الختمة",
    portion: portion ?? data?.string(forKey: "idle") ?? "افتح تبيان",
    reference: data?.string(forKey: "ref_\(key)") ?? "",
    url: URL(string: data?.string(forKey: "uri_\(key)") ?? "tibyan://khatma?homeWidget")
  )
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> KhatmaEntry {
    KhatmaEntry(date: Date(), title: "الختمة", portion: "", reference: "", url: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (KhatmaEntry) -> Void) {
    completion(entry(for: Date()))
  }

  // Today now, then each of the next days at midnight.
  func getTimeline(in context: Context, completion: @escaping (Timeline<KhatmaEntry>) -> Void) {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var entries = [entry(for: Date())]
    for i in 1..<14 {
      if let d = calendar.date(byAdding: .day, value: i, to: today) {
        entries.append(entry(for: d))
      }
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

struct KhatmaWidgetView: View {
  var entry: KhatmaEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(entry.title)
        .font(.caption.bold())
        .foregroundColor(Color(red: 0.72, green: 0.57, blue: 0.24))
      Text(entry.portion)
        .font(.headline)
        .foregroundColor(Color(red: 0.96, green: 0.93, blue: 0.87))
        .lineLimit(2)
      if !entry.reference.isEmpty {
        Text(entry.reference)
          .font(.caption)
          .foregroundColor(Color(red: 0.79, green: 0.83, blue: 0.80))
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .widgetURL(entry.url)
    .containerBackground(Color(red: 0.07, green: 0.25, blue: 0.19), for: .widget)
  }
}

@main
struct TibyanWidget: Widget {
  // Must match PluginHomeWidgetSync.iosKind.
  let kind = "TibyanWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      KhatmaWidgetView(entry: entry)
    }
    .configurationDisplayName("الختمة")
    .description("ورد اليوم من الختمة")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
