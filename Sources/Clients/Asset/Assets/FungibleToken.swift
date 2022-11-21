import BigInt
import Common
import Foundation
import Profile

// MARK: - FungibleToken
/// What we get from GatewayAPIClient, e.g. with this call:
///
/// 	curl -X 'POST' \
///			'https://alphanet.radixdlt.com/v0/state/resource' \
///			-H 'accept: application/json' \
///			-H 'Content-Type: application/json' \
///			-d '{
///			"resource_address": "resource_tdx_a_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqegh4k9"
///			}' | python3 -m json.tool
///
///	The response is this:
///
///		{
///			"substate_type": "ResourceManager",
///			"entity_type": "ResourceManager",
///			"resource_type": "Fungible",
///			"fungible_divisibility": 18,
///			"metadata": [
///				{
///					"key": "description",
///					"value": "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes."
///				},
///				{
///					"key": "symbol",
///					"value": "XRD"
///				},
///				{
///					"key": "url",
///					"value": "https://tokens.radixdlt.com"
///				},
///				{
///					"key": "name",
///					"value": "Radix"
///				}
///			],
///			"total_supply_attos": "1000000000000000000000000000000"
///		}
public struct FungibleToken: Sendable, Asset, Token, Hashable {
	public let address: ComponentAddress
	public let totalSupplyAttos: BigUInt?
	public let totalMintedAttos: BigUInt?
	public let totalBurntAttos: BigUInt?

	/// An optional desciption of this token, e.g.
	/// ` "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes."`
	public var tokenDescription: String?

	/// Short token name, e.g. `"Radix"`.
	public var name: String?

	/// Symbol of token, e.g. `"XRD"`.
	public var symbol: String?

	/// Token icon URL.
	public var iconURL: URL?

	/// Website of the token, e.g. `"https://tokens.radixdlt.com"`
	public var tokenInfoURL: String?

	/// Also known as `granularity`, often value `18`, meaning each whole unit
	/// can be divided into 10^18 subunits (attos). In case of `17` one CANNOT
	/// send 1 atto, 9 or 11 or 18 attos, rather the amount MUST be a multiple
	/// of 10, e.g. 10, 20, 90, 1002010 attos etc.
	public let divisibility: Int?

	public init(
		address: ComponentAddress,
		divisibility: Int?,
		totalSupplyAttos: BigUInt?,
		totalMintedAttos: BigUInt?,
		totalBurntAttos: BigUInt?,
		tokenDescription: String?,
		name: String?,
		symbol: String?,
		tokenInfoURL: String? = nil,
		iconURL: URL? = nil
	) {
		self.address = address
		self.divisibility = divisibility
		self.totalSupplyAttos = totalSupplyAttos
		self.totalMintedAttos = totalMintedAttos
		self.totalBurntAttos = totalBurntAttos
		self.tokenDescription = tokenDescription
		self.name = name
		self.symbol = symbol
		self.tokenInfoURL = tokenInfoURL
		self.iconURL = iconURL
	}
}

// MARK: - FungibleTokenContainer
public struct FungibleTokenContainer: AssetContainer, Equatable {
	public var owner: AccountAddress
	public typealias T = FungibleToken
	public let asset: FungibleToken

	/// Token amount held in one account.
	public var amountInAttos: BigUInt?
	/// Token worth in currently selected currency.
	public var worth: BigUInt?

	public var amountInWhole: BigUInt? {
		guard let amountInAttos else { return nil }
		// FIXME: what to do if nil? Assume 18.. really?
		let divisibility = asset.divisibility ?? 18
		return amountInAttos / BigUInt(10).power(divisibility)
	}

	public init(
		owner: AccountAddress,
		asset: FungibleToken,
		amountInAttos: BigUInt?,
		worth: BigUInt?
	) {
		self.owner = owner
		self.asset = asset
		self.amountInAttos = amountInAttos
		self.worth = worth
	}
}

public extension FungibleToken {
	/// The native token of the Radix Ledger
	static let xrd = Self(
		address: "resource_tdx_a_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqegh4k9",
		divisibility: 18,
		totalSupplyAttos: 24_000_000_000.inAttos,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: "The native token of the Radix Ledger",
		name: "Radix",
		symbol: "XRD",
		tokenInfoURL: "https://tokens.radixdlt.com",
		iconURL: nil
	)
}

#if DEBUG
public extension FungibleToken {
	static let btc = Self(
		address: "btc-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Bitcoin",
		symbol: "BTC"
	)

	static let dot = Self(
		address: "dot-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Polkadot",
		symbol: "DOT"
	)

	static let eth = Self(
		address: "eth-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Ethereum",
		symbol: "ETH"
	)

	static let ltc = Self(
		address: "ltc-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Litecoin",
		symbol: "LTC"
	)

	static let sol = Self(
		address: "sol-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Solana",
		symbol: "SOL"
	)

	static let usdt = Self(
		address: "usdt-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Tether",
		symbol: "USDT"
	)

	static let xrp = Self(
		address: "xrp-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "XRP token",
		symbol: "XRP"
	)
}
#endif
