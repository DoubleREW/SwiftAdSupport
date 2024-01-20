//
//  UsageCounter.swift
//  NetworkUtility-iOS
//
//  Created by Fausto Ristagno on 04/01/18.
//  Copyright © 2018 Fausto Ristagno. All rights reserved.
//
import Foundation

public struct UsageCounterContext: RawRepresentable, Hashable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension UsageCounterContext {
    static let `default` = UsageCounterContext(rawValue: "default")
}

public protocol UsageCounterStorage {
    func setCounter(_ value: Int, forKey key: String, in context: UsageCounterContext)
    func counterValue(forKey key: String, in context: UsageCounterContext) -> Int
    func clear(context: UsageCounterContext)
}

public protocol DateResolver {
    func now() -> Date
}

public protocol UsageCounter {
    func increment()
    func reset(force: Bool)
    func isLimitReached() -> Bool
}

public extension UsageCounter {
    func reset() {
        reset(force: false)
    }
}

public struct SystemDateResolver : DateResolver {
    public static let `default` = SystemDateResolver()
    
    public func now() -> Date {
        return Date()
    }
}

public struct UserDefaultsCounterStorage : UsageCounterStorage {
    private let storageName: String
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults = UserDefaults.standard, storageName: String = "usage_counters") {
        self.userDefaults = userDefaults
        self.storageName = storageName
    }
    
    private func storageKey(for key: String, in context: UsageCounterContext) -> String {
        return "\(context.rawValue)__\(key)"
    }
    
    public func setCounter(_ value: Int, forKey key: String, in context: UsageCounterContext) {
        let storeKey = storageKey(for: key, in: context)
        var values = self.userDefaults.object(forKey: storageName) as? [String: Int] ?? [String: Int]()
        values[storeKey] = value
        
        self.userDefaults.set(values, forKey: storageName)
        self.userDefaults.synchronize()
    }
    
    public func counterValue(forKey key: String, in context: UsageCounterContext) -> Int {
        guard let values = self.userDefaults.object(forKey: storageName) as? [String: Int] else {
            return 0
        }
        
        let storeKey = storageKey(for: key, in: context)
        
        return values[storeKey] ?? 0
    }
    
    public func clear(context: UsageCounterContext) {
        self.userDefaults.removeObject(forKey: storageName)
        self.userDefaults.synchronize()
    }
}

public struct TimeBasedUsageCounter : UsageCounter {
    public let name: String
    public let context: UsageCounterContext
    public let timeUnit: TimeUnit
    public let limit: Int
    public let resetRule: ResetRule

    private var storage: UsageCounterStorage
    private var dateResolver: DateResolver
    private var dateFormatter: DateFormatter

    public enum TimeUnit: Int {
        case day
        case month
    }

    public enum ResetRule: Int {
        case always
        case onlyReached
        case never
    }

    public init(
        name: String,
        context: UsageCounterContext,
        timeUnit: TimeUnit,
        limit: Int,
        resetRule: ResetRule = .always,
        storage: UsageCounterStorage = UserDefaultsCounterStorage(),
        dateResolver: DateResolver = SystemDateResolver.default) {
        self.name = name
        self.context = context
        self.timeUnit = timeUnit
        self.limit = limit
        self.resetRule = resetRule
        self.storage = storage
        self.dateResolver = dateResolver
        self.dateFormatter = DateFormatter()
        
        switch self.timeUnit {
        case .day:
            self.dateFormatter.dateFormat = "'D_'yyyyDDD"
        case .month:
            self.dateFormatter.dateFormat = "'M_'yyyyMM"
        }
    }
    
    private func storeKey() -> String {
        let now = self.dateResolver.now()
        let dateKey = self.dateFormatter.string(from: now)

        return "\(self.name)_\(dateKey)"
    }
    
    private func setUsages(_ usages: Int) {
        let key = self.storeKey()
        self.storage.setCounter(usages, forKey: key, in: self.context)
    }

    private func canReset() -> Bool {
        switch resetRule {
        case .always:
            return true
        case .onlyReached:
            return isLimitReached()
        case .never:
            return false
        }
    }

    public func usages() -> Int {
        return self.storage.counterValue(forKey: storeKey(), in: self.context)
    }
    
    public func increment() {
        let usages = self.usages()
        self.setUsages(usages + 1)
    }
    
    public func reset(force: Bool) {
        if force || canReset() {
            self.setUsages(0)
        }
    }
    
    public func isLimitReached() -> Bool {
        return self.usages() > limit
    }
}

public struct CompoundUsageCounter : UsageCounter {
    public let counters: [UsageCounter]
    public let rule: GroupRule
    
    public enum GroupRule {
        case any, all
    }
    
    public init(counters: [UsageCounter], rule: GroupRule = .all) {
        self.counters = counters
        self.rule = rule
    }
    
    public func increment() {
        self.counters.forEach { $0.increment() }
    }
    
    public func reset(force: Bool) {
        self.counters.forEach { $0.reset(force: force) }
    }
    
    public func isLimitReached() -> Bool {
        if self.rule == .all {
            return self.counters.allSatisfy { $0.isLimitReached() }
        } else {
            return self.counters.contains { $0.isLimitReached() }
        }
    }
}
