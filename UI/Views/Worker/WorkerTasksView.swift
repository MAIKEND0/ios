//
//  WorkerTasksView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 14/05/2025.
//

import SwiftUI

struct WorkerTasksView: View {
    @StateObject private var viewModel = WorkerTasksViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Ładowanie zadań…")
                } else if let error = viewModel.error {
                    Text(error).foregroundColor(.red)
                } else {
                    List(viewModel.tasks, id: \.task_id) { task in
                        NavigationLink(destination: WorkerTaskDetailView(task: task)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.headline)
                                Text(task.project?.title ?? "Brak projektu")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Moje zadania")
            .onAppear { viewModel.loadTasks() }
        }
    }
}

struct WorkerTasksView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerTasksView()
    }
}
