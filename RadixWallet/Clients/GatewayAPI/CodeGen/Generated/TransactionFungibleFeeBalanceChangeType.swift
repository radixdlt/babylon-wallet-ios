//
// TransactionFungibleFeeBalanceChangeType.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.TransactionFungibleFeeBalanceChangeType")
typealias TransactionFungibleFeeBalanceChangeType = GatewayAPI.TransactionFungibleFeeBalanceChangeType

extension GatewayAPI {

/** Indicates fee-related balance changes, for example:  - payment of the fee including tip and royalty, - distribution of royalties, - distribution of the fee and tip to the consensus-manager, for distributing to the relevant validator/s at end of epoch.  See https://www.radixdlt.com/blog/how-fees-work-in-babylon for further information on how fee payment works at Babylon.  */
enum TransactionFungibleFeeBalanceChangeType: String, Codable, CaseIterable {
    case feePayment = "FeePayment"
    case feeDistributed = "FeeDistributed"
    case tipDistributed = "TipDistributed"
    case royaltyDistributed = "RoyaltyDistributed"
}
}
