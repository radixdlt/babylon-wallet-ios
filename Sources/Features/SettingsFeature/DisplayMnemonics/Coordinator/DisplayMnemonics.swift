import FactorSourcesClient
import FeaturePrelude
import ImportMnemonicFeature
import Profile
import SecureStorageClient

// MARK: - AccountsForDeviceFactorSource
public struct AccountsForDeviceFactorSource: Sendable, Hashable, Identifiable {
	public typealias ID = FactorSourceID
	public var id: ID { deviceFactorSource.id }
	public let accounts: [Profile.Network.Account]
	public let deviceFactorSource: HDOnDeviceFactorSource
}

// MARK: - DisplayMnemonics
public struct DisplayMnemonics: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State? = nil

		public var deviceFactorSources: IdentifiedArrayOf<DisplayMnemonicRow.State> = []

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedFactorSources(TaskResult<IdentifiedArrayOf<AccountsForDeviceFactorSource>>)
	}

	public enum ChildAction: Sendable, Equatable {
		case row(id: DisplayMnemonicRow.State.ID, action: DisplayMnemonicRow.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, Equatable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case useCaution(AlertState<Action.UseCautionAlert>)
			case displayMnemonic(DisplayMnemonic.State)
		}

		public enum Action: Sendable, Equatable {
			case useCaution(UseCautionAlert)
			case displayMnemonic(DisplayMnemonic.Action)

			public enum UseCautionAlert: Sendable, Hashable {
				case revealTapped(DisplayMnemonicRow.State.ID)
				case cancelTapped
			}
		}

		public init() {}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.displayMnemonic, action: /Action.displayMnemonic) {
				DisplayMnemonic()
			}
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.secureStorageClient) var secureStorageClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.deviceFactorSources, action: /Action.child .. ChildAction.row) {
				DisplayMnemonicRow()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return load()
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedFactorSources(.success(accountsForDeviceFactorSources)):
			state.deviceFactorSources = .init(
				uniqueElements: accountsForDeviceFactorSources.map { .init(accountsForDeviceFactorSource: $0) },
				id: \.id
			)

			return .none

		case let .loadedFactorSources(.failure(error)):
			loggerGlobal.error("Failed to load factor source, error: \(error)")
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .row(id, action: .delegate(.openDetails)):
			state.destination = .useCaution(.useCaution(id))
			return .none
		case .destination(.presented(.displayMnemonic(.delegate(.failedToLoad)))):
			state.destination = nil
			return .none

		case .destination(.presented(.displayMnemonic(.delegate(.doneViewing)))):
			state.destination = nil
			return .none

		case let .destination(.presented(.useCaution(.revealTapped(id)))):
			guard let deviceFactorSource = state.deviceFactorSources[id: id]?.deviceFactorSource else {
				loggerGlobal.warning("Unable to find factor source in state... strange!")
				return .none
			}
			// FIXME: Auto close after 2 minutes?
			state.destination = .displayMnemonic(.init(deviceFactorSource: deviceFactorSource))
			return .none

		default: return .none
		}
	}
}

extension DisplayMnemonics {
	private func load() -> EffectTask<Action> {
		@Sendable func doLoad() async throws -> IdentifiedArrayOf<AccountsForDeviceFactorSource> {
			let sources = try await factorSourcesClient.getFactorSources(ofKind: .device)
			let accounts = try await accountsClient.getAccountsOnCurrentNetwork()
			return try IdentifiedArrayOf(uniqueElements: sources.map { factorSource in
				let accountsForSource = accounts.filter { account in
					switch account.securityState {
					case let .unsecured(unsecuredEntityControl):
						return unsecuredEntityControl.transactionSigning.factorSourceID == factorSource.id
					}
				}
				return try AccountsForDeviceFactorSource(
					accounts: accountsForSource,
					deviceFactorSource: HDOnDeviceFactorSource(factorSource: factorSource)
				)
			})
		}

		return .task {
			await .internal(.loadedFactorSources(TaskResult {
				try await doLoad()
			}))
		}
	}
}

extension AlertState<DisplayMnemonics.Destinations.Action.UseCautionAlert> {
	static func useCaution(_ id: DisplayMnemonicRow.State.ID) -> Self {
		Self {
			TextState("Use Caution") // FIXME: Strings
		} actions: {
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(role: .destructive, action: .revealTapped(id)) {
				TextState("Reveal Seed phrase") // FIXME: Strings
			}
		} message: {
			TextState("Make sure no person or camera can see your display. Don't read or mouth the words. We have prevented you from taking screenshots.") // FIXME: Strings
		}
	}
}
