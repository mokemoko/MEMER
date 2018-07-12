//
//  HKManager.swift
//  SelfOpenData
//
//  Created by 浅野　宏明 on 2018/05/21.
//  Copyright © 2018年 akylab. All rights reserved.
//

import HealthKit

final class HKManager {
    struct Setting {
        let type: HKQuantityType
        let option: HKStatisticsOptions
        let unit: HKUnit
        
        init(id: HKQuantityTypeIdentifier, option: HKStatisticsOptions, unit: HKUnit) {
            self.type = HKObjectType.quantityType(forIdentifier: id)!
            self.option = option
            self.unit = unit
            HKUnit.meter()
        }
    }

    static let shared = HKManager()
    
    static let targetList: [Setting] = [
        Setting(id: .activeEnergyBurned, option: .cumulativeSum, unit: HKUnit.kilocalorie()),   // アクティブエネルギー
        Setting(id: .basalEnergyBurned, option: .cumulativeSum, unit: HKUnit.kilocalorie()),    // 安静時消費エネルギー
        // スタンド時間 HKCategoryType?
        Setting(id: .stepCount, option: .cumulativeSum, unit: HKUnit.count()),                  // 歩数
        Setting(id: .distanceWalkingRunning, option: .cumulativeSum, unit: HKUnit.meter()),     // ウォーキング+ランニングの距離
        Setting(id: .appleExerciseTime, option: .cumulativeSum, unit: HKUnit.minute()),         // エクササイズ時間
        Setting(id: .flightsClimbed, option: .cumulativeSum, unit: HKUnit.count()),             // 登った階数
        Setting(id: .heartRate, option: .discreteAverage, unit: HKUnit.count().unitDivided(by: HKUnit.minute())), // 心拍数
    ]
    
    private let store = HKHealthStore()
    
    private init() {}
    
    func setup() {
        let targetType = type(of: self).targetList.map { $0.type }
        HKHealthStore().requestAuthorization(toShare: nil, read: Set(targetType)) { success, error in
            if let error = error {
                print(error)
            }
        }
    }
    
    func getAllData() {
        type(of: self).targetList.forEach { setting in
            getData(with: setting)
        }
    }
    
    func getData(with setting: Setting) {
        let calendar = Calendar(identifier: .gregorian)
        let end = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: DateComponents(day: -30), to: end)!
        let interval = DateComponents(day: 1)
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        
        let query = HKStatisticsCollectionQuery(quantityType: setting.type,
                                                quantitySamplePredicate: predicate,
                                                options: setting.option,
                                                anchorDate: end,
                                                intervalComponents: interval)

        query.initialResultsHandler = { query, result, error in
            guard let result = result, error == nil else{
                return
            }
            print("##### \(setting.type.identifier) #####")
            result.statistics().forEach { item in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let date = formatter.string(from: item.startDate)
                let value: Int
                if (setting.option == .cumulativeSum) {
                    value = Int(item.sumQuantity()!.doubleValue(for: setting.unit))
                } else if (setting.option == .discreteAverage) {
                    value = Int(item.averageQuantity()!.doubleValue(for: setting.unit))
                } else {
                    // TODO: improve
                    value = 0
                }
                print("\(date) : \(value)")
                
                FirebaseManager.shared.update(type: .health, additionalPath: date, data: [
                    setting.type.identifier: value
                    ])
            }
        }

        store.execute(query)
    }
}
