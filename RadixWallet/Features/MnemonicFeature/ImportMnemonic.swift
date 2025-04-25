import ComposableArchitecture
import Sargon
import SwiftUI

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

		var isProgressing: Bool
		let persistStrategy: PersistStrategy?
		let showCloseButton: Bool

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

			self.isProgressing = false
			self.persistStrategy = persistStrategy
			self.showCloseButton = showCloseButton
			self.grid = .init(count: wordCount, language: language, isWordCountFixed: isWordCountFixed)
			self.isWordCountFixed = isWordCountFixed
			self.bip39Passphrase = bip39Passphrase

			self.header = header
			self.warning = warning
			self.warningOnContinue = warningOnContinue
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
		case closeButtonTapped
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
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case onContinueWarning(AlertState<Action.OnContinueWarning>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case onContinueWarning(OnContinueWarning)

			enum OnContinueWarning: Sendable, Hashable {
				case buttonTapped
			}
		}

		var body: some Reducer<State, Action> {
			EmptyReducer()
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

		case .closeButtonTapped:
			if state.showCloseButton == true {
				return .run { _ in await dismiss() }
			} else {
				assertionFailure("Invalid mode: No close button should be visible")
				return .none
			}
		}
	}

	private func continueWithMnemonic(mnemonic: Mnemonic, in state: inout State) -> Effect<Action> {
		state.isProgressing = true
		let mnemonicWithPassphrase = MnemonicWithPassphrase(
			mnemonic: mnemonic,
			passphrase: state.bip39Passphrase
		)
		guard let persistStrategy = state.persistStrategy else {
			state.isProgressing = false
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .saveFactorSourceResult(.failure(error)):
			state.isProgressing = false
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to save mnemonic in profile, error: \(error)")
			return .none

		case let .saveFactorSourceResult(.success(saved)):
			state.isProgressing = false
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
		case .onContinueWarning(.buttonTapped):
			guard let mnemonic = state.mnemonic else {
				loggerGlobal.error("Can't read mnemonic")
				struct FailedToReadMnemonic: Error {}
				errorQueue.schedule(FailedToReadMnemonic())
				return .none
			}
			return continueWithMnemonic(mnemonic: mnemonic, in: &state)
		}
	}
}

extension ImportMnemonic.Destination.State {
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
