import EngineKit
import FeaturePrelude
import ScanQRFeature

extension ManageTrustedContactFactorSource.State {
	var viewState: ManageTrustedContactFactorSource.ViewState {
		.init(canEditRadixAddress: canEditRadixAddress, isCreatingNewFromScratch: mode == .new, radixAddress: radixAddress, emailAddress: emailAddress, name: name)
	}
}

// MARK: - ManageTrustedContactFactorSource.View
extension ManageTrustedContactFactorSource {
	public struct ViewState: Equatable {
		let canEditRadixAddress: Bool
		let isCreatingNewFromScratch: Bool
		let radixAddress: String
		let emailAddress: String
		let name: String
		var info: (
			accountAddress: AccountAddress,
			email: EmailAddress,
			name: NonEmptyString
		)? {
			guard
				let address,
				let email,
				let nameNonEmpty = NonEmptyString(rawValue: name)
			else {
				return nil
			}
			return (accountAddress: address, email: email, name: nameNonEmpty)
		}

		var address: AccountAddress? {
			try? AccountAddress(validatingAddress: radixAddress)
		}

		var addressHint: Hint? {
			if canEditRadixAddress {
				guard
					!radixAddress.isEmpty,
					address == nil
				else { return nil }
				// FIXME: Strings
				return .error("Invalid address")
			} else {
				// FIXME: Strings
				return .info("Cannot edit. Add new contact instead.")
			}
		}

		var email: EmailAddress? {
			guard
				let nonEmptyEmail = NonEmptyString(rawValue: self.emailAddress),
				let emailAddress = try? EmailAddress(validating: nonEmptyEmail)
			else {
				return nil
			}
			return emailAddress
		}

		var emailHint: Hint? {
			guard
				!emailAddress.isEmpty,
				email == nil
			else { return nil }
			// FIXME: Strings
			return .error("Invalid email")
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageTrustedContactFactorSource>

		public init(store: StoreOf<ManageTrustedContactFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .large3) {
					// FIXME: Strings
					Text("Your phone is your only access to your wallet. If you lose it, you’ll need someone you trust to lock your old phone and process a new one.")

					addressField(with: viewStore)
						.disabled(!viewStore.canEditRadixAddress) // do not allow edit of address

					emailField(with: viewStore)
					nameField(with: viewStore)
				}
				.padding()
				.footer {
					continueButton(viewStore)
				}
				// FIXME: Strings
				.navigationTitle(viewStore.isCreatingNewFromScratch ? "Add Trusted Contact" : "Edit Trusted Contact")
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ManageTrustedContactFactorSource.Destinations.State.scanAccountAddress,
					action: ManageTrustedContactFactorSource.Destinations.Action.scanAccountAddress,
					content: {
						ScanQRCoordinator.View(store: $0)
							// FIXME: Strings
							.navigationTitle("Scan address")
					}
				)
			}
		}

		private func addressField(
			with viewStore: ViewStoreOf<ManageTrustedContactFactorSource>
		) -> some SwiftUI.View {
			// FIXME: Strings
			AppTextField(
				primaryHeading: "Contact's Radix account address",
				placeholder: "account_tdx_c_1pyezed90u5qtagu2247rqw7f04vc7wnhsfjz4nf6vuvqtj9kcq",
				text: viewStore.binding(
					get: \.radixAddress,
					send: { .radixAddressChanged($0) }
				),
				hint: viewStore.addressHint,
				showClearButton: viewStore.canEditRadixAddress,
				innerAccessory: {
					if viewStore.canEditRadixAddress {
						Button {
							viewStore.send(.scanQRCode)
						} label: {
							Image(asset: AssetResource.qrCodeScanner)
						}
					}
				}
			)
			.autocorrectionDisabled()
			.keyboardType(.alphabet)
		}

		private func emailField(
			with viewStore: ViewStoreOf<ManageTrustedContactFactorSource>
		) -> some SwiftUI.View {
			// FIXME: Strings
			AppTextField(
				primaryHeading: "Contact's email address",
				placeholder: "my.friend@best.ever",
				text: viewStore.binding(
					get: \.emailAddress,
					send: { .emailAddressChanged($0) }
				),
				hint: viewStore.emailHint,
				showClearButton: true
			)
			.autocorrectionDisabled()
			.keyboardType(.emailAddress)
		}

		private func nameField(
			with viewStore: ViewStoreOf<ManageTrustedContactFactorSource>
		) -> some SwiftUI.View {
			// FIXME: Strings
			AppTextField(
				primaryHeading: "Contact's name",
				placeholder: "Jane Doe",
				text: viewStore.binding(
					get: \.name,
					send: { .nameChanged($0) }
				),
				hint: nil
			)
			.autocorrectionDisabled()
			.keyboardType(.alphabet)
		}

		private func continueButton(_ viewStore: ViewStoreOf<ManageTrustedContactFactorSource>) -> some SwiftUI.View {
			WithControlRequirements(
				viewStore.info,
				forAction: { result in
					viewStore.send(.continueButtonTapped(
						result.accountAddress,
						email: result.email,
						name: result.name
					))
				},
				control: { action in
					// FIXME: String
					Button("Continue", action: action)
						.buttonStyle(.primaryRectangular)
				}
			)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ManageTrustedContactFactorSource_Preview
struct ManageTrustedContactFactorSource_Preview: PreviewProvider {
	static var previews: some View {
		ManageTrustedContactFactorSource.View(
			store: .init(
				initialState: .previewValue,
				reducer: ManageTrustedContactFactorSource()
			)
		)
	}
}

extension ManageTrustedContactFactorSource.State {
	public static let previewValue = Self()
}
#endif
