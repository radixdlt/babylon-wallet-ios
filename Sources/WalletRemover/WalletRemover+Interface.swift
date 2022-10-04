import Foundation

// MARK: - WalletRemover
public struct WalletRemover {
	public var removeWallet: RemoveWallet

	public init(
		removeWallet: @escaping RemoveWallet
	) {
		self.removeWallet = removeWallet
	}
}

// MARK: WalletRemover.RemoveWallet
public extension WalletRemover {
	typealias RemoveWallet = @Sendable () async -> Void
}
