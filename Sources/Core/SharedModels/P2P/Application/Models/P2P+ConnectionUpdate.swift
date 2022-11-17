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

// MARK: - P2P.ConnectionUpdate
public extension P2P {
	// MARK: - ConnectionUpdate
	struct ConnectionUpdate: Sendable, Equatable, Identifiable {
		public let connectionStatus: Connection.State
		public let p2pClient: P2PClient

		public init(connectionStatus: Connection.State, p2pClient: P2PClient) {
			self.connectionStatus = connectionStatus
			self.p2pClient = p2pClient
		}
	}
}

public extension P2P.ConnectionUpdate {
	typealias ID = P2PClient.ID
	var id: ID {
		p2pClient.id
	}
}
