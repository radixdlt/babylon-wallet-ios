//
// ParsedTransaction.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public enum ParsedTransaction: Codable, Hashable {
    case typeParsedNotarizedTransaction(ParsedNotarizedTransaction)
    case typeParsedSignedTransactionIntent(ParsedSignedTransactionIntent)
    case typeParsedTransactionIntent(ParsedTransactionIntent)
    case typeParsedTransactionManifest(ParsedTransactionManifest)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .typeParsedNotarizedTransaction(let value):
            try container.encode(value)
        case .typeParsedSignedTransactionIntent(let value):
            try container.encode(value)
        case .typeParsedTransactionIntent(let value):
            try container.encode(value)
        case .typeParsedTransactionManifest(let value):
            try container.encode(value)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(ParsedNotarizedTransaction.self) {
            self = .typeParsedNotarizedTransaction(value)
        } else if let value = try? container.decode(ParsedSignedTransactionIntent.self) {
            self = .typeParsedSignedTransactionIntent(value)
        } else if let value = try? container.decode(ParsedTransactionIntent.self) {
            self = .typeParsedTransactionIntent(value)
        } else if let value = try? container.decode(ParsedTransactionManifest.self) {
            self = .typeParsedTransactionManifest(value)
        } else {
            throw DecodingError.typeMismatch(Self.Type.self, .init(codingPath: decoder.codingPath, debugDescription: "Unable to decode instance of ParsedTransaction"))
        }
    }
}

