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
    
    var dispatchSemaphore: DispatchSemaphore?
    var sessionsDispatchGroup: DispatchGroup = DispatchGroup()
    var dispatchQueue: DispatchQueue?
    
    let downloadManager = DownloadManager()
    let dispatchGroup = DispatchGroup()
    
    var downloadTasks: [String] = []
    var completedTasks: [String] = []
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        option = SimulationOption(jobCount: Int(tasksCountSlider.value), maxAsyncTasks: Int(maxAsyncTasksSlider.value), isRandomizedTime: randomizeTimeSwitch.isOn)

        setupNavigationItems()
        
        downloadManager.delegate = self
    }
    
    private func setupNavigationItems() {
        let startButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(startOperation))
        navigationItem.rightBarButtonItem = startButtonItem
    }
    
    @objc func startOperation() {
        navigationItem.rightBarButtonItem?.isEnabled = false
        randomizeTimeSwitch.isEnabled = false
        tasksCountSlider.isEnabled = false
        maxAsyncTasksSlider.isEnabled = false
        
        dispatchQueue = DispatchQueue(label: "com.alfianlosari.test", qos: .userInitiated, attributes: .concurrent)
        dispatchSemaphore = DispatchSemaphore(value: option.maxAsyncTasks)
        
        for i in 0..<option.jobCount {
            if let url = URL(string: K.urls[i]) {
                dispatchGroup.enter()
                
                addDownloadCell(tableView: downloadTableView, name: K.names[i])
                
                downloadManager.downloadFile(url: url, name: K.names[i])
            }
        }

        dispatchGroup.notify(queue: .main) { [unowned self] in
            self.presentAlertWith(title: "Info", message: "All Download tasks has been completed 😋😋😋")
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.randomizeTimeSwitch.isEnabled = true
            self.tasksCountSlider.isEnabled = true
            self.maxAsyncTasksSlider.isEnabled = true
        }
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

extension JobListViewController: DownloadManagerDelegate {
    func onProgress(url: URL, name: String, progress: Double) {
        print("Download of \(name) is \(String(format: "%.2f", progress * 100))% complete")
        
        DispatchQueue.main.async { [weak self] in
            guard let index = self?.downloadTasks.firstIndex(of: name) else { return }
            
            guard let cell = self?.downloadTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ProgressCell else {
                return
            }
            
            cell.updateProgressBar(at: progress)
        }
    }
    
    func onCompletion(url: URL, name: String, location: URL?, error: Error?) {
        dispatchGroup.leave()
        if let location = location {
            print("Download of \(url.lastPathComponent) completed successfully at \(location)")
        } else {
            print("Download of \(url.lastPathComponent) failed with error: \(error?.localizedDescription ?? "Unknown error")")
        }
        
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return }
            
            // Downloaded
            self.deleteCell(tableView: self.downloadTableView, name: name)
            
            // completed
            guard let index = self.addCompletedCell(tableView: self.completedTableView, name: name) else { return }
            

            guard let cell = self.completedTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ProgressCell else {
                return
            }
            
            cell.completeProgressBar(at: index)
            cell.configure(name: name)
        }
    }
    
    private func deleteCell(tableView: UITableView, name: String) {
        guard let index = downloadTasks.firstIndex(of: name) else { return }
        downloadTasks.remove(at: index)
        
        tableView.performBatchUpdates({
            tableView.deleteRows(at: [IndexPath(item: index, section: 0)], with: .none)
        }, completion: nil)
    }
    
    private func addCompletedCell(tableView: UITableView, name: String) -> Int? {
        completedTasks.append(name)
        
        guard let index = completedTasks.firstIndex(of: name) else { return nil }
        
        tableView.performBatchUpdates({
            tableView.insertRows(at: [IndexPath(item: index, section: 0)], with: .none)
        }, completion: nil)
        
        return index
    }
    
    private func addDownloadCell(tableView: UITableView, name: String) {
        downloadTasks.append(name)
        
        guard let index = downloadTasks.firstIndex(of: name) else { return }
        
        tableView.performBatchUpdates({
            tableView.insertRows(at: [IndexPath(item: index, section: 0)], with: .none)
        }, completion: nil)
        
        guard let cell = downloadTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ProgressCell else {
            return
        }
        
        cell.configure(name: name)
    }
}

extension JobListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === downloadTableView {
            return downloadTasks.count
        } else if tableView === completedTableView {
            return completedTasks.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ProgressCell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView === downloadTableView {
            return "Download Queue"
        } else if tableView === completedTableView {
            return "Completed"
        } else {
            return nil
        }
    }
}
