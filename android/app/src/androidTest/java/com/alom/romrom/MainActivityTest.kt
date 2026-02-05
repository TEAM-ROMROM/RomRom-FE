package com.alom.romrom

import pl.leancode.patrol.PatrolJUnitRunner

class MainActivityTest {
    @org.junit.Test
    fun runPatrolTest() {
        PatrolJUnitRunner.setUp(MainActivityTest::class.java)
        PatrolJUnitRunner.main(arrayOf())
    }
}
