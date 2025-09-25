import ComposableArchitecture
import Sargon

extension AddFactorSource {
	enum Context: Sendable, Hashable {
		case newFactorSource
		case recoverFactorSource(isOlympia: Bool)
	}

	@Reducer
	struct Coordinator: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			enum Mode {
				case preselectedKind(FactorSourceKind)
				case toSelectFromKinds([FactorSourceKind])
			}

			@Shared(.mnemonicBuilder) var mnemonicBuilder
			var kind: FactorSourceKind?

			var root: Root.State
			var path: StackState<Path.State>

			let context: Context
			var strategy: FactorSourceStrategy?

			init(mode: Mode, context: Context) {
				switch mode {
				case let .preselectedKind(factorSourceKind):
					self.kind = factorSourceKind
					self.root = .intro(.init(kind: factorSourceKind))
					self.strategy = .init(kind: factorSourceKind, context: context)
				case let .toSelectFromKinds(kinds):
					self.kind = nil
					self.root = .selectKind(.init(kinds: kinds))
				}
				self.context = context
				self.path = .init()
			}
		}

		@Reducer(state: .hashable, action: .equatable)
		enum Path {
			case intro(AddFactorSource.Intro)
			case deviceSeedPhrase(AddFactorSource.InputSeedPhrase)
			case arculusCreatePIN(ArculusCreatePIN)
			case confirmSeedPhrase(AddFactorSource.ConfirmSeedPhrase)
			case nameFactorSource(AddFactorSource.NameFactorSource)
		}

		@Reducer
		struct Root {
			@CasePathable
			@ObservableState
			enum State: Hashable, Sendable {
				case selectKind(AddFactorSource.SelectKind.State)
				case intro(AddFactorSource.Intro.State)
			}

			@CasePathable
			enum Action: Equatable, Sendable {
				case selectKind(AddFactorSource.SelectKind.Action)
				case intro(AddFactorSource.Intro.Action)
			}

			var body: some ReducerOf<Self> {
				Scope(state: \.selectKind, action: \.selectKind) {
					AddFactorSource.SelectKind()
				}

				Scope(state: \.intro, action: \.intro) {
					AddFactorSource.Intro()
				}
			}
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case root(Root.Action)
			case path(StackActionOf<Path>)
		}

		enum DelegateAction: Sendable, Equatable {
			case finished(FactorSource)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.root, action: \.child.root) {
				Root()
			}

			Reduce(core)
				.forEach(\.path, action: \.child.path)
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .root(.selectKind(.delegate(.completed(selectedKind)))):
				state.kind = selectedKind
				state.strategy = .init(kind: selectedKind, context: state.context)
				state.path.append(.intro(.init(kind: selectedKind)))
				return .none

			case let .path(.element(id: _, action: .nameFactorSource(.delegate(.saved(fs))))):
				// Reset
				state.$mnemonicBuilder.withLock { builder in
					builder = MnemonicBuilder()
				}
				return .send(.delegate(.finished(fs)))

			default:
				return state.strategy?.handleCompletion(childAction, &state) ?? .none
			}
		}

		func createDeviceFactorSource(state: State) -> DeviceFactorSource {
			let mwp = state.mnemonicBuilder.getMnemonicWithPassphrase()
			let factorType: DeviceFactorSourceType = switch state.context {
			case .newFactorSource:
				.babylon
			case let .recoverFactorSource(isOlympia):
				isOlympia ? .olympia : .babylon
			}
			return SargonOS.shared.createDeviceFactorSource(mnemonicWithPassphrase: mwp, factorType: factorType)
		}
	}
}

// MARK: - FactorSourceStrategy
struct FactorSourceStrategy: Sendable, Hashable {
	let kind: FactorSourceKind
	let context: AddFactorSource.Context

	let handleCompletion: @Sendable (AddFactorSource.Coordinator.ChildAction, inout AddFactorSource.Coordinator.State) -> Effect<AddFactorSource.Coordinator.Action>

	func hash(into hasher: inout Hasher) {
		hasher.combine(kind)
		hasher.combine(context)
	}

	static func == (lhs: FactorSourceStrategy, rhs: FactorSourceStrategy) -> Bool {
		lhs.kind == rhs.kind && lhs.context == rhs.context
	}
}

extension FactorSourceStrategy {
	init(kind: FactorSourceKind, context: AddFactorSource.Context) {
		switch kind {
		case .device:
			self = Self.device(context: context)
		case .ledgerHqHardwareWallet:
			self = Self.ledger(context: context)
		case .arculusCard:
			self = Self.arculus(context: context)
		default:
			fatalError("Unsupported kind \(kind)")
		}
	}
}

extension FactorSourceStrategy {
	static func device(context: AddFactorSource.Context) -> Self {
		@Sendable
		func createFactorSourceInput(state: AddFactorSource.Coordinator.State, context: AddFactorSource.Context) -> AddFactorSource.NameFactorSource.State.FactorSourceInput {
			let mwp = state.mnemonicBuilder.getMnemonicWithPassphrase()
			let factorType: DeviceFactorSourceType = switch context {
			case .newFactorSource:
				.babylon
			case let .recoverFactorSource(isOlympia):
				isOlympia ? .olympia : .babylon
			}
			return .device(
				SargonOS.shared.createDeviceFactorSource(mnemonicWithPassphrase: mwp, factorType: factorType),
				mwp
			)
		}

		return Self(
			kind: .device,
			context: context,
			handleCompletion: { action, state in
				switch action {
				case .root(.intro(.delegate(.completed))), .path(.element(id: _, action: .intro(.delegate(.completed)))):
					state.path.append(.deviceSeedPhrase(.init(context: context, factorSourceKind: .device)))
					return .none

				case .path(.element(id: _, action: .deviceSeedPhrase(.delegate(.completed(let withCustomSeedPhrase))))):
					if withCustomSeedPhrase {
						state.path.append(.nameFactorSource(.init(context: context, factorSourceInput: createFactorSourceInput(state: state, context: context))))
					} else {
						state.path.append(.confirmSeedPhrase(.init(factorSourceKind: .device)))
					}
					return .none

				case .path(.element(id: _, action: .confirmSeedPhrase(.delegate(.validated)))):
					state.path.append(.nameFactorSource(.init(context: context, factorSourceInput: createFactorSourceInput(state: state, context: context))))
					return .none

				default:
					return .none
				}
			}
		)
	}

	static func arculus(context: AddFactorSource.Context) -> Self {
		@Sendable
		func createFactorSourceInput(state: AddFactorSource.Coordinator.State, context: AddFactorSource.Context, pin: String) -> AddFactorSource.NameFactorSource.State.FactorSourceInput {
			let mwp = state.mnemonicBuilder.getMnemonicWithPassphrase()
			let fsId = newFactorSourceIdFromHashFromMnemonicWithPassphrase(factorSourceKind: .arculusCard, mnemonicWithPassphrase: mwp)
			return .arculus(
				ArculusCardFactorSource(id: fsId, common: .babylon(), hint: .init(label: "", model: .arculusColdStorageWallet)),
				mwp,
				pin
			)
		}

		return Self(
			kind: .arculusCard,
			context: context,
			handleCompletion: { action, state in
				switch action {
				case .root(.intro(.delegate(.completed))), .path(.element(id: _, action: .intro(.delegate(.completed)))):
					state.path.append(.deviceSeedPhrase(.init(context: context, factorSourceKind: .arculusCard)))
					return .none

				case .path(.element(id: _, action: .deviceSeedPhrase(.delegate(.completed(let withCustomSeedPhrase))))):
					if withCustomSeedPhrase {
						state.path.append(.arculusCreatePIN(.init()))
					} else {
						state.path.append(.confirmSeedPhrase(.init(factorSourceKind: .arculusCard)))
					}
					return .none

				case .path(.element(id: _, action: .confirmSeedPhrase(.delegate(.validated)))):
					state.path.append(.arculusCreatePIN(.init()))
					return .none

				case let .path(.element(id: _, action: .arculusCreatePIN(.delegate(.pinAdded(pin))))):
					state.path.append(.nameFactorSource(.init(context: context, factorSourceInput: createFactorSourceInput(state: state, context: context, pin: pin))))
					return .none

				default:
					return .none
				}
			}
		)
	}

	static func ledger(context: AddFactorSource.Context) -> Self {
		Self(
			kind: .ledgerHqHardwareWallet,
			context: context,
			handleCompletion: { action, state in
				switch action {
				case let .root(.intro(.delegate(.completedWithLedgerDeviceInfo(ledger)))),
				     let .path(.element(id: _, action: .intro(.delegate(.completedWithLedgerDeviceInfo(ledger))))):
					let ledgerFS = LedgerHardwareWalletFactorSource.from(device: ledger, name: "")
					state.path.append(.nameFactorSource(.init(context: context, factorSourceInput: .ledger(ledgerFS))))
					return .none

				default:
					return .none
				}
			}
		)
	}
}
