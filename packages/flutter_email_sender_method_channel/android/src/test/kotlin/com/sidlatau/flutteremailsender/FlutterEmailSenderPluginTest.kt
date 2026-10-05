package com.sidlatau.flutteremailsender

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35])
class FlutterEmailSenderPluginTest {
    private lateinit var activity: Activity
    private lateinit var lastResult: RecordingResult
    private val plugin = FlutterEmailSenderPlugin()

    @Before
    fun setUp() {
        // FileProvider caches its roots statically, while Robolectric gives every test a new data directory.
        FileProvider::class.java.getDeclaredField("sCache").apply { isAccessible = true }
            .let { (it.get(null) as MutableMap<*, *>).clear() }
        activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        FlutterEmailSenderPlugin.activity = activity
    }

    @After
    fun tearDown() {
        FlutterEmailSenderPlugin.activity = null
    }

    @Test
    fun noAttachmentsOpensMailtoIntent() {
        addThunderbird()

        val intent = sendAndAwaitIntent(emptyList())

        assertEquals(Intent.ACTION_SENDTO, intent.action)
        assertEquals(Uri.parse("mailto:"), intent.data)
        assertEquals("Subject", intent.getStringExtra(Intent.EXTRA_SUBJECT))
    }

    @Test
    fun singleAttachmentIsTypedAndTargetsTheEmailApp() {
        addThunderbird()

        val intent = sendAndAwaitIntent(listOf(writeFile(activity.cacheDir, "report.pdf")))

        assertEquals(Intent.ACTION_SEND, intent.action)
        assertEquals("*/*", intent.type)
        assertNull(intent.selector)
        assertEquals(THUNDERBIRD, intent.component)
        assertTrue(intent.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0)
        val uri = intent.streamExtra()
        assertEquals("report.pdf", uri.lastPathSegment)
        assertEquals(1, intent.clipData!!.itemCount)
        assertEquals("Body", intent.getCharSequenceExtra(Intent.EXTRA_TEXT).toString())
    }

    @Test
    fun multipleAttachmentsUseSendMultiple() {
        addThunderbird()

        val intent = sendAndAwaitIntent(
            listOf(writeFile(activity.cacheDir, "a.pdf"), writeFile(activity.cacheDir, "b.png")),
        )

        assertEquals(Intent.ACTION_SEND_MULTIPLE, intent.action)
        assertEquals("*/*", intent.type)
        assertEquals(THUNDERBIRD, intent.component)
        assertEquals(listOf("a.pdf", "b.png"), intent.streamListExtra().map { it.lastPathSegment })
        assertEquals(2, intent.clipData!!.itemCount)
    }

    @Test
    fun sendGoesToTheActivityThatHandlesAttachments() {
        val mailto = ComponentName("com.split", "MailtoActivity")
        val send = ComponentName("com.split", "SendActivity")
        addActivity(mailto, mailtoFilter())
        addActivity(send, sendFilter(Intent.ACTION_SEND), sendFilter(Intent.ACTION_SEND_MULTIPLE))

        val intent = sendAndAwaitIntent(listOf(writeFile(activity.cacheDir, "report.pdf")))

        assertEquals(send, intent.component)
    }

    @Test
    fun severalEmailAppsShowChooserWithoutOtherShareTargets() {
        addThunderbird()
        val gmail = ComponentName("com.gmail", "Compose")
        val gmailChat = ComponentName("com.gmail", "ChatShare")
        val chat = ComponentName("com.chat", "Share")
        addActivity(gmail, mailtoFilter(), sendFilter(Intent.ACTION_SEND), sendFilter(Intent.ACTION_SEND_MULTIPLE))
        addActivity(gmailChat, sendFilter(Intent.ACTION_SEND, "text/plain"))
        addActivity(chat, sendFilter(Intent.ACTION_SEND), sendFilter(Intent.ACTION_SEND_MULTIPLE))

        val chooser = sendAndAwaitIntent(listOf(writeFile(activity.cacheDir, "report.pdf")))

        assertEquals(Intent.ACTION_CHOOSER, chooser.action)
        val target = chooser.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)!!
        assertEquals(Intent.ACTION_SEND, target.action)
        assertEquals("*/*", target.type)
        val excluded = chooser.getParcelableArrayExtra(Intent.EXTRA_EXCLUDE_COMPONENTS, ComponentName::class.java)!!.toSet()
        assertEquals(setOf(gmailChat, chat), excluded)
    }

    @Test
    fun closingTheComposerCompletesTheCallWithoutAResult() {
        addThunderbird()
        sendAndAwaitIntent(listOf(writeFile(activity.cacheDir, "report.pdf")))
        assertFalse(lastResult.succeeded)

        plugin.onActivityResult(REQUEST_CODE_SEND, Activity.RESULT_CANCELED, null)

        assertTrue(lastResult.succeeded)
        assertNull(lastResult.value)
    }

    @Test
    fun noEmailAppReportsNotAvailable() {
        addActivity(ComponentName("com.chat", "Share"), sendFilter(Intent.ACTION_SEND))

        val result = sendAndAwaitError(listOf(writeFile(activity.cacheDir, "report.pdf")))

        assertEquals("not_available", result)
    }

    @Test
    fun missingAttachmentReportsError() {
        addThunderbird()

        val result = sendAndAwaitError(listOf(File(activity.cacheDir, "missing.pdf").path))

        assertEquals("error", result)
    }

    @Test
    fun attachmentsOutsideCacheAreCopiedIntoTheSharedFolder() {
        addThunderbird()
        val documents = File(activity.filesDir.parentFile, "app_flutter")
        val database = File(activity.filesDir.parentFile, "databases")

        val intent = sendAndAwaitIntent(
            listOf(writeFile(documents, "report.pdf"), writeFile(database, "report.pdf")),
        )

        val uris = intent.streamListExtra()
        assertEquals(listOf("report.pdf", "report.pdf"), uris.map { it.lastPathSegment })
        assertNotEquals(uris[0], uris[1])
        uris.forEach { uri ->
            activity.contentResolver.openInputStream(uri)!!.use { assertEquals("content of report.pdf", it.reader().readText()) }
        }
    }

    @Test
    fun previousCopiesAreDeleted() {
        addThunderbird()
        val attachmentsDir = File(activity.cacheDir, "flutter_email_sender")

        sendAndAwaitIntent(listOf(writeFile(activity.filesDir, "first.pdf")))
        sendAndAwaitIntent(listOf(writeFile(activity.filesDir, "second.pdf")))

        val sends = attachmentsDir.listFiles()!!
        assertEquals(1, sends.size)
        assertEquals("second.pdf", sends.single().walk().single { it.isFile }.name)
    }

    private fun addThunderbird() {
        addActivity(THUNDERBIRD, mailtoFilter(), sendFilter(Intent.ACTION_SEND), sendFilter(Intent.ACTION_SEND_MULTIPLE))
    }

    private fun addActivity(component: ComponentName, vararg filters: IntentFilter) {
        val packageManager = shadowOf(activity.packageManager)
        packageManager.addActivityIfNotPresent(component).exported = true
        filters.forEach { packageManager.addIntentFilterForActivity(component, it) }
    }

    private fun mailtoFilter() = IntentFilter(Intent.ACTION_SENDTO).apply { addDataScheme("mailto") }

    private fun sendFilter(action: String, mimeType: String = "*/*") = IntentFilter(action, mimeType)

    private fun writeFile(directory: File, name: String): String {
        val file = File(directory, name)
        file.parentFile!!.mkdirs()
        file.writeText("content of $name")
        return file.path
    }

    private fun send(attachmentPaths: List<String>): RecordingResult {
        val result = RecordingResult()
        val arguments = mapOf(
            "subject" to "Subject",
            "body" to "Body",
            "attachment_paths" to ArrayList(attachmentPaths),
        )
        plugin.onMethodCall(MethodCall("send", arguments), result)
        lastResult = result
        return result
    }

    private fun sendAndAwaitIntent(attachmentPaths: List<String>): Intent {
        val result = send(attachmentPaths)
        repeat(500) {
            shadowOf(Looper.getMainLooper()).idle()
            shadowOf(activity).nextStartedActivityForResult?.let { return it.intent }
            result.errorCode?.let { throw AssertionError("send failed: $it ${result.errorMessage}") }
            Thread.sleep(10)
        }
        throw AssertionError("No activity was started")
    }

    private fun sendAndAwaitError(attachmentPaths: List<String>): String {
        val result = send(attachmentPaths)
        repeat(500) {
            shadowOf(Looper.getMainLooper()).idle()
            result.errorCode?.let { return it }
            assertNull(shadowOf(activity).nextStartedActivityForResult)
            Thread.sleep(10)
        }
        throw AssertionError("send did not fail")
    }

    private fun Intent.streamExtra(): Uri = getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)!!

    private fun Intent.streamListExtra(): List<Uri> = getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)!!

    private class RecordingResult : MethodChannel.Result {
        var succeeded = false
        var value: Any? = null
        var errorCode: String? = null
        var errorMessage: String? = null

        override fun success(result: Any?) {
            succeeded = true
            value = result
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            this.errorCode = errorCode
            this.errorMessage = errorMessage
        }

        override fun notImplemented() {}
    }

    private companion object {
        const val REQUEST_CODE_SEND = 607
        val THUNDERBIRD = ComponentName("com.thunderbird", "MessageCompose")
    }
}
