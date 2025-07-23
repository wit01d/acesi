package com.example.company_app

import android.graphics.Rect
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class UserInteraction {
    companion object {
        private const val TAG = "UserInteraction"
        private const val SCROLL_THRESHOLD = 50
    }

    private var lastScrollPosition = Rect()
    private var lastScrollTime = 0L

    fun handleClickEvent(event: AccessibilityEvent) {
        val node = event.source
        try {
            node?.let {
                val clickInfo = StringBuilder().apply {
                    append("Click detected:")
                    append(" | Class: ${it.className}")
                    append(" | Text: ${it.text}")
                    append(" | ContentDesc: ${it.contentDescription}")

                    val bounds = Rect()
                    it.getBoundsInScreen(bounds)
                    append(" | Location: ${bounds.toShortString()}")


                    val parent = it.parent
                    if (parent != null) {
                        append(" | Parent: ${parent.className}")
                        parent.recycle()
                    }
                }
                Log.d(TAG, clickInfo.toString())
            }
        } finally {
            node?.recycle()
        }
    }

    fun handleScrollEvent(event: AccessibilityEvent) {
        val node = event.source
        try {
            node?.let {
                val currentTime = System.currentTimeMillis()
                val bounds = Rect()
                it.getBoundsInScreen(bounds)


                val verticalScroll = bounds.top - lastScrollPosition.top
                val horizontalScroll = bounds.left - lastScrollPosition.left
                val timeDelta = currentTime - lastScrollTime

                if (Math.abs(verticalScroll) > SCROLL_THRESHOLD ||
                    Math.abs(horizontalScroll) > SCROLL_THRESHOLD) {

                    val scrollInfo = StringBuilder().apply {
                        append("Scroll detected:")
                        append(" | Class: ${it.className}")
                        append(" | Direction: ${getScrollDirection(verticalScroll, horizontalScroll)}")
                        append(" | Distance: v=${verticalScroll}px, h=${horizontalScroll}px")
                        append(" | Speed: ${calculateScrollSpeed(verticalScroll, horizontalScroll, timeDelta)}px/s")
                        append(" | Location: ${bounds.toShortString()}")


                        if (it.isScrollable) {
                            append(" | Scrollable: true")
                            append(" | From index: ${event.fromIndex}")
                            append(" | To index: ${event.toIndex}")
                            append(" | Item count: ${event.itemCount}")
                        }
                    }
                    Log.d(TAG, scrollInfo.toString())

                    lastScrollPosition.set(bounds)
                    lastScrollTime = currentTime
                }
            }
        } finally {
            node?.recycle()
        }
    }

    private fun getScrollDirection(vertical: Int, horizontal: Int): String {
        val directions = mutableListOf<String>()
        if (vertical < 0) directions.add("UP")
        if (vertical > 0) directions.add("DOWN")
        if (horizontal < 0) directions.add("LEFT")
        if (horizontal > 0) directions.add("RIGHT")
        return if (directions.isEmpty()) "NONE" else directions.joinToString("+")
    }

    private fun calculateScrollSpeed(vertical: Int, horizontal: Int, timeDelta: Long): Int {
        if (timeDelta == 0L) return 0
        val distance = Math.sqrt((vertical * vertical + horizontal * horizontal).toDouble())
        return (distance / timeDelta * 1000).toInt()
    }

    private fun Rect.toShortString(): String = "[${left}, ${top}, ${right}, ${bottom}]"
}
