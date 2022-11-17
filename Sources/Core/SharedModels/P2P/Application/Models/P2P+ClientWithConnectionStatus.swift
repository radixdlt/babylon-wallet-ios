//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

import Converse
import ConverseCommon
import Foundation
import Profile

// MARK: - P2P.ClientWithConnectionStatus
public extension P2P {
	// MARK: - ClientWithConnectionStatus
	struct ClientWithConnectionStatus: Identifiable, Equatable {
		public let p2pClient: P2PClient
		public var connectionStatus: Connection.State

		public init(
			p2pClient: P2PClient,
			connectionStatus: Connection.State = .disconnected
		) {
			self.p2pClient = p2pClient
			self.connectionStatus = connectionStatus
		}
	}
}

public extension P2P.ClientWithConnectionStatus {
	typealias ID = P2PClient.ID
	var id: ID { p2pClient.id }
}
