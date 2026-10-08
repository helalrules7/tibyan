package app.tibyan.tibyan

import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/**
 * A Quick Settings tile: one tap from the notification shade starts the
 * recitation from where the reader stopped. It opens the app on
 * `tibyan://action/listen` (the same link as the actions widget's «استماع»
 * button), so the app does the rest.
 */
class ListenTileService : TileService() {
  override fun onStartListening() {
    qsTile?.apply {
      state = Tile.STATE_INACTIVE
      label = getString(R.string.tile_listen_label)
      updateTile()
    }
  }

  override fun onClick() {
    val intent =
        Intent(this, MainActivity::class.java)
            .setAction(HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION)
            .setData(Uri.parse("tibyan://action/listen?homeWidget"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    if (Build.VERSION.SDK_INT >= 34) {
      startActivityAndCollapse(
          PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
      )
    } else {
      @Suppress("DEPRECATION") startActivityAndCollapse(intent)
    }
  }
}
