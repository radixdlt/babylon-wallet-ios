import ComposableArchitecture
import Sargon
import SwiftUI

// FIXME: Refactor ImportMnemonic
typealias DisplayMnemonic = ImportMnemonic

// MARK: - ImportMnemonic
struct ImportMnemonic: Sendable, FeatureReducer {
	static let wordsPerRow = 3

	struct State: Sendable, Hashable {
		var grid: ImportMnemonicGrid.State
		var bip39Passphrase: String = ""

		var mnemonic: Mnemonic? {
			let completedWords = self.completedWords
			guard completedWords.count == grid.words.count else {
				return nil
			}
			return try? Mnemonic(
				words: completedWords
			)
		}

		var isComplete: Bool {
			completedWords.count == grid.words.count
		}

		var completedWords: [BIP39Word] {
			grid.words.compactMap(\.completeWord)
		}

		let isWordCountFixed: Bool
		var isAdvancedMode: Bool = false

		let header: Header?
		let warning: String?
		let warningOnContinue: OnContinueWarning?

		struct ReadonlyMode: Sendable, Hashable {
			enum Context: Sendable, Hashable {
				case fromSettings
				case fromBackupPrompt
			}

			let context: Context

			// FIXME: This aint pretty... but we are short on time, forgive me... we are putting WAY
			// to much logic and responsibility into this reducer here... for when a mnemonic is displayed
			// either from settings or from AccountDetails after user have pressed "Back up this mnemonic"
			// prompt, we need to able to mark a mnemonic as "backed up by user", we do so by use of
			// `FactorSourceIDFromHash` - which require a FactorSourceKind....
			let factorSourceID: FactorSourceIDFromHash

			init(context: Context, factorSourceID: FactorSourceIDFromHash) {
				self.context = context
				self.factorSourceID = factorSourceID
			}
		}

		struct WriteMode: Sendable, Hashable {
			var isProgressing: Bool
			let persistStrategy: PersistStrategy?
			let showCloseButton: Bool
		}

		enum Mode: Sendable, Hashable {
			case readonly(ReadonlyMode)
			case write(WriteMode)
			var readonly: ReadonlyMode? {
				switch self {
				case let .readonly(value): value
				case .write: nil
				}
			}

			var write: WriteMode? {
				switch self {
				case .readonly: nil
				case let .write(value): value
				}
			}

			mutating func update(isProgressing: Bool) {
				guard var write = self.write else {
					assertionFailure("Expected write mode")
					return
				}
				write.isProgressing = isProgressing
				self = .write(write)
			}
		}

		var mode: Mode

		@PresentationState
		var destination: Destination.State?

		struct PersistStrategy: Sendable, Hashable {
			enum Location: Sendable, Hashable {
				case intoKeychainAndProfile
			}

			enum OnMnemonicExistsStrategy: Sendable, Hashable {
				case abort
				case appendWithCryptoParamaters
			}

			let onMnemonicExistsStrategy: OnMnemonicExistsStrategy
			let factorSourceKindOfMnemonic: OnDeviceMnemonicKind
			let location: Location

			init(
				factorSourceKindOfMnemonic: OnDeviceMnemonicKind,
				location: Location,
				onMnemonicExistsStrategy: OnMnemonicExistsStrategy
			) {
				self.factorSourceKindOfMnemonic = factorSourceKindOfMnemonic
				self.location = location
				self.onMnemonicExistsStrategy = onMnemonicExistsStrategy
			}
		}

		struct OnContinueWarning: Sendable, Hashable {
			let title: String
			let text: String
			let button: String

			init(title: String, text: String, button: String) {
				self.title = title
				self.text = text
				self.button = button
			}
		}

		init(
			header: Header? = nil,
			warning: String? = nil,
			showCloseButton: Bool = false,
			warningOnContinue: OnContinueWarning? = nil,
			isWordCountFixed: Bool,
			persistStrategy: PersistStrategy?,
			language: BIP39Language = .english,
			wordCount: BIP39WordCount = .twelve,
			bip39Passphrase: String = ""
		) {
			precondition(wordCount.rawValue.isMultiple(of: UInt8(ImportMnemonic.wordsPerRow)))

			self.mode = .write(
				.init(
					isProgressing: false,
					persistStrategy: persistStrategy,
					showCloseButton: showCloseButton
				)
			)
			self.grid = .init(count: wordCount, language: language, isWordCountFixed: isWordCountFixed)
			self.isWordCountFixed = isWordCountFixed
			self.bip39Passphrase = bip39Passphrase

			self.header = header
			self.warning = warning
			self.warningOnContinue = warningOnContinue
		}

		init(
			header: Header? = nil,
			warning: String? = nil,
			mnemonicWithPassphrase: MnemonicWithPassphrase,
			readonlyMode: ReadonlyMode
		) {
			self.header = header
			self.warning = warning
			self.warningOnContinue = nil

			let mnemonic = mnemonicWithPassphrase.mnemonic
			self.grid = .init(mnemonic: mnemonic)
			self.mode = .readonly(readonlyMode)
			self.isWordCountFixed = true
			self.bip39Passphrase = mnemonicWithPassphrase.passphrase
		}

		struct Header: Sendable, Hashable {
			let title: String
			let subtitle: String?

			init(title: String, subtitle: String? = nil) {
				self.title = title
				self.subtitle = subtitle
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case toggleModeButtonTapped
		case passphraseChanged(String)
		case doneViewing
		case closeButtonTapped
		case backButtonTapped
		case continueButtonTapped(Mnemonic)
	}

	enum InternalAction: Sendable, Equatable {
		struct IntermediaryResult: Sendable, Equatable {
			let factorSource: FactorSource
			let savedIntoProfile: Bool
		}

		case saveFactorSourceResult(TaskResult<IntermediaryResult>)
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case grid(ImportMnemonicGrid.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case persistedNewFactorSourceInProfile(FactorSource)
		case persistedMnemonicInKeychainOnly(FactorSource)
		case notPersisted(MnemonicWithPassphrase)
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

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mnemonicClient) var mnemonicClient
	@Dependency(\.continuousClock) var clock
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	#if DEBUG
	@Dependency(\.pasteboardClient) var pasteboardClient
	#endif

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.grid, action: \.child.grid) {
			ImportMnemonicGrid()
		}

		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .passphraseChanged(passphrase):
			state.bip39Passphrase = passphrase
			return .none

		case .toggleModeButtonTapped:
			state.isAdvancedMode.toggle()
			return .none

		case let .continueButtonTapped(mnemonic):
			if let warningOnContinue = state.warningOnContinue {
				state.destination = .onContinueWarning(warningOnContinue)
				return .none
			}

			return continueWithMnemonic(mnemonic: mnemonic, in: &state)

		case .doneViewing:
			assert(state.mode.readonly != nil)
			return markAsBackedUpIfNeeded(&state)

		case .backButtonTapped:
			assert(state.mode.readonly?.context == .fromSettings)
			return markAsBackedUpIfNeeded(&state)

		case .closeButtonTapped:
			if state.mode.readonly?.context == .fromBackupPrompt {
				return markAsBackedUpIfNeeded(&state)
			} else if state.mode.write?.showCloseButton == true {
				return .run { _ in await dismiss() }
			} else {
				assertionFailure("Invalid mode: No close button should be visible")
				return .none
			}
		}
	}

	private func continueWithMnemonic(mnemonic: Mnemonic, in state: inout State) -> Effect<Action> {
		guard let write = state.mode.write else {
			preconditionFailure("expected write mode")
		}
		state.mode.update(isProgressing: true)
		let mnemonicWithPassphrase = MnemonicWithPassphrase(
			mnemonic: mnemonic,
			passphrase: state.bip39Passphrase
		)
		guard let persistStrategy = write.persistStrategy else {
			state.mode.update(isProgressing: false)
			return .send(.delegate(.notPersisted(mnemonicWithPassphrase)))
		}
		switch persistStrategy.location {
		case .intoKeychainAndProfile:
			return .run { send in
				await send(.internal(.saveFactorSourceResult(
					TaskResult {
						let saveIntoProfile = true
						let factorSource = try await factorSourcesClient.addOnDeviceFactorSource(
							onDeviceMnemonicKind: persistStrategy.factorSourceKindOfMnemonic,
							mnemonicWithPassphrase: mnemonicWithPassphrase,
							onMnemonicExistsStrategy: persistStrategy.onMnemonicExistsStrategy,
							saveIntoProfile: saveIntoProfile
						)
						return .init(factorSource: factorSource.asGeneral, savedIntoProfile: saveIntoProfile)
					}
				)))
			}
		}
	}

	private func markAsBackedUpIfNeeded(_ state: inout State) -> Effect<Action> {
		guard let factorSourceID = state.mode.readonly?.factorSourceID else {
			return .none
		}

		let listOfBackedUpMnemonics = userDefaults.getFactorSourceIDOfBackedUpMnemonics()
		if listOfBackedUpMnemonics.contains(factorSourceID) {
			return .send(.delegate(.doneViewing(idOfBackedUpFactorSource: nil))) // user has already marked this mnemonic as "backed up"
		} else {
			state.destination = .askUserIfSheHasBackedUpMnemonic()
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .saveFactorSourceResult(.failure(error)):
			state.mode.update(isProgressing: false)
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to save mnemonic in profile, error: \(error)")
			return .none

		case let .saveFactorSourceResult(.success(saved)):
			state.mode.update(isProgressing: false)
			overlayWindowClient.scheduleHUD(.seedPhraseImported)
			let factorSource = saved.factorSource

			if saved.savedIntoProfile {
				return .send(.delegate(.persistedNewFactorSourceInProfile(factorSource)))
			} else {
				return .send(.delegate(.persistedMnemonicInKeychainOnly(factorSource)))
			}
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .backupConfirmation(.userHasBackedUp):
			guard let mnemonic = state.mnemonic else {
				return .none
			}
			state.destination = .verifyMnemonic(.init(mnemonic: mnemonic))
			return .none

		case .backupConfirmation(.userHasNotBackedUp):
			loggerGlobal.notice("User have not backed up")
			return .send(.delegate(.doneViewing(idOfBackedUpFactorSource: nil)))

		case .onContinueWarning(.buttonTapped):
			guard let mnemonic = state.mnemonic else {
				loggerGlobal.error("Can't read mnemonic")
				struct FailedToReadMnemonic: Error {}
				errorQueue.schedule(FailedToReadMnemonic())
				return .none
			}
			return continueWithMnemonic(mnemonic: mnemonic, in: &state)

		case .verifyMnemonic(.delegate(.mnemonicVerified)):
			guard let factorSourceID = state.mode.readonly?.factorSourceID else {
				return .none
			}
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
}

extension ImportMnemonic.Destination.State {
	fileprivate static func askUserIfSheHasBackedUpMnemonic() -> Self {
		.backupConfirmation(.init(
			title: { TextState(L10n.ImportMnemonic.BackedUpAlert.title) },
			actions: {
				ButtonState(action: .userHasBackedUp, label: { TextState(L10n.ImportMnemonic.BackedUpAlert.confirmAction) })
				ButtonState(action: .userHasNotBackedUp, label: { TextState(L10n.ImportMnemonic.BackedUpAlert.noAction) })
			},
			message: { TextState(L10n.ImportMnemonic.BackedUpAlert.message) }
		))
	}

	fileprivate static func onContinueWarning(
		_ warning: ImportMnemonic.State.OnContinueWarning
	) -> Self {
		.onContinueWarning(.init(
			title: { TextState(warning.title) },
			actions: {
				ButtonState(action: .buttonTapped, label: { TextState(warning.button) })
			},
			message: { TextState(warning.text) }
		))
	}
}
