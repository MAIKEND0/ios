// NotificationsView.swift
import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showFilterSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtry
                filterBar
                
                // Lista powiadomień
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else if viewModel.displayedNotifications.isEmpty {
                    emptyNotificationsView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.displayedNotifications) { notification in
                                notificationCard(notification: notification)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilterSheet.toggle()
                    } label: {
                        Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(viewModel.hasActiveFilters ? Color.ksrYellow : Color.gray)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.markAllAsRead()
                    } label: {
                        Text("Mark All Read")
                            .foregroundColor(viewModel.unreadCount > 0 ? Color.ksrYellow : .gray)
                    }
                    .disabled(viewModel.unreadCount == 0)
                }
            }
            .onAppear {
                viewModel.loadNotifications()
            }
            .sheet(isPresented: $showFilterSheet) {
                filterSheet
            }
            .alert(isPresented: Binding(
                get: { viewModel.lastError != nil },
                set: { if !$0 { viewModel.lastError = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.lastError?.errorDescription ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .refreshable {
                viewModel.refreshNotifications()
            }
        }
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Clear filters button
                if viewModel.hasActiveFilters {
                    Button {
                        withAnimation {
                            viewModel.clearFilters()
                        }
                    } label: {
                        FilterChip(
                            label: "Clear All",
                            isSelected: false,
                            backgroundColor: .red.opacity(0.1),
                            foregroundColor: .red
                        )
                    }
                }
                
                // Filtr kategorii
                Menu {
                    Button("All Categories", action: { viewModel.setCategory(nil) })
                    ForEach(NotificationCategory.allCases, id: \.self) { category in
                        Button(category.displayName, action: { viewModel.setCategory(category) })
                    }
                } label: {
                    FilterChip(
                        label: viewModel.selectedCategory?.displayName ?? "Category",
                        isSelected: viewModel.selectedCategory != nil
                    )
                }
                
                // Filtr priorytetu
                Menu {
                    Button("All Priorities", action: { viewModel.setPriority(nil) })
                    ForEach(NotificationPriority.allCases, id: \.self) { priority in
                        Button(priority.displayName, action: { viewModel.setPriority(priority) })
                    }
                } label: {
                    FilterChip(
                        label: viewModel.selectedPriority?.displayName ?? "Priority",
                        isSelected: viewModel.selectedPriority != nil
                    )
                }
                
                // Toggle nieprzeczytanych
                Button {
                    viewModel.setShowUnreadOnly(!viewModel.showUnreadOnly)
                } label: {
                    FilterChip(
                        label: "Unread Only",
                        isSelected: viewModel.showUnreadOnly
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
    }
    
    // MARK: - Filter Sheet
    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Search")) {
                    TextField("Search notifications...", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section(header: Text("Filters")) {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("All Categories").tag(NotificationCategory?.none)
                        ForEach(NotificationCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(NotificationCategory?.some(category))
                        }
                    }
                    
                    Picker("Priority", selection: $viewModel.selectedPriority) {
                        Text("All Priorities").tag(NotificationPriority?.none)
                        ForEach(NotificationPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(NotificationPriority?.some(priority))
                        }
                    }
                    
                    Toggle("Show Only Unread", isOn: $viewModel.showUnreadOnly)
                }
                
                Section(header: Text("Statistics")) {
                    HStack {
                        Text("Total Notifications")
                        Spacer()
                        Text("\(viewModel.displayedNotifications.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Unread")
                        Spacer()
                        Text("\(viewModel.unreadCount)")
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("Requiring Action")
                        Spacer()
                        Text("\(viewModel.getNotificationsRequiringAction().count)")
                            .foregroundColor(.orange)
                    }
                }
                
                Section {
                    Button("Clear All Filters") {
                        viewModel.clearFilters()
                        showFilterSheet = false
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showFilterSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        viewModel.applyFilters()
                        showFilterSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Notifications View
    private var emptyNotificationsView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle" : "bell.slash")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text(viewModel.hasActiveFilters ? "No notifications match your filters" : "No notifications")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
            
            Text(viewModel.hasActiveFilters ?
                 "Try adjusting your filters to see more notifications" :
                 "New notifications will appear here when available")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                .padding(.horizontal)
            
            if viewModel.hasActiveFilters {
                Button("Clear Filters") {
                    withAnimation {
                        viewModel.clearFilters()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.ksrYellow.opacity(0.2))
                .foregroundColor(Color.ksrYellow)
                .cornerRadius(8)
            } else {
                Button {
                    viewModel.refreshNotifications()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.ksrYellow.opacity(0.2))
                    .foregroundColor(Color.ksrYellow)
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Notification Card
    private func notificationCard(notification: AppNotification) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Ikona
                Image(systemName: notification.iconName)
                    .font(.title2)
                    .foregroundColor(Color(notification.iconColor))
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
                
                // Treść
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : Color.ksrDarkGray)
                        Spacer()
                        Text(notification.formattedDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color.ksrMediumGray)
                        .lineLimit(3)
                    
                    if let context = notification.contextualInfo {
                        Text(context)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Priority indicator
                    if let priority = notification.priority, priority != .normal {
                        HStack {
                            Image(systemName: priority == .urgent ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                .font(.caption)
                            Text(priority.displayName.uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(priority == .urgent ? .red : .orange)
                        .padding(.top, 2)
                    }
                }
                
                // Wskaźnik nieprzeczytania
                if !notification.isRead {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(.red)
                }
            }
            
            // Quick Actions
            let quickActions = viewModel.getQuickActions(for: notification)
            if !quickActions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(quickActions.indices, id: \.self) { index in
                        let action = quickActions[index]
                        Button(action: action.action) {
                            HStack(spacing: 4) {
                                Image(systemName: action.icon)
                                    .font(.caption)
                                Text(action.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(action.color.opacity(0.1))
                            .foregroundColor(action.color)
                            .cornerRadius(6)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : .white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        .onTapGesture {
            if let action = viewModel.handleNotificationTap(notification) {
                handleNotificationAction(action)
            }
        }
    }
    
    // MARK: - Action Handling
    private func handleNotificationAction(_ action: NotificationAction) {
        switch action {
        case .navigateToWorkEntry(let taskId, let workEntryId):
            // Navigate to work entry form
            NotificationCenter.default.post(
                name: .openWorkEntryForm,
                object: nil,
                userInfo: [
                    "taskId": taskId ?? 0,
                    "workEntryId": workEntryId ?? 0
                ]
            )
            dismiss()
            
        case .navigateToTask(let taskId):
            // Navigate to task details
            NotificationCenter.default.post(
                name: .openTaskDetails,
                object: nil,
                userInfo: ["taskId": taskId ?? 0]
            )
            dismiss()
            
        case .navigateToProfile:
            // Navigate to profile
            dismiss()
            
        case .showEmergencyDetails(let notification):
            // Show emergency alert
            showEmergencyAlert(notification)
            
        case .openURL(let url):
            if let nsUrl = URL(string: url) {
                UIApplication.shared.open(nsUrl)
            }
        }
    }
    
    private func showEmergencyAlert(_ notification: AppNotification) {
        // Implementation for emergency alert
    }
}

// MARK: - Enhanced Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var backgroundColor: Color = Color.ksrYellow.opacity(0.2)
    var foregroundColor: Color = Color.ksrYellow
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? backgroundColor : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? foregroundColor : (colorScheme == .dark ? .white : .primary))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? foregroundColor : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NotificationsView()
                .preferredColorScheme(.light)
            NotificationsView()
                .preferredColorScheme(.dark)
        }
    }
}
