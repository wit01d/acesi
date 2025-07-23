// package com.example.company_app

// import android.graphics.Rect
// import android.view.accessibility.AccessibilityEvent
// import android.view.accessibility.AccessibilityNodeInfo

// class HierarchyReader {
//     companion object {
//         private const val TAG = "HierarchyReader"
//     }

//     data class NodeInfo(
//         val depth: Int,
//         val windowId: Int,
//         val hashCode: Int,
//         val className: CharSequence?,
//         val bounds: Rect,
//         val text: String = "",
//         val contentDescription: String = "",
//         val tooltipText: String = "",
//         val hintText: String = "",
//         val paneTitle: String = "",
//         val containerTitle: String = "",
//         val stateDescription: String = "",
//         val error: String = "",
//         val isScrollable: Boolean = false,
//         val isDismissable: Boolean? = null,
//         val isCheckable: Boolean = false,
//         val isChecked: Boolean? = null,
//         val isEditable: Boolean = false,
//         val inputType: Int = 0,
//         val maxTextLength: Int = -1,
//         val isPassword: Boolean = false,
//         val isVisibleToUser: Boolean = true,
//         val drawingOrder: String = "",
//         val children: List<NodeInfo> = emptyList()
//     )

//     fun readViewHierarchy(node: AccessibilityNodeInfo?, depth: Int, event: AccessibilityEvent): NodeInfo? {
//         if (node == null) return null

//         try {
//             val isScrollable = node.isScrollable
//             val error = node.error?.toString()?.trim().orEmpty()

//             val text = node.text?.toString()?.trim().orEmpty()
//             val constDesc = node.contentDescription?.toString()?.trim().orEmpty()
//             val tooltipText = node.tooltipText?.toString()?.trim().orEmpty()
//             val hintText = node.hintText?.toString()?.trim().orEmpty()
//             val paneTitle = node.paneTitle?.toString()?.trim().orEmpty()
//             val containerTitle = node.containerTitle?.toString()?.trim().orEmpty()
//             val stateDescription = node.stateDescription?.toString()?.trim().orEmpty()

//             val hasContent = text.isNotEmpty() || constDesc.isNotEmpty() || tooltipText.isNotEmpty() || stateDescription.isNotEmpty() ||
//                 hintText.isNotEmpty() || paneTitle.isNotEmpty() || containerTitle.isNotEmpty() || error.isNotEmpty() || isScrollable

//             // Process children first
//             val children = mutableListOf<NodeInfo>()
//             val childCount = node.childCount
//             for (i in 0 until childCount) {
//                 val child = node.getChild(i)
//                 try {
//                     if (child != null) {
//                         readViewHierarchy(child, depth + 1, event)?.let { children.add(it) }
//                     }
//                 } finally {
//                     child?.recycle()
//                 }
//             }

//             if (!hasContent && children.isEmpty()) return null

//             val nodeScreenBounds = Rect().also {
//                 node.getBoundsInScreen(it)
//             }

//             return NodeInfo(
//                 depth = depth,
//                 windowId = node.windowId,
//                 hashCode = node.hashCode(),
//                 className = node.className,
//                 bounds = nodeScreenBounds,
//                 text = text,
//                 contentDescription = constDesc,
//                 tooltipText = tooltipText,
//                 hintText = hintText,
//                 paneTitle = paneTitle,
//                 containerTitle = containerTitle,
//                 stateDescription = stateDescription,
//                 error = error,
//                 isScrollable = isScrollable,
//                 isDismissable = if (node.isDismissable) true else null,
//                 isCheckable = node.isCheckable,
//                 isChecked = if (node.isCheckable) node.isChecked else null,
//                 isEditable = node.isEditable,
//                 inputType = if (node.isEditable) node.inputType else 0,
//                 maxTextLength = if (node.isEditable) node.maxTextLength else -1,
//                 isPassword = if (node.isEditable) node.isPassword else false,
//                 isVisibleToUser = node.isVisibleToUser,
//                 drawingOrder = node.drawingOrder?.toString()?.trim().orEmpty(),
//                 children = children
//             )
//         } catch (e: Exception) {
//             return null
//         }
//     }
// }

//     fun getNodeBounds(node: AccessibilityNodeInfo): Rect {
//         val bounds = Rect()
//         node.getBoundsInScreen(bounds)
//         return bounds
//     }


//     private fun logViewHierarchy(node: AccessibilityNodeInfo?, depth: Int, event: AccessibilityEvent) {
//         if (node == null) return

//         try {
//             val isScrollable = node.isScrollable
//             val error = node.error?.toString()?.trim().orEmpty()

//             val text = node.text?.toString()?.trim().orEmpty()
//             val constDesc = node.contentDescription?.toString()?.trim().orEmpty()
//             val tooltipText = node.tooltipText?.toString()?.trim().orEmpty()
//             val hintText = node.hintText?.toString()?.trim().orEmpty()
//             val paneTitle = node.paneTitle?.toString()?.trim().orEmpty()
//             val containerTitle = node.containerTitle?.toString()?.trim().orEmpty()
//             val stateDescription = node.stateDescription?.toString()?.trim().orEmpty()

//             // Check for content first and return early if none exists
//             val hasContent = text.isNotEmpty() || constDesc.isNotEmpty() || tooltipText.isNotEmpty() || stateDescription.isNotEmpty() ||
//                 hintText.isNotEmpty() || paneTitle.isNotEmpty() || containerTitle.isNotEmpty() || error.isNotEmpty() || isScrollable

//             if (!hasContent) {
//                 // Process children even if current node has no content
//                 val childCount = node.childCount
//                 for (i in 0 until childCount) {
//                     val child = node.getChild(i)
//                     try {
//                         if (child != null) {
//                             logViewHierarchy(child, depth + 1, event)
//                         }
//                     } finally {
//                         child?.recycle()
//                     }
//                 }
//                 return
//             }

//             val hashCode = node.hashCode()
//             val windowId = node.windowId
//             val systemHashCode = System.identityHashCode(node)
//             val nodeScreenBounds = Rect().also {
//                 node.getBoundsInScreen(it)
//             }

//             // Now we know we have content, we can check these properties

//             val isDismissable = if (node.isDismissable) true else null
//             val isCheckable = node.isCheckable
//             val isChecked = if (isCheckable == true) node.isChecked else null

//             val isEditable = node.isEditable == true
//             // Only get these values if the node is editable
//             val inputType = if (isEditable) node.inputType else 0
//             val maxTextLength = if (isEditable) node.maxTextLength else -1
//             val isPassword = if (isEditable) node.isPassword else false
//             val isVisibleToUser = node.isVisibleToUser == false
//             val drawingOrder = node.drawingOrder?.toString()?.trim().orEmpty()

//             // Simplified logging focused on content changes
//             val info = StringBuilder().apply {
//                 append(" | [WindowId: $windowId]")
//                 append(" | [HashCode: $hashCode]")
//                 append("--".repeat(depth))
//                 if (error.isNotEmpty()) append(" | [error: $error]")
//                 if (isVisibleToUser) append(" [hiddenUI]")
//                 if (isScrollable == true) append(" isScrollable")

//                 append(" + ${node.className}:")
//                 if (text.isNotEmpty()) append(" | [Text: $text]")
//                 if (constDesc.isNotEmpty()) append(" | [Desc: $constDesc]")
//                 if (tooltipText.isNotEmpty()) append(" | [tooltipText: $tooltipText]")
//                 if (hintText.isNotEmpty()) append(" | [hintText: $hintText]")
//                 if (paneTitle.isNotEmpty()) append(" | [paneTitle: $paneTitle]")
//                 if (containerTitle.isNotEmpty()) append(" | [containerTitle: $containerTitle]")
//                 if (stateDescription.isNotEmpty()) append(" | [stateDescription: $stateDescription]")

//                 if (isDismissable == true) append(" | [isDismissable]")
//                 if (isCheckable == true) {
//                     append(" | [isCheckable]")
//                     if (isChecked == false) append(" | [notChecked]")
//                 }
//                 if (isEditable) {
//                     append(" | [isEditable: $isEditable]")
//                     if (inputType != 0) append(" | [inputType: $inputType]")
//                     if (maxTextLength > 0) append(" | [maxTextLength: $maxTextLength]")
//                     if (isPassword) append(" | [isPassword: $isPassword]")
//                 }
//                 if (drawingOrder.isNotEmpty()) append(" | [drawingOrder: $drawingOrder]")
//                 append(" | Bounds: ${nodeScreenBounds.toShortString()}")
//             }

//             Log.d(TAG, info.toString())

//             // Process children with safe access
//             try {
//                 val childCount = node.childCount
//                 for (i in 0 until childCount) {
//                     try {
//                         val child = node.getChild(i) ?: continue
//                         logViewHierarchy(child, depth + 1, event)
//                         child.recycle()
//                     } catch (e: Exception) {
//                         Log.e(TAG, "Error accessing child $i: ${e.message}")
//                     }
//                 }
//             } catch (e: Exception) {
//                 Log.e(TAG, "Error getting childCount: ${e.message}")
//             }
//         } catch (e: Exception) {
//             Log.e(TAG, "Error processing node: ${e.message}")
//         }
//     }
