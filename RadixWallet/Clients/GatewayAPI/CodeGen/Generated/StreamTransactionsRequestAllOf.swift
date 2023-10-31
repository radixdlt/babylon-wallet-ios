//
// StreamTransactionsRequestAllOf.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StreamTransactionsRequestAllOf")
public typealias StreamTransactionsRequestAllOf = GatewayAPI.StreamTransactionsRequestAllOf

extension GatewayAPI {

public struct StreamTransactionsRequestAllOf: Codable, Hashable {

    public enum KindFilter: String, Codable, CaseIterable {
        case user = "User"
        case epochChange = "EpochChange"
        case all = "All"
    }
    public enum Order: String, Codable, CaseIterable {
        case asc = "Asc"
        case desc = "Desc"
    }
    /** Limit returned transactions by their kind. Defaults to `user`. */
    public private(set) var kindFilter: KindFilter?
    public private(set) var manifestAccountsWithdrawnFromFilter: [String]?
    public private(set) var manifestAccountsDepositedIntoFilter: [String]?
    public private(set) var manifestResourcesFilter: [String]?
    public private(set) var affectedGlobalEntitiesFilter: [String]?
    public private(set) var eventsFilter: [StreamTransactionsRequestEventFilterItem]?
    /** Configures the order of returned result set. Defaults to `desc`. */
    public private(set) var order: Order?
    public private(set) var optIns: TransactionDetailsOptIns?

    public init(kindFilter: KindFilter? = nil, manifestAccountsWithdrawnFromFilter: [String]? = nil, manifestAccountsDepositedIntoFilter: [String]? = nil, manifestResourcesFilter: [String]? = nil, affectedGlobalEntitiesFilter: [String]? = nil, eventsFilter: [StreamTransactionsRequestEventFilterItem]? = nil, order: Order? = nil, optIns: TransactionDetailsOptIns? = nil) {
        self.kindFilter = kindFilter
        self.manifestAccountsWithdrawnFromFilter = manifestAccountsWithdrawnFromFilter
        self.manifestAccountsDepositedIntoFilter = manifestAccountsDepositedIntoFilter
        self.manifestResourcesFilter = manifestResourcesFilter
        self.affectedGlobalEntitiesFilter = affectedGlobalEntitiesFilter
        self.eventsFilter = eventsFilter
        self.order = order
        self.optIns = optIns
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case kindFilter = "kind_filter"
        case manifestAccountsWithdrawnFromFilter = "manifest_accounts_withdrawn_from_filter"
        case manifestAccountsDepositedIntoFilter = "manifest_accounts_deposited_into_filter"
        case manifestResourcesFilter = "manifest_resources_filter"
        case affectedGlobalEntitiesFilter = "affected_global_entities_filter"
        case eventsFilter = "events_filter"
        case order
        case optIns = "opt_ins"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(kindFilter, forKey: .kindFilter)
        try container.encodeIfPresent(manifestAccountsWithdrawnFromFilter, forKey: .manifestAccountsWithdrawnFromFilter)
        try container.encodeIfPresent(manifestAccountsDepositedIntoFilter, forKey: .manifestAccountsDepositedIntoFilter)
        try container.encodeIfPresent(manifestResourcesFilter, forKey: .manifestResourcesFilter)
        try container.encodeIfPresent(affectedGlobalEntitiesFilter, forKey: .affectedGlobalEntitiesFilter)
        try container.encodeIfPresent(eventsFilter, forKey: .eventsFilter)
        try container.encodeIfPresent(order, forKey: .order)
        try container.encodeIfPresent(optIns, forKey: .optIns)
    }
}

}
