import ComposableArchitecture
import Foundation
import KeychainClient
import Mnemonic
import UserDefaultsClient

// MARK: - Onboarding.Environment
public extension Onboarding {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let keychainClient: KeychainClient
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let userDefaultsClient: UserDefaultsClient // replace with `ProfileCreator`
		public let mnemonicGenerator: @Sendable (BIP39.WordCount, BIP39.Language) throws -> Mnemonic

		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			keychainClient: KeychainClient,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			userDefaultsClient: UserDefaultsClient,
			mnemonicGenerator: @escaping @Sendable (BIP39.WordCount, BIP39.Language) throws -> Mnemonic = { wordCount, language in
				try Mnemonic.generate(wordCount: wordCount, language: language)
			}
		) {
			self.backgroundQueue = backgroundQueue
			self.keychainClient = keychainClient
			self.mainQueue = mainQueue
			self.userDefaultsClient = userDefaultsClient
			self.mnemonicGenerator = mnemonicGenerator
		}
	}
}

#if DEBUG
public extension Onboarding.Environment {
	static let unimplemented = Self(
		backgroundQueue: .unimplemented,
		keychainClient: .unimplemented,
		mainQueue: .unimplemented,
		userDefaultsClient: .unimplemented
	)
}
#endif
