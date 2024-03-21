import EngineToolkit
@testable import Radix_Wallet_Dev
import XCTest

@MainActor
final class AssetTransferDepositRuleTests: TestCase {
	static let recipientAccount = Profile.Network.Account.testValueIdx0
	static let resourceAddress = try! ResourceAddress(validatingAddress: "resource_rdx1tkk83magp3gjyxrpskfsqwkg4g949rmcjee4tu2xmw93ltw2cz94sq")

	static let onLedgerAccountWithResource = OnLedgerEntity.Account(
		address: recipientAccount.address,
		atLedgerState: .init(version: 0, epoch: 0),
		metadata: .init(nil),
		fungibleResources: .init(
			xrdResource: .init(
				resourceAddress: resourceAddress,
				atLedgerState: .init(version: 0, epoch: 0),
				amount: .init(nominalAmount: .one()),
				metadata: .init(nil)
			)
		),
		nonFungibleResources: [],
		poolUnitResources: .init(radixNetworkStakes: [], poolUnits: [])
	)

	// MARK: - AcceptAll deposit rule
	func test__GIVEN__depositRuleIsAcceptAll__WHEN__resourceHasNoException__THEN__noSignatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptAll
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.removeAllAssetsExceptions()

		// THEN
		try await assertNoSignatureIsRequired(for: account)
	}

	func test__GIVEN__depositRuleIsAcceptAll__WHEN__resourceIsInAllowList__THEN__noSignatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptAll
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.setAssetsExceptionList([.init(address: Self.resourceAddress, exceptionRule: .allow)])

		// THEN
		try await assertNoSignatureIsRequired(for: account)
	}

	func test__GIVEN__depositRuleIsAcceptAll__WHEN__resourceIsInDenyList__THEN__signatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptAll
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.setAssetsExceptionList([.init(address: Self.resourceAddress, exceptionRule: .deny)])
		// THEN
		try await assertSignatureIsRequired(for: account)
	}

	// MARK: - DenyAll deposit rule

	func test__GIVEN__depositRuleIsDenyAll__WHEN__resourceHasNoException__THEN__signatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .denyAll
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.removeAllAssetsExceptions()

		// THEN
		try await assertSignatureIsRequired(for: account)
	}

	func test__GIVEN__depositRuleIsDenyAll__WHEN__resourceIsInAllowList__THEN__noSignatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .denyAll
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.setAssetsExceptionList([.init(address: Self.resourceAddress, exceptionRule: .allow)])

		// THEN
		try await assertNoSignatureIsRequired(for: account)
	}

	func test__GIVEN__depositRuleIsDenyAll__WHEN__resourceIsInDenyList__THEN__signatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .denyAll
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.setAssetsExceptionList([.init(address: Self.resourceAddress, exceptionRule: .deny)])

		// THEN
		try await assertSignatureIsRequired(for: account)
	}

	// MARK: - AcceptKnown deposit rule

	func test__GIVEN__depositRuleIsAcceptKnown__WHEN__accountDoesNotContainResource_resourceHasNoException__THEN__signatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.removeAllAssetsExceptions()

		// THEN
		try await assertSignatureIsRequired(for: account)
	}

	func test__GIVEN__depositRuleIsAcceptKnown__WHEN__accountDoesNotContainResource_resourceIsInAllowList__THEN__noSignatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.setAssetsExceptionList([.init(address: Self.resourceAddress, exceptionRule: .allow)])

		// THEN
		try await assertNoSignatureIsRequired(for: account)
	}

	func test__GIVEN__depositRuleIsAcceptKnown__WHEN__accountDoesNotContainResource_resourceIsInDenyList__THEN__signatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.setAssetsExceptionList([.init(address: Self.resourceAddress, exceptionRule: .deny)])

		// THEN
		try await assertSignatureIsRequired(for: account)
	}

	func test__GIVEN__depositRuleIsAcceptKnown__WHEN__accountContainResource_resourceHasNoException__THEN__noSignatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.removeAllAssetsExceptions()

		// THEN
		try await assertNoSignatureIsRequired(for: account, onLedgerAccounts: [Self.onLedgerAccountWithResource])
	}

	func test__GIVEN__depositRuleIsAcceptKnown__WHEN__accountContainResource_resourceIsInAllowList__THEN__noSignatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.setAssetsExceptionList([.init(address: Self.resourceAddress, exceptionRule: .allow)])

		// THEN
		try await assertNoSignatureIsRequired(for: account, onLedgerAccounts: [Self.onLedgerAccountWithResource])
	}

	func test__GIVEN__depositRuleIsAcceptKnown__WHEN__accountContainResource_resourceIsInDenyList__THEN__signatureIsRequired() async throws {
		var account = Self.recipientAccount
		// GIVEN
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown
		// WHEN
		account.onLedgerSettings.thirdPartyDeposits.setAssetsExceptionList([.init(address: Self.resourceAddress, exceptionRule: .deny)])

		// THEN
		try await assertSignatureIsRequired(for: account, onLedgerAccounts: [Self.onLedgerAccountWithResource])
	}

	// MARK: - Private

	private func assertSignatureIsRequired(
		for account: Profile.Network.Account,
		onLedgerAccounts: [OnLedgerEntity.Account] = []
	) async throws {
		try await assertSignatureIsRequired(for: account, isRequired: true, onLedgerAccounts: onLedgerAccounts)
	}

	private func assertNoSignatureIsRequired(
		for account: Profile.Network.Account,
		onLedgerAccounts: [OnLedgerEntity.Account] = []
	) async throws {
		try await assertSignatureIsRequired(for: account, isRequired: false, onLedgerAccounts: onLedgerAccounts)
	}

	private func assertSignatureIsRequired(for account: Profile.Network.Account, isRequired: Bool, onLedgerAccounts: [OnLedgerEntity.Account]) async throws {
		try await withTimeLimit(.fast) {
			await withDependencies { d in
				d.onLedgerEntitiesClient.getEntities = { _, _, _, _ in
					onLedgerAccounts.map { .account($0) }
				}
			} operation: {
				let result = await needsSignatureForDepositting(into: account, resource: Self.resourceAddress)
				XCTAssertEqual(isRequired, result)
			}
		}
	}
}
