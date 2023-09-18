import AsyncExtensions
import ComposableArchitecture
import Dependencies
@_exported import DesignSystem
@_exported import Resources
import SwiftUI

// MARK: - OverlayWindowClient
/// This client is the intermediary between Main Window and the Overlay Window.
public struct OverlayWindowClient: Sendable {
	/// All scheduled items to be shown in Overlay Window.
	public var scheduledItems: ScheduledItems

	/// Schedule an Alert to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	public var scheduleAlert: ScheduleAlert

	/// Schedule a HUD to be shown in the Overlay Window.
	/// Usually to be called from the Main Window.
	public var scheduleHUD: ScheduleHUD

	/// This is meant to be used by the Overlay Window to send
	/// back the actions from an Alert to the Main Window.
	public var sendAlertAction: SendAlertAction

	public var setIsUserIteractionEnabled: SetIsUserIteractionEnabled
	public var isUserInteractionEnabled: IsUserInteractionEnabled

	public init(
		scheduledItems: @escaping ScheduledItems,
		scheduleAlert: @escaping ScheduleAlert,
		scheduleHUD: @escaping ScheduleHUD,
		sendAlertAction: @escaping SendAlertAction,
		setIsUserIteractionEnabled: @escaping SetIsUserIteractionEnabled,
		isUserInteractionEnabled: @escaping IsUserInteractionEnabled
	) {
		self.scheduledItems = scheduledItems
		self.scheduleAlert = scheduleAlert
		self.scheduleHUD = scheduleHUD
		self.sendAlertAction = sendAlertAction
		self.setIsUserIteractionEnabled = setIsUserIteractionEnabled
		self.isUserInteractionEnabled = isUserInteractionEnabled
	}
}

extension OverlayWindowClient {
	public typealias ScheduleAlert = @Sendable (Item.AlertState) async -> Item.AlertAction
	public typealias ScheduleHUD = @Sendable (Item.HUD) -> Void
	public typealias SendAlertAction = @Sendable (Item.AlertAction, Item.AlertState.ID) -> Void
	public typealias ScheduledItems = @Sendable () -> AnyAsyncSequence<Item>

	public typealias SetIsUserIteractionEnabled = @Sendable (Bool) -> Void
	public typealias IsUserInteractionEnabled = @Sendable () -> AnyAsyncSequence<Bool>
}

// MARK: OverlayWindowClient.Item
extension OverlayWindowClient {
	public enum Item: Sendable, Hashable {
		public typealias AlertState = ComposableArchitecture.AlertState<AlertAction>
		public enum AlertAction: Equatable {
			case primaryButtonTapped
			case secondaryButtonTapped
			case dismissed
		}

		public struct HUD: Sendable, Hashable, Identifiable {
			public let id = UUID()
			public let text: String
			public let icon: Icon?

			public struct Icon: Hashable, Sendable {
				public enum Kind: Hashable, Sendable {
					case asset(ImageAsset)
					case system(String)
				}

				public let kind: Kind
				public let foregroundColor: Color

				public init(
					kind: Kind,
					foregroundColor: Color = .app.green1
				) {
					self.kind = kind
					self.foregroundColor = foregroundColor
				}
			}

			// FIXME: Strings
			public static let copied = Self(text: "Copied")

			// FIXME: Strings
			public static let updated = Self(text: "Updated")

			public init(
				text: String,
				icon: Icon? = Icon(
					kind: .system("checkmark.circle.fill"),
					foregroundColor: Color.app.green1
				)
			) {
				self.text = text
				self.icon = icon
			}
		}

		case hud(HUD)
		case alert(AlertState)
	}
}

extension DependencyValues {
	public var overlayWindowClient: OverlayWindowClient {
		get { self[OverlayWindowClient.self] }
		set { self[OverlayWindowClient.self] = newValue }
	}
}
