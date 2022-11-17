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

// MARK: - P2P.SentResponseToClient
public extension P2P {
	// MARK: - SentResponseToClient
	struct SentResponseToClient: Sendable, Equatable, Identifiable {
		public let sentReceipt: SentReceipt
		public let responseToDapp: P2P.ToDapp.Response
		public let client: P2PClient
		public init(
			sentReceipt: SentReceipt,
			responseToDapp: P2P.ToDapp.Response,
			client: P2PClient
		) {
			self.sentReceipt = sentReceipt
			self.responseToDapp = responseToDapp
			self.client = client
		}
	}
}

public extension P2P.SentResponseToClient {
	typealias SentReceipt = Connection.ConfirmedSentMessage
	typealias ID = P2P.ToDapp.Response.ID
	var id: ID { responseToDapp.id }
}
