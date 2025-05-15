import SwiftUI

struct WorkerTasksView: View {
    @StateObject private var viewModel = WorkerTasksViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Ładowanie zadań…")
                } else if let error = viewModel.error {
                    Text(error).foregroundColor(Color.red)
                } else {
                    List(viewModel.tasks, id: \.task_id) { task in
                        NavigationLink(destination: WorkerTaskDetailView(task: task)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(Font.headline)
                                Text(task.project?.title ?? "Brak projektu")
                                    .font(Font.subheadline)
                                    .foregroundColor(Color.secondary)
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

// Usunięta definicja WorkerTaskDetailView - już istnieje w oddzielnym pliku

struct WorkerTasksView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerTasksView()
    }
}
