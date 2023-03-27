//
// TransactionPreviewResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionPreviewResponse")
public typealias TransactionPreviewResponse = GatewayAPI.TransactionPreviewResponse

// MARK: - GatewayAPI.TransactionPreviewResponse
extension GatewayAPI {
	public struct TransactionPreviewResponse: Codable, Hashable {
		public private(set) var receipt: AnyCodable
		public private(set) var resourceChanges: [AnyCodable]
		public private(set) var logs: [TransactionPreviewResponseLogsInner]

		public init(receipt: AnyCodable, resourceChanges: [AnyCodable], logs: [TransactionPreviewResponseLogsInner]) {
			self.receipt = receipt
			self.resourceChanges = resourceChanges
			self.logs = logs
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case receipt
			case resourceChanges = "resource_changes"
			case logs
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(receipt, forKey: .receipt)
			try container.encode(resourceChanges, forKey: .resourceChanges)
			try container.encode(logs, forKey: .logs)
		}
	}
}
