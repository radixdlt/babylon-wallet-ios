//
// GatewayInfoResponseReleaseInfo.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.GatewayInfoResponseReleaseInfo")
typealias GatewayInfoResponseReleaseInfo = GatewayAPI.GatewayInfoResponseReleaseInfo

extension GatewayAPI {

struct GatewayInfoResponseReleaseInfo: Codable, Hashable {

    /** The release that is currently deployed to the Gateway API. */
    private(set) var releaseVersion: String
    /** The Open API Schema version that was used to generate the API models. */
    private(set) var openApiSchemaVersion: String
    /** Image tag that is currently deployed to the Gateway API. */
    private(set) var imageTag: String

    init(releaseVersion: String, openApiSchemaVersion: String, imageTag: String) {
        self.releaseVersion = releaseVersion
        self.openApiSchemaVersion = openApiSchemaVersion
        self.imageTag = imageTag
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case releaseVersion = "release_version"
        case openApiSchemaVersion = "open_api_schema_version"
        case imageTag = "image_tag"
    }

    // Encodable protocol methods

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(releaseVersion, forKey: .releaseVersion)
        try container.encode(openApiSchemaVersion, forKey: .openApiSchemaVersion)
        try container.encode(imageTag, forKey: .imageTag)
    }
}

}
