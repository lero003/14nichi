import FourteenDayCore
import Foundation
import LocalAuthentication

/// 緊急カード本文の閲覧ゲート。暗号化キーとしては使わない（脅威モデル §6）。
@MainActor
struct LocalAuthenticationService {
    var biometricsPolicy: LAPolicy = .deviceOwnerAuthentication

    func canEvaluate() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(biometricsPolicy, error: &error)
    }

    func authenticate(reason: String) async -> EmergencyCardAuthenticationResult {
        let context = LAContext()
        context.localizedCancelTitle = "キャンセル"

        var error: NSError?
        guard context.canEvaluatePolicy(biometricsPolicy, error: &error) else {
            return .notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(biometricsPolicy, localizedReason: reason)
            return success ? .success : .failed
        } catch let authError as LAError {
            switch authError.code {
            case .userCancel, .appCancel, .systemCancel:
                return .cancelled
            case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet:
                return .notAvailable
            default:
                return .failed
            }
        } catch {
            return .failed
        }
    }
}
