import AccountsClient // OlympiaAccountToMigrate
import Cryptography
import EngineToolkit
import FeaturePrelude
import ScanQRFeature

// MARK: - ScanMultipleOlympiaQRCodes
public struct ScanMultipleOlympiaQRCodes: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Step: Sendable, Hashable {
			case scanQR(ScanQR.State)

			public init() {
				self = .scanQR(.init())
			}
		}

		public var step: Step
		public var importedWalletInfos: OrderedSet<UncheckedImportedOlympiaWalletPayload>
		fileprivate var DelEteMeNoooooooooooWwwWw = 0
		public init(
			step: Step = .init(),
			importedWalletInfos: OrderedSet<UncheckedImportedOlympiaWalletPayload> = .init()
		) {
			self.step = step
			self.importedWalletInfos = importedWalletInfos
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum ChildAction: Sendable, Equatable {
		case scanQR(ScanQR.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case legacyWalletInfoResult(TaskResult<UncheckedImportedOlympiaWalletPayload>)
		case olympiaWallet(ImportedOlympiaWallet)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedScanning(ImportedOlympiaWallet)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.jsonDecoder) var jsonDecoder

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.scanQR, action: /Action.child .. ChildAction.scanQR) {
					ScanQR()
				}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .scanQR(.delegate(.scanned(qrString))):
			return .run { [DelEteMeNoooWWw = state.DelEteMeNoooooooooooWwwWw] send in
				loggerGlobal.critical("IGNORE SCANNED CONTENT. MOCKING RESPONSE!: \(qrString)")
				await send(.internal(.legacyWalletInfoResult(TaskResult {
					UncheckedImportedOlympiaWalletPayload.mockMany[DelEteMeNoooWWw]
				})))
			}

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .legacyWalletInfoResult(.success(info)):
			state.DelEteMeNoooooooooooWwwWw += 1
			state.importedWalletInfos.append(info)
			guard info.isLast else { return .none }

			return .run { [infos = state.importedWalletInfos] send in
				let wallet = try importWallet(infos)
				await send(.internal(.olympiaWallet(wallet)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .olympiaWallet(olympiaWallet):
			return .send(.delegate(.finishedScanning(olympiaWallet)))

		case let .legacyWalletInfoResult(.failure(error)):
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}

// MARK: - ImportedOlympiaWalletFailPayloadsEmpty
struct ImportedOlympiaWalletFailPayloadsEmpty: Swift.Error {}

// MARK: - ImportedOlympiaWalletFailInvalidWordCount
struct ImportedOlympiaWalletFailInvalidWordCount: Swift.Error {}

// MARK: - ImportedOlympiaWalletFailedToFindAnyAccounts
struct ImportedOlympiaWalletFailedToFindAnyAccounts: Swift.Error {}
extension ScanMultipleOlympiaQRCodes {
	private func importWallet(_ info: OrderedSet<UncheckedImportedOlympiaWalletPayload>) throws -> ImportedOlympiaWallet {
		guard let first = info.first else {
			throw ImportedOlympiaWalletFailPayloadsEmpty()
		}
		guard let wordCount = BIP39.WordCount(wordCount: first.words) else {
			throw ImportedOlympiaWalletFailInvalidWordCount()
		}
		let accounts = try info.flatMap { try $0.accountsToImport() }
		let accountSet = OrderedSet(uncheckedUniqueElements: accounts)
		guard let nonEmpty = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>(rawValue: accountSet) else {
			throw ImportedOlympiaWalletFailedToFindAnyAccounts()
		}
		return .init(
			mnemonicWordCount: wordCount,
			accounts: nonEmpty
		)
	}
}

// MARK: - ImportedOlympiaWallet
public struct ImportedOlympiaWallet: Sendable, Hashable {
	public let mnemonicWordCount: BIP39.WordCount
	public let accounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>

	/// This is set to the `max(allScannedAccounts.map(\.addressIndexNonHardendValue)) + 1`,
	/// N.B. max of all **scanned** accounts, **not** max of all selected accounts.
	public var nextDerivationAccountIndex: Profile.Network.NextDerivationIndices.Index {
		.init(accounts.elements.sorted(by: \.addressIndex).last!.addressIndex + 1)
	}
}

// MARK: - UncheckedImportedOlympiaWalletPayload
public struct UncheckedImportedOlympiaWalletPayload: Decodable, Sendable, Hashable {
	/// number of payloads (might be 1)
	public let payloads: Int

	/// the index of the current payload
	public let index: Int

	/// The word count of the mnemonic to import seperately.
	public let words: Int

	private let accounts: [AccountNonChecked]

	var isLast: Bool {
		index >= (payloads - 1)
	}

	fileprivate static let mockMany: OrderedSet<Self> = try! {
		let numberOfPayLoads = 2
		let accountsPerPayload = 2
		let numberOfAccounts = numberOfPayLoads * accountsPerPayload
		let mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		let passphrase = try Mnemonic().words[0].capitalized
		print("✅ Passhprase: \(passphrase)")
		let hdRoot = try mnemonic.hdRoot(passphrase: passphrase)
		let accounts: [AccountNonChecked] = try (0 ..< numberOfAccounts).map {
			let path = try LegacyOlympiaBIP44LikeDerivationPath(index: UInt32($0))
			let publicKey = try hdRoot.derivePublicKey(path: path.wrapAsDerivationPath(), curve: .secp256k1)
			let accountNonChecked = AccountNonChecked(pk: publicKey.compressedData.hex, path: path.derivationPath, xrd: "1\($0)0", name: "Sajjon i=\($0)")

			let accountChecked = try accountNonChecked.checked()
			assert(accountChecked.path == path)
			assert(accountChecked.publicKey.compressedRepresentation == publicKey.compressedRepresentation)
			return accountNonChecked
		}
		let array = (0 ..< numberOfPayLoads).map {
			Self(
				payloads: numberOfPayLoads,
				index: $0,
				words: mnemonic.wordCount.wordCount,
				accounts: Array(accounts[($0 * accountsPerPayload) ..< (($0 + 1) * accountsPerPayload)])
			)
		}
		return OrderedSet(uncheckedUniqueElements: array)
	}()

	struct AccountNonChecked: Decodable, Sendable, Hashable {
		let pk: String
		let path: String
		let xrd: String
		let name: String?

		func checked() throws -> OlympiaAccountToMigrate {
			let publicKeyData = try Data(hex: pk)

			// FIXME: Move to reducer and user a new EncodeOlympiaAddress endpoint we need from Omar (or impl Bech32 ourselves, N.B. Bech32, not Bech32m which we use for Babylon)
			let accountAddressPrefixByte: UInt8 = 0x04
			let addressBytes: [UInt8] = [accountAddressPrefixByte] + Array(publicKeyData.prefix(26))
			let bech32Address = try EngineToolkit().encodeAddressRequest(request: .init(addressBytes: addressBytes, networkId: .adapanet)).get().address
			guard let nonEmptyString = NonEmptyString(rawValue: bech32Address) else {
				fatalError()
			}
			let address = LegacyOlympiaAccountAddress(address: nonEmptyString)

			return try .init(
				publicKey: .init(compressedRepresentation: publicKeyData),
				path: .init(derivationPath: path),
				xrd: .init(fromString: xrd),
				address: address,
				displayName: name.map { NonEmptyString(rawValue: $0) } ?? nil
			)
		}
	}

	public func accountsToImport() throws -> [OlympiaAccountToMigrate] {
		try self.accounts.map {
			try $0.checked()
		}
	}
}

#if DEBUG
extension UncheckedImportedOlympiaWalletPayload {
	public static let previewValue: Self = .init(
		payloads: 1,
		index: 0,
		words: 12,
		accounts: [.previewValue]
	)
}

extension UncheckedImportedOlympiaWalletPayload.AccountNonChecked {
	public static let previewValue = Self(
		pk: "022a471424da5e657499d1ff51cb43c47481a03b1e77f951fe64cec9f5a48f7011",
		path: "m/44'/1022'/0'/0/1'",
		xrd: "1337",
		name: "PreviewValue"
	)
}

extension OlympiaAccountToMigrate {
	public static let previewValue = try! UncheckedImportedOlympiaWalletPayload.AccountNonChecked.previewValue.checked()
}

#endif // DEBUG
