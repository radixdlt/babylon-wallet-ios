//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-10-13.
//

import ComposableArchitecture
import Foundation

// MARK: - GatewayAPIClientKey
public enum GatewayAPIClientKey: DependencyKey {}
public extension GatewayAPIClientKey {
	typealias Value = GatewayAPIClient
	static let liveValue = GatewayAPIClient.mock()
	static let testValue = GatewayAPIClient.mock()
}

public extension DependencyValues {
	var gatewayAPIClient: GatewayAPIClient {
		get { self[GatewayAPIClientKey.self] }
		set { self[GatewayAPIClientKey.self] = newValue }
	}
}
