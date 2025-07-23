package com.example.company_app.accessibility

import android.accessibilityservice.AccessibilityService
import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo
import android.util.Log

object NodeUtils {
    private const val TAG = "NodeUtils"

    data class NodeState(
        val className: CharSequence?,
        val packageName: CharSequence?,
        val viewIdResourceName: String?,
        val text: String,
        val contentDescription: String,
        val bounds: Rect,
        val windowId: Int,
        val hashCode: Int,
        val tooltipText: String,
        val hintText: String,
        val paneTitle: String,
        val containerTitle: String,
        val stateDescription: String,
        val error: String,
        val isScrollable: Boolean,
        val isDismissable: Boolean?,
        val isCheckable: Boolean,
        val isChecked: Boolean?,
        val isEditable: Boolean,
        val inputType: Int,
        val maxTextLength: Int,
        val isPassword: Boolean,
        val isVisibleToUser: Boolean,
        val drawingOrder: String,
        val timestamp: Long = System.currentTimeMillis(),
        var needsBoundsUpdate: Boolean = false,
        var isVisible: Boolean = true,
        var lastSeenTime: Long = System.currentTimeMillis(),
        val hasContent: Boolean = text.isNotEmpty() ||
                                contentDescription.isNotEmpty() ||
                                tooltipText.isNotEmpty() ||
                                hintText.isNotEmpty() ||
                                paneTitle.isNotEmpty() ||
                                containerTitle.isNotEmpty() ||
                                stateDescription.isNotEmpty() ||
                                error.isNotEmpty() ||
                                isScrollable
    )

    fun AccessibilityNodeInfo.toNodeState(): NodeState {
        val bounds = Rect().also { this.getBoundsInScreen(it) }
        return NodeState(
            windowId = windowId,
            hashCode = hashCode(),
            packageName = packageName,
            className = className,
            viewIdResourceName = viewIdResourceName,
            text = text?.toString()?.trim().orEmpty(),
            contentDescription = contentDescription?.toString()?.trim().orEmpty(),
            tooltipText = tooltipText?.toString()?.trim().orEmpty(),
            hintText = hintText?.toString()?.trim().orEmpty(),
            paneTitle = paneTitle?.toString()?.trim().orEmpty(),
            containerTitle = containerTitle?.toString()?.trim().orEmpty(),
            stateDescription = stateDescription?.toString()?.trim().orEmpty(),
            error = error?.toString()?.trim().orEmpty(),
            isScrollable = isScrollable,
            isDismissable = isDismissable,
            isCheckable = isCheckable,
            isChecked = if (isCheckable) isChecked else null,
            isEditable = isEditable,
            inputType = if (isEditable) inputType else 0,
            maxTextLength = if (isEditable) maxTextLength else -1,
            isPassword = if (isEditable) isPassword else false,
            isVisibleToUser = isVisibleToUser,
            drawingOrder = drawingOrder.toString().trim(),
            bounds = bounds
        )
    }

    private inline fun <T> AccessibilityNodeInfo?.useNode(block: (AccessibilityNodeInfo) -> T): T? {
        return this?.let { node ->
            try {
                block(node)
            } finally {
                try {
                    node.recycle()
                } catch (e: Exception) {
                    Log.e(TAG, "Error recycling node: ${e.message}")
                }
            }
        }
    }

    fun traverseNodes(
        node: AccessibilityNodeInfo?,
        action: (AccessibilityNodeInfo, NodeState) -> Unit
    ) {
        if (node == null) return

        var nodeState: NodeState? = null
        try {
            nodeState = node.toNodeState()
            action(node, nodeState)
        } catch (e: IllegalStateException) {
            Log.e(TAG, "Node is invalid or has been recycled: ${e.message}")
            return
        } catch (e: Exception) {
            Log.e(TAG, "Error processing node: ${e.message}")
            return
        }

        val childCount = try {
            node.childCount
        } catch (e: Exception) {
            Log.e(TAG, "Error getting child count: ${e.message}")
            0
        }

        for (i in 0 until childCount) {
            try {
                node.getChild(i).useNode { child ->
                    traverseNodes(child, action)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing child node $i: ${e.message}")
            }
        }
    }

    fun NodeState.toDescription(depth: Int = 0): String = buildString {
        append(" | [WindowId: $windowId]")
        append(" | [HashCode: $hashCode]")
        append("${" ".repeat(depth * 2)}")
        append(" | [$packageName]")
        if (viewIdResourceName != null) append(" | [$viewIdResourceName]")
        if (error.isNotEmpty()) append(" | [error: $error]")
        if (!isVisibleToUser) append(" [hidden]")
        if (isScrollable) append("[isScrollable]")
        append(" + $className:")
        if (text.isNotEmpty()) append(" | [Text: $text]")
        if (contentDescription.isNotEmpty()) append(" | [Desc: $contentDescription]")
        if (tooltipText.isNotEmpty()) append(" | [tooltipText: $tooltipText]")
        if (hintText.isNotEmpty()) append(" | [hintText: $hintText]")
        if (paneTitle.isNotEmpty()) append(" | [paneTitle: $paneTitle]")
        if (containerTitle.isNotEmpty()) append(" | [containerTitle: $containerTitle]")
        if (stateDescription.isNotEmpty()) append(" | [stateDescription: $stateDescription]")
        if (isDismissable == true) append(" | [isDismissable]")
        if (isCheckable) {
            append(" | [isCheckable]")
            if (isChecked == false) append(" | [notChecked]")
        }
        if (isEditable) {
            append(" | [isEditable]")
            if (inputType != 0) append(" | [inputType: $inputType]")
            if (maxTextLength > 0) append(" | [maxTextLength: $maxTextLength]")
            if (isPassword) append(" | [isPassword]")
        }
        if (drawingOrder.isNotEmpty()) append(" | [$drawingOrder]")
        append("[${bounds.toShortString()}]")
    }

    private fun Rect.toShortString(): String = "[$left, $top, $right, $bottom]"
}
