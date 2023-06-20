import Cryptography
import DerivePublicKeysFeature
import FeaturePrelude
import PersonasClient

public struct CreationOfPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let name: NonEmptyString
		public let personaData: PersonaData
		public var derivePublicKeys: DerivePublicKeys.State

		public init(
			name: NonEmptyString,
			personaData: PersonaData? = nil
		) {
			self.name = name
			#if DEBUG
			// FIXME: REMOVE THIS TEMPORARY SETTING OF PERSONA DATA!
			self.personaData = try! .init(
				name: .init(value: .init(
					given: "Satoshi",
					middle: "Creator of Bitcoin",
					family: "Nakamoto", variant: .eastern
				)),
				dateOfBirth: .init(value: .init(year: 2009, month: 1, day: 3)),
				companyName: .init(value: .init(name: "Bitcoin")),
				emailAddresses: .init(collection: [
					.init(value: .init(validating: "satoshi@nakamoto.bitcoin")),
					.init(value: .init(validating: "be.your@own.bank")),
				]),
				postalAddresses: .init(collection: [
					.init(value: .init(validating: [
						.postalCodeNumber(21_000_000),
						.prefecture("SHA256"), .county("Hashtown"),
						.furtherDivisionsLine0("Sound money street"),
						.furtherDivisionsLine1(""),
						.country(.japan),
					])),
					.init(value: .init(validating: [
						.streetLine0("Copthall House"),
						.streetLine1("King street"),
						.city("Newcastle-under-Lyme"),
						.county("Newcastle"),
						.postcodeString("ST5 1UE"),
						.country(.unitedKingdom),
					])),
				]),
				phoneNumbers: .init(collection: [
					.init(value: .init(number: "21000000")),
					.init(value: .init(number: "123456789")),
				]),
				creditCards: .init(collection: [
					.init(value: .init(
						expiry: .init(year: 2142, month: 12),
						holder: "Satoshi Nakamoto",
						number: "0000 0000 2100 0000",
						cvc: 512
					)
					),
				])
			)
			#else
			self.personaData = .init()
			#endif
			self.derivePublicKeys = .init(
				derivationPathOption: .nextBasedOnFactorSource(
					networkOption: .useCurrent,
					entityKind: .identity,
					curve: .curve25519
				),
				factorSourceOption: .device,
				purpose: .createEntity
			)
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case createPersonaResult(TaskResult<Profile.Network.Persona>)
	}

	public enum ChildAction: Sendable, Equatable {
		case derivePublicKeys(DerivePublicKeys.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createdPersona(Profile.Network.Persona)
		case createPersonaFailed
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(
			state: \.derivePublicKeys,
			action: /Action.child .. ChildAction.derivePublicKeys
		) {
			DerivePublicKeys()
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .createPersonaResult(.failure(error)):
			errorQueue.schedule(error)
			return .send(.delegate(.createPersonaFailed))

		case let .createPersonaResult(.success(persona)):
			return .send(.delegate(.createdPersona(persona)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .derivePublicKeys(.delegate(.derivedPublicKeys(
			hdKeys,
			factorSourceID,
			networkID
		))):
			guard let hdKey = hdKeys.first else {
				loggerGlobal.error("Failed to create persona expected one single key, got: \(hdKeys.count)")
				return .send(.delegate(.createPersonaFailed))
			}
			return .run { [name = state.name, personaData = state.personaData] send in

				let persona = try Profile.Network.Persona(
					networkID: networkID,
					factorInstance: .init(
						factorSourceID: factorSourceID,
						publicKey: hdKey.publicKey,
						derivationPath: hdKey.derivationPath
					),
					displayName: name,
					extraProperties: .init(personaData: personaData)
				)

				await send(.internal(.createPersonaResult(
					TaskResult {
						try await personasClient.saveVirtualPersona(persona)
						return persona
					}
				)))
			} catch: { error, send in
				loggerGlobal.error("Failed to create persona, error: \(error)")
				await send(.delegate(.createPersonaFailed))
			}
		case .derivePublicKeys(.delegate(.failedToDerivePublicKey)):
			return .send(.delegate(.createPersonaFailed))

		default: return .none
		}
	}
}
