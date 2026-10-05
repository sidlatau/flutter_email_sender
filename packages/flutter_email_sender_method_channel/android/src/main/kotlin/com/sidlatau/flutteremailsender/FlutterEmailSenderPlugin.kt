package com.sidlatau.flutteremailsender

import android.app.Activity
import android.content.ClipData
import android.content.ClipDescription
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import androidx.core.text.HtmlCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.IOException
import java.util.UUID
import kotlin.concurrent.thread

private const val SUBJECT = "subject"
private const val BODY = "body"
private const val RECIPIENTS = "recipients"
private const val CC = "cc"
private const val BCC = "bcc"
private const val ATTACHMENTS = "attachments"
private const val IS_HTML = "is_html"
private const val CAN_SEND = "canSend"
private const val REQUEST_CODE_SEND = 607
private const val ATTACHMENTS_DIR = "flutter_email_sender"

class FlutterEmailSenderPlugin :
    FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.ActivityResultListener {
    companion object {
        private const val methodChannelName = "flutter_email_sender"

        var activity: Activity? = null
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(binding.binaryMessenger, methodChannelName)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        activity = activityPluginBinding.activity
        activityPluginBinding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        activity = activityPluginBinding.activity
        activityPluginBinding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private var channelResult: Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getCapabilities" -> result.success(mapOf(CAN_SEND to canSendMail()))
            "send" -> {
                channelResult = result
                sendEmail(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun canSendMail(): Boolean {
        val currentActivity = activity ?: return false
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))
        return currentActivity.packageManager.resolveActivity(intent, 0) != null
    }

    private fun sendEmail(options: MethodCall, callback: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            callback.error("error", "Activity == null!", null)
            return
        }

        val attachments = options.argument<List<Map<String, Any?>>>(ATTACHMENTS) ?: emptyList()
        if (attachments.isEmpty()) {
            composeEmail(currentActivity, options, emptyList(), callback)
            return
        }

        val attachmentsDir = File(currentActivity.cacheDir, ATTACHMENTS_DIR)
        thread {
            val files = try {
                writeAttachments(attachments, attachmentsDir)
            } catch (e: IOException) {
                mainHandler.post { callback.error("error", e.message, null) }
                return@thread
            }

            mainHandler.post {
                val attachedActivity = activity
                if (attachedActivity == null) {
                    callback.error("error", "Activity == null!", null)
                    return@post
                }

                val attachmentUris = files.map {
                    FileProvider.getUriForFile(attachedActivity, attachedActivity.packageName + ".file_provider", it)
                }
                composeEmail(attachedActivity, options, attachmentUris, callback)
            }
        }
    }

    private fun writeAttachments(attachments: List<Map<String, Any?>>, attachmentsDir: File): List<File> {
        val sendDir = File(attachmentsDir, UUID.randomUUID().toString())
        val files = attachments.mapIndexed { index, attachment ->
            val path = attachment["path"] as String?
            if (path != null) {
                val source = File(path)
                source.copyTo(File(sendDir, "$index/${source.name}"))
            } else {
                val fileName = File(attachment["file_name"] as String).name
                    .takeUnless { it.isEmpty() || it == "." || it == ".." } ?: "attachment"
                File(sendDir, "$index/$fileName").apply {
                    parentFile!!.mkdirs()
                    writeBytes(attachment["data"] as ByteArray)
                }
            }
        }
        attachmentsDir.listFiles()?.filter { it != sendDir }?.forEach { it.deleteRecursively() }
        return files
    }

    private fun composeEmail(currentActivity: Activity, options: MethodCall, attachmentUris: List<Uri>, callback: Result) {
        val body = options.argument<String>(BODY)
        val isHtml = options.argument<Boolean>(IS_HTML) ?: false
        val subject = options.argument<String>(SUBJECT)
        val recipients = options.argument<ArrayList<String>>(RECIPIENTS)
        val cc = options.argument<ArrayList<String>>(CC)
        val bcc = options.argument<ArrayList<String>>(BCC)

        var text: CharSequence? = null
        var html: String? = null
        if (body != null) {
            if (isHtml) {
                text = HtmlCompat.fromHtml(body, HtmlCompat.FROM_HTML_MODE_LEGACY)
                html = body
            } else {
                text = body
            }
        }

        val intent: Intent

        if (attachmentUris.isEmpty()) {
            intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))
        } else {
            // Some mail apps (e.g. Thunderbird) ignore EXTRA_STREAM on an untyped intent, and a typed
            // intent cannot carry a mailto: selector, so email apps are resolved one by one instead.
            intent = Intent(if (attachmentUris.size == 1) Intent.ACTION_SEND else Intent.ACTION_SEND_MULTIPLE)
            intent.type = "*/*"
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            if (attachmentUris.size == 1) {
                intent.putExtra(Intent.EXTRA_STREAM, attachmentUris.first())
            } else {
                intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(attachmentUris))
            }

            val clipItems = attachmentUris.map { ClipData.Item(it) }
            val clipDescription = ClipDescription("", arrayOf("application/octet-stream"))
            val clipData = ClipData(clipDescription, clipItems.first())
            for (item in clipItems.drop(1)) {
                clipData.addItem(item)
            }
            intent.clipData = clipData
        }

        if (text != null) {
            intent.putExtra(Intent.EXTRA_TEXT, text)
        }

        if (html != null) {
            intent.putExtra(Intent.EXTRA_HTML_TEXT, html)
        }

        if (subject != null) {
            intent.putExtra(Intent.EXTRA_SUBJECT, subject)
        }

        if (recipients != null) {
            intent.putExtra(Intent.EXTRA_EMAIL, listArrayToArray(recipients))
        }

        if (cc != null) {
            intent.putExtra(Intent.EXTRA_CC, listArrayToArray(cc))
        }

        if (bcc != null) {
            intent.putExtra(Intent.EXTRA_BCC, listArrayToArray(bcc))
        }

        val launchIntent = if (attachmentUris.isEmpty()) {
            intent.takeIf { currentActivity.packageManager.resolveActivity(it, 0) != null }
        } else {
            emailAppIntent(currentActivity.packageManager, intent)
        }

        if (launchIntent != null) {
            currentActivity.startActivityForResult(launchIntent, REQUEST_CODE_SEND)
        } else {
            callback.error("not_available", "No email clients found!", null)
        }
    }

    private fun emailAppIntent(packageManager: PackageManager, intent: Intent): Intent? {
        val emailApps = packageManager.queryIntentActivities(Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:")), 0)
        val composers = emailApps.mapNotNull { emailApp ->
            val handlers = packageManager.queryIntentActivities(
                Intent(intent.action).setType(intent.type).setPackage(emailApp.activityInfo.packageName),
                0,
            )
            val handler = handlers.firstOrNull { it.activityInfo.name == emailApp.activityInfo.name } ?: handlers.firstOrNull()
            handler?.let { ComponentName(it.activityInfo.packageName, it.activityInfo.name) }
        }.distinct()

        return when (composers.size) {
            0 -> null
            1 -> intent.setComponent(composers.first())
            else -> {
                val otherShareTargets = packageManager.queryIntentActivities(intent, 0)
                    .map { ComponentName(it.activityInfo.packageName, it.activityInfo.name) }
                    .filter { it !in composers }
                Intent.createChooser(intent, null)
                    .putExtra(Intent.EXTRA_EXCLUDE_COMPONENTS, otherShareTargets.toTypedArray())
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            REQUEST_CODE_SEND -> {
                channelResult?.success(null)
                channelResult = null
                true
            }
            else -> {
                false
            }
        }
    }

    private fun listArrayToArray(r: ArrayList<String>): Array<String> {
        return r.toArray(arrayOfNulls<String>(r.size))
    }
}
