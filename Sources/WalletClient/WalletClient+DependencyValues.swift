//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-10-19.
//

import ComposableArchitecture
import Foundation

// MARK: - WalletClientKey
public enum WalletClientKey: DependencyKey {}
public extension WalletClientKey {
	typealias Value = WalletClient
	static let liveValue = WalletClient.mock()
	static let testValue = WalletClient.mock()
}

public extension DependencyValues {
	var walletClient: WalletClient {
		get { self[WalletClientKey.self] }
		set { self[WalletClientKey.self] = newValue }
	}
}
