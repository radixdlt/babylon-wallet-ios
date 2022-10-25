//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2022-10-25.
//

import ComposableArchitecture
import Foundation
import KeychainClient

public extension KeychainClient {
    static let live = Self.live(
        accessibility: .whenPasscodeSetThisDeviceOnly
    )
}

// MARK: - KeychainClientKey
private enum KeychainClientKey: DependencyKey {
    typealias Value = KeychainClient
    static let liveValue = KeychainClient.live
    static let testValue = KeychainClient.unimplemented
}

public extension DependencyValues {
    var keychainClient: KeychainClient {
        get { self[KeychainClientKey.self] }
        set { self[KeychainClientKey.self] = newValue }
    }
}
