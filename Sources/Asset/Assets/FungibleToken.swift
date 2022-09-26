import Foundation

// MARK: - FungibleToken
public struct FungibleToken: Asset, Token {
	public let address: ComponentAddress
	public let supply: Supply

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
		supply: Supply,
		tokenDescription: String?,
		name: String?,
		code: String?,
		iconURL: String?
	) {
		self.address = address
		self.supply = supply
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
		supply: .fixed(24_000_000_000),
		tokenDescription: "The native token of the Radix Ledger",
		name: "RAD",
		code: "XRD",
		iconURL: nil
	)
}
