//
// StreamTransactionsRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StreamTransactionsRequest")
public typealias StreamTransactionsRequest = GatewayAPI.StreamTransactionsRequest

extension GatewayAPI {

public struct StreamTransactionsRequest: Codable, Hashable {

    public enum KindFilter: String, Codable, CaseIterable {
        case user = "User"
        case epochChange = "EpochChange"
        case all = "All"
    }
    public enum Order: String, Codable, CaseIterable {
        case asc = "Asc"
        case desc = "Desc"
    }
    public private(set) var atLedgerState: LedgerStateSelector?
    public private(set) var fromLedgerState: LedgerStateSelector?
    /** This cursor allows forward pagination, by providing the cursor from the previous request. */
    public private(set) var cursor: String?
    /** The page size requested. */
    public private(set) var limitPerPage: Int?
    /** Limit returned transactions by their kind. Defaults to `user`. */
    public private(set) var kindFilter: KindFilter?
    /** Allows specifying an array of account addresses. If specified, the response will contain only transactions with a manifest containing withdrawals from the given accounts. */
    public private(set) var manifestAccountsWithdrawnFromFilter: [String]?
    /** Similar to `manifest_accounts_withdrawn_from_filter`, but will return only transactions with a manifest containing deposits to the given accounts. */
    public private(set) var manifestAccountsDepositedIntoFilter: [String]?
    /** Allows specifying array of badge resource addresses. If specified, the response will contain only transactions where the given badges were presented. */
    public private(set) var manifestBadgesPresentedFilter: [String]?
    /** Allows specifying array of resource addresses. If specified, the response will contain only transactions containing the given resources in the manifest (regardless of their usage). */
    public private(set) var manifestResourcesFilter: [String]?
    /** Allows specifying an array of global addresses. If specified, the response will contain transactions that affected all of the given global entities. A global entity is marked as \"affected\" by a transaction if any of its state (or its descendents' state) was modified as a result of the transaction. For performance reasons consensus manager and transaction tracker are excluded from that filter. */
    public private(set) var affectedGlobalEntitiesFilter: [String]?
    /** Filters the transaction stream to transactions which emitted at least one event matching each filter (each filter can be satisfied by a different event). Currently *only* deposit and withdrawal events emitted by an internal vault entity are tracked. For the purpose of filtering, the emitter address is replaced by the global ancestor of the emitter, for example, the top-level account / component which contains the vault which emitted the event. */
    public private(set) var eventsFilter: [StreamTransactionsRequestEventFilterItem]?
    /** Allows specifying an array of account addresses. If specified, the response will contain only transactions that, for all specified accounts, contain manifest method calls to that account which require the owner role. See the [account docs](https://docs.radixdlt.com/docs/account) for more information. */
    public private(set) var accountsWithManifestOwnerMethodCalls: [String]?
    /** Allows specifying an array of account addresses. If specified, the response will contain only transactions that, for all specified accounts, do NOT contain manifest method calls to that account which require owner role. See the [account docs](https://docs.radixdlt.com/docs/account) for more information. */
    public private(set) var accountsWithoutManifestOwnerMethodCalls: [String]?
    public private(set) var manifestClassFilter: StreamTransactionsRequestAllOfManifestClassFilter?
    /** Allows specifying an array of global addresses. If specified, the response will contain transactions in which all entities emitted events. If an event was published by an internal entity, it is going to be indexed as it is a global ancestor. For performance reasons events published by consensus manager and native XRD resource are excluded from that filter. */
    public private(set) var eventGlobalEmittersFilter: [String]?
    /** Configures the order of returned result set. Defaults to `desc`. */
    public private(set) var order: Order?
    public private(set) var optIns: TransactionDetailsOptIns?

    public init(atLedgerState: LedgerStateSelector? = nil, fromLedgerState: LedgerStateSelector? = nil, cursor: String? = nil, limitPerPage: Int? = nil, kindFilter: KindFilter? = nil, manifestAccountsWithdrawnFromFilter: [String]? = nil, manifestAccountsDepositedIntoFilter: [String]? = nil, manifestBadgesPresentedFilter: [String]? = nil, manifestResourcesFilter: [String]? = nil, affectedGlobalEntitiesFilter: [String]? = nil, eventsFilter: [StreamTransactionsRequestEventFilterItem]? = nil, accountsWithManifestOwnerMethodCalls: [String]? = nil, accountsWithoutManifestOwnerMethodCalls: [String]? = nil, manifestClassFilter: StreamTransactionsRequestAllOfManifestClassFilter? = nil, eventGlobalEmittersFilter: [String]? = nil, order: Order? = nil, optIns: TransactionDetailsOptIns? = nil) {
        self.atLedgerState = atLedgerState
        self.fromLedgerState = fromLedgerState
        self.cursor = cursor
        self.limitPerPage = limitPerPage
        self.kindFilter = kindFilter
        self.manifestAccountsWithdrawnFromFilter = manifestAccountsWithdrawnFromFilter
        self.manifestAccountsDepositedIntoFilter = manifestAccountsDepositedIntoFilter
        self.manifestBadgesPresentedFilter = manifestBadgesPresentedFilter
        self.manifestResourcesFilter = manifestResourcesFilter
        self.affectedGlobalEntitiesFilter = affectedGlobalEntitiesFilter
        self.eventsFilter = eventsFilter
        self.accountsWithManifestOwnerMethodCalls = accountsWithManifestOwnerMethodCalls
        self.accountsWithoutManifestOwnerMethodCalls = accountsWithoutManifestOwnerMethodCalls
        self.manifestClassFilter = manifestClassFilter
        self.eventGlobalEmittersFilter = eventGlobalEmittersFilter
        self.order = order
        self.optIns = optIns
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case atLedgerState = "at_ledger_state"
        case fromLedgerState = "from_ledger_state"
        case cursor
        case limitPerPage = "limit_per_page"
        case kindFilter = "kind_filter"
        case manifestAccountsWithdrawnFromFilter = "manifest_accounts_withdrawn_from_filter"
        case manifestAccountsDepositedIntoFilter = "manifest_accounts_deposited_into_filter"
        case manifestBadgesPresentedFilter = "manifest_badges_presented_filter"
        case manifestResourcesFilter = "manifest_resources_filter"
        case affectedGlobalEntitiesFilter = "affected_global_entities_filter"
        case eventsFilter = "events_filter"
        case accountsWithManifestOwnerMethodCalls = "accounts_with_manifest_owner_method_calls"
        case accountsWithoutManifestOwnerMethodCalls = "accounts_without_manifest_owner_method_calls"
        case manifestClassFilter = "manifest_class_filter"
        case eventGlobalEmittersFilter = "event_global_emitters_filter"
        case order
        case optIns = "opt_ins"
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(atLedgerState, forKey: .atLedgerState)
        try container.encodeIfPresent(fromLedgerState, forKey: .fromLedgerState)
        try container.encodeIfPresent(cursor, forKey: .cursor)
        try container.encodeIfPresent(limitPerPage, forKey: .limitPerPage)
        try container.encodeIfPresent(kindFilter, forKey: .kindFilter)
        try container.encodeIfPresent(manifestAccountsWithdrawnFromFilter, forKey: .manifestAccountsWithdrawnFromFilter)
        try container.encodeIfPresent(manifestAccountsDepositedIntoFilter, forKey: .manifestAccountsDepositedIntoFilter)
        try container.encodeIfPresent(manifestBadgesPresentedFilter, forKey: .manifestBadgesPresentedFilter)
        try container.encodeIfPresent(manifestResourcesFilter, forKey: .manifestResourcesFilter)
        try container.encodeIfPresent(affectedGlobalEntitiesFilter, forKey: .affectedGlobalEntitiesFilter)
        try container.encodeIfPresent(eventsFilter, forKey: .eventsFilter)
        try container.encodeIfPresent(accountsWithManifestOwnerMethodCalls, forKey: .accountsWithManifestOwnerMethodCalls)
        try container.encodeIfPresent(accountsWithoutManifestOwnerMethodCalls, forKey: .accountsWithoutManifestOwnerMethodCalls)
        try container.encodeIfPresent(manifestClassFilter, forKey: .manifestClassFilter)
        try container.encodeIfPresent(eventGlobalEmittersFilter, forKey: .eventGlobalEmittersFilter)
        try container.encodeIfPresent(order, forKey: .order)
        try container.encodeIfPresent(optIns, forKey: .optIns)
    }
}

}
