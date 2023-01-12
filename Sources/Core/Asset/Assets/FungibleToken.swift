import EngineToolkit
import Prelude
import Profile

// MARK: - FungibleToken
public struct FungibleToken: Sendable, Asset, Token, Hashable {
	public let componentAddress: ComponentAddress
	public let totalSupplyAttos: BigUInt?
	public let totalMintedAttos: BigUInt?
	public let totalBurntAttos: BigUInt?

	/// An optional desciption of this token, e.g.
	/// ` "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes."`
	public let tokenDescription: String?

	/// Short token name, e.g. `"Radix"`.
	public let name: String?

	/// Symbol of token, e.g. `"XRD"`.
	public let symbol: String?

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
		totalSupplyAttos: BigUInt?,
		totalMintedAttos: BigUInt?,
		totalBurntAttos: BigUInt?,
		tokenDescription: String?,
		name: String?,
		symbol: String?,
		tokenInfoURL: String? = nil,
		iconURL: URL? = nil
	) {
		self.componentAddress = componentAddress
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

public extension FungibleToken {
	var isXRD: Bool {
		for networkID in NetworkID.allCases {
			if
				let xrdAddress = Network.KnownAddresses.addressMap[networkID]?.xrd,
				self.componentAddress.address == xrdAddress.address
			{
				return true
			}
		}
		return false
	}
}

// MARK: - FungibleTokenContainer
public struct FungibleTokenContainer: Sendable, AssetContainer, Equatable {
	public let owner: AccountAddress
	public typealias T = FungibleToken
	public var asset: FungibleToken

	// TODO: replace String type with appropriate numeric type with 0b2^256 / 0d1e18 ~ 1e60 support
	/// Token amount held in one account, expressed as regular decimal value, for example: 105.78 XRD
	public var amount: String?
	/// Token worth in currently selected currency.
	public var worth: BigUInt?

	public init(
		owner: AccountAddress,
		asset: FungibleToken,
		amount: String?,
		worth: BigUInt?
	) {
		self.owner = owner
		self.asset = asset
		self.amount = amount
		self.worth = worth
	}
}

public extension FungibleToken {
	/// The native token of the Radix Ledger
	static let xrd = Self(
		componentAddress: "resource_tdx_a_1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqegh4k9",
		divisibility: 18,
		totalSupplyAttos: 24_000_000_000.inAttos,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: "The native token of the Radix Ledger",
		name: "Radix",
		symbol: "XRD",
		tokenInfoURL: "https://tokens.radixdlt.com"
	)
}

#if DEBUG
public extension FungibleToken {
	static let btc = Self(
		componentAddress: "btc-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Bitcoin",
		symbol: "BTC"
	)

	static let dot = Self(
		componentAddress: "dot-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Polkadot",
		symbol: "DOT"
	)

	static let eth = Self(
		componentAddress: "eth-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Ethereum",
		symbol: "ETH"
	)

	static let ltc = Self(
		componentAddress: "ltc-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Litecoin",
		symbol: "LTC"
	)

	static let sol = Self(
		componentAddress: "sol-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Solana",
		symbol: "SOL"
	)

	static let usdt = Self(
		componentAddress: "usdt-deadbeef",
		divisibility: 18,
		totalSupplyAttos: 0,
		totalMintedAttos: 0,
		totalBurntAttos: 0,
		tokenDescription: nil,
		name: "Tether",
		symbol: "USDT"
	)

	static let xrp = Self(
		componentAddress: "xrp-deadbeef",
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
