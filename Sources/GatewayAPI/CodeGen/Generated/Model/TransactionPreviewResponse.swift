////
//// TransactionPreviewResponse.swift
////
//// Generated by openapi-generator
//// https://openapi-generator.tech
////
//
//import Foundation
//#if canImport(AnyCodable)
//import AnyCodable
//#endif
//
//public struct TransactionPreviewResponse: Sendable, Codable, Hashable {
//
//    public let coreApiResponse: AnyCodable
//
//    public init(coreApiResponse: AnyCodable) {
//        self.coreApiResponse = coreApiResponse
//    }
//
//    public enum CodingKeys: String, CodingKey, CaseIterable {
//        case coreApiResponse = "core_api_response"
//    }
//
//    // Encodable protocol methods
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(coreApiResponse, forKey: .coreApiResponse)
//    }
//}
//
