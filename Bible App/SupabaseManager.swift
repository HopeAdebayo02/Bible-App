//
//  SupabaseManager.swift
//  Bible App
//
//  Created by Hope Adebayo on 9/9/25.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let supabaseURL = URL(string: "https://bvbqaueaupzuwdtlneqb.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2YnFhdWVhdXB6dXdkdGxuZXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1MzU1NTgsImV4cCI6MjA3MzExMTU1OH0.KPEdfZ6LHq-lNvZr6YEy9r5PxjS8k7pteo3A0Nad6r8"

        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
}
