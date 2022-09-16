#if DEBUG
import Foundation

public enum AssetGenerator {
	public static var mockAssets: [[any Asset]] {
		[
			[
				FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Bitcoin", code: "BTC", iconURL: ""),
				FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Polkadot", code: "DOT", iconURL: ""),
				FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Ethereum", code: "ETH", iconURL: ""),
				FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Litecoin", code: "LTC", iconURL: ""),
				FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Solana", code: "SOL", iconURL: ""),
				FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "Tether", code: "USDT", iconURL: ""),
				FungibleToken.xrd,
				FungibleToken(address: .random, supply: .fixed(100), tokenDescription: nil, name: "XRP token", code: "XRP", iconURL: ""),
			],
			[
				NonFungibleToken(address: .random, supply: .fixed(100), iconURL: "nft"),
				NonFungibleToken(address: .random, supply: .fixed(100), iconURL: "nft"),
				NonFungibleToken(address: .random, supply: .fixed(100), iconURL: "nft"),
			],
		]
	}
}
#endif
