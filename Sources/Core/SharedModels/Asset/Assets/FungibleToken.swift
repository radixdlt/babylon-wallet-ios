import EngineToolkitModels
import Prelude
import ProfileModels

// MARK: - FungibleToken
public struct FungibleToken: Sendable, Asset, Token, Hashable {
	public let componentAddress: ComponentAddress
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
		componentAddress: ComponentAddress,
		divisibility: Int?,
		totalSupply: BigDecimal?,
		totalMinted: BigDecimal?,
		totalBurnt: BigDecimal?,
		tokenDescription: String?,
		name: String?,
		symbol: String?,
		isXRD: Bool,
		tokenInfoURL: String? = nil,
		iconURL: URL? = nil
	) {
		self.componentAddress = componentAddress
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
public struct FungibleTokenContainer: Sendable, AssetContainer, Equatable {
	public let owner: AccountAddress
	public var asset: FungibleToken

	// TODO: replace String type with appropriate numeric type with 0b2^256 / 0d1e18 ~ 1e60 support
	/// Token amount held in one account, expressed as regular decimal value, for example: 105.78 XRD
	public var amount: String?
	/// Token worth in currently selected currency.
	public var worth: BigDecimal?

	public init(
		owner: AccountAddress,
		asset: FungibleToken,
		amount: String?,
		worth: BigDecimal?
	) {
		self.owner = owner
		self.asset = asset
		self.amount = amount
		self.worth = worth
	}
}

// TODO: delete this when support for big decimals is added
public extension FungibleTokenContainer {
	var unsafeFailingAmountWithoutPrecision: Float {
		if let amount = amount,
		   let floatAmount = Float(amount)
		{
			return floatAmount
		} else {
			return 0
		}
	}
}

public extension FungibleToken {
	/// The native token of the Radix Ledger
	static let xrd = Self(
		componentAddress: "resource_tdx_22_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqj3nwpk",
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
}

#if DEBUG
public extension FungibleToken {
	static let btc = Self(
		componentAddress: "btc-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Bitcoin",
		symbol: "BTC",
		isXRD: false
	)

	static let dot = Self(
		componentAddress: "dot-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Polkadot",
		symbol: "DOT",
		isXRD: false
	)

	static let eth = Self(
		componentAddress: "eth-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Ethereum",
		symbol: "ETH",
		isXRD: false
	)

	static let ltc = Self(
		componentAddress: "ltc-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Litecoin",
		symbol: "LTC",
		isXRD: false
	)

	static let sol = Self(
		componentAddress: "sol-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Solana",
		symbol: "SOL",
		isXRD: false
	)

	static let usdt = Self(
		componentAddress: "usdt-deadbeef",
		divisibility: 18,
		totalSupply: 0,
		totalMinted: 0,
		totalBurnt: 0,
		tokenDescription: nil,
		name: "Tether",
		symbol: "USDT",
		isXRD: false
	)

	static let xrp = Self(
		componentAddress: "xrp-deadbeef",
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
