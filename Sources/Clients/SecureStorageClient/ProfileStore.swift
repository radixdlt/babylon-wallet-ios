import ClientPrelude
import Cryptography
import Profile

#if DEBUG
// Only used by tests.
extension DispatchSemaphore: @unchecked Sendable {}
#endif

// MARK: - ProfileStore
public final actor ProfileStore: GlobalActor {
	@Dependency(\.secureStorageClient) var secureStorageClient
	public static let shared = ProfileStore()
	private var profile: Profile

	private init() {
		self.profile = Self.newEphemeral()
		#if DEBUG
		let semaphore = DispatchSemaphore(value: 0)
		// Must do this in a separate thread, otherwise we block the concurrent thread pool
		DispatchQueue.global(qos: .userInitiated).async {
			Task {
				await self.restoreFromSecureStorageIfAble()
				semaphore.signal()
			}
		}
		semaphore.wait()
		#else
		Task {
			await restoreFromSecureStorageIfAble()
		}
		#endif
	}
}

// MARK: Private
extension ProfileStore {
	private static func newEphemeral() -> Profile {
		@Dependency(\.mnemonicClient) var mnemonicClient
		do {
			let mnemonic = try mnemonicClient.generate(BIP39.WordCount.twentyFour, BIP39.Language.english)
			let bip39Passphrase = ""
			let mnemonicWithPassphrase = MnemonicWithPassphrase(mnemonic: mnemonic, passphrase: bip39Passphrase)
			let factorSource = try FactorSource.babylon(mnemonic: mnemonic, bip39Passphrase: bip39Passphrase)
		} catch {
			fatalError()
		}
	}

	private func restoreFromSecureStorageIfAble() async {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard
			let existing = try? await secureStorageClient.loadProfile()
		else {
			return
		}

		await self.update(profile: existing)
	}
}

// MARK: Public
extension ProfileStore {
	public func update(profile: Profile) async {}
}
