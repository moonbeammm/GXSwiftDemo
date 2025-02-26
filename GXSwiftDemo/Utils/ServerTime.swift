//
//  ServerTime.swift
//  GXSwiftDemo
//
//  Created by 孙广鑫 on 2025/1/5.
//

import Foundation

extension Notification.Name {
    static let serverTimeBaselineDidChange = Notification.Name("com.bilibili.quiz.server_time_sync")
}

class ServerTime {
    static let shared = ServerTime()
    
    private var serverTimestamp: TimeInterval = 0
    private var syncMachTime: UInt64 = 0
    private var timebase: mach_timebase_info_data_t = mach_timebase_info_data_t()
    
    private init() {
        mach_timebase_info(&timebase)
    }
    
    // MARK: - Public Methods
    
    /// 获取当前服务器时间
    var currentServerTime: TimeInterval {
        let currentMachTime = mach_absolute_time()
        let elapsedNano = Double(currentMachTime - syncMachTime) * Double(timebase.numer) / Double(timebase.denom)
        let elapsedSeconds = elapsedNano / Double(NSEC_PER_SEC)
        return serverTimestamp + elapsedSeconds
    }
    
    var integerServerTime: Int64 {
        Int64(currentServerTime)
    }
    
    var floorServerTime: TimeInterval {
        floor(currentServerTime)
    }
    
    /// ！！！需要手动同步服务器时间
    /// 比如app启动时从接口拿到时间，然后调用此方法同步
    func sync(serverTimestamp: TimeInterval) {
        self.serverTimestamp = serverTimestamp
        self.syncMachTime = mach_absolute_time()
    }
}
