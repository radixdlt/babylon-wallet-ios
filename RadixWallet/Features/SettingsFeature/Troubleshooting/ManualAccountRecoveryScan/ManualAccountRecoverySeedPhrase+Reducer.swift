import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoverySeedPhrase
public struct ManualAccountRecoverySeedPhrase: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	// MARK: - State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State? = nil

		public let isOlympia: Bool
		public var selected: EntitiesControlledByFactorSource? = nil
		public var deviceFactorSources: IdentifiedArrayOf<EntitiesControlledByFactorSource> = []
	}

	// MARK: - Destination

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case importMnemonic(ImportMnemonic.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case importMnemonic(ImportMnemonic.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.importMnemonic, action: \.importMnemonic) {
				ImportMnemonic()
			}
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case selected(EntitiesControlledByFactorSource?)
		case addButtonTapped
		case continueButtonTapped(EntitiesControlledByFactorSource)
		case closeEnterMnemonicButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedDeviceFactorSources(TaskResult<IdentifiedArrayOf<EntitiesControlledByFactorSource>>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case recover(FactorSourceIDFromHash, olympia: Bool)
	}

	// MARK: - Reducer

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.userDefaults) var userDefaults

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return updateEntities(state: &state)

		case let .selected(selection):
			state.selected = selection
			return .none

		case .addButtonTapped:
			let title = state.isOlympia ? L10n.AccountRecoveryScan.ChooseSeedPhrase.importMnemonicTitleOlympia : L10n.AccountRecoveryScan.ChooseSeedPhrase.importMnemonicTitleBabylon

			let persistStrategy = ImportMnemonic.State.PersistStrategy(
				factorSourceKindOfMnemonic: state.isOlympia ? .olympia : .babylon(isMain: false),
				location: .intoKeychainAndProfile,
				onMnemonicExistsStrategy: .appendWithCryptoParamaters
			)

			state.destination = .importMnemonic(
				ImportMnemonic.State(
					header: .init(title: title),
					warning: L10n.EnterSeedPhrase.warning,
					warningOnContinue: nil,
					isWordCountFixed: !state.isOlympia,
					persistStrategy: persistStrategy,
					wordCount: state.isOlympia ? BIP39WordCount.twelve : BIP39WordCount.twentyFour,
					bip39Passphrase: ""
				)
			)
			return .none

		case .closeEnterMnemonicButtonTapped:
			state.destination = nil
			return .none

		case let .continueButtonTapped(factorSource):
			return .send(.delegate(.recover(factorSource.factorSourceID, olympia: state.isOlympia)))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedDeviceFactorSources(.success(deviceFactorSources)):
			state.deviceFactorSources = deviceFactorSources
			if state.deviceFactorSources.count == 1 {
				state.selected = deviceFactorSources[0]
			}
			return .none

		case let .loadedDeviceFactorSources(.failure(error)):
			loggerGlobal.error("Failed to load device factor sources, error: \(error)")
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .importMnemonic(.delegate(.persistedNewFactorSourceInProfile(factorSource))):
			do {
				guard case let .device(deviceFactorSource) = factorSource else {
					struct NotDeviceFactorSource: Error {}
					throw NotDeviceFactorSource()
				}

				let entitiesControlledByFactorSource = EntitiesControlledByFactorSource(
					entities: [],
					hiddenEntities: [],
					deviceFactorSource: deviceFactorSource,
					isMnemonicPresentInKeychain: true,
					isMnemonicMarkedAsBackedUp: false
				)

				state.deviceFactorSources.append(entitiesControlledByFactorSource)
				state.selected = entitiesControlledByFactorSource

				// Not important enough to throw.
				try? userDefaults.addFactorSourceIDOfBackedUpMnemonic(deviceFactorSource.id)

				state.destination = nil
			} catch {
				loggerGlobal.error("Failed to add mnemonic \(error)")
				errorQueue.schedule(error)
			}

			return .none

		default:
			return .none
		}
	}

	// Helper effects

	private func updateEntities(state: inout State) -> Effect<Action> {
		.run { [isOlympia = state.isOlympia] send in
			let result = await TaskResult {
				try await deviceFactorSourceClient.controlledEntities(nil)
					.filter {
						let dfs = $0.deviceFactorSource

						if isOlympia {
							return dfs.supportsOlympia
						} else {
							// The word count == 24 check SHOULD always be true, but best include it anyway.
							return dfs.supportsBabylon && dfs.hint.mnemonicWordCount == .twentyFour
						}
					}
			}
			await send(.internal(.loadedDeviceFactorSources(result)))
		} catch: { error, _ in
			loggerGlobal.error("Error: \(error)")
		}
	}
}
