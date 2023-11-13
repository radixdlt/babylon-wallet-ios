import ComposableArchitecture
import SwiftUI

// MARK: - View

extension PersonaDetails {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<PersonaDetails>

		public init(store: StoreOf<PersonaDetails>) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		let thumbnail: URL?
		let personaName: String
		let isDappPersona: Bool
	}
}

// MARK: - Body

extension PersonaDetails.View {
	public var body: some View {
		ScrollView(showsIndicators: false) {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					PersonaThumbnail(viewStore.thumbnail, size: .veryLarge)
						.padding(.vertical, .large2)

					InfoSection(store: store)

					Button(L10n.AuthorizedDapps.PersonaDetails.editPersona) {
						viewStore.send(.editPersonaTapped)
					}
					.buttonStyle(.secondaryRectangular)
					.padding(.vertical, .large3)

					if viewStore.isDappPersona {
						IfLetStore(store.scope(state: \.accountSection, action: PersonaDetails.Action.view)) {
							AccountSection(store: $0)
								.background(.app.gray5)
						}

						Button(L10n.AuthorizedDapps.PersonaDetails.removeAuthorization) {
							viewStore.send(.deauthorizePersonaTapped)
						}
						.buttonStyle(.primaryRectangular(isDestructive: true))
						.padding([.horizontal, .top], .medium3)
						.padding(.bottom, .large2)
					} else {
						IfLetStore(store.scope(state: \.dAppsSection, action: PersonaDetails.Action.view)) {
							DappsSection(store: $0)
								.background(.app.gray5)
						}

						Button(L10n.AuthorizedDapps.PersonaDetails.hideThisPersona) {
							viewStore.send(.hidePersonaTapped)
						}
						.buttonStyle(.primaryRectangular(isDestructive: true))
						.padding([.horizontal, .top], .medium3)
						.padding(.bottom, .large2)
					}
				}
				.navigationTitle(viewStore.personaName)
				.navigationBarTitleDisplayMode(.inline)
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
		.destinations(with: store)
	}
}

private extension StoreOf<PersonaDetails> {
	var destination: PresentationStoreOf<PersonaDetails.Destination> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PersonaDetails>) -> some View {
		let destinationStore = store.destination
		return dAppDetails(with: destinationStore)
			.editPersona(with: destinationStore)
			.confirmForgetAlert(with: destinationStore)
			.confirmHideAlert(with: destinationStore)
	}

	private func dAppDetails(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /PersonaDetails.Destination.State.dAppDetails,
			action: PersonaDetails.Destination.Action.dAppDetails,
			destination: { DappDetails.View(store: $0) }
		)
	}

	private func editPersona(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /PersonaDetails.Destination.State.editPersona,
			action: PersonaDetails.Destination.Action.editPersona,
			content: { EditPersona.View(store: $0) }
		)
	}

	private func confirmForgetAlert(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /PersonaDetails.Destination.State.confirmForgetAlert,
			action: PersonaDetails.Destination.Action.confirmForgetAlert
		)
	}

	private func confirmHideAlert(with destinationStore: PresentationStoreOf<PersonaDetails.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /PersonaDetails.Destination.State.confirmHideAlert,
			action: PersonaDetails.Destination.Action.confirmHideAlert
		)
	}
}

// MARK: - Extensions

private extension PersonaDetails.State {
	var viewState: PersonaDetails.ViewState {
		.init(
			thumbnail: nil,
			personaName: personaName,
			isDappPersona: isDappPersona
		)
	}

	var personaName: String {
		switch mode {
		case let .general(persona, _):
			persona.displayName.rawValue
		case let .dApp(_, persona):
			persona.displayName.rawValue
		}
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
			.init(dAppName: dApp.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName, sharingAccounts: persona.simpleAccounts ?? [])
		}
	}

	struct AccountSection: Equatable {
		let dAppName: String
		let sharingAccounts: OrderedSet<Profile.Network.AccountForDisplay>
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
							SmallAccountCard(
								account.label.rawValue,
								identifiable: .address(.account(account.address)),
								gradient: .init(account.appearanceID)
							)
							.cornerRadius(.small1)
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
			}
		}
	}
}

// MARK: - DappsSection

extension PersonaDetails.State {
	var dAppsSection: DappsSection? {
		switch mode {
		case let .general(_, dApps):
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
				VStack(spacing: .medium1) {
					Text(L10n.AuthorizedDapps.PersonaDetails.authorizedDappsHeading)
						.textBlock
						.flushedLeft
						.padding(.horizontal, .medium1)

					ForEach(viewStore.state) { dApp in
						Card {
							viewStore.send(.dAppTapped(dApp.id))
						} contents: {
							PlainListRow(title: dApp.displayName) {
								DappThumbnail(.known(dApp.thumbnail))
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
		case let .dApp(_, persona: persona):
			.init(
				dAppInfo: dAppInfo,
				personaName: persona.displayName.rawValue,
				personaData: persona.sharedPersonaData
			)
		case let .general(persona, _):
			.init(
				dAppInfo: nil,
				personaName: persona.displayName.rawValue,
				personaData: persona.personaData
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
			let companyName: String?
			let fullName: String?
			let dateOfBirth: Date?
			let emailAddresses: [String]?
			let phoneNumbers: [String]?
			let urls: [String]?
			let postalAddresses: [PersonaData.PostalAddress]?
			let creditCards: [PersonaData.CreditCard]?

			struct DappInfo: Equatable {
				let name: String
				let isSharingNothing: Bool
			}

			init(
				dAppInfo: DappInfo?,
				personaName: String,
				personaData: PersonaData?
			) {
				self.dAppInfo = dAppInfo
				self.personaName = personaName
				self.fullName = personaData?.name?.value.formatted
				self.emailAddresses = personaData?.emailAddresses.map(\.value.email)
				self.phoneNumbers = personaData?.phoneNumbers.map(\.value.number)

				self.dateOfBirth = personaData?.dateOfBirth?.value.date
				self.companyName = personaData?.companyName?.value.name
				self.urls = personaData?.urls.map(\.value.url)
				self.postalAddresses = personaData?.postalAddresses.map(\.value)
				self.creditCards = personaData?.creditCards.map(\.value)

				// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
				// we do not forget to handle it here.
				switch PersonaData.Entry.Kind.fullName {
				case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
				}
			}
		}

		let store: StoreOf<PersonaDetails>

		var body: some View {
			WithViewStore(store, observe: \.infoSectionViewState) { viewStore in
				VStack(alignment: .leading, spacing: .medium1) {
					VPair(heading: L10n.AuthorizedDapps.PersonaDetails.personaLabelHeading, item: viewStore.personaName)

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
