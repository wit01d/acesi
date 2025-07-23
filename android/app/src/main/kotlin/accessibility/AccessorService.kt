package com.example.company_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.graphics.Rect
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.util.WeakHashMap
import com.example.company_app.accessibility.NodeUtils
import com.example.company_app.accessibility.NodeUtils.NodeState
import com.example.company_app.accessibility.NodeUtils.toNodeState
import com.example.company_app.accessibility.NodeUtils.toDescription
import com.example.company_app.accessibility.NodeUtils.traverseNodes

class AccessorService : AccessibilityService() {

    companion object {
        private const val TAG = "LOG"
        private val IMPORTANT_EVENTS = setOf(
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_VIEW_CLICKED
        )
        private const val SUMMARY_DELAY_MS = 1000L
        private const val BATCH_WINDOW_MS = 800L
        private const val MAX_BATCH_SIZE = 50
        private const val EVENT_DEDUP_WINDOW_MS = 100L
        private const val MAX_RECENT_EVENTS = 10
    }

    private val userInteraction = UserInteraction()
    private val loggedKeys = mutableSetOf<String>()
    private val globalLoggedHashCodes = mutableSetOf<Int>()
    private val boundsCache = WeakHashMap<Int, Rect>()

    private val uniqueNodesBuffer = mutableMapOf<Int, NodeState>()
    private var lastWindowChangeTime = 0L
    private var summaryHandlerPosted = false
    private val handler = Handler(Looper.getMainLooper())

    private var lastEventTime = 0L
    private var batchStartTime = 0L
    private var batchCount = 0
    private val pendingNodes = mutableMapOf<Int, NodeState>()
    private val seenHashCodes = mutableSetOf<Int>()

    private val visibleViewport = Rect()
    private var batchSize = 0
    private var lastBatchTime = 0L
    private val deferredNodes = mutableMapOf<Int, NodeState>()
    private val batchProcessor = Runnable {
        processBatchedNodes()
    }

    private val offScreenHashes = mutableSetOf<Int>()
    private val onScreenHashes = mutableSetOf<Int>()

    private data class EventKey(
        val type: Int,
        val windowId: Int,
        val sourceId: Int
    )

    private val recentEvents = object : LinkedHashMap<EventKey, Long>() {
        override fun removeEldestEntry(eldest: Map.Entry<EventKey, Long>): Boolean {
            return size > MAX_RECENT_EVENTS
        }
    }

    private fun isDuplicateEvent(event: AccessibilityEvent): Boolean {
        val currentTime = System.currentTimeMillis()
        val eventKey = EventKey(
            type = event.eventType,
            windowId = event.windowId,
            sourceId = event.source?.hashCode() ?: 0
        )

        val lastTime = recentEvents[eventKey]
        if (lastTime != null && (currentTime - lastTime) < EVENT_DEDUP_WINDOW_MS) {
            Log.d(TAG, "__Dropping__ duplicate event: ${eventTypeToString(event.eventType)}")
            return true
        }

        recentEvents[eventKey] = currentTime
        return false
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "AccessorService connected")

        val info = AccessibilityServiceInfo()
        info.apply {
            eventTypes = AccessibilityEvent.TYPE_VIEW_CLICKED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_SPOKEN
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                    AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_REQUEST_TOUCH_EXPLORATION_MODE
            notificationTimeout = 100L
        }

        this.serviceInfo = info
        Log.d(TAG, "AccessorService configured")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {

        if (isDuplicateEvent(event)) {
            return
        }

        Log.d(TAG, "Received event: ${eventTypeToString(event.eventType)}")

        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                Log.d(TAG, "Processing click event")
                userInteraction.handleClickEvent(event)
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                val currentTime = System.currentTimeMillis()
                Log.d(TAG, "Processing window content change")
                if (currentTime - lastEventTime > BATCH_WINDOW_MS) {
                    batchStartTime = currentTime
                    batchCount = 1
                    seenHashCodes.clear()
                } else {
                    batchCount++
                }
                lastEventTime = currentTime
                lastWindowChangeTime = currentTime
                if (currentTime - lastBatchTime > BATCH_WINDOW_MS) {
                    batchSize = 1
                } else {
                    batchSize++
                }
                lastBatchTime = currentTime
                handler.removeCallbacks(batchProcessor)
                rootInActiveWindow?.let { root -> root.getBoundsInScreen(visibleViewport)
                }
                collectDeferredNodes(event)
                handler.postDelayed(batchProcessor, SUMMARY_DELAY_MS)
                rootInActiveWindow?.let { root ->
                    if (root.refresh()) {
                                            collectBatchedNodes(root, isBatchEnd = false)
                    }
                }
                if (!summaryHandlerPosted) {
                    summaryHandlerPosted = true
                    handler.postDelayed({

                        rootInActiveWindow?.let { root ->
                            if (root.refresh()) {
                                collectBatchedNodes(root, isBatchEnd = true)
                            }
                        }
                        logBatchedNodesSummary()
                        summaryHandlerPosted = false
                        pendingNodes.clear()
                        seenHashCodes.clear()
                        batchCount = 0
                    }, SUMMARY_DELAY_MS)
                }
            }
        }
    }

    override fun onInterrupt() {

    }
    private fun flag(propName: String, value: Boolean, logIfDefault: Boolean = false, default: Boolean = false): String {
        return if (value != default || logIfDefault) " | [$propName]: [$value]" else ""
    }

    private fun collectUniqueNodes(node: AccessibilityNodeInfo?) {
        traverseNodes(node) { node, nodeState ->
            if (nodeState.hasContent) {
                uniqueNodesBuffer[nodeState.hashCode] = nodeState
            }
        }
    }

    private fun collectBatchedNodes(node: AccessibilityNodeInfo?, isBatchEnd: Boolean) {
        traverseNodes(node) { node, nodeState ->
            val hashCode = nodeState.hashCode
            val isNewNode = seenHashCodes.add(hashCode)
            if (isNewNode || isBatchEnd) {
                pendingNodes[hashCode] = nodeState.copy(needsBoundsUpdate = false)
            } else if (!isBatchEnd) {
                pendingNodes[hashCode]?.needsBoundsUpdate = true
            }
        }
    }

    private fun collectDeferredNodes(event: AccessibilityEvent) {
        if (batchSize > MAX_BATCH_SIZE) {
            Log.d(TAG, "Batch size exceeded, waiting for quiet period...")
            return
        }

        rootInActiveWindow?.let { root ->
            traverseNodes(root) { node, nodeState ->
                if (nodeState.hasContent && Rect.intersects(nodeState.bounds, visibleViewport)) {
                    deferredNodes[nodeState.hashCode] = nodeState.copy(
                        isVisible = true,
                        lastSeenTime = System.currentTimeMillis()
                    )
                    onScreenHashes.add(nodeState.hashCode)
                } else if (nodeState.hasContent) {
                    offScreenHashes.add(nodeState.hashCode)
                }
            }
        }
    }

    private fun logUniqueNodesSummary() {
        if (uniqueNodesBuffer.isEmpty()) return

        Log.d(TAG, "=== Unique Nodes Summary (${uniqueNodesBuffer.size} nodes) ===")
        uniqueNodesBuffer
            .entries
            .groupBy { it.key }
            .mapValues { entry -> entry.value.maxBy { it.value.timestamp }?.value }
            .forEach { (_, state) ->
                state?.let {
                    Log.d(TAG, it.toDescription())
                }
            }
        Log.d(TAG, "====================================")
    }

    private fun logBatchedNodesSummary() {
        if (pendingNodes.isEmpty()) return

        Log.d(TAG, "=== Batch Summary (${pendingNodes.size} unique nodes from $batchCount events) ===")
        pendingNodes.values
            .filter { it.hasContent }
            .forEach { state ->
                Log.d(TAG, state.toDescription())
            }
        Log.d(TAG, "====================================")
    }

    private fun processBatchedNodes() {
        if (deferredNodes.isEmpty() && offScreenHashes.isEmpty()) return

        val currentTime = System.currentTimeMillis()
        val visibleNodes = deferredNodes.values.filter {
            it.isVisible && (currentTime - it.lastSeenTime) < BATCH_WINDOW_MS
        }

        Log.d(TAG, """
            ===== Batch Summary =====
            Total Events: $batchSize
            Visible Nodes: ${visibleNodes.size}
            Off-screen Elements: ${offScreenHashes.size}
            Total Unique Elements: ${onScreenHashes.size + offScreenHashes.size}
            Viewport: ${visibleViewport.toShortString()}
            ======================
        """.trimIndent())

        visibleNodes.forEach { node ->
            Log.d(TAG, node.toDescription())
        }

        if (offScreenHashes.isNotEmpty()) {
            Log.d(TAG, "Off-screen element hashes: ${offScreenHashes.joinToString()}")
        }

        deferredNodes.clear()
        offScreenHashes.clear()
        onScreenHashes.clear()
        batchSize = 0
    }

    override fun onDestroy() {
        boundsCache.clear()
        loggedKeys.clear()
        globalLoggedHashCodes.clear()
        offScreenHashes.clear()
        onScreenHashes.clear()
        super.onDestroy()
    }


    private fun Rect.toShortString(): String = "[${left}, ${top}, ${right}, ${bottom}]"

    private fun eventTypeToString(eventType: Int): String = when(eventType) {
        AccessibilityEvent.TYPE_VIEW_CLICKED -> "TYPE_VIEW_CLICKED"
        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> "TYPE_WINDOW_CONTENT_CHANGED"
        else -> "TYPE_$eventType"
    }
}
