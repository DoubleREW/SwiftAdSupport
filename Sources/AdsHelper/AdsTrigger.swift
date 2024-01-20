//
//  AdsTrigger.swift
//
//
//  Created by Fausto Ristagno on 15/01/24.
//

import Foundation
import SwiftUI

public enum AdsDisplayOrder {
    case before
    case after

    public static var defaultOrder: Self {
        AdsDisplayOrder.after
    }
}

struct AsyncThrowingAdsTrigger {
    private let manager: AdInterstitialManager
    private let position: AdsDisplayOrder
    private let action: () async throws -> Void
    private let completion: (() async -> Void)?

    init(
        manager: AdInterstitialManager,
        position: AdsDisplayOrder = .defaultOrder,
        action: @escaping () async throws -> Void,
        completion: (() async -> Void)? = nil
    ) {
        self.manager = manager
        self.position = position
        self.action = action
        self.completion = completion
    }

    func callAsFunction() async throws {
        if position == .after {
            print("Show ads")
            manager.trigger()
        }

        try await action()

        if position == .before {
            print("Show ads")
            manager.trigger()
        }

        if let completion {
            await completion()
        }
    }
}

public func AdsTrigger(
    manager: AdInterstitialManager,
    position: AdsDisplayOrder = .defaultOrder,
    action: @escaping () async throws -> Void,
    completion: (() async -> Void)? = nil
) async throws {
    try await AsyncThrowingAdsTrigger(
        manager: manager,
        position: position,
        action: action,
        completion: completion
    )()
}

public func AdsTrigger(
    manager: AdInterstitialManager,
    position: AdsDisplayOrder = .defaultOrder,
    action: @escaping () async -> Void,
    completion: (() async -> Void)? = nil
) async {
    do {
        try await AsyncThrowingAdsTrigger(
            manager: manager,
            position: position,
            action: action,
            completion: completion
        )()
    } catch {
        fatalError("Non throwing action as thrown an error")
    }
}

public func AdsTrigger(
    manager: AdInterstitialManager,
    position: AdsDisplayOrder = .defaultOrder,
    action: @escaping () throws -> Void,
    completion: (() async -> Void)? = nil
) throws {
    Task {
        try await AsyncThrowingAdsTrigger(
            manager: manager,
            position: position,
            action: action,
            completion: completion
        )()
    }
}

public func AdsTrigger(
    manager: AdInterstitialManager,
    position: AdsDisplayOrder = .defaultOrder,
    action: @escaping () -> Void,
    completion: (() async -> Void)? = nil
) {
    Task {
        do {
            try await AsyncThrowingAdsTrigger(
                manager: manager,
                position: position,
                action: action,
                completion: completion
            )()
        } catch {
            fatalError("Non throwing action as thrown an error")
        }
    }
}
