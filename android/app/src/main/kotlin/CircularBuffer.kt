package com.example.company_app

class CircularBuffer<T>(private val capacity: Int) {
    private val buffer = arrayOfNulls<Any>(capacity)
    private var head = 0
    private var size = 0

    fun add(item: T) {
        buffer[head] = item
        head = (head + 1) % capacity
        if (size < capacity) size++
    }

    fun forEach(action: (T) -> Unit) {
        for (i in 0 until size) {
            @Suppress("UNCHECKED_CAST")
            action(buffer[(head - size + i + capacity) % capacity] as T)
        }
    }

    fun clear() {
        for (i in 0 until capacity) {
            buffer[i] = null
        }
        head = 0
        size = 0
    }
}
