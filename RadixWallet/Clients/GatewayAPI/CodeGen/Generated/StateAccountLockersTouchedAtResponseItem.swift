//
// StateAccountLockersTouchedAtResponseItem.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateAccountLockersTouchedAtResponseItem")
public typealias StateAccountLockersTouchedAtResponseItem = GatewayAPI.StateAccountLockersTouchedAtResponseItem

extension GatewayAPI {

public struct StateAccountLockersTouchedAtResponseItem: Codable, Hashable {

    /** Bech32m-encoded human readable version of the address. */
    public private(set) var lockerAddress: String
    /** Bech32m-encoded human readable version of the address. */
    public private(set) var accountAddress: String
    /** The most recent state version underlying object was modified at. */
    public private(set) var lastTouchedAtStateVersion: Int64

    public init(lockerAddress: String, accountAddress: String, lastTouchedAtStateVersion: Int64) {
        self.lockerAddress = lockerAddress
        self.accountAddress = accountAddress
        self.lastTouchedAtStateVersion = lastTouchedAtStateVersion
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case lockerAddress = "locker_address"
        case accountAddress = "account_address"
        case lastTouchedAtStateVersion = "last_touched_at_state_version"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lockerAddress, forKey: .lockerAddress)
        try container.encode(accountAddress, forKey: .accountAddress)
        try container.encode(lastTouchedAtStateVersion, forKey: .lastTouchedAtStateVersion)
    }
}

}
