//
// SubstateType.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public enum SubstateType: String, Codable, CaseIterable {
    case system = "System"
    case resourceManager = "ResourceManager"
    case componentInfo = "ComponentInfo"
    case componentState = "ComponentState"
    case package = "Package"
    case vault = "Vault"
    case nonFungible = "NonFungible"
    case keyValueStoreEntry = "KeyValueStoreEntry"
}
