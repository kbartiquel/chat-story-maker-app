//
//  TimestampView.swift
//  ChatStoryMaker
//
//  iMessage-style centered timestamp divider
//

import SwiftUI

struct TimestampView: View {
    let date: Date

    private var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        Text(formattedTime)
            .font(.system(size: 11, weight: .regular))
            .foregroundColor(Color(.systemGray))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        TimestampView(date: Date())
        TimestampView(date: Date().addingTimeInterval(-86400))
        TimestampView(date: Date().addingTimeInterval(-86400 * 5))
    }
}
