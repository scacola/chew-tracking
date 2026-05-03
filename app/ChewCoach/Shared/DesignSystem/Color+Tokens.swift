import SwiftUI

extension Color {
    /// Asset 카탈로그 없이도 dark mode adaptive하도록 dynamic UIColor로 정의.
    /// Asset 카탈로그가 빌드 환경에 등록되면 `Color("BrandPrimary")` 자동 fallback 가능.
    static let brandPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.498, green: 0.612, blue: 1.0, alpha: 1.0)
            : UIColor(red: 0.357, green: 0.486, blue: 1.0, alpha: 1.0)
    })

    static let brandAccent = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.745, blue: 0.396, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.710, blue: 0.290, alpha: 1.0)
    })

    static let positive = Color(uiColor: .systemGreen)
    static let warning = Color(uiColor: .systemOrange)
    static let critical = Color(uiColor: .systemRed)
}
