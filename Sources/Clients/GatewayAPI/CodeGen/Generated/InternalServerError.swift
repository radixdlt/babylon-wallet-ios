//
// InternalServerError.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

// MARK: - InternalServerError
public struct InternalServerError: Codable, Hashable {
	/** The type of error. Each subtype may have its own additional structured fields. */
	public private(set) var type: String
	/** Gives an error type which occurred within the Gateway API when serving the request. */
	public private(set) var exception: String
	/** Gives a human readable message - likely just a trace ID for reporting the error. */
	public private(set) var cause: String

	public init(type: String, exception: String, cause: String) {
		self.type = type
		self.exception = exception
		self.cause = cause
	}

	public enum CodingKeys: String, CodingKey, CaseIterable {
		case type
		case exception
		case cause
	}

	// Encodable protocol methods

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(type, forKey: .type)
		try container.encode(exception, forKey: .exception)
		try container.encode(cause, forKey: .cause)
	}
}
