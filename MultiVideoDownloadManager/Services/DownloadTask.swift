//
//  DownloadTask.swift
//  MultiVideoDownloadManager
//
//  Created by yilmaz on 27.12.2022.
//

import Foundation

protocol DownloadManagerDelegate: AnyObject {
    func onProgress(url: URL, name: String, progress: Double)
    func onCompletion(url: URL, name: String, location: URL?, error: Error?)
}

class DownloadTask {
    let url: URL
    let task: URLSessionDownloadTask
    let name: String
    
    init(url: URL, task: URLSessionDownloadTask, name: String) {
        self.url = url
        self.task = task
        self.name = name
    }
}

class DownloadManager: NSObject, URLSessionDownloadDelegate {
    private var tasks = NSMapTable<URLSessionDownloadTask, DownloadTask>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.yourapp.downloadmanager")
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    weak var delegate: DownloadManagerDelegate?
    
    func downloadFile(url: URL, name: String) {
        let task = session.downloadTask(with: url)
        let downloadTask = DownloadTask(url: url, task: task, name: name)
        tasks.setObject(downloadTask, forKey: task)
        task.resume()
    }
    
    // MARK: - URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let task = tasks.object(forKey: downloadTask) else {
            return
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(task.name)
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            delegate?.onCompletion(url: task.url, name: task.name, location: location, error: nil)
        } catch {
            delegate?.onCompletion(url: task.url, name: task.name, location: nil, error: error)
        }
        tasks.removeObject(forKey: downloadTask)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let downloadTask = tasks.object(forKey: downloadTask) else { return }
        let percentage = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        delegate?.onProgress(url: downloadTask.url, name: downloadTask.name, progress: percentage)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let sessionTask = task as? URLSessionDownloadTask,
              let downloadTask = tasks.object(forKey: sessionTask) else { return }
        tasks.removeObject(forKey: sessionTask)
        
        delegate?.onCompletion(url: downloadTask.url, name: downloadTask.name, location: nil, error: error)
    }
    
    func pauseDownload(name: String) {
        let task = tasks.objectEnumerator()?.allObjects as? [DownloadTask] ?? []
        task.filter({$0.name == name}).first?.task.suspend()
    }

    func resumeDownload(name: String) {
        let task = tasks.objectEnumerator()?.allObjects as? [DownloadTask] ?? []
        task.filter({$0.name == name}).first?.task.resume()
    }
}


enum TaskState {
    case pending
    case inProgess(Int)
    case completed
    
    var description: String {
        switch self {
        case .pending:
            return "Pending"
            
        case .inProgess(_):
            return "Downloading"
            
        case .completed:
            return "Completed"
        }
    }
}

