package cn.iouf.tune;

import android.content.ContentUris;
import android.database.Cursor;
import android.provider.MediaStore;
import androidx.annotation.NonNull;
import com.ryanheise.audioservice.AudioServiceActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

// audio_service keeps the engine attached to the activity while the sound
// plays in the background; the plain FlutterActivity would drop it.
//
// The media library of the system is read here instead of from Dart: scoped
// storage does not let a path walk see the files of other apps, so the
// scanner asks MediaStore and gets one row per track with a playable
// content:// address.
public class MainActivity extends AudioServiceActivity {
  private static final String CHANNEL = "cn.iouf.tune/media_store";

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        .setMethodCallHandler(
            (call, result) -> {
              if (!"listAudio".equals(call.method)) {
                result.notImplemented();
                return;
              }
              try {
                result.success(listAudio());
              } catch (SecurityException error) {
                result.error("permission_denied", error.getMessage(), null);
              } catch (Exception error) {
                result.error("media_store_failed", error.getMessage(), null);
              }
            });
  }

  private List<Map<String, Object>> listAudio() {
    final List<Map<String, Object>> rows = new ArrayList<>();
    final String[] projection = {
      MediaStore.Audio.Media._ID,
      MediaStore.Audio.Media.TITLE,
      MediaStore.Audio.Media.ARTIST,
      MediaStore.Audio.Media.ALBUM,
      MediaStore.Audio.Media.DURATION,
      MediaStore.Audio.Media.DATE_ADDED,
      MediaStore.Audio.Media.YEAR,
      MediaStore.Audio.Media.SIZE,
      MediaStore.Audio.Media.MIME_TYPE,
    };
    try (Cursor cursor =
        getContentResolver()
            .query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                MediaStore.Audio.Media.IS_MUSIC + " != 0",
                null,
                MediaStore.Audio.Media.TITLE + " COLLATE NOCASE ASC")) {
      if (cursor == null) return rows;
      while (cursor.moveToNext()) {
        final long id = cursor.getLong(0);
        final Map<String, Object> row = new HashMap<>();
        row.put(
            "uri",
            ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
                .toString());
        row.put("mediaId", id);
        row.put("title", cursor.getString(1));
        row.put("artist", cursor.getString(2));
        row.put("album", cursor.getString(3));
        row.put("durationMs", cursor.getLong(4));
        row.put("dateAddedSeconds", cursor.getLong(5));
        row.put("year", cursor.isNull(6) ? 0 : cursor.getInt(6));
        row.put("size", cursor.isNull(7) ? 0 : cursor.getLong(7));
        row.put("mimeType", cursor.getString(8));
        rows.add(row);
      }
    }
    return rows;
  }
}
