import ComposableArchitecture
import CoreMotion
import SwiftUI

// MARK: - OnboardingStartup.View
extension OnboardingStartup {
	@MainActor
	public struct View: SwiftUI.View {
		@SwiftUI.State private var offsetX: CGFloat = 0
		@SwiftUI.State private var offsetY: CGFloat = 0

		let store: StoreOf<OnboardingStartup>

		public init(store: StoreOf<OnboardingStartup>) {
			self.store = store
		}
	}
}

extension OnboardingStartup.View {
	public var body: some View {
		NavigationStack {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					Text(L10n.Onboarding.Step1.title)
						.foregroundColor(.app.gray1)
						.textStyle(.sheetTitle)
						.padding(.top, .large1)
						.padding(.horizontal, .large1)
						.padding(.bottom, .medium3)

					Text(L10n.Onboarding.Step1.subtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.secondaryHeader)
						.padding(.horizontal, .huge3)

					Spacer(minLength: 0)

					SplashGraphic()

					Spacer(minLength: 0)
				}
				.multilineTextAlignment(.center)
				.footer {
					Button(L10n.Onboarding.newUser) {
						viewStore.send(.selectedNewWalletUser)
					}
					.buttonStyle(.primaryRectangular)
					.padding(.bottom, .small2)

					Button(L10n.Onboarding.restoreFromBackup) {
						viewStore.send(.selectedRestoreFromBackup)
					}
					.buttonStyle(.primaryText())
				}
			}
			.sheet(
				store: store.destination,
				state: /OnboardingStartup.Destinations.State.restoreFromBackup,
				action: OnboardingStartup.Destinations.Action.restoreFromBackup,
				content: {
					RestoreProfileFromBackupCoordinator.View(store: $0)
				}
			)
		}
	}
}

private extension StoreOf<OnboardingStartup> {
	var destination: PresentationStoreOf<OnboardingStartup.Destinations> {
		scope(state: \.$destination) { .child(.destination($0)) }
	}
}

// MARK: - SplashGraphic
@MainActor
struct SplashGraphic: View {
	@ObservedObject private var motion: MotionManager = .shared

	@State private var rotate: Bool = false

	private let height: CGFloat = 254
	private let maskWidth: CGFloat = 116
	private let maskHeight: CGFloat = 219
	private let maskRadius: CGFloat = 20
	private let verticalPadding: CGFloat = 10

	private let coordinateName: String = "ScrollViewCoords"

	var body: some View {
		GeometryReader { sizeProxy in
			ScrollView(.horizontal, showsIndicators: false) {
				GeometryReader { proxy in
					let offset = CGSize(width: proxy.frame(in: .named(coordinateName)).minX, height: 0) + motion.offset
					ZStack {
						items(offset: offset)
							.blur(radius: 5)

						RoundedRectangle(cornerRadius: maskRadius)
							.fill(.white)
							.frame(width: maskWidth, height: maskHeight)

						items(offset: offset)
							.mask {
								RoundedRectangle(cornerRadius: maskRadius)
									.frame(width: maskWidth, height: maskHeight)
							}

						Image(asset: AssetResource.splashPhoneFrame)
					}
					.frame(width: sizeProxy.size.width)
				}
				.padding(.vertical, verticalPadding)
			}

			.coordinateSpace(name: coordinateName)
		}
		.frame(height: height + 2 * verticalPadding)
		.onAppear {
			motion.start()
			withAnimation(.linear(duration: 90).repeatForever(autoreverses: false)) {
				rotate = true
			}
		}
		.onDisappear {
			motion.stop()
		}
	}

	private func items(offset: CGSize) -> some View {
		ZStack {
			ForEach(itemModels) { item in
				Image(asset: item.asset)
					.rotationEffect(.degrees(item.rotation * (rotate ? 360.0 : 0)))
					.offset(item.offset - item.z * offset)
			}
		}
	}

	private let itemModels: [ItemModel] = [
		.init(
			id: 1,
			asset: AssetResource.splashItem1,
			offset: .init(width: 55, height: -63),
			z: 0.35,
			rotation: 3
		),
		.init(
			id: 2,
			asset: AssetResource.splashItem2,
			offset: .init(width: -110, height: -50),
			z: 0.4,
			rotation: -5
		),
		.init(
			id: 3,
			asset: AssetResource.splashItem3,
			offset: .init(width: 16, height: 36),
			z: 0.53,
			rotation: 4
		),
		.init(
			id: 4,
			asset: AssetResource.splashItem4,
			offset: .init(width: 122, height: 82),
			z: 0.63,
			rotation: -4
		),
		.init(
			id: 5,
			asset: AssetResource.splashItem5,
			offset: .init(width: -117, height: 102),
			z: 0.69,
			rotation: -6
		),
	]

	private struct ItemModel: Identifiable {
		let id: Int
		let asset: ImageAsset
		let offset: CGSize
		let z: CGFloat
		let rotation: CGFloat
	}
}

// MARK: - MotionManager
@MainActor
final class MotionManager: ObservableObject {
	@Published var offset: CGSize = .zero

	/// Controls how fast we converge back to zero offset
	private let rho: CGFloat = 0.003
	/// Controls how much we scale the motion values
	private let scale: CGFloat = 0.7

	private let manager = CMMotionManager()

	static let shared = MotionManager()

	func stop() {
		manager.stopDeviceMotionUpdates()
	}

	func start() {
		manager.deviceMotionUpdateInterval = 1 / 60
		manager.startDeviceMotionUpdates(to: .main) { [weak self] motionData, error in
			guard let self else { return }
			if let error {
				loggerGlobal.warning("Onboarding splash parallax CoreMotion error: \(error)")
				return
			} else if let motionData {
				let rate = CGSize(width: motionData.rotationRate.y, height: motionData.rotationRate.x)
				offset = (1 - rho) * (offset + scale * rate)
			}
		}
	}
}
