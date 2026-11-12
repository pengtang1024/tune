package cn.iouf.tune;

import android.app.Activity;
import android.content.ContentUris;
import android.content.Intent;
import android.content.UriPermission;
import android.database.Cursor;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.provider.OpenableColumns;
import androidx.annotation.NonNull;
import com.ryanheise.audioservice.AudioServiceActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
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
//
// A reader who wants one folder instead of the whole system library picks it
// through the system directory picker. The permission is taken as a
// persistable one, so the tree answers after a restart; the tree is walked
// here because the document ids are not paths (docs/android.md §5).
public class MainActivity extends AudioServiceActivity {
  private static final String MEDIA_STORE_CHANNEL = "cn.iouf.tune/media_store";
  private static final String SAF_CHANNEL = "cn.iouf.tune/saf";

  private static final int PICK_DIRECTORY_REQUEST = 0x5AF;
  private static final int TREE_DEPTH_LIMIT = 12;
  private static final int PAGE_SIZE = 500;

  private MethodChannel.Result pendingPick;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), MEDIA_STORE_CHANNEL)
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
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SAF_CHANNEL)
        .setMethodCallHandler(
            (call, result) -> {
              switch (call.method) {
                case "pickDirectory":
                  pickDirectory(result);
                  break;
                case "listTree":
                  {
                    final String uri = call.argument("uri");
                    final Integer offset = call.argument("offset");
                    final Integer limit = call.argument("limit");
                    try {
                      result.success(
                          listTree(uri, offset == null ? 0 : offset, limit == null ? PAGE_SIZE : limit));
                    } catch (SecurityException error) {
                      result.error("permission_lost", error.getMessage(), null);
                    } catch (Exception error) {
                      result.error("saf_failed", error.getMessage(), null);
                    }
                    break;
                  }
                case "canWrite":
                  try {
                    result.success(canWrite(call.argument("uri")));
                  } catch (Exception error) {
                    result.success(false);
                  }
                  break;
                case "writeSheet":
                  try {
                    result.success(
                        writeSheet(
                            call.argument("treeUri"),
                            call.argument("songUri"),
                            call.argument("name"),
                            call.argument("content")));
                  } catch (SecurityException error) {
                    result.error("permission_lost", error.getMessage(), null);
                  } catch (Exception error) {
                    result.error("saf_failed", error.getMessage(), null);
                  }
                  break;
                default:
                  result.notImplemented();
                  break;
              }
            });
  }

  @Override
  protected void onActivityResult(int requestCode, int resultCode, Intent data) {
    super.onActivityResult(requestCode, resultCode, data);
    if (requestCode != PICK_DIRECTORY_REQUEST) return;
    final MethodChannel.Result pending = pendingPick;
    pendingPick = null;
    if (pending == null) return;
    if (resultCode != Activity.RESULT_OK) {
      pending.success(null);
      return;
    }
    final Uri tree = data == null ? null : data.getData();
    if (tree == null) {
      pending.success(null);
      return;
    }
    final int flags =
        data.getFlags()
            & (Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);
    try {
      if (flags != 0) {
        getContentResolver().takePersistableUriPermission(tree, flags);
      }
    } catch (SecurityException error) {
      // A provider may refuse persistable access. The tree still answers for
      // this process, so it is handed back as read-only instead of failing.
    }
    final Map<String, Object> picked = new HashMap<>();
    picked.put("uri", tree.toString());
    picked.put("name", nameOf(tree));
    picked.put("writable", canWrite(tree.toString()));
    pending.success(picked);
  }

  private void pickDirectory(MethodChannel.Result result) {
    if (pendingPick != null) {
      pendingPick.error("busy", "a directory pick is already open", null);
    }
    pendingPick = result;
    final Intent intent =
        new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            .addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION
                    | Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION);
    try {
      startActivityForResult(intent, PICK_DIRECTORY_REQUEST);
    } catch (Exception error) {
      pendingPick = null;
      result.error("picker_unavailable", error.getMessage(), null);
    }
  }

  // The label of the tree: the last segment of its document id.
  private String nameOf(Uri tree) {
    try {
      final String id = DocumentsContract.getTreeDocumentId(tree);
      final int slash = id.lastIndexOf('/');
      return slash >= 0 ? id.substring(slash + 1) : id;
    } catch (Exception error) {
      return tree.getLastPathSegment();
    }
  }

  private List<Map<String, Object>> listTree(String treeUri, int offset, int limit) {
    if (treeUri == null || treeUri.isEmpty()) return new ArrayList<>();
    final Uri tree = Uri.parse(treeUri);
    final List<Map<String, Object>> rows = new ArrayList<>();
    // Audio rows already walked: the pages are cut by the consumer, while the
    // walk itself stays stateless (no cursor is kept between calls).
    final int[] seen = {0};
    // A tree URI answers to getTreeDocumentId; a document URI is resolved by
    // its own id. The walk starts from the tree id and recurses with the ids
    // of the children, so getDocumentId is never asked of a tree.
    final String rootId;
    try {
      rootId = DocumentsContract.getTreeDocumentId(tree);
    } catch (Exception error) {
      return rows;
    }
    walkTree(tree, rootId, rows, seen, offset, Math.max(1, limit), 0);
    return rows;
  }

  private void walkTree(
      Uri tree,
      String documentId,
      List<Map<String, Object>> rows,
      int[] seen,
      int offset,
      int limit,
      int depth) {
    if (rows.size() >= limit || depth > TREE_DEPTH_LIMIT) return;
    final String[] projection = {
      DocumentsContract.Document.COLUMN_DOCUMENT_ID,
      DocumentsContract.Document.COLUMN_DISPLAY_NAME,
      DocumentsContract.Document.COLUMN_MIME_TYPE,
      DocumentsContract.Document.COLUMN_SIZE,
      DocumentsContract.Document.COLUMN_LAST_MODIFIED,
    };
    final Uri children;
    try {
      children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, documentId);
    } catch (Exception error) {
      return;
    }
    try (Cursor cursor = getContentResolver().query(children, projection, null, null, null)) {
      if (cursor == null) return;
      while (cursor.moveToNext() && rows.size() < limit) {
        final String id = cursor.getString(0);
        final String name = cursor.getString(1);
        final String mime = cursor.getString(2);
        final long size = cursor.isNull(3) ? 0 : cursor.getLong(3);
        final long modified = cursor.isNull(4) ? 0 : cursor.getLong(4);
        if (id == null || name == null) continue;
        final Uri child;
        try {
          child = DocumentsContract.buildDocumentUriUsingTree(tree, id);
        } catch (Exception error) {
          continue;
        }
        if (DocumentsContract.Document.MIME_TYPE_DIR.equals(mime)) {
          walkTree(tree, id, rows, seen, offset, limit, depth + 1);
        } else if (isAudio(mime, name)) {
          if (seen[0]++ < offset) continue;
          rows.add(rowOf(child, id, name, mime, size, modified));
        }
      }
    }
  }

  private boolean isAudio(String mime, String name) {
    if (mime != null
        && (mime.startsWith("audio/") || "application/ogg".equals(mime))) {
      return true;
    }
    final int dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    switch (name.substring(dot + 1).toLowerCase()) {
      case "mp3":
      case "flac":
      case "wav":
      case "ogg":
      case "opus":
      case "m4a":
      case "aac":
      case "wma":
      case "ape":
      case "wv":
      case "dsf":
      case "aiff":
      case "aif":
        return true;
      default:
        return false;
    }
  }

  private Map<String, Object> rowOf(
      Uri uri, String id, String name, String mime, long size, long modified) {
    String title = null;
    String artist = null;
    String album = null;
    long duration = 0;
    final MediaMetadataRetriever retriever = new MediaMetadataRetriever();
    try {
      retriever.setDataSource(this, uri);
      title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE);
      artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST);
      album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM);
      final String raw =
          retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
      if (raw != null && !raw.isEmpty()) duration = Long.parseLong(raw);
    } catch (Exception error) {
      // Tags are a bonus: a provider that cannot serve them still gives a
      // playable row, named after its file.
    } finally {
      try {
        retriever.release();
      } catch (Exception ignored) {
      }
    }
    if (title == null || title.isEmpty()) title = nameWithoutExtension(name);

    final Map<String, Object> row = new HashMap<>();
    row.put("uri", uri.toString());
    row.put("mediaId", id);
    row.put("title", title);
    row.put("artist", artist == null ? "" : artist);
    row.put("album", album == null ? "" : album);
    row.put("durationMs", duration);
    row.put("dateAddedSeconds", modified > 0 ? modified / 1000 : 0);
    row.put("size", size);
    row.put("mimeType", mime);
    return row;
  }

  private String nameWithoutExtension(String name) {
    final int dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  private boolean canWrite(String uri) {
    if (uri == null || uri.isEmpty()) return false;
    final Uri target = Uri.parse(uri);
    for (UriPermission permission : getContentResolver().getPersistedUriPermissions()) {
      if (permission.getUri().equals(target) && permission.isWritePermission()) {
        return true;
      }
    }
    return false;
  }

  // Writes one small text file — the sheet — into the folder that holds the
  // track. The name is looked up first, so a second run replaces the sheet
  // instead of leaving a copy behind; a document created for a write that
  // then failed is removed, so no half sheet stays in the folder.
  private Map<String, Object> writeSheet(String treeUri, String songUri, String name, String content)
      throws IOException {
    if (treeUri == null || treeUri.isEmpty()) {
      throw new IllegalArgumentException("a tree is needed");
    }
    if (songUri == null || songUri.isEmpty()) {
      throw new IllegalArgumentException("a track is needed");
    }
    if (name == null || name.trim().isEmpty()) {
      throw new IllegalArgumentException("a sheet needs a name");
    }
    final Uri tree = Uri.parse(treeUri);
    final Uri song = Uri.parse(songUri);
    // The sibling of the track lives in the folder that holds it; the
    // document id of the track ends with its own name, so the folder is the
    // id without the last segment. Providers with opaque ids keep no path in
    // the id: the picked folder is the only folder they name.
    final String parentId =
        parentDocumentId(
            DocumentsContract.getDocumentId(song), DocumentsContract.getTreeDocumentId(tree));
    final Uri children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parentId);
    Uri target = findChild(tree, children, name);
    final boolean replaced = target != null;
    if (target == null) {
      final Uri created =
          DocumentsContract.createDocument(getContentResolver(), children, "text/plain", name);
      if (created == null) {
        throw new IOException("the provider did not create the sheet");
      }
      try {
        target = keepName(created, name);
      } catch (IOException error) {
        try {
          DocumentsContract.deleteDocument(getContentResolver(), created);
        } catch (Exception ignored) {
          // The provider may keep the unnamed document; the run still fails.
        }
        throw error;
      }
    }
    try (OutputStream out = getContentResolver().openOutputStream(target, "wt")) {
      if (out == null) throw new IOException("the provider did not open the sheet");
      out.write(content == null ? new byte[0] : content.getBytes(StandardCharsets.UTF_8));
      out.flush();
    } catch (Exception error) {
      if (!replaced) {
        try {
          DocumentsContract.deleteDocument(getContentResolver(), target);
        } catch (Exception ignored) {
          // The provider may keep the empty document; the run still fails.
        }
      }
      if (error instanceof IOException) throw (IOException) error;
      throw new IOException(error);
    }
    final Map<String, Object> written = new HashMap<>();
    written.put("uri", target.toString());
    written.put("replaced", replaced);
    return written;
  }

  private static String parentDocumentId(String documentId, String treeId) {
    if (documentId == null || documentId.isEmpty()) return treeId;
    final int slash = documentId.lastIndexOf('/');
    if (slash <= 0) return treeId;
    return documentId.substring(0, slash);
  }

  private Uri findChild(Uri tree, Uri children, String name) {
    final String[] projection = {
      DocumentsContract.Document.COLUMN_DOCUMENT_ID,
      DocumentsContract.Document.COLUMN_DISPLAY_NAME,
    };
    try (Cursor cursor = getContentResolver().query(children, projection, null, null, null)) {
      if (cursor == null) return null;
      while (cursor.moveToNext()) {
        if (name.equals(cursor.getString(1))) {
          return DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0));
        }
      }
    }
    return null;
  }

  // A provider may add an extension of its own when it creates a text
  // document (`Saf_One.smart.lrc` became `...lrc.txt` on the system
  // provider). The sheet name is the contract with the reader and with the
  // desktop side, so the document is renamed back when that happened.
  private Uri keepName(Uri document, String name) throws IOException {
    if (name.equals(displayNameOf(document))) return document;
    final Uri renamed;
    try {
      renamed = DocumentsContract.renameDocument(getContentResolver(), document, name);
    } catch (Exception error) {
      throw new IOException("the provider did not keep the sheet name", error);
    }
    if (renamed == null) {
      throw new IOException("the provider did not rename the sheet");
    }
    return renamed;
  }

  private String displayNameOf(Uri document) {
    final String[] projection = {OpenableColumns.DISPLAY_NAME};
    try (Cursor cursor = getContentResolver().query(document, projection, null, null, null)) {
      if (cursor != null && cursor.moveToFirst() && !cursor.isNull(0)) {
        return cursor.getString(0);
      }
    } catch (Exception error) {
      // Without a name there is no proof the provider kept it; the rename
      // that follows puts the sheet name back.
    }
    return null;
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
