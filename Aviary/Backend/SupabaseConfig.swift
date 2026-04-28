import Foundation

enum SupabaseConfig {
    static var isConfigured: Bool {
        guard let urlString = string(forKey: "SUPABASE_URL"),
              !urlString.contains("YOUR-PROJECT-REF"),
              URL(string: urlString) != nil,
              let key = string(forKey: "SUPABASE_ANON_KEY"),
              !key.isEmpty,
              key != "YOUR-ANON-PUBLISHABLE-KEY" else {
            return false
        }
        return true
    }

    static let url: URL = {
        if let value = string(forKey: "SUPABASE_URL"),
           !value.contains("YOUR-PROJECT-REF"),
           let url = URL(string: value) {
            return url
        }
        return URL(string: "https://placeholder.supabase.co")!
    }()

    static let anonKey: String = {
        if let value = string(forKey: "SUPABASE_ANON_KEY"),
           !value.isEmpty,
           value != "YOUR-ANON-PUBLISHABLE-KEY" {
            return value
        }
        return "placeholder"
    }()

    private static func string(forKey key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        return dict[key] as? String
    }
}
