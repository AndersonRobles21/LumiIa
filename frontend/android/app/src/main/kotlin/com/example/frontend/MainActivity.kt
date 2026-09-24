package com.example.frontend

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
	private val channelName = "lumi/pdf_download"
	private val writeStorageRequestCode = 4101
	private var pendingDownload: PendingDownload? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				if (call.method != "savePdfToDownloads") {
					result.notImplemented()
					return@setMethodCallHandler
				}

				val bytes = call.argument<ByteArray>("bytes")
				val filename = call.argument<String>("filename")
				if (bytes == null || filename.isNullOrBlank()) {
					result.error("INVALID_ARGUMENTS", "PDF bytes and filename are required", null)
					return@setMethodCallHandler
				}

				savePdfToDownloads(bytes, filename, result)
			}
	}

	private fun savePdfToDownloads(
		bytes: ByteArray,
		filename: String,
		result: MethodChannel.Result,
	) {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
			ContextCompat.checkSelfPermission(
				this,
				Manifest.permission.WRITE_EXTERNAL_STORAGE,
			) != PackageManager.PERMISSION_GRANTED
		) {
			pendingDownload = PendingDownload(bytes, filename, result)
			requestPermissions(
				arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
				writeStorageRequestCode,
			)
			return
		}

		try {
			val savedLocation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				saveWithMediaStore(bytes, filename)
			} else {
				saveWithLegacyDownloadsDirectory(bytes, filename)
			}
			result.success(savedLocation)
		} catch (error: Exception) {
			result.error("PDF_SAVE_FAILED", error.message, null)
		}
	}

	override fun onRequestPermissionsResult(
		requestCode: Int,
		permissions: Array<out String>,
		grantResults: IntArray,
	) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode != writeStorageRequestCode) return

		val download = pendingDownload ?: return
		pendingDownload = null
		if (grantResults.firstOrNull() != PackageManager.PERMISSION_GRANTED) {
			download.result.error(
				"STORAGE_PERMISSION_DENIED",
				"Storage permission is required to save the PDF in Downloads",
				null,
			)
			return
		}

		savePdfToDownloads(download.bytes, download.filename, download.result)
	}

	private fun saveWithMediaStore(bytes: ByteArray, filename: String): String {
		val resolver = contentResolver
		val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
		val relativePath = Environment.DIRECTORY_DOWNLOADS + File.separator

		resolver.query(
			collection,
			arrayOf(MediaStore.MediaColumns._ID),
			"${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND ${MediaStore.MediaColumns.RELATIVE_PATH} = ?",
			arrayOf(filename, relativePath),
			null,
		)?.use { cursor ->
			val idIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
			while (cursor.moveToNext()) {
				resolver.delete(
					android.content.ContentUris.withAppendedId(collection, cursor.getLong(idIndex)),
					null,
					null,
				)
			}
		}

		val values = ContentValues().apply {
			put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
			put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
			put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
			put(MediaStore.MediaColumns.IS_PENDING, 1)
		}

		val uri = resolver.insert(collection, values)
			?: error("Android could not create the PDF in Downloads")

		try {
			resolver.openOutputStream(uri)?.use { output -> output.write(bytes) }
				?: error("Android could not open the PDF output stream")
			resolver.update(
				uri,
				ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
				null,
				null,
			)
			return "Downloads/$filename"
		} catch (error: Exception) {
			resolver.delete(uri, null, null)
			throw error
		}
	}

	@Suppress("DEPRECATION")
	private fun saveWithLegacyDownloadsDirectory(bytes: ByteArray, filename: String): String {
		val directory = Environment.getExternalStoragePublicDirectory(
			Environment.DIRECTORY_DOWNLOADS,
		)
		if (!directory.exists() && !directory.mkdirs()) {
			error("Android could not create the public Downloads directory")
		}

		val file = File(directory, filename)
		FileOutputStream(file).use { output -> output.write(bytes) }
		return file.absolutePath
	}

	private data class PendingDownload(
		val bytes: ByteArray,
		val filename: String,
		val result: MethodChannel.Result,
	)
}
