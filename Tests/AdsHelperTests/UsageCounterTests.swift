//
//  NetworkUtility_iOS_Tests.swift
//  NetworkUtility-iOS-Tests
//
//  Created by Fausto Ristagno on 27/02/21.
//  Copyright © 2021 Fausto Ristagno. All rights reserved.
//

import XCTest
@testable import AdsHelper

class UsageCounterTests: XCTestCase {
    var userDefaults: UserDefaults?
    let userDefaultsSuiteName = "TestDefaults"
    
    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)
    }

    override func tearDownWithError() throws {
        UserDefaults().removePersistentDomain(forName: userDefaultsSuiteName)
    }

    func testUsageCounter() throws {
        let storage = UserDefaultsCounterStorage(userDefaults: userDefaults!)
        let counter = TimeBasedUsageCounter(
            name: "test_counter",
            context: .default,
            timeUnit: .day,
            limit: 3,
            storage: storage)
        
        XCTAssertEqual(counter.limit, 3)
        XCTAssertEqual(counter.usages(), 0)
        XCTAssertFalse(counter.isLimitReached())
        
        counter.increment()
        XCTAssertEqual(counter.usages(), 1)
        XCTAssertFalse(counter.isLimitReached())
        
        counter.increment()
        XCTAssertEqual(counter.usages(), 2)
        XCTAssertFalse(counter.isLimitReached())
        
        counter.increment()
        XCTAssertEqual(counter.usages(), 3)
        XCTAssertFalse(counter.isLimitReached())
        
        counter.increment()
        XCTAssertEqual(counter.usages(), 4)
        XCTAssertTrue(counter.isLimitReached())
        
        counter.reset()
        XCTAssertEqual(counter.usages(), 0)
        XCTAssertFalse(counter.isLimitReached())
    }
    
    func testUsageCounterDayChange() throws {
        let storage = UserDefaultsCounterStorage(userDefaults: userDefaults!)
        let dateResolver = FakeDateResolver()
        let dayCounter = TimeBasedUsageCounter(
            name: "day_counter",
            context: .default,
            timeUnit: .day,
            limit: 3,
            storage: storage,
            dateResolver: dateResolver)
        let monthCounter = TimeBasedUsageCounter(
            name: "month_counter",
            context: .default,
            timeUnit: .month,
            limit: 3,
            storage: storage,
            dateResolver: dateResolver)
        
        dateResolver.setResolvedDate(isoDate: "2016-04-14T12:00:00+0000")
        
        XCTAssertEqual(dayCounter.usages(), 0)
        dayCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 1)
        
        XCTAssertEqual(monthCounter.usages(), 0)
        monthCounter.increment()
        XCTAssertEqual(monthCounter.usages(), 1)
        
        dateResolver.setResolvedDate(isoDate: "2016-04-15T12:00:00+0000")
        
        XCTAssertEqual(dayCounter.usages(), 0)
        dayCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 1)
        
        XCTAssertEqual(monthCounter.usages(), 1)
        monthCounter.increment()
        XCTAssertEqual(monthCounter.usages(), 2)
        
        dateResolver.setResolvedDate(isoDate: "2016-05-15T12:00:00+0000")
        
        XCTAssertEqual(dayCounter.usages(), 0)
        dayCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 1)
        
        XCTAssertEqual(monthCounter.usages(), 0)
        monthCounter.increment()
        XCTAssertEqual(monthCounter.usages(), 1)
    }

    func testCompoundUsageCounterAny() throws {
        let storage = UserDefaultsCounterStorage(userDefaults: userDefaults!)
        let dateResolver = FakeDateResolver()
        let dayCounter = TimeBasedUsageCounter(
            name: "day_counter",
            context: .default,
            timeUnit: .day,
            limit: 3,
            storage: storage,
            dateResolver: dateResolver)
        let monthCounter = TimeBasedUsageCounter(
            name: "month_counter",
            context: .default,
            timeUnit: .month,
            limit: 5,
            storage: storage,
            dateResolver: dateResolver)
        let anyCompoundCounter = CompoundUsageCounter(
            counters: [dayCounter, monthCounter],
            rule: .any)
        
        dateResolver.setResolvedDate(isoDate: "2016-04-14T12:00:00+0000")
        
        XCTAssertEqual(dayCounter.usages(), 0)
        XCTAssertEqual(monthCounter.usages(), 0)
        
        anyCompoundCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 1)
        XCTAssertEqual(monthCounter.usages(), 1)
        XCTAssertFalse(anyCompoundCounter.isLimitReached())
        
        anyCompoundCounter.increment()
        anyCompoundCounter.increment()
        anyCompoundCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 4)
        XCTAssertEqual(monthCounter.usages(), 4)
        XCTAssertTrue(anyCompoundCounter.isLimitReached())
        
        dateResolver.setResolvedDate(isoDate: "2016-04-15T12:00:00+0000")
        
        anyCompoundCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 1)
        XCTAssertEqual(monthCounter.usages(), 5)
        XCTAssertFalse(anyCompoundCounter.isLimitReached())
        
        dateResolver.setResolvedDate(isoDate: "2016-04-16T12:00:00+0000")
        
        anyCompoundCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 1)
        XCTAssertEqual(monthCounter.usages(), 6)
        XCTAssertTrue(anyCompoundCounter.isLimitReached())
        
        anyCompoundCounter.reset()
        XCTAssertEqual(dayCounter.usages(), 0)
        XCTAssertEqual(monthCounter.usages(), 0)
        XCTAssertFalse(anyCompoundCounter.isLimitReached())
    }
    
    func testCompoundUsageCounterAll() throws {
        let storage = UserDefaultsCounterStorage(userDefaults: userDefaults!)
        let dateResolver = FakeDateResolver()
        let dayCounter = TimeBasedUsageCounter(
            name: "day_counter",
            context: .default,
            timeUnit: .day,
            limit: 3,
            storage: storage,
            dateResolver: dateResolver)
        let monthCounter = TimeBasedUsageCounter(
            name: "month_counter",
            context: .default,
            timeUnit: .month,
            limit: 5,
            storage: storage,
            dateResolver: dateResolver)
        
        let allCompoundCounter = CompoundUsageCounter(
            counters: [dayCounter, monthCounter],
            rule: .all)
        
        dateResolver.setResolvedDate(isoDate: "2016-04-14T12:00:00+0000")
        
        XCTAssertEqual(dayCounter.usages(), 0)
        XCTAssertEqual(monthCounter.usages(), 0)
        
        allCompoundCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 1)
        XCTAssertEqual(monthCounter.usages(), 1)
        XCTAssertFalse(allCompoundCounter.isLimitReached())
        
        allCompoundCounter.increment()
        allCompoundCounter.increment()
        allCompoundCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 4)
        XCTAssertEqual(monthCounter.usages(), 4)
        XCTAssertFalse(allCompoundCounter.isLimitReached())
        
        dateResolver.setResolvedDate(isoDate: "2016-04-15T12:00:00+0000")
        
        allCompoundCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 1)
        XCTAssertEqual(monthCounter.usages(), 5)
        XCTAssertFalse(allCompoundCounter.isLimitReached())
        
        dateResolver.setResolvedDate(isoDate: "2016-04-16T12:00:00+0000")
        
        allCompoundCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 1)
        XCTAssertEqual(monthCounter.usages(), 6)
        XCTAssertFalse(allCompoundCounter.isLimitReached())
        
        allCompoundCounter.increment()
        allCompoundCounter.increment()
        allCompoundCounter.increment()
        XCTAssertEqual(dayCounter.usages(), 4)
        XCTAssertEqual(monthCounter.usages(), 9)
        XCTAssertTrue(allCompoundCounter.isLimitReached())
    }
    
    func testCompoundUsageCounterNested() throws {
        let storage = UserDefaultsCounterStorage(userDefaults: userDefaults!)
        let dateResolver = FakeDateResolver()
        let dayMaxCounter = TimeBasedUsageCounter(
            name: "dayMax_counter",
            context: .default,
            timeUnit: .day,
            limit: 3,
            storage: storage,
            dateResolver: dateResolver)
        let dayMinCounter = TimeBasedUsageCounter(
            name: "dayMin_counter",
            context: .default,
            timeUnit: .day,
            limit: 1,
            storage: storage,
            dateResolver: dateResolver)
        let monthCounter = TimeBasedUsageCounter(
            name: "month_counter",
            context: .default,
            timeUnit: .month,
            limit: 5,
            storage: storage,
            dateResolver: dateResolver)
        let monthCompoundCounter = CompoundUsageCounter(
            counters: [dayMinCounter, monthCounter],
            rule: .all)
        
        let compoundCounter = CompoundUsageCounter(
            counters: [dayMaxCounter, monthCompoundCounter],
            rule: .any)
        
        dateResolver.setResolvedDate(isoDate: "2016-04-14T12:00:00+0000")
        
        XCTAssertEqual(dayMaxCounter.usages(), 0)
        XCTAssertEqual(dayMinCounter.usages(), 0)
        XCTAssertEqual(monthCounter.usages(), 0)
        
        compoundCounter.increment()
        XCTAssertEqual(dayMaxCounter.usages(), 1)
        XCTAssertEqual(dayMinCounter.usages(), 1)
        XCTAssertEqual(monthCounter.usages(), 1)
        XCTAssertFalse(compoundCounter.isLimitReached())
        
        dateResolver.setResolvedDate(isoDate: "2016-04-15T12:00:00+0000")
        
        compoundCounter.increment()
        compoundCounter.increment()
        compoundCounter.increment()
        compoundCounter.increment()
        XCTAssertEqual(dayMaxCounter.usages(), 4)
        XCTAssertEqual(dayMinCounter.usages(), 4)
        XCTAssertEqual(monthCounter.usages(), 5)
        XCTAssertTrue(dayMaxCounter.isLimitReached())
        XCTAssertTrue(dayMinCounter.isLimitReached())
        XCTAssertFalse(monthCounter.isLimitReached())
        XCTAssertFalse(monthCompoundCounter.isLimitReached())
        XCTAssertTrue(compoundCounter.isLimitReached())
        
        dateResolver.setResolvedDate(isoDate: "2016-04-16T12:00:00+0000")
        
        compoundCounter.increment()
        XCTAssertEqual(dayMaxCounter.usages(), 1)
        XCTAssertEqual(dayMinCounter.usages(), 1)
        XCTAssertEqual(monthCounter.usages(), 6)
        XCTAssertFalse(dayMaxCounter.isLimitReached())
        XCTAssertFalse(dayMinCounter.isLimitReached())
        XCTAssertTrue(monthCounter.isLimitReached())
        XCTAssertFalse(monthCompoundCounter.isLimitReached())
        XCTAssertFalse(compoundCounter.isLimitReached())
        
        compoundCounter.increment()
        XCTAssertEqual(dayMaxCounter.usages(), 2)
        XCTAssertEqual(dayMinCounter.usages(), 2)
        XCTAssertEqual(monthCounter.usages(), 7)
        XCTAssertFalse(dayMaxCounter.isLimitReached())
        XCTAssertTrue(dayMinCounter.isLimitReached())
        XCTAssertTrue(monthCounter.isLimitReached())
        XCTAssertTrue(monthCompoundCounter.isLimitReached())
        XCTAssertTrue(compoundCounter.isLimitReached())
        
        compoundCounter.reset()
        XCTAssertEqual(dayMaxCounter.usages(), 0)
        XCTAssertEqual(dayMinCounter.usages(), 0)
        XCTAssertEqual(monthCounter.usages(), 0)
        XCTAssertFalse(compoundCounter.isLimitReached())
    }
}
