import BigInt
import Common
import Foundation

// MARK: - FungibleToken
public struct FungibleToken: Asset, Token {
	public let address: ComponentAddress
	public let totalSupplyAttos: BigUInt
	public let totalMintedAttos: BigUInt
	public let totalBurntAttos: BigUInt

	/// An optional desciption of this token.
	public let tokenDescription: String?

	/// Short token name.
	public let name: String?

	/// Token code.
	public let code: String?

	/// Token icon URL.
	public var iconURL: String?

	public init(
		address: ComponentAddress,
		totalSupplyAttos: BigUInt,
		totalMintedAttos: BigUInt,
		totalBurntAttos: BigUInt,
		tokenDescription: String?,
		name: String?,
		code: String?,
		iconURL: String?
	) {
		self.address = address
		self.totalSupplyAttos = totalSupplyAttos
		self.totalMintedAttos = totalMintedAttos
		self.totalBurntAttos = totalBurntAttos
		self.tokenDescription = tokenDescription
		self.name = name
		self.code = code
		self.iconURL = iconURL
	}
}

// MARK: - FungibleTokenContainer
public struct FungibleTokenContainer: AssetContainer, Equatable {
	public typealias T = FungibleToken
	public let asset: FungibleToken

	/// Token amount held in one account.
	public var amount: Float?
	/// Token worth in currently selected currency.
	public var worth: Float?

	public init(
		asset: FungibleToken,
		amount: Float?,
		worth: Float?
	) {
		self.asset = asset
		self.amount = amount
		self.worth = worth
	}
}

public extension FungibleToken {
	/// The native token of the Radix Ledger
	static let xrd = Self(
		address: "unknown at this point",
		totalSupplyAttos: 24_000_000_000.inAttos,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: "The native token of the Radix Ledger",
		name: "RAD",
		code: "XRD",
		iconURL: nil
	)
}

#if DEBUG
public extension FungibleToken {
	static let btc = Self(
		address: "btc-deadbeef",
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Bitcoin",
		code: "BTC",
		iconURL: nil
	)

	static let dot = Self(
		address: "dot-deadbeef",
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Polkadot",
		code: "DOT",
		iconURL: nil
	)

	static let eth = Self(
		address: "eth-deadbeef",
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Ethereum",
		code: "ETH",
		iconURL: nil
	)

	static let ltc = Self(
		address: "ltc-deadbeef",
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Litecoin",
		code: "LTC",
		iconURL: nil
	)

	static let sol = Self(
		address: "sol-deadbeef",
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Solana",
		code: "SOL",
		iconURL: nil
	)

	static let usdt = Self(
		address: "usdt-deadbeef",
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Tether",
		code: "USDT",
		iconURL: nil
	)

	static let xrp = Self(
		address: "xrp-deadbeef",
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "XRP token",
		code: "XRP",
		iconURL: nil
	)
}
#endif
