//
//  VelocityTests.swift
//  GXSwiftDemoTests
//
//  Created by sgx on 2025/12/5.
//

import XCTest

final class VelocityTests: XCTestCase {
    
    // 用于 V2 算法的状态维护
    private var lastVelocity: CGFloat = 0
    private var lastTime: TimeInterval = 0
    private var currentScale: CGFloat = 1.0
    private var velocity: CGFloat = 0  // 当前的缩放速度

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testVelocity1() throws {
        lastTime = Date().timeIntervalSince1970
        
        let t1 = calculateDurationV1(velocity: 4000)
        print("--- \(t1)")
        let t2 = calculateDurationV1(velocity: 3000)
        print("--- \(t2)")
        let t3 = calculateDurationV1(velocity: 2000)
        print("--- \(t3)")
        let t4 = calculateDurationV1(velocity: 1000)
        print("--- \(t4)")
        let t5 = calculateDurationV1(velocity: 500)
        print("--- \(t5)")
        let t6 = calculateDurationV1(velocity: 100)
        print("--- \(t6)")
        
        print("------------------")
        

    }
    
    func testVelocity2() throws {
        let tt1 = calculateDurationV2(velocity: 4000)
        let tt2 = calculateDurationV2(velocity: 3000)
        let tt3 = calculateDurationV2(velocity: 2000)
        let tt4 = calculateDurationV2(velocity: 1000)
        let tt5 = calculateDurationV2(velocity: 500)
        let tt6 = calculateDurationV2(velocity: 100)
        print("--- \(tt1)")
        print("--- \(tt2)")
        print("--- \(tt3)")
        print("--- \(tt4)")
        print("--- \(tt5)")
        print("--- \(tt6)")
    }
    
    func testVelocity3() throws {
        let tt1 = calculateDurationV3(velocity: 4000)
        let tt2 = calculateDurationV3(velocity: 3000)
        let tt3 = calculateDurationV3(velocity: 2000)
        let tt4 = calculateDurationV3(velocity: 1000)
        let tt5 = calculateDurationV3(velocity: 500)
        let tt6 = calculateDurationV3(velocity: 100)
        print("--- \(tt1)")
        print("--- \(tt2)")
        print("--- \(tt3)")
        print("--- \(tt4)")
        print("--- \(tt5)")
        print("--- \(tt6)")
    }
}

extension VelocityTests {
    /// 根据滑动速度动态计算动画时长
    /// - Parameters:
    ///   - v: 滑动速度（px/ms）
    /// - Returns: 动画时长（秒）
    private func calculateDurationV1(velocity v: CGFloat) -> CGFloat {
        let maxV: CGFloat = 5000.0  // 最大手势速度（px/ms）
        let k: CGFloat = 0.003    // 调整系数
        let exponent: CGFloat = 0.7 // 指数，0.5-0.8之间

        // 归一化速度（0-1之间）
        let normalizedV = min(abs(v) / maxV, 1.0)

        // 使用幂函数让曲线更自然
        var scaleSpeed = k * pow(normalizedV, exponent)

        // 根据当前缩放比例调整灵敏度
        // 放大时稍微慢一些，缩小时快一些（符合物理直觉）
        if v > 0 { // 假设v>0表示放大手势
            scaleSpeed *= 1.0
        } else {
            scaleSpeed *= 0.8
        }

        let finalSpeed = scaleSpeed * (v >= 0 ? 1 : -1)

        // 根据速度计算duration：速度越快，duration越短
        // 当速度为0时，使用默认值0.3秒
        if abs(finalSpeed) < 0.0001 {
            return 0.3
        }

        // 速度越大，duration越小，范围控制在0.1-0.5秒之间
        let duration = max(0.1, min(0.5, 0.3 / abs(normalizedV + 0.1)))
        print("sgx >>>> duration: \(duration)")
        return duration
        

    }
    
    private func calculateDurationV3(velocity v: CGFloat) -> CGFloat {
        // 1. 取绝对值
        let absVelocity = abs(v)

        // 2. 定义速度范围
        let minVelocity: CGFloat = 100   // 慢速阈值（点/秒）
        let maxVelocity: CGFloat = 2000  // 快速阈值（点/秒）

        // 3. 归一化到0-1范围
        let normalizedVelocity = min(max((absVelocity - minVelocity) / (maxVelocity - minVelocity), 0), 1)

        // 4. 映射到duration范围（速度越快，duration越短）
        let minDuration: CGFloat = 0.15  // 最短时长（快速滑动）
        let maxDuration: CGFloat = 0.4   // 最长时长（慢速滑动）
        let duration = maxDuration - (normalizedVelocity * (maxDuration - minDuration))

        return duration
    }

    /// 基于物理模型的 duration 计算（考虑加速度、惯性、边界）
    /// - Parameter v: 当前手势速度（px/ms）
    /// - Returns: 动画时长（秒）
    private func calculateDurationV2(velocity v: CGFloat) -> CGFloat {
        let currentTime = Date().timeIntervalSince1970

        // 计算时间间隔（转换为毫秒）
        let deltaTime = CGFloat((currentTime - lastTime) * 1000)
        let safetyDeltaTime = deltaTime > 0 ? deltaTime : 16 // 默认 16ms

        // 计算加速度（速度变化率）
        let acceleration = (v - lastVelocity) / safetyDeltaTime

        // 物理模型参数
        let k1: CGFloat = 0.002   // 速度系数
        let k2: CGFloat = 0.0005  // 加速度系数
        let friction: CGFloat = 0.95 // 阻力系数

        // 基础响应部分：速度 + 加速度贡献
        let scaleSpeed = k1 * v + k2 * acceleration

        // 添加惯性：当前缩放速度受上次影响
        velocity = velocity * friction + scaleSpeed

        // 边界处理：放大/缩小到极限时减速
        if currentScale > 3.0 {
            velocity *= 0.8 // 放大到极限时减速
        } else if currentScale < 0.5 {
            velocity *= 0.8 // 缩小到极限时减速
        }

        // 更新缩放比例（模拟）
        currentScale += velocity * safetyDeltaTime

        // 限制缩放范围
        currentScale = max(0.1, min(5.0, currentScale))

        // 保存状态用于下次计算
        lastVelocity = v
        lastTime = currentTime

        // 根据计算出的速度决定 duration
        // 速度越大，duration 越短；考虑惯性效果
        let baseSpeed = abs(velocity)

        // 当速度很小时，使用默认 duration
        if baseSpeed < 0.0001 {
            return 0.3
        }

        // 速度映射到 duration：速度越快，duration 越短
        // 范围：0.1s - 0.5s
        let normalizedSpeed = min(baseSpeed / 0.01, 1.0) // 归一化到 0-1
        let duration = max(0.1, min(0.5, 0.5 - normalizedSpeed * 0.4))

        print("sgx >>>> V2 duration: \(duration), velocity: \(velocity), scale: \(currentScale)")

        return duration
    }
}
