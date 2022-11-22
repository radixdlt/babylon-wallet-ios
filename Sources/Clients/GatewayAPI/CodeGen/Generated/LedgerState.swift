//
// LedgerState.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.LedgerState")
public typealias LedgerState = GatewayAPI.LedgerState

// MARK: - GatewayAPI.LedgerState
public extension GatewayAPI {
	/** The ledger state against which the response was generated. Can be used to detect if the Network Gateway is returning up-to-date information.  */
	struct LedgerState: Codable, Hashable {
		/** The name of the network against which the request is made. */
		public private(set) var network: String
		/** The state version of the ledger. Each transaction increments the state version by 1. */
		public private(set) var stateVersion: Int64
		/** The round timestamp of the consensus round when this transaction was committed to ledger. This is not guaranteed to be strictly increasing, as it is computed as an average across the validator set. If this is significantly behind the current timestamp, the Network Gateway is likely reporting out-dated information, or the network has stalled.  */
		public private(set) var timestamp: String
		/** The epoch number of the ledger at this state version. */
		public private(set) var epoch: Int64
		/** The consensus round in the epoch that this state version was committed in. */
		public private(set) var round: Int64

		public init(network: String, stateVersion: Int64, timestamp: String, epoch: Int64, round: Int64) {
			self.network = network
			self.stateVersion = stateVersion
			self.timestamp = timestamp
			self.epoch = epoch
			self.round = round
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case network
			case stateVersion = "state_version"
			case timestamp
			case epoch
			case round
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(network, forKey: .network)
			try container.encode(stateVersion, forKey: .stateVersion)
			try container.encode(timestamp, forKey: .timestamp)
			try container.encode(epoch, forKey: .epoch)
			try container.encode(round, forKey: .round)
		}
	}
}
