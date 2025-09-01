//
//  SessionTimerView.swift
//  Narration
//
//  Session timer display component
//

import SwiftUI

struct SessionTimerView: View {
    @ObservedObject var session: VisitSession
    
    var body: some View {
        if session.isSessionActive {
            HStack(spacing: 8) {
                Image(systemName: session.sessionTimeRemaining > 120 ? "clock" : "clock.fill")
                    .foregroundColor(session.sessionTimeRemaining > 120 ? .blue : .orange)
                
                Text("Session: \(session.formatTime(session.sessionTimeRemaining))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(session.sessionTimeRemaining > 120 ? .blue : .orange)
                
                if session.sessionTimeRemaining <= 0 {
                    Text("(Expired)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(session.sessionTimeRemaining > 120 ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
            )
            .animation(.easeInOut(duration: 0.3), value: session.sessionTimeRemaining > 120)
        }
    }
}