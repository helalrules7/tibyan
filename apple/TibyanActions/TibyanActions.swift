// The actions widget: four buttons for what is done most, in an extension
// of its own (iOS 17 / macOS 14, where a widget's button can run an intent).
//
//   continue reading, listen, search: open the app on that screen
//   today's portion read: does NOT open the app. The intent queues
//   `portion_done` in the App Group and the widget shows it done; the app
//   marks the portion read the next time it runs (home_widget_sync.dart,
//   `takePending`).

import AppIntents
import SwiftUI
import WidgetKit

struct MarkPortionDoneIntent: AppIntent {
  static var title: LocalizedStringResource = "Mark today's portion read"

  func perform() async throws -> some IntentResult {
    WidgetStore.queue("portion_done")
    WidgetStore.defaults?.set(WidgetStore.dayKey(Date()), forKey: "done_day")
    WidgetCenter.shared.reloadTimelines(ofKind: "TibyanActionsWidget")
    return .result()
  }
}

struct ActionsEntry: TimelineEntry {
  let date: Date
  let title: String
  let portion: String
  let hasPortion: Bool
  let done: Bool
}

private func actionsEntry(for date: Date) -> ActionsEntry {
  let data = WidgetStore.defaults
  let key = WidgetStore.dayKey(date)
  let portion = data?.string(forKey: "portion_\(key)")
  return ActionsEntry(
    date: date,
    title: data?.string(forKey: "title") ?? WidgetStore.text("تبيان", "Tibyan"),
    portion: portion ?? data?.string(forKey: "idle") ?? "",
    hasPortion: portion != nil,
    done: data?.string(forKey: "done_day") == key
  )
}

struct ActionsProvider: TimelineProvider {
  func placeholder(in context: Context) -> ActionsEntry {
    ActionsEntry(date: Date(), title: "تبيان", portion: "", hasPortion: true, done: false)
  }

  func getSnapshot(in context: Context, completion: @escaping (ActionsEntry) -> Void) {
    completion(actionsEntry(for: Date()))
  }

  // Now, then again at midnight (a new day's portion, the done mark cleared).
  func getTimeline(in context: Context, completion: @escaping (Timeline<ActionsEntry>) -> Void) {
    let midnight = Calendar.current.startOfDay(
      for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
    completion(Timeline(entries: [actionsEntry(for: Date())], policy: .after(midnight)))
  }
}

private let paper = Color(red: 0.96, green: 0.93, blue: 0.87)
private let gold = Color(red: 0.72, green: 0.57, blue: 0.24)

private struct ActionLabel: View {
  let symbol: String
  let text: String
  var tint: Color = paper

  var body: some View {
    VStack(spacing: 4) {
      Image(systemName: symbol).font(.title3)
      Text(text).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
    }
    .foregroundColor(tint)
    .frame(maxWidth: .infinity, minHeight: 52)
    .background(Color.white.opacity(0.12))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

private func open(_ action: String, symbol: String, text: String) -> some View {
  Link(destination: URL(string: "tibyan://action/\(action)?homeWidget")!) {
    ActionLabel(symbol: symbol, text: text)
  }
}

struct ActionsView: View {
  var entry: ActionsEntry
  @Environment(\.widgetFamily) private var family

  private var doneButton: some View {
    Button(intent: MarkPortionDoneIntent()) {
      ActionLabel(
        symbol: entry.done ? "checkmark.circle.fill" : "checkmark.circle",
        text: entry.done
          ? WidgetStore.text("تم", "Done") : WidgetStore.text("قرأت الورد", "Read"),
        tint: entry.done ? gold : paper)
    }
    .buttonStyle(.plain)
    // Nothing to mark when no portion is due today, or it is already marked.
    .disabled(!entry.hasPortion || entry.done)
  }

  private var buttons: [AnyView] {
    [
      AnyView(open("continue", symbol: "book", text: WidgetStore.text("تابع", "Continue"))),
      AnyView(open("listen", symbol: "play.circle", text: WidgetStore.text("استماع", "Listen"))),
      AnyView(open("search", symbol: "magnifyingglass", text: WidgetStore.text("بحث", "Search"))),
      AnyView(doneButton),
    ]
  }

  var body: some View {
    if family == .accessoryCircular {
      // Lock screen: one tap to listen from where the reader stopped.
      Link(destination: URL(string: "tibyan://action/listen?homeWidget")!) {
        ZStack {
          AccessoryWidgetBackground()
          Image(systemName: "play.fill").font(.title3)
        }
      }
      .containerBackground(.clear, for: .widget)
    } else {
      homeBody
    }
  }

  private var homeBody: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(entry.title)
        .font(.caption.bold())
        .foregroundColor(gold)
        .lineLimit(1)
      if family != .systemSmall && !entry.portion.isEmpty {
        Text(entry.portion).font(.footnote).foregroundColor(paper).lineLimit(1)
      }
      if family == .systemSmall {
        VStack(spacing: 6) {
          HStack(spacing: 6) { buttons[0]; buttons[1] }
          HStack(spacing: 6) { buttons[2]; buttons[3] }
        }
      } else {
        HStack(spacing: 8) { ForEach(0..<4, id: \.self) { buttons[$0] } }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .containerBackground(Color(red: 0.07, green: 0.25, blue: 0.19), for: .widget)
  }
}

@main
struct TibyanActionsWidget: Widget {
  // Must match PluginHomeWidgetSync.iosActionsKind.
  let kind = "TibyanActionsWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ActionsProvider()) { entry in
      ActionsView(entry: entry)
    }
    .configurationDisplayName("تبيان: اختصارات")
    .description("متابعة القراءة، الاستماع، البحث، وتسجيل ورد اليوم")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
  }
}
