import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - DisplayMnemonic
@Reducer
struct DisplayMnemonic: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		@Shared(.mnemonicBuilder) var mnemonicBuilder
		let mnemonic: Mnemonic

		let factorSourceID: FactorSourceIDFromHash
		var words: NonEmpty<IdentifiedArrayOf<OffsetIdentified<BIP39Word>>> {
			let identifiedWords = mnemonic.words.identifiablyEnumerated()
			return .init(identifiedWords)!
		}

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case doneViewingButtonTapped
		case closeButtonTapped
		case backButtonTapped
		#if DEBUG
		case debugCopy
		#endif
	}

	enum DelegateAction: Sendable, Equatable {
		case backedUp(FactorSourceIdFromHash)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case backupConfirmation(AlertState<Action.BackupConfirmation>)
			case onContinueWarning(AlertState<Action.OnContinueWarning>)
			case verifyMnemonic(AddFactorSource.ConfirmSeedPhrase.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case backupConfirmation(BackupConfirmation)
			case onContinueWarning(OnContinueWarning)
			case verifyMnemonic(AddFactorSource.ConfirmSeedPhrase.Action)

			enum BackupConfirmation: Sendable, Hashable {
				case userHasBackedUp
				case userHasNotBackedUp
			}

			enum OnContinueWarning: Sendable, Hashable {
				case buttonTapped
			}
		}

		var body: some Reducer<State, Action> {
			Scope(state: \.verifyMnemonic, action: \.verifyMnemonic) {
				AddFactorSource.ConfirmSeedPhrase()
			}
		}
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss
	#if DEBUG
	@Dependency(\.pasteboardClient) var pasteboardClient
	#endif

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .doneViewingButtonTapped:
			return markAsBackedUpIfNeeded(&state)

		case .backButtonTapped:
			return markAsBackedUpIfNeeded(&state)

		case .closeButtonTapped:
			return markAsBackedUpIfNeeded(&state)
		#if DEBUG
		case .debugCopy:
			let phrase = state.words.elements.map(\.element.word).joined(separator: " ")
			pasteboardClient.copyString(phrase)
			return .none
		#endif
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .backupConfirmation(.userHasBackedUp):
			state.$mnemonicBuilder.withLock { builder in
				builder = try! builder.createMnemonicFromWords(words: state.mnemonic.words.map(\.word))
			}
			state.destination = .verifyMnemonic(.init(factorSourceKind: .device))
			return .none

		case .backupConfirmation(.userHasNotBackedUp):
			return .run { _ in
				await dismiss()
			}

		case .verifyMnemonic(.delegate(.validated)):
			let factorSourceID = state.factorSourceID
			// Reset
			state.$mnemonicBuilder.withLock { builder in
				builder = .init()
			}
			return .run { send in
				try userDefaults.addFactorSourceIDOfBackedUpMnemonic(factorSourceID)
				await send(.delegate(.backedUp(factorSourceID)))
			} catch: { error, _ in
				loggerGlobal.error("Failed to save mnemonic as backed up")
				errorQueue.schedule(error)
			}

		default:
			return .none
		}
	}

	private func markAsBackedUpIfNeeded(_ state: inout State) -> Effect<Action> {
		let listOfBackedUpMnemonics = userDefaults.getFactorSourceIDOfBackedUpMnemonics()
		if listOfBackedUpMnemonics.contains(state.factorSourceID) {
			return .run { _ in
				await dismiss()
			}
		} else {
			state.destination = .askUserIfTheyHaveBackedUpMnemonic()
			return .none
		}
	}
}

extension DisplayMnemonic.Destination.State {
	fileprivate static func askUserIfTheyHaveBackedUpMnemonic() -> Self {
		.backupConfirmation(.init(
			title: { TextState(L10n.ImportMnemonic.BackedUpAlert.title) },
			actions: {
				ButtonState(action: .userHasBackedUp, label: { TextState(L10n.ImportMnemonic.BackedUpAlert.confirmAction) })
				ButtonState(action: .userHasNotBackedUp, label: { TextState(L10n.ImportMnemonic.BackedUpAlert.noAction) })
			},
			message: { TextState(L10n.ImportMnemonic.BackedUpAlert.message) }
		))
	}
}
