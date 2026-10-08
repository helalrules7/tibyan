package app.tibyan.tibyan

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * The actions widget, on its own: four buttons for what is done most.
 * Continue reading, listen and search open the app on that screen
 * (`tibyan://action/<name>`). «Today's portion read» does not open it: the
 * button queues `portion_done` in the widget preferences and shows it done,
 * and the app marks the portion read the next time it runs
 * (`takePending` in home_widget_sync.dart).
 */
class ActionsWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val today = today()
    val hasPortion = widgetData.getString("portion_$today", null) != null
    val done = widgetData.getString(DONE_DAY, null) == today

    for (id in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.actions_widget)
      views.setTextViewText(
          R.id.actions_title,
          widgetData.getString("title", null) ?: context.getString(R.string.actions_widget_label),
      )
      views.setOnClickPendingIntent(R.id.action_continue, launch(context, "continue"))
      views.setOnClickPendingIntent(R.id.action_listen, launch(context, "listen"))
      views.setOnClickPendingIntent(R.id.action_search, launch(context, "search"))
      views.setTextViewText(
          R.id.action_done_label,
          context.getString(if (done) R.string.actions_done else R.string.actions_read),
      )
      views.setImageViewResource(
          R.id.action_done_icon,
          if (done) R.drawable.ic_action_check_filled else R.drawable.ic_action_check,
      )
      // Nothing to mark when no portion is due today, or it is already marked.
      if (hasPortion && !done) {
        val intent = Intent(context, ActionsWidgetProvider::class.java).setAction(PORTION_DONE)
        views.setOnClickPendingIntent(
            R.id.action_done,
            PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            ),
        )
      } else {
        views.setOnClickPendingIntent(R.id.action_done, null)
      }
      appWidgetManager.updateAppWidget(id, views)
    }
  }

  override fun onReceive(context: Context, intent: Intent) {
    if (intent.action != PORTION_DONE) return super.onReceive(context, intent)
    val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
    val queue = prefs.getString(PENDING, "") ?: ""
    prefs
        .edit()
        .putString(PENDING, if (queue.isEmpty()) "portion_done" else "$queue,portion_done")
        .putString(DONE_DAY, today())
        .apply()
    val manager = AppWidgetManager.getInstance(context)
    val ids = manager.getAppWidgetIds(ComponentName(context, ActionsWidgetProvider::class.java))
    onUpdate(context, manager, ids, prefs)
  }

  private fun launch(context: Context, action: String): PendingIntent =
      HomeWidgetLaunchIntent.getActivity(
          context,
          MainActivity::class.java,
          Uri.parse("tibyan://action/$action?homeWidget"),
      )

  private fun today(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

  companion object {
    const val PORTION_DONE = "app.tibyan.tibyan.PORTION_DONE"

    // home_widget's preferences file, and the keys shared with the app.
    const val PREFERENCES = "HomeWidgetPreferences"
    const val PENDING = "pending_actions"
    const val DONE_DAY = "done_day"
  }
}
