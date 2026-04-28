import Foundation
import Supabase

enum Backend {
    static let client: SupabaseClient = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey
    )
}
