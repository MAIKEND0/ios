//
//  WorkerTaskDetailView.swift
//  KSR Cranes App
//
//  Created by Maksymilian Marcinowski on 14/05/2025.
//

import SwiftUI

struct WorkerTaskDetailView: View {
    let task: WorkerAPIService.Task

    var body: some View {
        Form {
            Section("Projekt") {
                Text(task.project?.title ?? "-")
            }
            Section("Opis") {
                Text(task.description ?? "Brak opisu")
            }
            Section("Deadline") {
                if let deadline = task.deadline {
                    Text(DateFormatter.localizedString(
                        from: deadline, dateStyle: .medium, timeStyle: .none))
                } else {
                    Text("Brak")
                }
            }
        }
        .navigationTitle("Szczegóły zadania")
    }
}

struct WorkerTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let example = WorkerAPIService.Task(
            task_id: 1,
            title: "Przykładowe zadanie",
            description: "Opis",
            deadline: nil,
            project: nil
        )
        return NavigationView {
            WorkerTaskDetailView(task: example)
        }
    }
}
