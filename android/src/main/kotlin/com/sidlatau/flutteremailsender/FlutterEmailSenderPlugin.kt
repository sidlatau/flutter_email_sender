package com.sidlatau.flutteremailsender

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.core.text.HtmlCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.File

private const val SUBJECT = "subject"
private const val BODY = "body"
private const val RECIPIENTS = "recipients"
private const val CC = "cc"
private const val BCC = "bcc"
private const val ATTACHMENT_PATH = "attachment_path"
private const val IS_HTML = "is_html"
private const val REQUEST_CODE_SEND = 607

class FlutterEmailSenderPlugin(private val registrar: Registrar)
    : MethodCallHandler, PluginRegistry.ActivityResultListener {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_email_sender")
            val plugin = FlutterEmailSenderPlugin(registrar)
            registrar.addActivityResultListener(plugin)
            channel.setMethodCallHandler(plugin)
        }
    }

    private var channelResult: Result? = null

    override fun onMethodCall(call: MethodCall, result: Result) {
        this.channelResult = result
        if (call.method == "send") {
            sendEmail(call, result)
        } else {
            result.notImplemented()
        }
    }

    private fun sendEmail(options: MethodCall, callback: Result) {
        val activity = registrar.activity()
        if (activity == null) {
            callback.error("error", "Activity == null!", null)
        }

        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))

        if (options.hasArgument(SUBJECT)) {
            val subject = options.argument<String>(SUBJECT)
            intent.putExtra(Intent.EXTRA_SUBJECT, subject)
        }

        if (options.hasArgument(BODY)) {
            val body = options.argument<String>(BODY)
            var isHtml = false
            if (options.hasArgument(IS_HTML)) {
                isHtml = options.argument<Boolean>(IS_HTML) ?: false
            }
            if (body != null) {
                if (isHtml) {
                    intent.putExtra(Intent.EXTRA_HTML_TEXT, body)
                    intent.putExtra(Intent.EXTRA_TEXT, HtmlCompat.fromHtml(body, HtmlCompat.FROM_HTML_MODE_LEGACY))
                } else {
                    intent.putExtra(Intent.EXTRA_TEXT, body)
                }
            }
        }

        if (options.hasArgument(RECIPIENTS)) {
            val recipients = options.argument<ArrayList<String>>(RECIPIENTS)
            if (recipients != null) {
                intent.putExtra(Intent.EXTRA_EMAIL, listArrayToArray(recipients))
            }
        }

        if (options.hasArgument(CC)) {
            val cc = options.argument<ArrayList<String>>(CC)
            if (cc != null) {
                intent.putExtra(Intent.EXTRA_CC, listArrayToArray(cc))
            }
        }

        if (options.hasArgument(BCC)) {
            val bcc = options.argument<ArrayList<String>>(BCC)
            if (bcc != null) {
                intent.putExtra(Intent.EXTRA_BCC, listArrayToArray(bcc))
            }
        }

        if (options.hasArgument(ATTACHMENT_PATH)) {
            val attachmentPath = options.argument<String>(ATTACHMENT_PATH)
            if (attachmentPath != null) {
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

                val file = File(attachmentPath)
                val uri = FileProvider.getUriForFile(activity, registrar.context().packageName + ".file_provider", file)

                intent.action = Intent.ACTION_SEND
                intent.type = "vnd.android.cursor.dir/email"
                intent.putExtra(Intent.EXTRA_STREAM, uri)
            }
        }

        val packageManager = activity.packageManager

        if (packageManager.resolveActivity(intent, 0) != null) {
            activity.startActivityForResult(intent, REQUEST_CODE_SEND)
        } else {
            callback.error("not_available", "No email clients found!", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            REQUEST_CODE_SEND -> {
                channelResult?.success(null)
                return true
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
