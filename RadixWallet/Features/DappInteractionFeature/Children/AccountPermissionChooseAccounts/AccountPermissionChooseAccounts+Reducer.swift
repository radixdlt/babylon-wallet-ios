import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ChooseAccountsResult
typealias AccountPermissionChooseAccountsResult = WalletToDappInteractionResponse.Accounts

// MARK: - AccountPermissionChooseAccounts
struct AccountPermissionChooseAccounts: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		enum AccessKind: Sendable, Hashable {
			case ongoing
			case oneTime
		}

		/// if `proofOfOwnership`, sign this challenge
		let challenge: DappToWalletInteractionAuthChallengeNonce?

		let accessKind: AccessKind
		let dappMetadata: DappMetadata
		var chooseAccounts: ChooseAccounts.State

		init(
			challenge: DappToWalletInteractionAuthChallengeNonce?,
			accessKind: AccessKind,
			dappMetadata: DappMetadata,
			chooseAccounts: ChooseAccounts.State
		) {
			self.challenge = challenge
			self.accessKind = accessKind
			self.dappMetadata = dappMetadata
			self.chooseAccounts = chooseAccounts
		}

		init(
			challenge: DappToWalletInteractionAuthChallengeNonce?,
			accessKind: AccessKind,
			dappMetadata: DappMetadata,
			numberOfAccounts: DappInteractionNumberOfAccounts
		) {
			self.init(
				challenge: challenge,
				accessKind: accessKind,
				dappMetadata: dappMetadata,
				chooseAccounts: .init(context: .permission(.init(numberOfAccounts)))
			)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped([ChooseAccountsRow.State])
	}

	enum InternalAction: Sendable, Equatable {
		case handleSignedAuthIntent(SignedAuthIntent, selectedAccounts: [Account])
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case chooseAccounts(ChooseAccounts.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case `continue`(
			accessKind: AccountPermissionChooseAccounts.State.AccessKind,
			chosenAccounts: AccountPermissionChooseAccountsResult
		)
		case failedToProveOwnership(of: [Account])
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	var body: some ReducerOf<Self> {
		Scope(state: \.chooseAccounts, action: \.child.chooseAccounts) {
			ChooseAccounts()
		}

		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .continueButtonTapped(selectedAccounts):
			let selectedAccounts = selectedAccounts.map(\.account)

			guard let challenge = state.challenge else {
				return .send(.delegate(.continue(
					accessKind: state.accessKind,
					chosenAccounts: .withoutProofOfOwnership(selectedAccounts.asIdentified())
				)))
			}

			guard let metadata = state.dappMetadata.requestMetadata else {
				assertionFailure("Unable to sign Account Permission without the request metadata")
				return .none
			}

			return .run { send in
				let signedAuthIntent = try await SargonOS.shared.signAuthAccounts(accountAddresses: selectedAccounts.map(\.address), challengeNonce: challenge, metadata: metadata)
				await send(.internal(.handleSignedAuthIntent(signedAuthIntent, selectedAccounts: selectedAccounts)))
			} catch: { _, send in
				loggerGlobal.error("Failed to sign proof of ownership")
				await send(.delegate(.failedToProveOwnership(of: selectedAccounts)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .handleSignedAuthIntent(signedAuthIntent, selectedAccounts):
			var accountsLeftToVerifyDidSign: Set<Account.ID> = Set(selectedAccounts.map(\.id))

			let accountProofs: [WalletToDappInteractionResponse.Accounts.WithProof] = signedAuthIntent.intentSignaturesPerOwner.compactMap { item -> WalletToDappInteractionResponse.Accounts.WithProof? in
				guard
					let accountAddress = item.owner.accountAddress,
					let account = selectedAccounts.first(where: { $0.address == accountAddress })
				else {
					return nil
				}
				accountsLeftToVerifyDidSign.remove(account.id)

				let proof = WalletToDappInteractionAuthProof(intentSignatureOfOwner: item)
				return .init(account: .init(account: account), proof: proof)
			}

			// Verify there is a signature for each address
			guard accountsLeftToVerifyDidSign.isEmpty else {
				loggerGlobal.error("Failed to sign with all accounts..")
				return .send(.delegate(.failedToProveOwnership(of: selectedAccounts)))
			}

			let chosenAccounts: AccountPermissionChooseAccountsResult = .withProofOfOwnership(
				challenge: signedAuthIntent.intent.challengeNonce,
				accountProofs.asIdentified()
			)
			return .send(.delegate(.continue(accessKind: state.accessKind, chosenAccounts: chosenAccounts)))
		}
	}
}
