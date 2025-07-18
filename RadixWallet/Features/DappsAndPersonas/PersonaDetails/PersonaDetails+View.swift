import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - View

extension PersonaDetails {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PersonaDetails>

		init(store: StoreOf<PersonaDetails>) {
			self.store = store
		}
	}

	struct ViewState: Equatable {
		let thumbnail: URL?
		let personaName: String
		let isDappPersona: Bool
		let factorSourceRow: FactorSourcesList.Row?
	}
}

// MARK: - Body

extension PersonaDetails.View {
	var body: some View {
		ScrollView(showsIndicators: false) {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					Thumbnail(.persona, url: viewStore.thumbnail, size: .veryLarge)
						.padding(.vertical, .large2)

					InfoSection(store: store)

					Button(L10n.AuthorizedDapps.PersonaDetails.editPersona) {
						viewStore.send(.editPersonaTapped)
					}
					.buttonStyle(.secondaryRectangular)
					.padding(.vertical, .large3)

					if viewStore.isDappPersona {
						IfLetStore(store.scope(state: \.accountSection, action: \.view)) {
							AccountSection(store: $0)
								.background(.secondaryBackground)
						}

						Button(L10n.AuthorizedDapps.PersonaDetails.removeAuthorization) {
							viewStore.send(.deauthorizePersonaTapped)
						}
						.buttonStyle(.primaryRectangular(isDestructive: true))
						.padding([.horizontal, .top], .medium3)
						.padding(.bottom, .large2)
					} else {
						IfLetStore(store.scope(state: \.dAppsSection, action: \.view)) {
							DappsSection(store: $0)
								.background(.tertiaryBackground)
						}

						Button(L10n.AuthorizedDapps.PersonaDetails.hideThisPersona) {
							viewStore.send(.hidePersonaTapped)
						}
						.buttonStyle(.primaryRectangular(isDestructive: true))
						.padding([.horizontal, .top], .medium3)
						.padding(.bottom, .large2)
					}
				}
				.radixToolbar(title: viewStore.personaName)
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
		.background(.secondaryBackground)
		.destinations(with: store)
	}
}

private extension StoreOf<PersonaDetails> {
	var destination: PresentationStoreOf<PersonaDetails.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PersonaDetails>) -> some View {
		let destinationStore = store.destination
		return dAppDetails(with: destinationStore)
			.editPersona(with: destinationStore)
			.factorSourceDetails(with: destinationStore)
			.displayMnemonic(with: destinationStore)
			.enterMnemonic(with: destinationStore)
			.confirmForgetAlert(with: destinationStore)
			.confirmHideAlert(with: destinationStore)
	}

	private func dAppDetails(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.dAppDetails, action: \.dAppDetails))
			{ DappDetails.View(store: $0) }
	}

	private func editPersona(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		sheet(
			store: destinationStore.scope(state: \.editPersona, action: \.editPersona)
		)
			{ EditPersona.View(store: $0) }
	}

	private func confirmForgetAlert(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		alert(
			store: destinationStore.scope(state: \.confirmForgetAlert, action: \.confirmForgetAlert)
		)
	}

	private func confirmHideAlert(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		alert(
			store: destinationStore.scope(state: \.confirmHideAlert, action: \.confirmHideAlert)
		)
	}

	private func factorSourceDetails(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.factorSourceDetail, action: \.factorSourceDetail)) {
			FactorSourceDetail.View(store: $0)
		}
	}

	private func displayMnemonic(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.displayMnemonic, action: \.displayMnemonic)) {
			DisplayMnemonic.View(store: $0)
		}
	}

	private func enterMnemonic(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.enterMnemonic, action: \.enterMnemonic)) { store in
			NavigationStack {
				ImportMnemonicForFactorSource.View(store: store)
			}
		}
	}
}

// MARK: - Extensions

private extension PersonaDetails.State {
	var viewState: PersonaDetails.ViewState {
		.init(
			thumbnail: nil,
			personaName: personaName,
			isDappPersona: isDappPersona,
			factorSourceRow: factorSourceRow
		)
	}

	var personaName: String {
		persona.displayName.rawValue
	}

	var isDappPersona: Bool {
		switch mode {
		case .general:
			false
		case .dApp:
			true
		}
	}
}

// MARK: - AccountSection

extension PersonaDetails.State {
	var accountSection: AccountSection? {
		switch mode {
		case .general:
			nil
		case let .dApp(dApp, persona):
			AccountSection(
				dAppName: dApp.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName,
				sharingAccounts: persona.simpleAccounts?.asIdentified() ?? []
			)
		}
	}

	struct AccountSection: Equatable {
		let dAppName: String
		let sharingAccounts: AccountsForDisplay
	}
}

// MARK: - PersonaDetails.View.AccountSection
extension PersonaDetails.View {
	@MainActor
	struct AccountSection: View {
		let store: Store<PersonaDetails.State.AccountSection, PersonaDetails.ViewAction>

		var body: some View {
			WithViewStore(store, observe: identity) { viewStore in
				VStack(spacing: 0) {
					Text(L10n.AuthorizedDapps.PersonaDetails.accountSharingDescription(viewStore.dAppName))
						.textBlock
						.flushedLeft
						.padding(.vertical, .medium2)
						.padding(.horizontal, .medium1)

					VStack(spacing: .medium3) {
						ForEach(viewStore.sharingAccounts) { account in
							AccountCard(account: account)
						}
					}
					.padding(.horizontal, .medium3)

					//	FIXME: Uncomment and enable the functionality
					//	Button(L10n.AuthorizedDapps.PersonaDetails.editAccountSharing) {
					//		viewStore.send(.editAccountSharingTapped)
					//	}
					//	.buttonStyle(.secondaryRectangular)
					//	.padding(.vertical, .large3)
				}
				.padding(.vertical, .medium2)
			}
		}
	}
}

// MARK: - DappsSection

extension PersonaDetails.State {
	var dAppsSection: DappsSection? {
		switch mode {
		case let .general(dApps):
			dApps.isEmpty ? nil : dApps
		case .dApp:
			nil
		}
	}

	typealias DappsSection = IdentifiedArrayOf<PersonaDetails.State.DappInfo>
}

// MARK: - PersonaDetails.View.DappsSection
extension PersonaDetails.View {
	@MainActor
	struct DappsSection: View {
		let store: Store<PersonaDetails.State.DappsSection, PersonaDetails.ViewAction>

		var body: some View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: .medium3) {
					Text(L10n.AuthorizedDapps.PersonaDetails.authorizedDappsHeading)
						.textBlock
						.flushedLeft
						.padding(.horizontal, .medium1)

					ForEach(viewStore.state) { dApp in
						Card {
							viewStore.send(.dAppTapped(dApp.id))
						} contents: {
							PlainListRow(context: .dappAndPersona, title: dApp.displayName) {
								Thumbnail(.dapp, url: dApp.thumbnail)
							}
						}
						.padding(.horizontal, .medium3)
					}
				}
			}
			.padding(.vertical, .medium2)
		}
	}
}

// MARK: - InfoSection

private extension PersonaDetails.State {
	var infoSectionViewState: PersonaDetails.View.InfoSection.ViewState {
		switch mode {
		case let .dApp(_, authorizedPersonaData):
			.init(
				dAppInfo: dAppInfo,
				personaName: persona.displayName.rawValue,
				personaData: authorizedPersonaData.sharedPersonaData,
				factorSourceRow: factorSourceRow
			)
		case .general:
			.init(
				dAppInfo: nil,
				personaName: persona.displayName.rawValue,
				personaData: persona.personaData,
				factorSourceRow: factorSourceRow
			)
		}
	}

	var dAppInfo: PersonaDetails.View.InfoSection.ViewState.DappInfo? {
		guard case let .dApp(dApp, persona) = mode else { return nil }
		return .init(
			name: dApp.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName,
			isSharingNothing: persona.sharedPersonaData.entries.isEmpty
		)
	}
}

// MARK: - PersonaDetails.View.InfoSection
extension PersonaDetails.View {
	@MainActor
	struct InfoSection: View {
		struct ViewState: Equatable {
			let dAppInfo: DappInfo?
			let personaName: String
			let fullName: String?
			let emailAddresses: [String]?
			let phoneNumbers: [String]?
			let factorSourceRow: FactorSourcesList.Row?

			struct DappInfo: Equatable {
				let name: String
				let isSharingNothing: Bool
			}

			init(
				dAppInfo: DappInfo?,
				personaName: String,
				personaData: PersonaData?,
				factorSourceRow: FactorSourcesList.Row?
			) {
				self.dAppInfo = dAppInfo
				self.personaName = personaName
				self.fullName = personaData?.name?.value.formatted
				self.emailAddresses = personaData?.emailAddresses.collection.map(\.value.email)
				self.phoneNumbers = personaData?.phoneNumbers.collection.map(\.value.number)
				self.factorSourceRow = factorSourceRow
			}
		}

		let store: StoreOf<PersonaDetails>

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					VPair(heading: L10n.AuthorizedDapps.PersonaDetails.personaLabelHeading, item: viewStore.personaName)

					Separator()

					if let factorSourceRow = viewStore.factorSourceRow {
						Text("Secured with")
							.textStyle(.body1HighImportance)
							.foregroundColor(.secondaryText)

						FactorSourceCard(
							kind: .instance(
								factorSource: factorSourceRow.integrity.factorSource,
								kind: .extended
							),
							mode: .display,
							messages: factorSourceRow.messages,
							onAction: { action in
								switch action {
								case .messageTapped:
									viewStore.send(.view(.factorSourceMessageTapped(factorSourceRow)))
								case .removeTapped:
									break
								}
							}
						)
						.onTapGesture {
							viewStore.send(.view(.factorSourceCardTapped))
						}
					}

					Separator()

					if let dAppInfo = viewStore.dAppInfo {
						if dAppInfo.isSharingNothing {
							Text(L10n.AuthorizedDapps.PersonaDetails.notSharingAnything(dAppInfo.name))
								.textBlock
						} else {
							Text(L10n.AuthorizedDapps.PersonaDetails.personalDataSharingDescription(dAppInfo.name))
								.textBlock
						}
					}

					if let fullName = viewStore.fullName {
						VPair(
							heading: L10n.AuthorizedDapps.PersonaDetails.fullName,
							item: fullName
						)
						Separator()
					}

					if let phoneNumber = viewStore.phoneNumbers?.first {
						VPair(
							heading: L10n.AuthorizedDapps.PersonaDetails.phoneNumber,
							item: phoneNumber
						)
						Separator()
					}

					if let emailAddress = viewStore.emailAddresses?.first {
						VPair(
							heading: L10n.AuthorizedDapps.PersonaDetails.emailAddress,
							item: emailAddress
						)
						Separator()
					}
				}
				.padding(.horizontal, .medium1)
			}
		}
	}
}
