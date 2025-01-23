import Foundation
import OrderedCollections
import Sargon

extension WalletToDappInteractionPersonaDataRequestResponseItem {
	init(
		personaDataRequested requested: DappToWalletInteractionPersonaDataRequestItem,
		personaData: PersonaData
	) throws {
		try self.init(
			name: { () -> PersonaDataEntryName? in
				// Check if incoming Dapp requested this persona data entry kind
				guard requested[keyPath: \.isRequestingName] == true else { return nil }
				guard let personaDataEntry = personaData[keyPath: \.name] else { return nil }
				return personaDataEntry.value
			}(),
			emailAddresses: { () -> [PersonaDataEntryEmailAddress]? in
				// Check if incoming Dapp requests the persona data entry kind
				guard
					let numberOfRequestedElements = requested[keyPath: \.numberOfRequestedEmailAddresses],
					numberOfRequestedElements.quantity > 0
				else {
					// Incoming Dapp request did not ask for access to this kind
					return nil
				}
				let personaDataEntries = personaData[keyPath: \.emailAddresses]
				let personaDataEntriesOrderedSet = try OrderedSet<PersonaDataEntryEmailAddress>(validating: personaDataEntries.collection.map(\.value))

				guard personaDataEntriesOrderedSet.satisfies(numberOfRequestedElements) else {
					return nil
				}
				return personaDataEntriesOrderedSet.elements
			}(),
			// OH NOOOOOES! TERRIBLE COPY PASTE, alas, we are gonna migrate this into Sargon very soon.
			// so please do forgive me.
			phoneNumbers: { () -> [PersonaDataEntryPhoneNumber]? in
				// Check if incoming Dapp requests the persona data entry kind
				guard
					let numberOfRequestedElements = requested[keyPath: \.numberOfRequestedPhoneNumbers],
					numberOfRequestedElements.quantity > 0
				else {
					// Incoming Dapp request did not ask for access to this kind
					return nil
				}
				let personaDataEntries = personaData[keyPath: \.phoneNumbers]
				let personaDataEntriesOrderedSet = try OrderedSet<PersonaDataEntryPhoneNumber>(validating: personaDataEntries.collection.map(\.value))

				guard personaDataEntriesOrderedSet.satisfies(numberOfRequestedElements) else {
					return nil
				}
				return personaDataEntriesOrderedSet.elements
			}()
		)
	}
}

extension WalletInteractionWalletAccount {
	init(account: Account) {
		self.init(
			address: account.address,
			label: account.displayName,
			appearanceId: account.appearanceID
		)
	}
}

extension WalletToDappInteractionAuthProof {
	init(intentSignatureOfOwner: IntentSignatureOfOwner) {
		switch intentSignatureOfOwner.intentSignature.signatureWithPublicKey {
		case let .secp256k1(publicKey, signature):
			self.init(
				publicKey: .secp256k1(publicKey),
				curve: .secp256k1,
				signature: .secp256k1(value: signature)
			)
		case let .ed25519(publicKey, signature):
			self.init(
				publicKey: .ed25519(publicKey),
				curve: .curve25519,
				signature: .ed25519(value: signature)
			)
		}
	}
}

extension DappWalletInteractionPersona {
	init(persona: Persona) {
		self.init(identityAddress: persona.address, label: persona.displayName.rawValue)
	}
}

extension DappToWalletInteraction {
	enum MissingEntry: Sendable, Hashable {
		case missingEntry
		case missing(Int)
	}

	enum KindRequest: Sendable, Hashable {
		case entry
		case number(RequestedQuantity)
	}
}

extension DappToWalletInteractionPersonaDataRequestItem {
	var kindRequests: [PersonaData.Entry.Kind: DappToWalletInteraction.KindRequest] {
		var result: [PersonaData.Entry.Kind: DappToWalletInteraction.KindRequest] = [:]
		if isRequestingName == true {
			result[.fullName] = .entry
		}
		if let numberOfRequestedPhoneNumbers, numberOfRequestedPhoneNumbers.isValid {
			result[.phoneNumber] = .number(numberOfRequestedPhoneNumbers)
		}
		if let numberOfRequestedEmailAddresses, numberOfRequestedEmailAddresses.isValid {
			result[.emailAddress] = .number(numberOfRequestedEmailAddresses)
		}
		return result
	}
}

// MARK: - WalletToDappInteractionResponse
extension WalletToDappInteractionResponse {
	var interactionId: WalletInteractionId {
		switch self {
		case let .success(response):
			response.interactionId
		case let .failure(response):
			response.interactionId
		}
	}

	enum Accounts: Sendable, Hashable {
		case withoutProofOfOwnership(IdentifiedArrayOf<Account>)
		case withProofOfOwnership(challenge: DappToWalletInteractionAuthChallengeNonce, IdentifiedArrayOf<WithProof>)

		struct WithProof: Sendable, Hashable, Identifiable {
			typealias ID = WalletInteractionWalletAccount
			var id: ID { account }
			let account: WalletInteractionWalletAccount

			let proof: WalletToDappInteractionAuthProof

			init(
				account: WalletInteractionWalletAccount,
				proof: WalletToDappInteractionAuthProof
			) {
				self.account = account
				self.proof = proof
			}
		}
	}
}

// MARK: - WalletToDappInteractionAccountsRequestResponseItem
extension WalletToDappInteractionAccountsRequestResponseItem {
	init(
		accounts: WalletToDappInteractionResponse.Accounts
	) {
		switch accounts {
		case let .withProofOfOwnership(challenge, accountsWithProof):
			self.init(
				accounts: accountsWithProof.map(\.account),
				challenge: challenge,
				proofs: accountsWithProof.map { .init(accountAddress: $0.account.address, proof: $0.proof) }
			)
		case let .withoutProofOfOwnership(account):
			self.init(
				accounts: account.map(WalletInteractionWalletAccount.init(account:)),
				challenge: nil,
				proofs: nil
			)
		}
	}
}
