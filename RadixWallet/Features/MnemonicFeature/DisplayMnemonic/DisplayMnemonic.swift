import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - DisplayMnemonic
@Reducer
struct DisplayMnemonic: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let mnemonic: Mnemonic
		enum Context: Sendable, Hashable {
			case fromSettings
			case fromBackupPrompt
		}

		let context: Context
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
	}

	enum DelegateAction: Sendable, Equatable {
		case doneViewing(idOfBackedUpFactorSource: FactorSourceIdFromHash?) // `nil` means it was already marked as backed up
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case backupConfirmation(AlertState<Action.BackupConfirmation>)
			case onContinueWarning(AlertState<Action.OnContinueWarning>)
			case verifyMnemonic(VerifyMnemonic.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case backupConfirmation(BackupConfirmation)
			case onContinueWarning(OnContinueWarning)
			case verifyMnemonic(VerifyMnemonic.Action)

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
				VerifyMnemonic()
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

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .doneViewingButtonTapped:
			return markAsBackedUpIfNeeded(&state)

		case .backButtonTapped:
			return markAsBackedUpIfNeeded(&state)

		case .closeButtonTapped:
			if state.context == .fromBackupPrompt {
				return markAsBackedUpIfNeeded(&state)
			}
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .backupConfirmation(.userHasBackedUp):
			state.destination = .verifyMnemonic(.init(mnemonic: state.mnemonic))
			return .none

		case .backupConfirmation(.userHasNotBackedUp):
			loggerGlobal.notice("User have not backed up")
			return .send(.delegate(.doneViewing(idOfBackedUpFactorSource: nil)))

		case .verifyMnemonic(.delegate(.mnemonicVerified)):
			let factorSourceID = state.factorSourceID
			return .run { send in
				try userDefaults.addFactorSourceIDOfBackedUpMnemonic(factorSourceID)
				await send(.delegate(.doneViewing(idOfBackedUpFactorSource: factorSourceID)))
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
			return .send(.delegate(.doneViewing(idOfBackedUpFactorSource: nil))) // user has already marked this mnemonic as "backed up"
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
