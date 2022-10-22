//
// PackageSubstate.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

// MARK: - PackageSubstate
public struct PackageSubstate: Codable, Hashable {
	public private(set) var entityType: EntityType
	public private(set) var substateType: SubstateType
	/** The hex-encoded package code */
	public private(set) var codeHex: String

	public init(entityType: EntityType, substateType: SubstateType, codeHex: String) {
		self.entityType = entityType
		self.substateType = substateType
		self.codeHex = codeHex
	}

	public enum CodingKeys: String, CodingKey, CaseIterable {
		case entityType = "entity_type"
		case substateType = "substate_type"
		case codeHex = "code_hex"
	}

	// Encodable protocol methods

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(entityType, forKey: .entityType)
		try container.encode(substateType, forKey: .substateType)
		try container.encode(codeHex, forKey: .codeHex)
	}
}
