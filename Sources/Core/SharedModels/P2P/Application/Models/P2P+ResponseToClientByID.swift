//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-11-16.
//

import Foundation
import Profile

// MARK: - P2P.ResponseToClientByID
public extension P2P {
	// MARK: - ResponseToClientByID
	struct ResponseToClientByID: Sendable, Equatable, Identifiable {
		public let connectionID: P2PClient.ID
		public let responseToDapp: ToDapp.Response
		public init(
			connectionID: P2PClient.ID,
			responseToDapp: ToDapp.Response
		) {
			self.connectionID = connectionID
			self.responseToDapp = responseToDapp
		}
	}
}

public extension P2P.ResponseToClientByID {
	var requestID: ID {
		responseToDapp.id
	}

	typealias ID = P2P.ToDapp.Response.ID
	var id: ID { requestID }
}
