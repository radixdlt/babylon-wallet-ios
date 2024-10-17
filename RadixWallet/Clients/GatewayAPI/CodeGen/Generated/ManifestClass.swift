//
// ManifestClass.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ManifestClass")
typealias ManifestClass = GatewayAPI.ManifestClass

extension GatewayAPI {

/** High-level manifest class type:   * &#x60;General&#x60;: A general manifest that involves any amount of arbitrary components and packages where nothing more concrete can be said about the manifest and its nature.   * &#x60;Transfer&#x60;: A manifest of a 1-to-1 transfer to a one-to-many transfer of resources.   * &#x60;PoolContribution&#x60;: A manifest that contributed some amount of resources to a liquidity pool that can be a one-resource pool, two-resource pool, or a multi-resource pool.   * &#x60;PoolRedemption&#x60;: A manifest that redeemed resources from a liquidity pool. Similar to contributions, this can be any of the three pool blueprints available in the pool package.   * &#x60;ValidatorStake&#x60;: A manifest where XRD is staked to one or more validators.   * &#x60;ValidatorUnstake&#x60;: A manifest where XRD is unstaked from one or more validators.   * &#x60;ValidatorClaim&#x60;: A manifest where XRD is claimed from one or more validators.   * &#x60;AccountDepositSettingsUpdate&#x60;: A manifest that updated the deposit settings of the account.  */
enum ManifestClass: String, Codable, CaseIterable {
    case general = "General"
    case transfer = "Transfer"
    case poolContribution = "PoolContribution"
    case poolRedemption = "PoolRedemption"
    case validatorStake = "ValidatorStake"
    case validatorUnstake = "ValidatorUnstake"
    case validatorClaim = "ValidatorClaim"
    case accountDepositSettingsUpdate = "AccountDepositSettingsUpdate"
}
}
