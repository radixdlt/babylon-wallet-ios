import Cryptography
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
		public var importedWalletInfos: OrderedSet<ImportedOlympiaLegacyWalletInfo>
		fileprivate var DelEteMeNoooooooooooWwwWw = 0
		public init(
			step: Step = .init(),
			importedWalletInfos: OrderedSet<ImportedOlympiaLegacyWalletInfo> = .init()
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
		case legacyWalletInfoResult(TaskResult<ImportedOlympiaLegacyWalletInfo>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedScanning(OrderedSet<ImportedOlympiaLegacyWalletInfo>)
	}

	@Dependency(\.errorQueue) var errorQueue

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
					ImportedOlympiaLegacyWalletInfo.mockMany[DelEteMeNoooWWw]
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
			return .send(.delegate(.finishedScanning(state.importedWalletInfos)))
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

// MARK: - ImportedOlympiaLegacyWalletInfo
public struct ImportedOlympiaLegacyWalletInfo: Decodable, Sendable, Hashable {
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
		let numberOfPayLoads = 3
		let accountsPerPayload = 2
		let numberOfAccounts = numberOfPayLoads * accountsPerPayload
		let mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		let hdRoot = try mnemonic.hdRoot(passphrase: "")
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
				words: 12,
				accounts: Array(accounts[$0 ..< (($0 + 1) * accountsPerPayload)])
			)
		}
		print("🎉 array: \(array)")
		return OrderedSet(uncheckedUniqueElements: array)
	}()

	struct AccountNonChecked: Decodable, Sendable, Hashable {
		let pk: String
		let path: String
		let xrd: String
		let name: String?

		func checked() throws -> Account {
			try .init(
				publicKey: .init(compressedRepresentation: Data(hex: pk)),
				path: .init(derivationPath: path),
				xrd: .init(fromString: xrd),
				displayName: name.map { NonEmptyString(rawValue: $0) } ?? nil
			)
		}
	}

	public struct Account: Sendable, Hashable {
		public let publicKey: K1.PublicKey
		public let path: LegacyOlympiaBIP44LikeDerivationPath
		public let xrd: BigDecimal
		public let displayName: NonEmptyString?
	}

	public func accountsToImport() throws -> [Account] {
		fatalError()
	}
}
