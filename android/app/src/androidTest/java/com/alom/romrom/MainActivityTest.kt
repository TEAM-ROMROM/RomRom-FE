package com.alom.romrom

import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import org.junit.runners.Parameterized.Parameters
import pl.leancode.patrol.PatrolJUnitRunner

@RunWith(Parameterized::class)
class MainActivityTest(private val dartTest: String) {
    companion object {
        @JvmStatic
        @Parameters(name = "{0}")
        fun testCases(): List<String> {
            val instrumentation = InstrumentationRegistry.getInstrumentation() as PatrolJUnitRunner

            // 1) 앱을 실행하고 PatrolAppServiceClient를 초기화
            instrumentation.setUp(MainActivity::class.java)

            // 2) Dart 쪽 PatrolAppService가 준비될 때까지 대기
            instrumentation.waitForPatrolAppService()

            // 3) Dart 테스트 목록 가져오기
            return instrumentation.listDartTests().map { it.toString() }
        }
    }

    @Test
    fun runTest() {
        val instrumentation = InstrumentationRegistry.getInstrumentation() as PatrolJUnitRunner
        instrumentation.runDartTest(dartTest)
    }
}
