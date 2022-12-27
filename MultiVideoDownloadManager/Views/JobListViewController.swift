//
//  JobListViewController.swift
//  MultiVideoDownloadManager
//
//  Created by yilmaz on 27.12.2022.
//

import UIKit

class JobListViewController: UIViewController {
    @IBOutlet weak var downloadTableView: UITableView!
    @IBOutlet weak var completedTableView: UITableView!
    @IBOutlet weak var tasksCountSlider: UISlider!
    @IBOutlet weak var randomizeTimeSwitch: UISwitch!
    @IBOutlet weak var jobLabel: UILabel!
    @IBOutlet weak var maxAsyncTasksSlider: UISlider!
    @IBOutlet weak var maxAsyncTasksLabel: UILabel!
    
    var sessionsDownloadTask: [URLSessionDownloadTask] = []
    let operationQueue = OperationQueue()
    var dispatchSemaphore: DispatchSemaphore?
    var dispatchGroup: DispatchGroup?
    var sessionsDispatchGroup: DispatchGroup = DispatchGroup()
    var dispatchQueue: DispatchQueue?
    
    struct SimulationOption {
        var jobCount: Int
        var maxAsyncTasks: Int
        var isRandomizedTime: Bool
    }
    
    var option: SimulationOption! {
        didSet {
            updateJobLabel()
            updateMaxAsyncLabel()
        }
    }
    
    var downloadTasks = [DownloadTask]() {
        didSet {
            downloadTableView.reloadData()
        }
    }
    var completedTasks = [DownloadTask]() {
        didSet {
            completedTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        option = SimulationOption(jobCount: Int(tasksCountSlider.value), maxAsyncTasks: Int(maxAsyncTasksSlider.value), isRandomizedTime: randomizeTimeSwitch.isOn)
        downloadTableView.tableFooterView = UIView()
        completedTableView.tableFooterView = UIView()
        setupNavigationItems()
    }
    
    private func setupNavigationItems() {
        let startButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(startOperation))
        navigationItem.rightBarButtonItem = startButtonItem
    }
    
    @objc func startOperation() {
        downloadTasks = []
        completedTasks = []
        sessionsDownloadTask = []
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        randomizeTimeSwitch.isEnabled = false
        tasksCountSlider.isEnabled = false
        maxAsyncTasksSlider.isEnabled = false
        
        dispatchQueue = DispatchQueue(label: "com.alfianlosari.test", qos: .userInitiated, attributes: .concurrent)
        dispatchGroup = DispatchGroup()
        dispatchSemaphore = DispatchSemaphore(value: option.maxAsyncTasks)
        
        downloadTasks = (0..<option.jobCount).map({ (i) -> DownloadTask in
            let identifier = "\(i)"
            return DownloadTask(identifier: identifier, stateUpdateHandler: { (task) in
                DispatchQueue.main.async { [unowned self] in
                    
                    // session enter
                    sessionsDispatchGroup.enter()
                    guard let index = self.downloadTasks.indexOfTaskWith(identifier: identifier) else {
                        return
                    }
                    
                    switch task.state {
                    case .completed:
                        self.downloadTasks.remove(at: index)
                        self.completedTasks.insert(task, at: 0)
                        
                    case .pending, .inProgess(_):
                        guard let cell = self.downloadTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ProgressCell else {
                            return
                        }
                        cell.configure(task, at: index)
                        self.downloadTableView.beginUpdates()
                        self.downloadTableView.endUpdates()
                    }
                    
                    // session leave
                    sessionsDispatchGroup.leave()
                }
            })
        })
        
        for i in 0..<option.jobCount {
            if let url = URL(string: K.urls[i]) {
                download(from: url)
            }
        }
        
        for el in sessionsDownloadTask {
            dispatchQueue?.async(group: dispatchGroup) { [weak self] in
                self?.dispatchGroup?.enter()
                self?.dispatchSemaphore?.wait()
                el.resume()
            }
        }
        
        dispatchGroup?.notify(queue: .main) { [unowned self] in
            self.presentAlertWith(title: "Info", message: "All Download tasks has been completed 😋😋😋")
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.randomizeTimeSwitch.isEnabled = true
            self.tasksCountSlider.isEnabled = true
            self.maxAsyncTasksSlider.isEnabled = true
        }
    }
    
    func download(from url: URL) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        let downloadTask = session.downloadTask(with: url)
        sessionsDownloadTask.append(downloadTask)
    }
    
    @IBAction func maxAsyncTasksSliderchanged(_ sender: UISlider) {
        option.maxAsyncTasks = Int(sender.value)
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        option.jobCount = Int(sender.value)
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        option.isRandomizedTime = sender.isOn
    }
    
    private func updateMaxAsyncLabel() {
        maxAsyncTasksLabel.text = "\(option.maxAsyncTasks) Max Parallel Running Tasks"
    }
    
    private func updateJobLabel() {
        jobLabel.text = "\(option.jobCount) Tasks"
    }
    
    private func presentAlertWith(title: String , message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension JobListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === downloadTableView {
            return downloadTasks.count
        } else if tableView === completedTableView {
            return completedTasks.count
        } else {
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ProgressCell
        let task: DownloadTask
        if tableView === downloadTableView {
            task = downloadTasks[indexPath.row]
        } else if tableView === completedTableView {
            task = completedTasks[indexPath.row]
        } else {
            fatalError()
        }
        cell.configure(task, at: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView === downloadTableView {
            return "Download Queue (\(downloadTasks.count))"
        } else if tableView === completedTableView {
            return "Completed (\(completedTasks.count))"
        } else {
            return nil
        }
    }
    
}

extension JobListViewController: URLSessionDownloadDelegate {
    // MARK: protocol stub for download completion tracking
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        // session enter
        sessionsDispatchGroup.enter()
        let index = sessionsDownloadTask.firstIndex(of: downloadTask) ?? 0
        
        sessionsDownloadTask.remove(at: index)
        downloadTasks[index].state = .completed
        
        // session leave
        sessionsDispatchGroup.leave()
        
        dispatchGroup?.leave()
        dispatchSemaphore?.signal()
        
        print("Download finished: \(index)")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        
        let index = sessionsDownloadTask.firstIndex(of: downloadTask) ?? 0
        
        downloadTasks[index].state = .inProgess(Int(progress * 100))
        
        print("Download in progress: \(index)" + " - " + "\(progress * 100)".components(separatedBy: ".")[0] + "%")
    }
}
