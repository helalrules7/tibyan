package app.tibyan.tibyan

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Today's khatma portion and the verse it starts at. The app writes an
 * entry for each of the coming days (`portion_yyyy-MM-dd`, `ref_…`, `uri_…`),
 * so the widget shows the right day without the app being opened. A tap
 * opens the app on the portion's first page.
 */
class KhatmaWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    val title = widgetData.getString("title", null)
    val portion = widgetData.getString("portion_$today", null)
    val reference = widgetData.getString("ref_$today", null)
    val uri = widgetData.getString("uri_$today", null)
    val idle = widgetData.getString("idle", null)

    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.khatma_widget)
      views.setTextViewText(
          R.id.khatma_title,
          title ?: context.getString(R.string.khatma_widget_label),
      )
      views.setTextViewText(
          R.id.khatma_portion,
          portion ?: idle ?: context.getString(R.string.khatma_widget_open),
      )
      if (reference.isNullOrEmpty()) {
        views.setViewVisibility(R.id.khatma_reference, View.GONE)
      } else {
        views.setViewVisibility(R.id.khatma_reference, View.VISIBLE)
        views.setTextViewText(R.id.khatma_reference, reference)
      }
      val launch =
          HomeWidgetLaunchIntent.getActivity(
              context,
              MainActivity::class.java,
              Uri.parse(uri ?: "tibyan://khatma"),
          )
      views.setOnClickPendingIntent(R.id.khatma_root, launch)
      appWidgetManager.updateAppWidget(id, views)
    }
  }
}
