import EngineToolkitModels
import Prelude
import Profile

// MARK: - FungibleToken
public struct FungibleToken: Sendable, Asset, Token, Hashable {
	public let resourceAddress: ResourceAddress
	public let totalSupply: BigDecimal?
	public let totalMinted: BigDecimal?
	public let totalBurnt: BigDecimal?

	/// An optional desciption of this token, e.g.
	/// ` "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes."`
	public let tokenDescription: String?

	/// Short token name, e.g. `"Radix"`.
	public let name: String?

	/// Symbol of token, e.g. `"XRD"`.
	public let symbol: String?

	/// True if the token represents XRD.
	public let isXRD: Bool

	/// Token icon URL.
	public let iconURL: URL?

	/// Website of the token, e.g. `"https://tokens.radixdlt.com"`
	public let tokenInfoURL: String?

	/// Also known as `granularity`, often value `18`, meaning each whole unit
	/// can be divided into 10^18 subunits (attos). In case of `17` one CANNOT
	/// send 1 atto, 9 or 11 or 18 attos, rather the amount MUST be a multiple
	/// of 10, e.g. 10, 20, 90, 1002010 attos etc.
	public let divisibility: Int?

	public init(
		resourceAddress: ResourceAddress,
		divisibility: Int? = nil,
		totalSupply: BigDecimal? = nil,
		totalMinted: BigDecimal? = nil,
		totalBurnt: BigDecimal? = nil,
		tokenDescription: String? = nil,
		name: String? = nil,
		symbol: String? = nil,
		isXRD: Bool,
		tokenInfoURL: String? = nil,
		iconURL: URL? = nil
	) {
		self.resourceAddress = resourceAddress
		self.divisibility = divisibility
		self.totalSupply = totalSupply
		self.totalMinted = totalMinted
		self.totalBurnt = totalBurnt
		self.tokenDescription = tokenDescription
		self.name = name
		self.symbol = symbol
		self.isXRD = isXRD
		self.tokenInfoURL = tokenInfoURL
		self.iconURL = iconURL
	}
}

// MARK: - FungibleTokenContainer
public struct FungibleTokenContainer: Sendable, AssetContainer, Hashable {
	public let owner: AccountAddress
	public var asset: FungibleToken

	public var amount: BigDecimal
	/// Token worth in currently selected currency.
	public var worth: BigDecimal?

	public init(
		owner: AccountAddress,
		asset: FungibleToken,
		amount: BigDecimal,
		worth: BigDecimal?
	) {
		self.owner = owner
		self.asset = asset
		self.amount = amount
		self.worth = worth
	}
}

#if DEBUG
extension FungibleToken {
	/// The native token of the Radix Ledger
	public static let xrd = Self(
		resourceAddress: "resource_tdx_a_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqegh4k9",
		divisibility: 18,
		totalSupply: 24_000_000_000,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: "The native token of the Radix Ledger",
		name: "Radix",
		symbol: "XRD",
		isXRD: true,
		tokenInfoURL: "https://tokens.radixdlt.com"
	)

	public static let btc = Self(
		resourceAddress: "btc-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Bitcoin",
		symbol: "BTC",
		isXRD: false
	)

	public static let dot = Self(
		resourceAddress: "dot-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Polkadot",
		symbol: "DOT",
		isXRD: false
	)

	public static let eth = Self(
		resourceAddress: "eth-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Ethereum",
		symbol: "ETH",
		isXRD: false
	)

	public static let ltc = Self(
		resourceAddress: "ltc-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Litecoin",
		symbol: "LTC",
		isXRD: false
	)

	public static let sol = Self(
		resourceAddress: "sol-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Solana",
		symbol: "SOL",
		isXRD: false
	)

	public static let usdt = Self(
		resourceAddress: "usdt-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Tether",
		symbol: "USDT",
		isXRD: false
	)

	public static let xrp = Self(
		resourceAddress: "xrp-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "XRP token",
		symbol: "XRP",
		isXRD: false
	)
}
#endif
